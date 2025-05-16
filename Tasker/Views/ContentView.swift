//
//  ContentView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import SwiftUI

struct ContentView: View {
    // State variables to manage the visibility of sheets and other dynamic properties
    @State private var isLeadingSheetPresented = false
    @State private var isTrailingSheetPresented = false
    @State private var tasks: [Task] = []
    @State private var selectedDate: Date = Date()
    @State private var selectedTab = 0

    var body: some View {
        // A TabView to provide navigation between different sections of the app
        TabView {
            // Tasks tab
            NavigationView {
                TaskListView(tasks: $tasks, selectedDate: $selectedDate) // Displays a list of tasks
            }
            .navigationViewStyle(StackNavigationViewStyle()) // Optimizes for smaller screens
            .tabItem {
                Label("Tasks", systemImage: "list.bullet") // Tab label and icon
            }
            
            // Schedule tab
            NavigationView {
                VStack {
                    // Picker to switch between "Weekly View" and "Calendar View"
                    Picker("Select View", selection: $selectedTab) {
                        Text("Weekly View").tag(0) // First option for Weekly View
                        Text("Calendar View").tag(1) // Second option for Calendar View
                    }
                    .pickerStyle(SegmentedPickerStyle()) // Styling for the picker
                    .padding()
                    
                    // Conditional views based on the selected tab
                    if selectedTab == 0 {
                        WeeklyView(tasks: $tasks, selectedDate: $selectedDate) // Displays a weekly view
                    } else {
                        CalendarView(tasks: $tasks, selectedDate: $selectedDate, selectedTab: $selectedTab) // Displays a calendar view
                    }
                }
                .navigationTitle(selectedTab == 0 ? "Weekly View" : "Calendar")
                .toolbar {
                    // Toolbar items for additional actions
                    ToolbarItem(placement: .navigationBarLeading) {
                        // Leading button to open AIView sheet
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
                        // Trailing button to open TaskFormView sheet
                        Button(action: {
                            isTrailingSheetPresented = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                // Sheets for additional views
                .sheet(isPresented: $isLeadingSheetPresented) {
                    AIView(tasks: $tasks, isPresented: $isLeadingSheetPresented)
                }
                .sheet(isPresented: $isTrailingSheetPresented) {
                    TaskFormView(tasks: $tasks)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle()) // Optimized navigation view style
            .tabItem {
                Label("Schedule", systemImage: "calendar") // Tab label and icon
            }
        }
    }
}

// A struct representing a Task with relevant attributes
struct Task: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let beginTime: Date?
    let endTime: Date?
    let days: [String]?
    let dueDate: Date?
    let categoryColor: Color
    var isCompleted: Bool
}

#Preview {
    ContentView()
}

