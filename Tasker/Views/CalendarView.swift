//
//  CalendarView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI

struct CalendarView: View {
    @Binding var tasks: [Task]
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    
    let calendar = Calendar.current
    
    var body: some View {
        VStack {
            // Header: Month and Year Navigation
            HStack {
                Button(action: {
                    if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString(for: selectedDate))
                    .font(.title)
                
                Spacer()
                
                Button(action: {
                    if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Days of the Week
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
            }
            
            // Days of the Month
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(for: selectedDate), id: \.self) { date in
                    VStack {
                        if calendar.isDate(date, equalTo: Date.distantPast, toGranularity: .day) {
                            Text("") // Placeholder for empty days
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Text("\(calendar.component(.day, from: date))")
                                .foregroundColor(calendar.isDate(date, inSameDayAs: Date()) ? .blue : .primary)
                                .fontWeight(calendar.isDate(date, inSameDayAs: Date()) ? .bold : .regular)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(calendar.isDate(selectedDate, inSameDayAs: date) ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .padding(.vertical)
                                .onTapGesture {
                                    selectedDate = date
                                }
                                .onTapGesture(count: 2) { // Double-tap gesture
                                    selectedDate = date
                                    selectedTab = 0 // Switch to TaskListView tab
                                }
                            
                            // Red Dot for Days with Tasks
                            if hasTasks(on: date) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(y: -10)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        
        Spacer()
    }

    
    // Helper Methods
    
    func daysInMonth(for date: Date) -> [Date] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        // Add empty days for alignment
        var days: [Date] = (0..<firstWeekday).map { _ in Date.distantPast }
        
        // Add days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }
    
    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Explicitly set the locale
        formatter.dateFormat = "MMMM yyyy" // Month and year format
        return formatter.string(from: date)
    }
    
    func hasTasks(on date: Date) -> Bool {
        tasks.contains { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            if let taskDays = task.days {
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                return taskDays.contains(dayName)
            }
            return false
        }
    }
}

