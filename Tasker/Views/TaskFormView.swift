//
//  TaskFormView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI
import UserNotifications

struct TaskFormView: View {
    @Binding var tasks: [Task]
    
    @State private var taskName: String = ""
    @State private var beginTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var selectedDays: [String] = []
    @State private var isScheduled: Bool = true
    @State private var dueDate: Date = Date()
    @State private var selectedColor: Color = .blue
    
    // Calendar and pre-defined color options
    let calendar = Calendar.current
    let colors: [Color] = [.blue, .red, .green, .yellow]

    var body: some View {
        NavigationView {
            Form {
                // Section to toggle task type
                Section(header: Text("Task Type")) {
                    Toggle(isOn: $isScheduled) {
                        Text(isScheduled ? "Scheduled Task" : "Due Task") // Label updates dynamically
                    }
                }
                
                // Section for entering task details
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName) // Input for task name
                    
                    if isScheduled {
                        // Inputs for scheduled task times
                        DatePicker("Begin Time", selection: $beginTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                        
                        // Color picker for task category
                        HStack {
                            Text("Pick Category")
                            Spacer()
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 25)
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color // Updates the selected color
                                    }
                            }
                        }
                    } else {
                        // Input for due task date and time
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .onAppear {
                                // Sets default due time to 11:59 PM if unchanged
                                if dueDate == Date() {
                                    dueDate = calendar.startOfDay(for: Date()).addingTimeInterval(23 * 60 * 60 + 59 * 60)
                                }
                            }
                        
                        // Color picker for task category
                        HStack {
                            Text("Pick Category")
                            Spacer()
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 25)
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }
                
                // Section to select repeat days for scheduled tasks
                if isScheduled {
                    Section(header: Text("Repeat Days")) {
                        ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                            HStack {
                                Text(day)
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle()) // Makes the whole row tappable
                            .onTapGesture {
                                // Toggles day selection
                                if let index = selectedDays.firstIndex(of: day) {
                                    selectedDays.remove(at: index)
                                } else {
                                    selectedDays.append(day)
                                }
                            }
                        }
                    }
                }
                
                // Button to add the new task
                Button(action: addTask) {
                    Text("Add Task")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("New Task") // Title for the form
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
            print("Notification permissions granted: \(granted)")
        }
    }
    
    // Function to schedule notifications
    func scheduleNotifications(for task: Task) {
        guard let dueDate = task.dueDate ?? task.beginTime else { return }
        
        let notificationTimes: [TimeInterval] = [-24 * 60 * 60, -1 * 60 * 60, -30 * 60] // 24 hours, 1 hour, 30 minutes before
        
        for offset in notificationTimes {
            let notificationDate = dueDate.addingTimeInterval(offset)
            if notificationDate > Date() { // Ensure the notification is in the future
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "Task: \(task.name) is \(offset == -24 * 60 * 60 ? "due in 24 hours" : offset == -1 * 60 * 60 ? "starting in 1 hour" : "starting in 30 minutes")."
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus != .authorized {
                        print("Notifications are not enabled")
                    }
                }
            }
        }
    }



    
    // Function to create and add a new task based on user input
    func addTask() {
        if isScheduled {
            let newTask = Task(name: taskName, beginTime: beginTime, endTime: endTime, days: selectedDays, dueDate: nil, categoryColor: selectedColor, isCompleted: false)
            tasks.append(newTask)
            scheduleNotifications(for: newTask)
        } else {
            let newTask = Task(name: taskName, beginTime: nil, endTime: nil, days: [], dueDate: dueDate, categoryColor: selectedColor, isCompleted: false)
            tasks.append(newTask)
            scheduleNotifications(for: newTask)
        }
        dismiss()
    }
    
    @Environment(\.dismiss) private var dismiss // Environment variable to dismiss the view
}

