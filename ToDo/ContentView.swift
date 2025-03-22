//
//  ContentView.swift
//  ToDo
//
//  Created by Harun Bülbül on 22.03.2025.
//

import SwiftUI

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var date: Date
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, description: String, date: Date, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.isCompleted = isCompleted
    }
}

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    
    init() {
        load()
    }
    
    // Get
    func load() {
        guard let data = UserDefaults.standard.data(forKey: "tasks"),
              let decoded = try? JSONDecoder().decode([Task].self, from: data) else {
            tasks = []
            return
        }
        tasks = decoded
    }
    
    // Save
    func save() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    
    // Add task
    func addTask(title: String, description: String, date: Date) {
        let task = Task(title: title, description: description, date: date)
        tasks.append(task)
        save()
    }
    
    // Edit task
    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
            save()
        }
    }
    
    // Delete task
    func deleteTasks(at offsets: IndexSet, for date: Date) {
        let tasksForDate = tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        offsets.forEach { index in
            if let taskIndex = tasks.firstIndex(where: { $0.id == tasksForDate[index].id }) {
                tasks.remove(at: taskIndex)
            }
        }
        save()
    }
    
    // Selected date's tasks
    func tasksForDate(_ date: Date) -> [Task] {
        return tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

struct ContentView: View {
    @StateObject private var taskStore = TaskStore()
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Selector
                DatePicker("Tarih Seç", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                // Task List
                List {
                    ForEach(taskStore.tasksForDate(selectedDate)) { task in
                        TaskRow(taskStore: taskStore, task: task)
                    }
                    .onDelete { offsets in
                        taskStore.deleteTasks(at: offsets, for: selectedDate)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("ToDo App")
            .toolbar {
                // Add Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        EditTaskView(taskStore: taskStore, selectedDate: selectedDate)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    @ObservedObject var taskStore: TaskStore
    let task: Task
    
    var body: some View {
        HStack {
            
            Button {
                var updatedTask = task
                updatedTask.isCompleted.toggle()
                taskStore.updateTask(updatedTask)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Task details
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Edit Task
            NavigationLink {
                EditTaskView(taskStore: taskStore, taskToEdit: task, selectedDate: task.date)
            } label: {
                Text("")
            }
        }
        .padding(.vertical, 8)
    }
}
struct EditTaskView: View {
    @ObservedObject var taskStore: TaskStore
        var taskToEdit: Task?
        let selectedDate: Date
        
        @State private var title: String = ""
        @State private var taskDescription: String = ""
    @Environment(\.dismiss) var dismiss

    init(taskStore: TaskStore, taskToEdit: Task? = nil, selectedDate: Date) {
        self.taskStore = taskStore
        self.taskToEdit = taskToEdit
        self.selectedDate = selectedDate
        
        if let taskToEdit = taskToEdit {
                    self._title = State(initialValue: taskToEdit.title)
                    self._taskDescription = State(initialValue: taskToEdit.description)
                } else {
                    self._title = State(initialValue: "")
                    self._taskDescription = State(initialValue: "")
                }
    }
    
    var body: some View {
        Form {
            Section("Görev Detayları") {
                TextField("Başlık", text: $title)
                TextField("Açıklama", text: $taskDescription)
            }
            
            Section {
                Button(taskToEdit == nil ? "Ekle" : "Güncelle") {
                    if let taskToEdit = taskToEdit {
                        let updatedTask = Task(
                            id: taskToEdit.id,
                            title: title,
                            description: taskDescription,
                            date: selectedDate,
                            isCompleted: taskToEdit.isCompleted
                        )
                        taskStore.updateTask(updatedTask)
                    } else {
                        taskStore.addTask(title: title, description: taskDescription, date: selectedDate)
                    }
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .navigationTitle(taskToEdit == nil ? "Yeni Görev" : "Görevi Düzenle")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
