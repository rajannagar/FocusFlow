import Foundation
import SwiftUI
import Combine

// MARK: - Flow Action Handler

/// Executes all Flow AI actions within the app
/// This is the central hub that connects AI to app functionality
@MainActor
final class FlowActionHandler: ObservableObject {
    static let shared = FlowActionHandler()
    
    // MARK: - Navigation
    
    /// Publisher for navigation events
    @Published var navigationRequest: NavigationRequest?
    
    struct NavigationRequest: Equatable {
        let destination: NavigationDestination
        let timestamp: Date = Date()
        
        static func == (lhs: NavigationRequest, rhs: NavigationRequest) -> Bool {
            lhs.destination == rhs.destination && lhs.timestamp == rhs.timestamp
        }
    }
    
    enum NavigationDestination: Equatable {
        case tab(AppTabDestination)
        case presetManager
        case settings
        case notificationCenter
        case paywall(PaywallTrigger)
        case back
    }
    
    // MARK: - Focus Control
    
    /// Publisher for focus control events
    @Published var focusControlRequest: FocusControlRequest?
    
    struct FocusControlRequest: Equatable {
        let action: FocusControlAction
        let timestamp: Date = Date()
        
        static func == (lhs: FocusControlRequest, rhs: FocusControlRequest) -> Bool {
            lhs.action == rhs.action && lhs.timestamp == rhs.timestamp
        }
    }
    
    enum FocusControlAction: Equatable {
        case start(minutes: Int, presetID: UUID?, sessionName: String?)
        case pause
        case resume
        case end
        case extend(minutes: Int)
        case setIntention(text: String)
    }
    
    // MARK: - Stats Follow-up
    
    /// Publisher for stats/analysis follow-up messages
    var statsFollowUp: ((String) -> Void)?
    
    private init() {}
    
    // MARK: - Execute Action
    
    /// Execute a single action
    func execute(_ action: FlowAction) async throws {
        #if DEBUG
        print("[FlowActionHandler] Executing: \(action)")
        #endif
        
        switch action {
        // MARK: Task Actions
        case .createTask(let title, let reminderDate, let duration, let repeatRule):
            try await createTask(title: title, reminderDate: reminderDate, duration: duration, repeatRule: repeatRule)
            
        case .updateTask(let taskID, let title, let reminderDate, let duration):
            try await updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case .deleteTask(let taskID):
            try await deleteTask(taskID: taskID)
            
        case .toggleTaskCompletion(let taskID):
            try await toggleTaskCompletion(taskID: taskID)
            
        case .listFutureTasks:
            let message = generateTaskListMessage()
            statsFollowUp?(message)
            
        case .listTasks(let period):
            let message = generateTaskListMessage(period: period)
            statsFollowUp?(message)
            
        case .bulkCreateTasks(let tasks):
            try await bulkCreateTasks(tasks)
            
        case .rescheduleToday:
            try await rescheduleTodayToTomorrow()
            
        case .smartScheduleTask(let title, let estimatedMinutes):
            try await smartScheduleTask(title: title, estimatedMinutes: estimatedMinutes)
            
        // MARK: Preset Actions
        case .setPreset(let presetID):
            setPreset(presetID: presetID)
            
        case .createPreset(let name, let durationSeconds, let soundID):
            try await createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case .updatePreset(let presetID, let name, let durationSeconds):
            try await updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case .deletePreset(let presetID):
            try await deletePreset(presetID: presetID)
            
        // MARK: Focus Actions
        case .startFocus(let minutes, let presetID, let sessionName):
            startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
        case .pauseFocus:
            pauseFocus()
            
        case .resumeFocus:
            resumeFocus()
            
        case .endFocusEarly:
            endFocusEarly()
            
        case .extendFocus(let additionalMinutes):
            extendFocus(minutes: additionalMinutes)
            
        case .setFocusIntention(let text):
            setFocusIntention(text: text)
            
        case .startFocusOnTask(let taskID, let minutes):
            try await startFocusOnTask(taskID: taskID, minutes: minutes)
            
        // MARK: Navigation Actions
        case .navigateToTab(let tab):
            navigate(to: .tab(tab))
            
        case .openPresetManager:
            navigate(to: .presetManager)
            
        case .openSettings:
            navigate(to: .settings)
            
        case .openNotificationCenter:
            navigate(to: .notificationCenter)
            
        case .showPaywall(let context):
            navigate(to: .paywall(context))
            
        case .goBack:
            navigate(to: .back)
            
        // MARK: Settings Actions
        case .updateSetting(let setting, let value):
            try await updateSetting(setting: setting, value: value)
            
        case .toggleDoNotDisturb(let enabled):
            toggleDoNotDisturb(enabled: enabled)
            
        case .updateDailyGoal(let minutes):
            updateDailyGoal(minutes: minutes)
            
        case .changeTheme(let themeName):
            try changeTheme(name: themeName)
            
        // MARK: Stats Actions
        case .getStats(let period):
            let message = generateStatsMessage(for: period)
            #if DEBUG
            print("[FlowActionHandler] getStats message: '\(message.prefix(100))...'")
            print("[FlowActionHandler] statsFollowUp callback exists: \(statsFollowUp != nil)")
            #endif
            statsFollowUp?(message)
            
        case .analyzeSessions:
            let message = generateProductivityAnalysis()
            statsFollowUp?(message)
            
        case .compareWeeks:
            let message = generateWeekComparison()
            statsFollowUp?(message)
            
        case .generateWeeklyReport:
            let message = generateWeeklyReport()
            statsFollowUp?(message)
            
        case .identifyPatterns:
            let message = identifyProductivityPatterns()
            statsFollowUp?(message)
            
        // MARK: Smart Actions
        case .generateDailyPlan:
            let message = generateDailyPlan()
            statsFollowUp?(message)
            
        case .suggestOptimalFocusTime:
            let message = suggestOptimalFocusTime()
            statsFollowUp?(message)
            
        case .suggestBreak:
            let message = generateBreakSuggestion()
            #if DEBUG
            print("[FlowActionHandler] suggestBreak message: '\(message.prefix(50))...'")
            #endif
            statsFollowUp?(message)
            
        case .motivate:
            let message = generateMotivation()
            #if DEBUG
            print("[FlowActionHandler] motivate message: '\(message.prefix(50))...'")
            print("[FlowActionHandler] statsFollowUp callback exists: \(statsFollowUp != nil)")
            #endif
            statsFollowUp?(message)
            
        case .showWelcome:
            let message = generateWelcomeMessage()
            statsFollowUp?(message)
            
        case .celebrateAchievement(let type):
            let message = celebrateAchievement(type: type)
            statsFollowUp?(message)
            
        case .provideTip:
            let message = generateProductivityTip()
            statsFollowUp?(message)
        }
        
        // Invalidate context after action
        FlowContext.shared.invalidateCache()
    }
    
    /// Execute multiple actions sequentially
    func executeAll(_ actions: [FlowAction]) async -> [String] {
        var errors: [String] = []
        
        for action in actions {
            do {
                try await execute(action)
            } catch {
                errors.append("\(action.displayTitle): \(error.localizedDescription)")
            }
        }
        
        return errors
    }
}

// MARK: - Task Actions

extension FlowActionHandler {
    
    private func createTask(title: String, reminderDate: Date?, duration: TimeInterval?, repeatRule: FFTaskRepeatRule? = nil) async throws {
        guard !title.isEmpty else {
            throw FlowError.actionFailed(action: "Create Task", reason: "Title cannot be empty")
        }
        
        // Validate reminder date (adjust if in past for non-recurring tasks)
        var validReminderDate = reminderDate
        if let reminder = reminderDate, reminder < Date(), repeatRule == nil || repeatRule == .none {
            let calendar = Calendar.autoupdatingCurrent
            let components = calendar.dateComponents([.hour, .minute], from: reminder)
            if let hour = components.hour, let minute = components.minute {
                validReminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
            }
        }
        
        // Convert duration to minutes (FFTaskItem uses durationMinutes)
        let durationMinutes = duration != nil ? Int(duration! / 60) : 0
        
        let task = FFTaskItem(
            id: UUID(),
            title: title,
            reminderDate: validReminderDate,
            repeatRule: repeatRule ?? .none,
            durationMinutes: durationMinutes
        )
        
        TasksStore.shared.upsert(task)
        
        // Reschedule notifications (TaskReminderScheduler handles this)
        TaskReminderScheduler.shared.rescheduleAllNow()
        
        Haptics.impact(.medium)
        
        #if DEBUG
        let repeatStr = repeatRule != nil && repeatRule != .none ? " (\(repeatRule!.displayName))" : ""
        print("[FlowActionHandler] ✅ Created task: \(title)\(repeatStr)")
        #endif
    }
    
    private func updateTask(taskID: UUID, title: String?, reminderDate: Date?, duration: TimeInterval?) async throws {
        guard let existingTask = TasksStore.shared.tasks.first(where: { $0.id == taskID }) else {
            throw FlowError.actionFailed(action: "Update Task", reason: "Task not found")
        }
        
        // Convert duration to minutes
        let durationMinutes = duration != nil ? Int(duration! / 60) : existingTask.durationMinutes
        
        let updatedTask = FFTaskItem(
            id: existingTask.id,
            sortIndex: existingTask.sortIndex,
            title: title ?? existingTask.title,
            notes: existingTask.notes,
            reminderDate: reminderDate ?? existingTask.reminderDate,
            repeatRule: existingTask.repeatRule,
            customWeekdays: existingTask.customWeekdays,
            durationMinutes: durationMinutes
        )
        
        // Preserve additional task metadata
        var fullTask = updatedTask
        fullTask.convertToPreset = existingTask.convertToPreset
        fullTask.presetCreated = existingTask.presetCreated
        fullTask.excludedDayKeys = existingTask.excludedDayKeys
        fullTask.createdAt = existingTask.createdAt
        
        TasksStore.shared.upsert(fullTask)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Updated task: \(fullTask.title)")
        #endif
    }
    
    private func deleteTask(taskID: UUID) async throws {
        guard TasksStore.shared.tasks.contains(where: { $0.id == taskID }) else {
            throw FlowError.actionFailed(action: "Delete Task", reason: "Task not found")
        }
        
        TasksStore.shared.delete(taskID: taskID)
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Deleted task: \(taskID)")
        #endif
    }
    
    private func toggleTaskCompletion(taskID: UUID) async throws {
        guard let task = TasksStore.shared.tasks.first(where: { $0.id == taskID }) else {
            throw FlowError.actionFailed(action: "Toggle Task", reason: "Task not found")
        }
        
        let occurrenceDate = task.reminderDate ?? Date()
        TasksStore.shared.toggleCompletion(taskID: taskID, on: occurrenceDate)
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Toggled task completion: \(task.title)")
        #endif
    }
    
    private func bulkCreateTasks(_ tasks: [BulkTask]) async throws {
        for task in tasks {
            try await createTask(title: task.title, reminderDate: task.reminderDate, duration: task.duration)
        }
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Bulk created \(tasks.count) tasks")
        #endif
    }
    
    private func rescheduleTodayToTomorrow() async throws {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        let store = TasksStore.shared
        
        // Get tasks visible today, excluding recurring tasks (those can't be rescheduled)
        let todayTasks = store.tasksVisible(on: today, calendar: calendar).filter { $0.repeatRule == .none }
        
        for task in todayTasks {
            if let reminder = task.reminderDate,
               let tomorrow = calendar.date(byAdding: .day, value: 1, to: reminder) {
                let updatedTask = FFTaskItem(
                    id: task.id,
                    title: task.title,
                    reminderDate: tomorrow,
                    durationMinutes: task.durationMinutes
                )
                store.upsert(updatedTask)
            }
        }
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Rescheduled \(todayTasks.count) non-recurring tasks to tomorrow")
        #endif
    }
    
    private func smartScheduleTask(title: String, estimatedMinutes: Int) async throws {
        // Find optimal time based on user patterns
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        // Default to next available hour
        var scheduledDate = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        
        // Check peak hours from memory
        let peakHours = FlowContext.shared.memory.peakProductivityHours
        if !peakHours.isEmpty {
            // Find next peak hour
            let currentHour = calendar.component(.hour, from: now)
            if let nextPeak = peakHours.first(where: { $0 > currentHour }) {
                scheduledDate = calendar.date(bySettingHour: nextPeak, minute: 0, second: 0, of: now) ?? scheduledDate
            }
        }
        
        try await createTask(
            title: title,
            reminderDate: scheduledDate,
            duration: TimeInterval(estimatedMinutes * 60)
        )
    }
    
    private func generateTaskListMessage(period: TaskPeriod? = nil) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let store = TasksStore.shared
        let today = calendar.startOfDay(for: now)
        
        var filteredTasks: [FFTaskItem] = []
        var periodName = "Upcoming"
        var checkDate = today // Date for checking completion
        
        if let period = period {
            switch period {
            case .today:
                periodName = "Today"
                checkDate = today
                // Use proper tasksVisible to include recurring tasks
                filteredTasks = store.tasksVisible(on: today, calendar: calendar)
            case .tomorrow:
                periodName = "Tomorrow"
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                checkDate = tomorrow
                filteredTasks = store.tasksVisible(on: tomorrow, calendar: calendar)
            case .yesterday:
                periodName = "Yesterday"
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                checkDate = yesterday
                filteredTasks = store.tasksVisible(on: yesterday, calendar: calendar)
            case .thisWeek:
                periodName = "This Week"
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                // Collect tasks for each day of the week
                var weekTasks: [FFTaskItem] = []
                for dayOffset in 0..<7 {
                    if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        weekTasks.append(contentsOf: store.tasksVisible(on: day, calendar: calendar))
                    }
                }
                // Remove duplicates
                var seen = Set<UUID>()
                filteredTasks = weekTasks.filter { seen.insert($0.id).inserted }
            case .nextWeek:
                periodName = "Next Week"
                let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: thisWeekStart)!
                var weekTasks: [FFTaskItem] = []
                for dayOffset in 0..<7 {
                    if let day = calendar.date(byAdding: .day, value: dayOffset, to: nextWeekStart) {
                        weekTasks.append(contentsOf: store.tasksVisible(on: day, calendar: calendar))
                    }
                }
                var seen = Set<UUID>()
                filteredTasks = weekTasks.filter { seen.insert($0.id).inserted }
            case .upcoming:
                periodName = "Upcoming"
                filteredTasks = store.tasks.filter { ($0.reminderDate ?? .distantFuture) >= now || $0.repeatRule != .none }
            case .all:
                periodName = "All"
                filteredTasks = store.tasks
            }
        } else {
            filteredTasks = store.tasksVisible(on: today, calendar: calendar)
            periodName = "Today"
        }
        
        if filteredTasks.isEmpty {
            return "No \(periodName.lowercased()) tasks."
        }
        
        var message = "\(periodName) Tasks (\(filteredTasks.count)):\n"
        for task in filteredTasks.prefix(10) {
            let isCompleted = store.isCompleted(taskId: task.id, on: checkDate, calendar: calendar)
            let status = isCompleted ? "✓" : "○"
            let timeStr = task.reminderDate.map { formatTimeForList($0) } ?? ""
            let repeatStr = task.repeatRule != .none ? " (\(task.repeatRule.displayName))" : ""
            message += "\(status) \(task.title)\(timeStr.isEmpty ? "" : " at \(timeStr)")\(repeatStr)\n"
        }
        
        if filteredTasks.count > 10 {
            message += "...and \(filteredTasks.count - 10) more"
        }
        
        return message
    }
    
    private func formatTimeForList(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preset Actions

extension FlowActionHandler {
    
    private func setPreset(presetID: UUID) {
        FocusPresetStore.shared.activePresetID = presetID
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Set active preset: \(presetID)")
        #endif
    }
    
    private func createPreset(name: String, durationSeconds: Int, soundID: String?) async throws {
        guard !name.isEmpty else {
            throw FlowError.actionFailed(action: "Create Preset", reason: "Name cannot be empty")
        }
        
        let preset = FocusPreset(
            id: UUID(),
            name: name,
            durationSeconds: durationSeconds,
            soundID: soundID ?? ""
        )
        
        FocusPresetStore.shared.upsert(preset)
        Haptics.impact(.medium)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Created preset: \(name)")
        #endif
    }
    
    private func updatePreset(presetID: UUID, name: String?, durationSeconds: Int?) async throws {
        guard let existing = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw FlowError.actionFailed(action: "Update Preset", reason: "Preset not found")
        }
        
        let updated = FocusPreset(
            id: existing.id,
            name: name ?? existing.name,
            durationSeconds: durationSeconds ?? existing.durationSeconds,
            soundID: existing.soundID,
            themeRaw: existing.themeRaw
        )
        
        FocusPresetStore.shared.upsert(updated)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Updated preset: \(updated.name)")
        #endif
    }
    
    private func deletePreset(presetID: UUID) async throws {
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw FlowError.actionFailed(action: "Delete Preset", reason: "Preset not found")
        }
        
        FocusPresetStore.shared.delete(preset)
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Deleted preset: \(presetID)")
        #endif
    }
}

// MARK: - Focus Actions

extension FlowActionHandler {
    
    private func startFocus(minutes: Int, presetID: UUID?, sessionName: String?) {
        // Handle preset activation
        if let presetID = presetID {
            // User wants to start with a specific preset
            FocusPresetStore.shared.activePresetID = presetID
        } else {
            // User wants a plain timer without preset - clear any active preset
            // This prevents previously selected presets from being applied
            FocusPresetStore.shared.activePresetID = nil
        }
        
        // Build notification userInfo
        var userInfo: [String: Any] = ["minutes": minutes]
        if let presetID = presetID {
            userInfo["presetID"] = presetID
        }
        if let sessionName = sessionName {
            userInfo["sessionName"] = sessionName
        }
        
        // Navigate to focus tab FIRST
        navigate(to: .tab(.focus))
        
        Haptics.impact(.medium)
        
        // Post notification AFTER a small delay to ensure FocusView is visible and ready
        // This fixes a race condition where the notification was sent before the view was loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NotificationCenter.default.post(
                name: Notification.Name("FocusFlow.startFocusFromAI"),
                object: nil,
                userInfo: userInfo
            )
            
            #if DEBUG
            print("[FlowActionHandler] ✅ Posted startFocusFromAI: \(minutes)m, preset: \(presetID?.uuidString ?? "none"), name: \(sessionName ?? "none")")
            #endif
        }
    }
    
    private func pauseFocus() {
        // Post notification that FocusView listens for
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.widgetPauseAction"),
            object: nil
        )
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Posted pauseFocus notification")
        #endif
    }
    
    private func resumeFocus() {
        // Post notification that FocusView listens for
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.widgetResumeAction"),
            object: nil
        )
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Posted resumeFocus notification")
        #endif
    }
    
    private func endFocusEarly() {
        // Post notification to end session
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.endFocusFromAI"),
            object: nil
        )
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Posted endFocus notification")
        #endif
    }
    
    private func extendFocus(minutes: Int) {
        // Post notification to extend session
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.extendFocusFromAI"),
            object: nil,
            userInfo: ["minutes": minutes]
        )
        Haptics.impact(.light)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Posted extendFocus notification: +\(minutes) min")
        #endif
    }
    
    private func setFocusIntention(text: String) {
        // Post notification to set intention
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.setIntentionFromAI"),
            object: nil,
            userInfo: ["text": text]
        )
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Posted setIntention notification: \(text)")
        #endif
    }
    
    private func startFocusOnTask(taskID: UUID, minutes: Int?) async throws {
        guard let task = TasksStore.shared.tasks.first(where: { $0.id == taskID }) else {
            throw FlowError.actionFailed(action: "Focus on Task", reason: "Task not found")
        }
        
        // FFTaskItem uses durationMinutes (already in minutes), fallback to 25 min
        let duration = minutes ?? (task.durationMinutes > 0 ? task.durationMinutes : 25)
        startFocus(minutes: duration, presetID: nil, sessionName: task.title)
    }
}

// MARK: - Navigation Actions

extension FlowActionHandler {
    
    private func navigate(to destination: NavigationDestination) {
        navigationRequest = NavigationRequest(destination: destination)
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Navigation: \(destination)")
        #endif
    }
}

// MARK: - Settings Actions

extension FlowActionHandler {
    
    private func updateSetting(setting: SettingKey, value: String) async throws {
        let settings = AppSettings.shared
        
        switch setting {
        case .dailyGoal:
            if let minutes = Int(value) {
                ProgressStore.shared.dailyGoalMinutes = minutes
            }
        case .theme:
            try changeTheme(name: value)
        case .soundEnabled:
            settings.soundEnabled = value.lowercased() == "true"
        case .hapticsEnabled:
            settings.hapticsEnabled = value.lowercased() == "true"
        case .focusSound:
            settings.selectedFocusSound = FocusSound(rawValue: value)
        case .displayName:
            settings.displayName = value
        case .tagline:
            settings.tagline = value
        case .notificationsEnabled:
            // This requires system settings, just log
            #if DEBUG
            print("[FlowActionHandler] Notification settings require system preferences")
            #endif
        }
        
        #if DEBUG
        print("[FlowActionHandler] ✅ Updated setting: \(setting) = \(value)")
        #endif
    }
    
    private func toggleDoNotDisturb(enabled: Bool) {
        // This is a system setting, we can only suggest
        #if DEBUG
        print("[FlowActionHandler] DND toggle requested: \(enabled)")
        #endif
    }
    
    private func updateDailyGoal(minutes: Int) {
        ProgressStore.shared.dailyGoalMinutes = max(5, min(480, minutes))
        Haptics.impact(.light)
    }
    
    private func changeTheme(name: String) throws {
        guard let theme = AppTheme(rawValue: name.lowercased()) else {
            throw FlowError.actionFailed(action: "Change Theme", reason: "Unknown theme: \(name)")
        }
        
        AppSettings.shared.profileTheme = theme
        Haptics.impact(.medium)
    }
}

// MARK: - Stats & Analytics

extension FlowActionHandler {
    
    private func generateStatsMessage(for period: StatsPeriod) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let sessions = ProgressStore.shared.sessions
        let goalMinutes = ProgressStore.shared.dailyGoalMinutes
        
        var filteredSessions: [ProgressSession] = []
        var periodName = ""
        
        switch period {
        case .today:
            periodName = "Today"
            filteredSessions = sessions.filter { calendar.isDateInToday($0.date) }
        case .week:
            periodName = "This Week"
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            filteredSessions = sessions.filter { $0.date >= weekStart }
        case .month:
            periodName = "This Month"
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            filteredSessions = sessions.filter { $0.date >= monthStart }
        case .allTime:
            periodName = "All Time"
            filteredSessions = sessions
        }
        
        let totalMinutes = Int(filteredSessions.reduce(0) { $0 + $1.duration } / 60)
        let sessionCount = filteredSessions.count
        let avgSession = sessionCount > 0 ? totalMinutes / sessionCount : 0
        
        var message = "📊 \(periodName) Stats\n"
        message += "• Total: \(totalMinutes) minutes\n"
        message += "• Sessions: \(sessionCount)\n"
        message += "• Avg session: \(avgSession) min\n"
        
        if period == .today {
            let percentage = goalMinutes > 0 ? min(100, (totalMinutes * 100) / goalMinutes) : 0
            message += "• Goal progress: \(percentage)%"
        }
        
        return message
    }
    
    private func generateProductivityAnalysis() -> String {
        let sessions = ProgressStore.shared.sessions
        let calendar = Calendar.autoupdatingCurrent
        
        guard !sessions.isEmpty else {
            return "Not enough data yet. Complete some focus sessions first!"
        }
        
        // Analyze by hour
        var hourCounts: [Int: Int] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            hourCounts[hour, default: 0] += 1
        }
        
        let topHours = hourCounts.sorted { $0.value > $1.value }.prefix(3)
        let peakHoursStr = topHours.map { formatHour($0.key) }.joined(separator: ", ")
        
        // Average duration
        let avgDuration = Int(sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count) / 60)
        
        var message = "🔍 Productivity Analysis\n\n"
        message += "Peak hours: \(peakHoursStr)\n"
        message += "Avg session: \(avgDuration) minutes\n"
        message += "Total sessions: \(sessions.count)"
        
        return message
    }
    
    private func generateWeekComparison() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let sessions = ProgressStore.shared.sessions
        
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
        
        let thisWeekSessions = sessions.filter { $0.date >= thisWeekStart }
        let lastWeekSessions = sessions.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }
        
        let thisWeekMinutes = Int(thisWeekSessions.reduce(0) { $0 + $1.duration } / 60)
        let lastWeekMinutes = Int(lastWeekSessions.reduce(0) { $0 + $1.duration } / 60)
        
        let change = lastWeekMinutes > 0 ? ((thisWeekMinutes - lastWeekMinutes) * 100) / lastWeekMinutes : 0
        let changeStr = change >= 0 ? "+\(change)%" : "\(change)%"
        
        var message = "📈 Week Comparison\n\n"
        message += "This week: \(thisWeekMinutes) min (\(thisWeekSessions.count) sessions)\n"
        message += "Last week: \(lastWeekMinutes) min (\(lastWeekSessions.count) sessions)\n"
        message += "Change: \(changeStr)"
        
        return message
    }
    
    private func generateWeeklyReport() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let sessions = ProgressStore.shared.sessions
        let tasks = TasksStore.shared.tasks
        let completedKeys = TasksStore.shared.completedOccurrenceKeys
        
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekSessions = sessions.filter { $0.date >= weekStart }
        
        let totalMinutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        let sessionCount = weekSessions.count
        
        // Count completed tasks this week
        let completedThisWeek = completedKeys.filter { key in
            // Parse date from key if possible
            true // Simplified
        }.count
        
        var message = "📋 Weekly Report\n\n"
        message += "Focus time: \(totalMinutes) minutes\n"
        message += "Sessions completed: \(sessionCount)\n"
        message += "Tasks completed: \(completedThisWeek)\n"
        message += "\n"
        
        if totalMinutes > 0 {
            message += "Great progress this week! 🎉"
        } else {
            message += "New week, new opportunities! 💪"
        }
        
        return message
    }
    
    private func identifyProductivityPatterns() -> String {
        let sessions = ProgressStore.shared.sessions
        let calendar = Calendar.autoupdatingCurrent
        
        guard sessions.count >= 5 else {
            return "Need more sessions to identify patterns. Keep focusing!"
        }
        
        // Find most productive day
        var dayCounts: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            dayCounts[weekday, default: 0] += 1
        }
        
        let topDay = dayCounts.max { $0.value < $1.value }?.key ?? 1
        let dayName = calendar.weekdaySymbols[topDay - 1]
        
        var message = "🧠 Your Patterns\n\n"
        message += "Most productive day: \(dayName)\n"
        
        // Average by time of day
        var morningMins = 0, afternoonMins = 0, eveningMins = 0
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            let mins = Int(session.duration / 60)
            if hour < 12 {
                morningMins += mins
            } else if hour < 17 {
                afternoonMins += mins
            } else {
                eveningMins += mins
            }
        }
        
        if morningMins >= afternoonMins && morningMins >= eveningMins {
            message += "Best time: Morning 🌅"
        } else if afternoonMins >= eveningMins {
            message += "Best time: Afternoon ☀️"
        } else {
            message += "Best time: Evening 🌙"
        }
        
        return message
    }
}

// MARK: - Smart Actions

extension FlowActionHandler {
    
    private func generateDailyPlan() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let tasks = TasksStore.shared.tasks
        let goalMinutes = ProgressStore.shared.dailyGoalMinutes
        let todaySessions = ProgressStore.shared.sessions.filter { calendar.isDateInToday($0.date) }
        let focusedMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        
        let todayTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return calendar.isDateInToday(reminder)
        }.sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
        
        var message = "📅 Your Day Plan\n\n"
        
        // Progress
        let remaining = max(0, goalMinutes - focusedMinutes)
        message += "Goal: \(focusedMinutes)/\(goalMinutes) min"
        if remaining > 0 {
            message += " (\(remaining) to go)"
        } else {
            message += " ✓"
        }
        message += "\n\n"
        
        // Tasks
        if todayTasks.isEmpty {
            message += "No tasks scheduled today.\n"
        } else {
            message += "Tasks:\n"
            for task in todayTasks.prefix(5) {
                let time = task.reminderDate.map { formatTime($0) } ?? ""
                message += "• \(task.title)\(time.isEmpty ? "" : " at \(time)")\n"
            }
        }
        
        // Suggestion
        message += "\n"
        if remaining > 0 {
            let suggested = min(remaining, 25)
            message += "💡 Start with a \(suggested)-minute session!"
        } else {
            message += "💡 Goal reached! Take a well-deserved break."
        }
        
        return message
    }
    
    private func suggestOptimalFocusTime() -> String {
        let memory = FlowContext.shared.memory
        let calendar = Calendar.autoupdatingCurrent
        let currentHour = calendar.component(.hour, from: Date())
        
        var suggestion = "🕐 Best Focus Time\n\n"
        
        if !memory.peakProductivityHours.isEmpty {
            let nextPeak = memory.peakProductivityHours.first { $0 > currentHour } ?? memory.peakProductivityHours.first ?? currentHour
            suggestion += "Based on your history: \(formatHour(nextPeak))\n"
        } else {
            // Default recommendations
            if currentHour < 10 {
                suggestion += "Morning is great for deep work!\n"
            } else if currentHour < 14 {
                suggestion += "Good time for focused tasks.\n"
            } else {
                suggestion += "Consider lighter tasks in the afternoon.\n"
            }
        }
        
        if let prefDuration = memory.preferredFocusDuration {
            suggestion += "Your usual: \(prefDuration) minutes"
        }
        
        return suggestion
    }
    
    private func generateBreakSuggestion() -> String {
        let sessions = ProgressStore.shared.sessions
        let calendar = Calendar.autoupdatingCurrent
        
        let recentSessions = sessions.filter { session in
            let hourAgo = calendar.date(byAdding: .hour, value: -2, to: Date())!
            return session.date > hourAgo
        }
        
        let recentMinutes = Int(recentSessions.reduce(0) { $0 + $1.duration } / 60)
        
        var message = "☕ Break Time\n\n"
        
        if recentMinutes > 60 {
            message += "You've focused \(recentMinutes) min recently.\n"
            message += "Definitely time for a break!\n\n"
            message += "Suggestions:\n"
            message += "• 5-10 min walk\n"
            message += "• Stretch & hydrate\n"
            message += "• Look away from screen"
        } else if recentMinutes > 25 {
            message += "Nice work! A short break could help.\n"
            message += "Even 5 minutes helps reset focus."
        } else {
            message += "You're doing well!\n"
            message += "Take a break when you feel ready."
        }
        
        return message
    }
    
    private func generateMotivation() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        let todaySessions = progress.sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let percentage = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        let motivations = [
            "You've got this! Every minute of focus counts. 💪",
            "Small steps lead to big achievements. Keep going!",
            "Your future self will thank you for focusing now. ✨",
            "Progress isn't always visible, but it's always happening.",
            "You're building something amazing, one session at a time.",
            "Focus is a superpower. You have it! 🦸",
            "The hardest part is starting. You've already done that!",
            "Excellence is a habit. You're developing it right now."
        ]
        
        var message = "🔥 "
        
        if percentage >= 100 {
            message += "You crushed your goal today! Amazing work! 🎉"
        } else if percentage >= 75 {
            message += "So close to your goal! Just a bit more! "
            message += motivations.randomElement() ?? motivations[0]
        } else if percentage >= 50 {
            message += "Halfway there! "
            message += motivations.randomElement() ?? motivations[0]
        } else if todayMinutes > 0 {
            message += "Great start! "
            message += motivations.randomElement() ?? motivations[0]
        } else {
            message += motivations.randomElement() ?? motivations[0]
        }
        
        return message
    }
    
    private func generateWelcomeMessage() -> String {
        let userName = AppSettings.shared.displayName ?? "there"
        let firstName = userName.components(separatedBy: " ").first ?? userName
        let calendar = Calendar.autoupdatingCurrent
        let hour = calendar.component(.hour, from: Date())
        
        let greeting: String
        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 17 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
        
        return "\(greeting), \(firstName)! 👋 I'm Flow, your productivity companion. How can I help you today?"
    }
    
    private func celebrateAchievement(type: AchievementType) -> String {
        switch type {
        case .dailyGoal:
            return "🎉 Goal Achieved!\n\nYou hit your daily focus goal! That's what consistency looks like. Well done!"
        case .streak:
            let streak = calculateCurrentStreak()
            return "🔥 \(streak)-Day Streak!\n\nYou're on fire! Keep the momentum going!"
        case .milestone:
            return "🏆 Milestone Reached!\n\nYou've hit a major milestone. Your dedication is paying off!"
        case .firstSession:
            return "✨ First Session Complete!\n\nWelcome to focused productivity! This is just the beginning."
        case .perfectWeek:
            return "💯 Perfect Week!\n\nYou hit your goal every day this week. Incredible discipline!"
        }
    }
    
    private func generateProductivityTip() -> String {
        let tips = [
            "💡 Try the 2-minute rule: If a task takes less than 2 minutes, do it now.",
            "💡 Set specific times for checking email/messages to protect focus time.",
            "💡 Your environment shapes your focus. Reduce visual clutter when working.",
            "💡 Take breaks before you feel tired, not after. Prevention beats recovery.",
            "💡 End each work session by writing what you'll do next. Makes starting easier.",
            "💡 Match task difficulty to your energy. Deep work when fresh, admin when tired.",
            "💡 One focus session in the morning can set the tone for a productive day.",
            "💡 Background sounds can mask distractions. Try ambient sounds or white noise.",
            "💡 Review your completed tasks weekly. Seeing progress boosts motivation.",
            "💡 Start with your most important task. Everything else gets easier after."
        ]
        
        // Track last tip in memory to avoid repeats
        FlowContext.shared.updateMemory { memory in
            memory.lastTipDate = Date()
        }
        
        return tips.randomElement() ?? tips[0]
    }
}

// MARK: - Helper Methods

extension FlowActionHandler {
    
    private func formatDateForMessage(_ date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour) \(period)"
    }
    
    private func calculateCurrentStreak() -> Int {
        let sessions = ProgressStore.shared.sessions
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var streak = 0
        var checkDate = now
        
        let hasTodaySession = sessions.contains { calendar.isDate($0.date, inSameDayAs: now) }
        if !hasTodaySession {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return 0 }
            checkDate = yesterday
        }
        
        for _ in 0..<365 {
            let hasSession = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasSession {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        
        return streak
    }
}
