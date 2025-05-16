//
//  TaskListView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI

struct TaskListView: View {
    @Binding var tasks: [Task]
    @Binding var selectedDate: Date

    // State variables to control UI behaviors
    @State private var isShowingTaskForm = false
    @State private var isDeleteMode = false
    @State private var isLeadingSheetPresented = false
    @State private var isTrailingSheetPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Button to go to the previous day
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                // Display the formatted selected date
                Text(formattedDate(selectedDate))
                    .font(.headline)
                    .padding()

                Spacer()

                // Button to go to the next day
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // List of tasks for the selected day
            List {
                // Section for tasks that are due
                Section(header: Text("Tasks Due")) {
                    ForEach(tasksForToday().filter { $0.dueDate != nil && !$0.isCompleted }, id: \.self) { task in
                        HStack {
                            TaskView(task: task) // Displays task details
                            Spacer()
                            if isDeleteMode {
                                // Button to delete the task in delete mode
                                Button(action: {
                                    deleteTask(task)
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }

                // Section for scheduled tasks
                Section(header: Text("Scheduled Items")) {
                    ForEach(tasksForToday().filter { $0.beginTime != nil && $0.endTime != nil && !$0.isCompleted }, id: \.self) { task in
                        HStack {
                            TaskView(task: task) // Displays task details
                            Spacer()
                            if isDeleteMode {
                                // Button to delete the task in delete mode
                                Button(action: {
                                    deleteTask(task)
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
            }

            // Button to toggle delete mode
            Button(action: {
                isDeleteMode.toggle()
            }) {
                Text(isDeleteMode ? "Done" : "Delete Tasks") // Updates button label dynamically
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            .padding()
        }
        .navigationTitle("Tasks List") // Title for the view
        .toolbar {
            // Toolbar buttons
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isLeadingSheetPresented = true
                }) {
                    HStack{
                        Image(systemName: "sparkles")
                        Text("AI Feature")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isTrailingSheetPresented = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        // Sheets for AI and task form views
        .sheet(isPresented: $isLeadingSheetPresented) {
            AIView(tasks: $tasks, isPresented: $isLeadingSheetPresented)
        }
        .sheet(isPresented: $isTrailingSheetPresented) {
            TaskFormView(tasks: $tasks)
        }
    }
    
    // Filters tasks for the selected date
    func tasksForToday() -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: selectedDate) // Matches due date to selected date
            }
            if let days = task.days {
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1]
                return days.contains(dayName) // Matches repeat days
            }
            return false
        }
    }
    
    // Formats the date to show only time
    func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Formats the date to a medium style
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Deletes a task from the list
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
}

struct TaskView: View {
    let task: Task // Task to display
    var showTimeOnly: Bool = false // Controls whether to show only time

    var body: some View {
        VStack(alignment: .leading) {
            Text(task.name) // Task name
                .font(.headline)
            
            // Display task times or due dates
            if let beginTime = task.beginTime, let endTime = task.endTime {
                Text("\(formattedTimeOnly(beginTime)) - \(formattedTimeOnly(endTime))") // Time range for scheduled tasks
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else if let dueDate = task.dueDate {
                Text(showTimeOnly ? "Due at: \(formattedTimeOnly(dueDate))" : "Due: \(formattedTime(dueDate))") // Due date
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(task.categoryColor.opacity(0.1)) // Background color based on task category
        .cornerRadius(8) // Rounded corners for task view
    }
    
    // Formats the date and time
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Formats only the time
    func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

