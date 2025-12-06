import Foundation
import Combine
import SwiftUI   // for move/remove helpers

struct Habit: Identifiable, Codable {
    let id: UUID
    let name: String
    var isDoneToday: Bool
    
    init(id: UUID = UUID(), name: String, isDoneToday: Bool) {
        self.id = id
        self.name = name
        self.isDoneToday = isDoneToday
    }
}

class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    
    private let storageKey = "focusflow_habits"
    
    init() {
        loadHabits()
        
        if habits.isEmpty {
            habits = [
                Habit(name: "Read 20 minutes", isDoneToday: false),
                Habit(name: "Workout", isDoneToday: false),
                Habit(name: "Study / Learn", isDoneToday: false),
                Habit(name: "Journal", isDoneToday: false)
            ]
            saveHabits()
        }
    }
    
    // MARK: - Public API
    
    func addHabit(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newHabit = Habit(name: trimmed, isDoneToday: false)
        habits.append(newHabit)
        saveHabits()
    }
    
    func delete(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        saveHabits()
    }
    
    func delete(habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits.remove(at: index)
            saveHabits()
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        saveHabits()
    }
    
    func toggle(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isDoneToday.toggle()
        saveHabits()
    }
    
    func resetAll() {
        for index in habits.indices {
            habits[index].isDoneToday = false
        }
        saveHabits()
    }
    
    // MARK: - Persistence
    
    private func saveHabits() {
        do {
            let data = try JSONEncoder().encode(habits)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save habits: \(error)")
        }
    }
    
    private func loadHabits() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            habits = try JSONDecoder().decode([Habit].self, from: data)
        } catch {
            print("Failed to load habits: \(error)")
        }
    }
}
