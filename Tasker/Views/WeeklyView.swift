//
//  WeeklyView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI

struct WeeklyView: View {
    @Binding var tasks: [Task]
    @Binding var selectedDate: Date
    
    let calendar = Calendar.current // Calendar instance for date calculations
    
    var body: some View {
        VStack {
            // Navigation controls for changing the week
            HStack {
                // Button to go to the previous week
                Button(action: {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                // Display the date range for the selected week
                Text(weekRangeString(for: selectedDate))
                    .font(.headline)
                
                Spacer()
                
                // Button to go to the next week
                Button(action: {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Horizontal scrollable view for the days of the selected week
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // Generate a view for each day in the selected week
                    ForEach(daysInSelectedWeek(), id: \.self) { date in
                        Text(formattedDate(date)) // Display the date
                            .padding()
                            .background(calendar.isDate(selectedDate, inSameDayAs: date) ? Color.blue.opacity(0.2) : Color.clear) // Highlight the selected day
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedDate = date // Update the selected date on tap
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            // Scrollable view for tasks displayed by hour
            ScrollView {
                VStack(alignment: .leading) {
                    // Loop through each hour of the day (0–23)
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(alignment: .top) {
                            // Display the hour label
                            Text("\(hour):00")
                                .frame(width: 50, alignment: .leading)
                                .padding(.top, 8)
                            
                            // Draw a line to represent the time slot
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                                .padding(.top, 12)
                        }
                        .padding(.horizontal)
                        
                        // Filter and display tasks that fall in the current hour
                        let filteredTasks = tasks.filter { task in
                            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1]
                            let isInDay = task.days?.contains(dayName) ?? false
                            let isDueToday = task.dueDate != nil && calendar.isDate(task.dueDate!, inSameDayAs: selectedDate)
                            return (isInDay && isTaskInHour(task, hour: hour)) || (isDueToday && Calendar.current.component(.hour, from: task.dueDate!) == hour)
                        }
                        ForEach(filteredTasks, id: \.self) { task in
                            TaskView(task: task) // Display task details
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    // Generates an array of dates representing the days in the selected week
    func daysInSelectedWeek() -> [Date] {
        // Get the start of the week
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else { return [] }
        // Create a list of dates for each day of the week
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    // Checks if a task falls within a specific hour
    func isTaskInHour(_ task: Task, hour: Int) -> Bool {
        guard let taskBeginTime = task.beginTime, let taskEndTime = task.endTime else { return false }
        let taskBeginHour = Calendar.current.component(.hour, from: taskBeginTime)
        let taskEndHour = Calendar.current.component(.hour, from: taskEndTime)
        // Return true if the hour is within the task's start and end time
        return hour >= taskBeginHour && hour < taskEndHour
    }
    
    // Returns a formatted string for the range of the selected week
    func weekRangeString(for date: Date) -> String {
        // Get the start and end dates for the week
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        // Format the dates as "MMM d"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    // Formats a date to a medium style
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

