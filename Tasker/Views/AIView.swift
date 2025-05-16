//
//  AIView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI

struct AIView: View {
    // Binding to manage the task list shared with other views
    @Binding var tasks: [Task]
    @Binding var isPresented: Bool
    @State private var userInput: String = ""
    @State private var errorMessage: String? = nil
    let groqAPI = GroqAPI()

    var body: some View {
        VStack {
            // TextField for user input with a placeholder
            TextField("Enter your task...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Instructions for the user on how to format input
            VStack(alignment: .leading) {
                Text("- For singular tasks only")
                Text("- Task Category will always be Yellow, and end time will always be 11:59 PM")
                Text("- Include the end date for the task as MM/DD/YYYY")
            }
            
            // Button to trigger the processing of the user input
            Button(action: {
                processUserInput()
                isPresented = false}) {
                Text("Add Task")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            // Display any error message if it exists
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("AI Task Assistant") // Sets the title for the navigation bar
    }
    
    // Processes user input by calling the GroqAPI to extract relevant task details
    func processUserInput() {
        groqAPI.extractEntities(from: userInput) { result in
            switch result {
            case .success(let extractedInfo): // If extraction is successful
                DispatchQueue.main.async {
                    print("Extracted Info: \(extractedInfo)")
                    self.createTask(from: extractedInfo) // Create a task from the extracted information
                }
            case .failure(let error): // If there was an error
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to process input: \(error.localizedDescription)"
                }
            }
        }
    }

    // Parses the extracted information and creates a new task
    func createTask(from extractedInfo: String) {
        print("Parsing Extracted Info: \(extractedInfo)")

        // Split the extracted information into components for parsing
        let components = extractedInfo.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var taskName = ""
        var dueDate: Date? = nil
        var categoryColor: Color = .yellow // Default category color is yellow
        let calendar = Calendar.current

        // Iterate through components to extract specific task attributes
        for component in components {
            if component.lowercased().hasPrefix("* due date:") { // Check if the component specifies a due date
                let dateString = component.replacingOccurrences(of: "* Due date:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy" // Expecting the date in MM/dd/yyyy format
                if let date = formatter.date(from: dateString) {
                    // Set the due date to the end of the specified day
                    dueDate = calendar.startOfDay(for: date).addingTimeInterval(23 * 60 * 60 + 59 * 60)
                }
            } else if component.lowercased().hasPrefix("* task name:") { // Check if the component specifies a task name
                taskName = component.replacingOccurrences(of: "* Task name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if component.lowercased().contains("color:") { // Check if the component specifies a category color
                let colorString = component.replacingOccurrences(of: "color:", with: "").trimmingCharacters(in: .whitespaces)
                switch colorString.lowercased() {
                case "blue":
                    categoryColor = .blue
                case "red":
                    categoryColor = .red
                case "green":
                    categoryColor = .green
                case "yellow":
                    categoryColor = .yellow
                default:
                    categoryColor = .yellow // Default to yellow if color is not recognized
                }
            }
        }

        // Validate task details and show an error if necessary
        if taskName.isEmpty {
            errorMessage = "Task name is missing."
            print("Error: Task name is missing.")
            return
        }

        // Create a new Task object
        let newTask = Task(name: taskName, beginTime: nil, endTime: nil, days: nil, dueDate: dueDate, categoryColor: categoryColor, isCompleted: false)
        tasks.append(newTask) // Add the task to the list
        print("Tasks after appending: \(tasks)")
        errorMessage = nil // Clear any error messages
    }
}



struct Message: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

class GroqAPI {
    let apiKey = "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"
    let model = "llama3-8b-8192"

    func extractEntities(from userInput: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let systemMessage = Message(role: "system", content: "Extract the task name, days, start time, end time, and due date from the following input. For repeating tasks, extract days of the week and time intervals. Convert any relative dates such as 'next Wednesday' to an absolute date in the format MM/dd/yyyy.")
        let userMessage = Message(role: "user", content: userInput)
        let chatRequest = ChatCompletionRequest(model: model, messages: [systemMessage, userMessage])

        do {
            let encoder = JSONEncoder()
            let requestBody = try encoder.encode(chatRequest)
            request.httpBody = requestBody
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }

            do {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                if let content = chatResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

