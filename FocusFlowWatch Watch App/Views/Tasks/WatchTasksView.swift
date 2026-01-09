import SwiftUI

struct WatchTasksView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if dataManager.tasks.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundColor(accentColor.opacity(0.5))
                        
                        Text("No tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button(action: {
                            // TODO: Add task via voice
                        }) {
                            Label("Add Task", systemImage: "plus")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(dataManager.tasks) { task in
                                TaskRow(task: task) {
                                    dataManager.toggleTaskCompletion(task.id)
                                }
                            }
                            
                            // Add task button
                            Button(action: {
                                // TODO: Show add task sheet
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(accentColor)
                                    Text("Quick Task")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Tasks")
        }
    }
}

struct TaskRow: View {
    let task: WatchTask
    let onToggle: () -> Void
    
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                // Checkbox
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? accentColor : .white.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(task.isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(task.isCompleted)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchTasksView()
        .environmentObject(WatchDataManager.shared)
}
