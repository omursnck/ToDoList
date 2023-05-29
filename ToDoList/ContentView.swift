import SwiftUI

struct ContentView: View {
    @ObservedObject var taskStore = TaskStore()
    @State private var newTaskName = ""
    @State private var expandedSections = Set<Int>() // Keep track of expanded sections
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(taskStore.groupedTasks.indices, id: \.self) { index in
                        let tasksForDate = taskStore.groupedTasks[index]
                        Section(header: Text(dateHeader(for: tasksForDate[0].date))) {
                            ForEach(tasksForDate) { task in
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .primary)
                                        .onTapGesture {
                                            taskStore.toggleTaskCompletion(task)
                                        }
                                        .frame(width: 24, height: 24)
                                        .padding(.trailing, 8)
                                    
                                    if task.isCompleted {
                                        Text(task.name)
                                            .strikethrough()
                                    } else {
                                        Text(task.name)
                                    }
                                }
                            }
                        }
                        .textCase(nil)
                        .animation(.default) // Apply animation to the section
                        .onTapGesture {
                            toggleSection(index)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let task = taskStore.tasks[index]
                            taskStore.removeTask(task)
                        }
                    }
                }
                
                HStack {
                    TextField("New Item", text: $newTaskName)

                    Button(action: addTask) {
                        Text("Add")
                    }
                    .disabled(newTaskName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Market List")
           // .navigationBarItems(leading: clearTasksButton)
        }
    }
    
    func dateHeader(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    var clearTasksButton: some View {
        Button(action: clearTasks) {
            Text("Clear All Tasks")
                .foregroundColor(.red)
        }
    }
    
    func toggleSection(_ index: Int) {
        if expandedSections.contains(index) {
            expandedSections.remove(index)
        } else {
            expandedSections.insert(index)
        }
    }
    
    func addTask() {
        let task = Task(name: newTaskName, date: Date())
        taskStore.addTask(task)
        newTaskName = ""
        
        // Expand the section for the newly added task
        if let index = taskStore.groupedTasks.indices.last {
            expandedSections.insert(index)
        }
    }
    
    func clearTasks() {
        taskStore.tasks.removeAll()
        taskStore.saveTasks()
    }
}

struct Task: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    var isCompleted = false
    let date: Date
}

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    var groupedTasks: [[Task]] = [] // Change the access level to internal

    init() {
        loadTasks()
        groupTasks()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        groupTasks()
    }
    
    func removeTask(_ task: Task) {
        if let index = tasks.firstIndex(of: task) {
            tasks.remove(at: index)
            saveTasks()
            groupTasks()
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
          if let index = tasks.firstIndex(of: task) {
              tasks[index].isCompleted.toggle()
              saveTasks()
          }
          
          // Re-group the tasks after updating the completion status
          groupTasks()
      }
    
    func clearTasks() {
        tasks.removeAll()
        saveTasks()
        groupTasks()
    }
    
    func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: "tasks")
        } catch {
            print("Error saving tasks: \(error.localizedDescription)")
        }
    }
    
    func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: "tasks") else {
            return
        }
        
        do {
            tasks = try JSONDecoder().decode([Task].self, from: data)
        } catch {
            print("Error loading tasks: \(error.localizedDescription)")
        }
    }
    
    private func groupTasks() {
        let groupedDictionary = Dictionary(grouping: tasks) { task in
            Calendar.current.startOfDay(for: task.date)
        }
        groupedTasks = groupedDictionary.values.sorted { $0[0].date > $1[0].date }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
