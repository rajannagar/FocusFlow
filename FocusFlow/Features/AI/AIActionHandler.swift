import Foundation
import SwiftUI

/// Handles AI-initiated actions
/// Executes actions returned by the AI service (task creation, preset management, etc.)
@MainActor
final class AIActionHandler {
    static let shared = AIActionHandler()
    
    private init() {}
    
    /// Execute an AI action
    /// - Parameter action: The action to execute
    /// - Throws: AIActionError if the action fails
    func execute(_ action: AIAction) async throws {
        #if DEBUG
        print("[AIActionHandler] Executing action: \(action)")
        #endif
        
        switch action {
        // MARK: - Task Actions
        case .createTask(let title, let reminderDate, let duration):
            try createTask(title: title, reminderDate: reminderDate, duration: duration)
            
        case .updateTask(let taskID, let title, let reminderDate, let duration):
            try updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case .deleteTask(let taskID):
            try deleteTask(taskID: taskID)
            
        case .toggleTaskCompletion(let taskID):
            try toggleTaskCompletion(taskID: taskID)
            
        case .listFutureTasks:
            // Generate a formatted task list message
            AIContextBuilder.shared.invalidateCache()
            let tasksMessage = generateTaskListMessage()
            postStatsFollowUp(tasksMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Task list generated")
            #endif
            
        case .listTasks(let period):
            AIContextBuilder.shared.invalidateCache()
            let tasksMessage = generateTaskListMessage(period: period)
            postStatsFollowUp(tasksMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Task list generated for period: \(period)")
            #endif
            
        // MARK: - Preset Actions
        case .setPreset(let presetID):
            setPreset(presetID: presetID)
            
        case .createPreset(let name, let durationSeconds, let soundID):
            try createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case .updatePreset(let presetID, let name, let durationSeconds):
            try updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case .deletePreset(let presetID):
            try deletePreset(presetID: presetID)
            
        // MARK: - Focus Actions
        case .startFocus(let minutes, let presetID, let sessionName):
            startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
        // MARK: - Settings Actions
        case .updateSetting(let setting, let value):
            try updateSetting(setting: setting, value: value)
            
        // MARK: - Stats Actions
        case .getStats(let period):
            let statsMessage = generateStatsMessage(for: period)
            postStatsFollowUp(statsMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Stats generated for period: \(period)")
            #endif
            
        case .analyzeSessions:
            let analysisMessage = generateProductivityAnalysis()
            postStatsFollowUp(analysisMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Productivity analysis generated")
            #endif
            
        // MARK: - Smart Planning Actions
        case .generateDailyPlan:
            let planMessage = generateSmartDailyPlan()
            postStatsFollowUp(planMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Daily plan generated")
            #endif
            
        case .suggestBreak:
            let breakMessage = generateBreakSuggestion()
            postStatsFollowUp(breakMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Break suggestion generated")
            #endif
            
        case .motivate:
            let motivationMessage = generateMotivation()
            postStatsFollowUp(motivationMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Motivation generated")
            #endif
            
        // MARK: - Advanced Analytics Actions
        case .generateWeeklyReport:
            let reportMessage = generateWeeklyReport()
            postStatsFollowUp(reportMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Weekly report generated")
            #endif
            
        case .showWelcome:
            let welcomeMessage = generateWelcomeMessage()
            postStatsFollowUp(welcomeMessage)
            #if DEBUG
            print("[AIActionHandler] ✅ Welcome message generated")
            #endif
        }
    }
    
    // MARK: - Task Actions
    
    private func createTask(title: String, reminderDate: Date?, duration: TimeInterval?) throws {
        guard !title.isEmpty else {
            throw AIActionError.invalidTaskTitle
        }
        
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        // Validate reminder date - if it's in the past, adjust to today at the same time
        var validReminderDate = reminderDate
        if let reminder = reminderDate, reminder < now {
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder)
            if let hour = reminderComponents.hour, let minute = reminderComponents.minute {
                validReminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
                #if DEBUG
                print("[AIActionHandler] ⚠️ Reminder date was in the past, adjusted to today: \(validReminderDate?.description ?? "none")")
                #endif
            }
        }
        
        #if DEBUG
        print("[AIActionHandler] Creating task: '\(title)'")
        print("[AIActionHandler] Reminder date: \(validReminderDate?.description ?? "none")")
        print("[AIActionHandler] Duration: \(duration != nil ? "\(Int(duration! / 60)) minutes" : "none")")
        #endif
        
        // Create task using TasksStore
        let task = FFTaskItem(
            id: UUID(),
            title: title,
            reminderDate: validReminderDate,
            repeatRule: .none,
            customWeekdays: [],
            durationMinutes: duration != nil ? Int(duration! / 60) : 0,
            createdAt: Date()
        )
        
        TasksStore.shared.upsert(task)
        
        // Schedule notification if reminder is set and in the future
        if let reminder = validReminderDate, reminder > now {
            FocusLocalNotificationManager.shared.scheduleTaskReminder(
                taskId: task.id,
                taskTitle: task.title,
                date: reminder,
                repeatRule: task.repeatRule,
                customWeekdays: task.customWeekdays
            )
        }
        
        // Invalidate context cache so AI sees the new task
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Task created successfully: \(task.id) - '\(title)'")
        #endif
    }
    
    private func updateTask(taskID: UUID, title: String?, reminderDate: Date?, duration: TimeInterval?) throws {
        guard let task = TasksStore.shared.tasks.first(where: { $0.id == taskID }) else {
            throw AIActionError.taskNotFound
        }
        
        var updatedTask = task
        if let title = title {
            updatedTask.title = title
        }
        if let reminderDate = reminderDate {
            updatedTask.reminderDate = reminderDate
        }
        if let duration = duration {
            updatedTask.durationMinutes = Int(duration / 60)
        }
        
        TasksStore.shared.upsert(updatedTask)
        
        // Update notification if reminder changed
        if let reminder = updatedTask.reminderDate, reminder > Date() {
            FocusLocalNotificationManager.shared.scheduleTaskReminder(
                taskId: updatedTask.id,
                taskTitle: updatedTask.title,
                date: reminder,
                repeatRule: updatedTask.repeatRule,
                customWeekdays: updatedTask.customWeekdays
            )
        } else {
            // Cancel if reminder was removed or is in the past
            FocusLocalNotificationManager.shared.cancelTaskReminder(taskId: taskID)
        }
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Task updated: \(taskID)")
        #endif
    }
    
    private func deleteTask(taskID: UUID) throws {
        // Cancel any scheduled notifications for this task
        FocusLocalNotificationManager.shared.cancelTaskReminder(taskId: taskID)
        
        TasksStore.shared.delete(taskID: taskID)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Task deleted: \(taskID)")
        #endif
    }
    
    private func toggleTaskCompletion(taskID: UUID) throws {
        let store = TasksStore.shared
        let calendar = Calendar.autoupdatingCurrent
        
        guard store.tasks.contains(where: { $0.id == taskID }) else {
            throw AIActionError.taskNotFound
        }
        
        // Toggle completion for today
        let today = calendar.startOfDay(for: Date())
        
        // Check current completion status using the correct method
        let wasCompleted = store.isCompleted(taskId: taskID, on: today, calendar: calendar)
        
        // Toggle using TasksStore's method
        store.toggleCompletion(taskID: taskID, on: today, calendar: calendar)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Task \(wasCompleted ? "marked incomplete" : "marked complete"): \(taskID)")
        #endif
    }
    
    // MARK: - Preset Actions
    
    private func setPreset(presetID: UUID) {
        // Set the preset as active
        FocusPresetStore.shared.activePresetID = presetID
        
        // Notify FocusView to apply the preset
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.applyPresetFromWidget"),
            object: nil,
            userInfo: ["presetID": presetID, "autoStart": false]
        )
        
        #if DEBUG
        print("[AIActionHandler] ✅ Preset activated: \(presetID)")
        #endif
    }
    
    private func createPreset(name: String, durationSeconds: Int, soundID: String) throws {
        guard !name.isEmpty else {
            throw AIActionError.invalidPresetName
        }
        
        guard durationSeconds > 0 else {
            throw AIActionError.invalidPresetDuration
        }
        
        let preset = FocusPreset(
            name: name,
            durationSeconds: durationSeconds,
            soundID: soundID,
            isSystemDefault: false
        )
        FocusPresetStore.shared.upsert(preset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Preset created: \(preset.id) - '\(name)' (\(durationSeconds / 60) min)")
        #endif
    }
    
    private func updatePreset(presetID: UUID, name: String?, durationSeconds: Int?) throws {
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw AIActionError.presetNotFound
        }
        
        var updatedPreset = preset
        if let name = name {
            updatedPreset.name = name
        }
        if let durationSeconds = durationSeconds {
            updatedPreset.durationSeconds = durationSeconds
        }
        
        FocusPresetStore.shared.upsert(updatedPreset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Preset updated: \(presetID)")
        #endif
    }
    
    private func deletePreset(presetID: UUID) throws {
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw AIActionError.presetNotFound
        }
        
        // Don't allow deleting system default presets
        if preset.isSystemDefault {
            throw AIActionError.cannotDeleteSystemPreset
        }
        
        FocusPresetStore.shared.delete(preset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Preset deleted: \(presetID)")
        #endif
    }
    
    // MARK: - Focus Actions
    
    private func startFocus(minutes: Int, presetID: UUID?, sessionName: String?) {
        guard minutes > 0 && minutes <= 480 else {
            #if DEBUG
            print("[AIActionHandler] ⚠️ Invalid focus duration: \(minutes) minutes")
            #endif
            return
        }
        
        // Post notification to start focus session
        // FocusView listens for this notification via handleAIStartFocus
        var userInfo: [String: Any] = [
            "minutes": minutes,
            "autoStart": true
        ]
        
        if let presetID = presetID {
            userInfo["presetID"] = presetID
        }
        
        if let sessionName = sessionName {
            userInfo["sessionName"] = sessionName
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.startFocusFromAI"),
            object: nil,
            userInfo: userInfo
        )
        
        // Provide haptic feedback
        Haptics.impact(.medium)
        
        #if DEBUG
        print("[AIActionHandler] ✅ Starting \(minutes)-minute focus session")
        if let name = sessionName {
            print("[AIActionHandler]    Session name: \(name)")
        }
        if let preset = presetID {
            print("[AIActionHandler]    Using preset: \(preset)")
        }
        #endif
    }
    
    // MARK: - Stats Generation
    
    private func generateStatsMessage(for period: String) -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var stats: (sessions: Int, minutes: Int, avgMinutes: Int) = (0, 0, 0)
        var periodLabel = ""
        
        switch period.lowercased() {
        case "today":
            periodLabel = "Today"
            let todaySessions = progress.sessions.filter { calendar.isDateInToday($0.date) }
            stats.sessions = todaySessions.count
            stats.minutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
            stats.avgMinutes = stats.sessions > 0 ? stats.minutes / stats.sessions : 0
            
        case "week":
            periodLabel = "This Week"
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let weekSessions = progress.sessions.filter { $0.date >= weekAgo }
            stats.sessions = weekSessions.count
            stats.minutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
            stats.avgMinutes = stats.sessions > 0 ? stats.minutes / stats.sessions : 0
            
        case "month":
            periodLabel = "This Month"
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let monthSessions = progress.sessions.filter { $0.date >= monthAgo }
            stats.sessions = monthSessions.count
            stats.minutes = Int(monthSessions.reduce(0) { $0 + $1.duration } / 60)
            stats.avgMinutes = stats.sessions > 0 ? stats.minutes / stats.sessions : 0
            
        default: // alltime
            periodLabel = "All Time"
            stats.sessions = progress.sessions.count
            stats.minutes = Int(progress.sessions.reduce(0) { $0 + $1.duration } / 60)
            stats.avgMinutes = stats.sessions > 0 ? stats.minutes / stats.sessions : 0
        }
        
        // Calculate goal progress for today
        let todayMinutes = Int(progress.totalToday / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let goalPercent = goalMinutes > 0 ? min(100, (todayMinutes * 100) / goalMinutes) : 0
        
        // Calculate streak
        let streak = progress.lifetimeBestStreak
        
        // Format hours and minutes nicely
        let hours = stats.minutes / 60
        let mins = stats.minutes % 60
        let timeStr = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
        
        var message = "📊 \(periodLabel) Stats\n\n"
        message += "⏱ Focus Time: \(timeStr)\n"
        message += "🎯 Sessions: \(stats.sessions)\n"
        
        if stats.avgMinutes > 0 {
            message += "📈 Avg Session: \(stats.avgMinutes) min\n"
        }
        
        if period.lowercased() == "today" {
            message += "\n🎯 Daily Goal: \(todayMinutes)/\(goalMinutes) min (\(goalPercent)%)\n"
            if goalPercent >= 100 {
                message += "🏆 Goal achieved! Great work!"
            } else {
                let remaining = goalMinutes - todayMinutes
                message += "💪 \(remaining) min to go!"
            }
        }
        
        if streak > 1 {
            message += "\n🔥 Current Streak: \(streak) days"
        }
        
        return message
    }
    
    /// Generate a formatted list of user's tasks
    private func generateTaskListMessage(period: String = "all") -> String {
        let tasksStore = TasksStore.shared
        let tasks = tasksStore.tasks
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        if tasks.isEmpty {
            return "📋 You don't have any tasks yet!\n\nWant me to create one? Just say something like \"Create a task to review documents at 3pm\""
        }
        
        let normalizedPeriod = period.lowercased()
        var dates: [Date] = []
        
        func days(from start: Date, count: Int) -> [Date] {
            (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        }
        
        let today = calendar.startOfDay(for: now)
        switch normalizedPeriod {
        case "today":
            dates = [today]
        case "tomorrow":
            if let d = calendar.date(byAdding: .day, value: 1, to: today) { dates = [d] }
        case "yesterday":
            if let d = calendar.date(byAdding: .day, value: -1, to: today) { dates = [d] }
        case "this_week":
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            dates = days(from: startOfWeek, count: 7)
        case "next_week":
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            if let nextWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) {
                dates = days(from: nextWeek, count: 7)
            }
        case "upcoming":
            dates = days(from: today, count: 14)
        default: // all
            // For "all", just use tasks without date filtering
            dates = []
        }
        
        var filteredTasks: [FFTaskItem] = []
        var completionMap: [UUID: Bool] = [:]
        
        if dates.isEmpty {
            filteredTasks = tasks
            // completion status for today
            for task in tasks {
                completionMap[task.id] = tasksStore.isCompleted(taskId: task.id, on: today, calendar: calendar)
            }
        } else {
            let dateSet = Set(dates)
            for date in dateSet {
                let visible = tasksStore.tasksVisible(on: date, calendar: calendar)
                for task in visible {
                    filteredTasks.append(task)
                    completionMap[task.id] = tasksStore.isCompleted(taskId: task.id, on: date, calendar: calendar)
                }
            }
            // Deduplicate by task ID while preserving order
            var seen = Set<UUID>()
            var unique: [FFTaskItem] = []
            for task in filteredTasks {
                if seen.insert(task.id).inserted {
                    unique.append(task)
                }
            }
            filteredTasks = unique
        }
        
        if filteredTasks.isEmpty {
            let label = periodLabel(normalizedPeriod: normalizedPeriod)
            return "📋 No tasks for \(label)."
        }
        
        var pendingTasks: [FFTaskItem] = []
        var completedTasks: [FFTaskItem] = []
        
        for task in filteredTasks {
            let isCompleted = completionMap[task.id] ?? false
            if isCompleted {
                completedTasks.append(task)
            } else {
                pendingTasks.append(task)
            }
        }
        
        var message = "📋 **Your Tasks**\n\n"
        message += periodLabel(normalizedPeriod: normalizedPeriod, long: true) + "\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        // Pending tasks
        if !pendingTasks.isEmpty {
            message += "\n**Pending** (\(pendingTasks.count))\n"
            
            let sorted = pendingTasks.sorted { task1, task2 in
                let date1 = task1.reminderDate ?? Date.distantFuture
                let date2 = task2.reminderDate ?? Date.distantFuture
                return date1 < date2
            }
            
            for task in sorted {
                let emoji = task.durationMinutes > 0 ? "⏱️" : "📌"
                message += "\(emoji) \(task.title)"
                
                if let reminder = task.reminderDate {
                    if calendar.isDateInToday(reminder) {
                        message += " • Today \(timeFormatter.string(from: reminder))"
                        if reminder < now { message += " ⚠️ Overdue" }
                    } else if calendar.isDateInTomorrow(reminder) {
                        message += " • Tomorrow \(timeFormatter.string(from: reminder))"
                    } else {
                        message += " • \(dateFormatter.string(from: reminder))"
                    }
                }
                
                if task.durationMinutes > 0 {
                    message += " (\(task.durationMinutes)m)"
                }
                message += "\n"
            }
        } else {
            message += "\n✅ **All caught up!** No pending tasks.\n"
        }
        
        // Completed
        if !completedTasks.isEmpty {
            message += "\n**Completed** (\(completedTasks.count))\n"
            for task in completedTasks.prefix(10) {
                message += "✅ \(task.title)\n"
            }
            if completedTasks.count > 10 {
                message += "   ...and \(completedTasks.count - 10) more\n"
            }
        }
        
        return message
    }
    
    private func periodLabel(normalizedPeriod: String, long: Bool = false) -> String {
        switch normalizedPeriod {
        case "today": return long ? "Today" : "today"
        case "tomorrow": return long ? "Tomorrow" : "tomorrow"
        case "yesterday": return long ? "Yesterday" : "yesterday"
        case "this_week": return long ? "This Week" : "this week"
        case "next_week": return long ? "Next Week" : "next week"
        case "upcoming": return long ? "Upcoming 14 days" : "upcoming"
        default: return long ? "All Tasks" : "all tasks"
        }
    }
    
    private func generateProductivityAnalysis() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var message = "🧠 Productivity Analysis\n\n"
        
        // Get sessions from last 30 days
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentSessions = progress.sessions.filter { $0.date >= monthAgo }
        
        if recentSessions.isEmpty {
            message += "No sessions recorded in the last 30 days. Start a focus session to build your productivity data!"
            return message
        }
        
        // Total stats
        let totalMinutes = Int(recentSessions.reduce(0) { $0 + $1.duration } / 60)
        let avgSessionLength = totalMinutes / max(1, recentSessions.count)
        
        // Find most productive day of week
        var dayStats: [Int: Int] = [:] // weekday -> total minutes
        for session in recentSessions {
            let weekday = calendar.component(.weekday, from: session.date)
            dayStats[weekday, default: 0] += Int(session.duration / 60)
        }
        let bestDay = dayStats.max(by: { $0.value < $1.value })
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        // Find most productive hour
        var hourStats: [Int: Int] = [:] // hour -> total minutes
        for session in recentSessions {
            let hour = calendar.component(.hour, from: session.date)
            hourStats[hour, default: 0] += Int(session.duration / 60)
        }
        let bestHour = hourStats.max(by: { $0.value < $1.value })
        
        // Sessions per day average
        let uniqueDays = Set(recentSessions.map { calendar.startOfDay(for: $0.date) }).count
        let sessionsPerDay = Double(recentSessions.count) / Double(max(1, uniqueDays))
        
        // Build analysis
        message += "📅 Last 30 Days Overview:\n"
        message += "• \(recentSessions.count) sessions totaling \(totalMinutes / 60)h \(totalMinutes % 60)m\n"
        message += "• Average session: \(avgSessionLength) minutes\n"
        message += "• Sessions per active day: \(String(format: "%.1f", sessionsPerDay))\n\n"
        
        message += "🎯 Insights:\n"
        
        if let day = bestDay {
            message += "• Most productive day: \(dayNames[day.key - 1]) (\(day.value) min)\n"
        }
        
        if let hour = bestHour {
            let hourStr = hour.key == 0 ? "12 AM" : hour.key < 12 ? "\(hour.key) AM" : hour.key == 12 ? "12 PM" : "\(hour.key - 12) PM"
            message += "• Peak focus hour: \(hourStr)\n"
        }
        
        // Recommendations
        message += "\n💡 Recommendations:\n"
        
        if avgSessionLength < 20 {
            message += "• Try longer sessions (25-50 min) for deeper focus\n"
        } else if avgSessionLength > 60 {
            message += "• Great endurance! Consider short breaks between sessions\n"
        }
        
        if sessionsPerDay < 2 {
            message += "• Aim for 2-3 sessions daily for consistent progress\n"
        }
        
        if let hour = bestHour {
            let hourStr = hour.key == 0 ? "12 AM" : hour.key < 12 ? "\(hour.key) AM" : hour.key == 12 ? "12 PM" : "\(hour.key - 12) PM"
            message += "• Schedule important work around \(hourStr) - your peak time!"
        }
        
        return message
    }
    
    private func postStatsFollowUp(_ message: String) {
        // Post a follow-up message with the stats
        let statsMessage = AIMessage(text: message, sender: .assistant)
        AIMessageStore.shared.addMessage(statsMessage)
    }
    
    // MARK: - Smart Planning
    
    private func generateSmartDailyPlan() -> String {
        let progress = ProgressStore.shared
        let tasks = TasksStore.shared.tasks
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var message = "📋 Your Smart Daily Plan\n\n"
        
        // Get today's progress so far
        let todayMinutes = Int(progress.totalToday / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let remainingGoal = max(0, goalMinutes - todayMinutes)
        
        // Find best focus hour from history
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentSessions = progress.sessions.filter { $0.date >= monthAgo }
        
        var hourStats: [Int: Int] = [:]
        for session in recentSessions {
            let hour = calendar.component(.hour, from: session.date)
            hourStats[hour, default: 0] += Int(session.duration / 60)
        }
        let peakHour = hourStats.max(by: { $0.value < $1.value })?.key ?? 10
        
        // Current hour
        let currentHour = calendar.component(.hour, from: now)
        
        // Get today's tasks with reminders
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? now
        let todayTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return reminder >= todayStart && reminder < todayEnd
        }.sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
        
        // Morning greeting based on time
        if currentHour < 12 {
            message += "☀️ Good morning! Here's your focus plan:\n\n"
        } else if currentHour < 17 {
            message += "🌤 Good afternoon! Here's what's left today:\n\n"
        } else {
            message += "🌙 Good evening! Here's your evening plan:\n\n"
        }
        
        // Progress so far
        if todayMinutes > 0 {
            message += "✅ Progress: \(todayMinutes)/\(goalMinutes) min done\n"
        }
        
        // Upcoming tasks
        if !todayTasks.isEmpty {
            message += "\n📌 Today's Tasks:\n"
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            
            for task in todayTasks.prefix(5) {
                if let reminder = task.reminderDate {
                    let timeStr = dateFormatter.string(from: reminder)
                    let isPast = reminder < now
                    let emoji = isPast ? "⏰" : "📍"
                    message += "\(emoji) \(timeStr) - \(task.title)\n"
                }
            }
        }
        
        // Suggested focus blocks
        message += "\n💡 Suggested Focus Blocks:\n"
        
        if remainingGoal > 0 {
            let sessionsNeeded = max(1, remainingGoal / 25) // 25-min sessions
            
            // Suggest based on peak hour
            if currentHour <= peakHour && peakHour < 20 {
                let peakStr = peakHour < 12 ? "\(peakHour) AM" : peakHour == 12 ? "12 PM" : "\(peakHour - 12) PM"
                message += "🎯 Peak time at \(peakStr) - schedule deep work!\n"
            }
            
            if sessionsNeeded == 1 {
                message += "• 1 session of \(remainingGoal) min to hit your goal\n"
            } else {
                message += "• \(sessionsNeeded) sessions of 25 min each\n"
            }
            
            // Time-specific suggestions
            if currentHour < 10 {
                message += "• Morning: Great for creative/deep work\n"
            } else if currentHour < 14 {
                message += "• Try a session before lunch\n"
            } else if currentHour < 18 {
                message += "• Afternoon session recommended\n"
            } else {
                message += "• Evening wind-down session\n"
            }
        } else {
            message += "🏆 You've hit your goal! Any extra is bonus!\n"
        }
        
        // Quick motivation
        let motivations = [
            "\n💪 You've got this!",
            "\n🚀 Ready to crush it!",
            "\n✨ Focus mode: activated!",
            "\n🔥 Let's make today count!"
        ]
        message += motivations.randomElement() ?? ""
        
        return message
    }
    
    private func generateBreakSuggestion() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var message = "☕️ Break Time Suggestion\n\n"
        
        // Check recent activity
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        let recentSessions = progress.sessions.filter { $0.date >= oneHourAgo }
        let recentMinutes = Int(recentSessions.reduce(0) { $0 + $1.duration } / 60)
        
        // Today's total
        let todayMinutes = Int(progress.totalToday / 60)
        
        if recentMinutes >= 50 {
            message += "🧠 You've focused for \(recentMinutes) min in the last hour!\n\n"
            message += "Your brain needs rest to consolidate learning.\n\n"
            message += "🌟 Suggested break activities:\n"
            message += "• 🚶 5-min walk\n"
            message += "• 💧 Hydrate & stretch\n"
            message += "• 👀 Look at something far away (20-20-20 rule)\n"
            message += "• 🧘 Quick breathing exercise\n"
            message += "\n⏰ Recommended break: 10-15 minutes"
        } else if todayMinutes >= 120 {
            message += "📊 You've done \(todayMinutes) min today - solid work!\n\n"
            message += "Consider a medium break:\n"
            message += "• ☕️ Grab a healthy snack\n"
            message += "• 🎵 Listen to a favorite song\n"
            message += "• 💬 Quick chat with someone\n"
            message += "\n⏰ Suggested: 5-10 min break"
        } else if recentMinutes > 0 {
            message += "Good progress! \(recentMinutes) min in the last hour.\n\n"
            message += "Quick refresh ideas:\n"
            message += "• 💨 Take 3 deep breaths\n"
            message += "• 🙆 Quick stretch at your desk\n"
            message += "• 💧 Drink some water\n"
            message += "\n⏰ 2-5 min micro-break"
        } else {
            message += "Ready to start? Here's a quick energizer:\n\n"
            message += "• 🙆 Stretch for 1 minute\n"
            message += "• 💨 5 deep breaths\n"
            message += "• 🎯 Set your intention\n"
            message += "\nThen start a focus session! 💪"
        }
        
        return message
    }
    
    private func generateMotivation() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        // Gather stats for personalized motivation
        let todayMinutes = Int(progress.totalToday / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let goalPercent = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        // Calculate streak
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        for _ in 0..<365 {
            let hasSession = progress.sessions.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if streak > 0 {
                break
            } else {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        var message = ""
        
        // Context-aware motivation
        if goalPercent >= 100 {
            let celebrations = [
                "🏆 GOAL CRUSHED!\n\nYou hit \(todayMinutes) min today - that's \(goalPercent)% of your goal!\n\nYou're building something amazing. Every session compounds into mastery.",
                "🎉 YOU DID IT!\n\n\(todayMinutes) minutes of pure focus today!\n\nThis is what champions do. Keep showing up!",
                "⭐️ INCREDIBLE!\n\nGoal: Smashed ✓\nFocus: On point ✓\nYou: Unstoppable ✓\n\nYou're not just meeting goals, you're exceeding them!"
            ]
            message = celebrations.randomElement() ?? celebrations[0]
        } else if goalPercent >= 75 {
            message = "🔥 SO CLOSE!\n\n\(todayMinutes)/\(goalMinutes) min - you're at \(goalPercent)%!\n\nJust \(goalMinutes - todayMinutes) more minutes. One session away from victory!\n\nYou didn't come this far to only come this far. 💪"
        } else if goalPercent >= 50 {
            message = "💪 HALFWAY THERE!\n\n\(todayMinutes) min done - solid foundation!\n\nThe second half is where champions are made.\n\nRemember: Progress > Perfection\n\nLet's keep the momentum going! 🚀"
        } else if todayMinutes > 0 {
            message = "🌱 GREAT START!\n\n\(todayMinutes) min in the books.\n\nEvery minute of focus is an investment in your future self.\n\n\"The secret of getting ahead is getting started.\" - Mark Twain\n\nYou've started. Now let's build! 💫"
        } else {
            let starters = [
                "🚀 READY TO BEGIN?\n\nToday is a fresh canvas.\n\nYou have \(goalMinutes) minutes of potential waiting.\n\nOne small step: Start a 5-minute session. Just 5 minutes.\n\nYour future self will thank you! ⏰",
                "✨ NEW DAY, NEW OPPORTUNITIES!\n\nYesterday is gone. Tomorrow isn't here.\n\nBut right now? Right now is yours.\n\nStart with just one session. You've got this! 💪",
                "🎯 TODAY'S THE DAY!\n\n\"The best time to plant a tree was 20 years ago. The second best time is now.\"\n\nYour goal: \(goalMinutes) min\nYour first step: One session\n\nLet's go! 🔥"
            ]
            message = starters.randomElement() ?? starters[0]
        }
        
        // Add streak if impressive
        if streak >= 3 {
            message += "\n\n🔥 \(streak)-day streak! Don't break the chain!"
        }
        
        return message
    }
    
    /// Generate comprehensive weekly productivity report
    private func generateWeeklyReport() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        // Get sessions from the past week
        let weeklySessions = progress.sessions.filter { $0.date >= weekAgo }
        
        // Calculate weekly stats
        let totalMinutes = Int(weeklySessions.reduce(0) { $0 + $1.duration } / 60)
        let totalSessions = weeklySessions.count
        let avgSessionLength = totalSessions > 0 ? totalMinutes / totalSessions : 0
        
        // Daily breakdown
        var dailyMinutes: [String: Int] = [:]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        for session in weeklySessions {
            let dayName = dayFormatter.string(from: session.date)
            dailyMinutes[dayName, default: 0] += Int(session.duration / 60)
        }
        
        // Find best and worst days
        let sortedDays = dailyMinutes.sorted { $0.value > $1.value }
        let bestDay = sortedDays.first
        let activeDays = dailyMinutes.filter { $0.value > 0 }.count
        
        // Calculate streak
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: now)
        for _ in 0..<365 {
            let hasSession = progress.sessions.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasSession {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if currentStreak > 0 {
                break
            } else {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        // Build the report
        var message = "📊 **WEEKLY PRODUCTIVITY REPORT**\n"
        message += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        // Overview stats
        message += "📈 **OVERVIEW**\n"
        message += "• Total Focus Time: \(totalMinutes) min (\(totalMinutes / 60)h \(totalMinutes % 60)m)\n"
        message += "• Sessions Completed: \(totalSessions)\n"
        message += "• Avg Session Length: \(avgSessionLength) min\n"
        message += "• Active Days: \(activeDays)/7\n"
        if currentStreak > 0 {
            message += "• Current Streak: \(currentStreak) days 🔥\n"
        }
        
        message += "\n"
        
        // Daily breakdown
        message += "📅 **DAILY BREAKDOWN**\n"
        let orderedDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        for day in orderedDays {
            let mins = dailyMinutes[day] ?? 0
            let bar = String(repeating: "█", count: min(mins / 10, 10))
            let emoji = mins >= 60 ? "✅" : mins > 0 ? "🟡" : "⬜️"
            message += "\(emoji) \(day.prefix(3)): \(mins) min \(bar)\n"
        }
        
        message += "\n"
        
        // Insights
        message += "💡 **INSIGHTS**\n"
        
        if let best = bestDay, best.value > 0 {
            message += "• Best day: \(best.key) (\(best.value) min) 🌟\n"
        }
        
        let weeklyGoal = progress.dailyGoalMinutes * 7
        let goalPercent = weeklyGoal > 0 ? (totalMinutes * 100) / weeklyGoal : 0
        message += "• Weekly goal progress: \(goalPercent)%\n"
        
        if avgSessionLength >= 25 {
            message += "• Great session lengths! Perfect for deep work 🎯\n"
        } else if avgSessionLength > 0 {
            message += "• Try longer sessions (25+ min) for deeper focus 📈\n"
        }
        
        if activeDays >= 5 {
            message += "• Excellent consistency this week! 💪\n"
        } else if activeDays >= 3 {
            message += "• Good start! Aim for 5+ active days 🎯\n"
        } else {
            message += "• Build consistency with daily focus habits 🌱\n"
        }
        
        message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        message += "Keep up the great work! 🚀"
        
        return message
    }
    
    /// Generate personalized welcome/greeting message
    private func generateWelcomeMessage() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Get user info
        let displayName = AppSettings.shared.displayName ?? "there"
        let firstName = displayName.components(separatedBy: " ").first ?? displayName
        
        // Time-based greeting
        let greeting: String
        if hour >= 5 && hour < 12 {
            greeting = "Good morning"
        } else if hour >= 12 && hour < 17 {
            greeting = "Good afternoon"
        } else if hour >= 17 && hour < 21 {
            greeting = "Good evening"
        } else {
            greeting = "Hey"
        }
        
        // Calculate today's stats
        let todayMinutes = Int(progress.totalToday / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let goalPercent = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        // Calculate streak
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        for _ in 0..<365 {
            let hasSession = progress.sessions.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if streak > 0 {
                break
            } else {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        // Get pending tasks (not completed today)
        let today = calendar.startOfDay(for: now)
        let pendingTasks = TasksStore.shared.tasks.filter { 
            !TasksStore.shared.isCompleted(taskId: $0.id, on: today, calendar: calendar) 
        }
        
        // Build welcome message
        var message = "\(greeting), \(firstName)! 👋\n\n"
        
        // Quick status
        message += "📊 **TODAY'S STATUS**\n"
        if todayMinutes > 0 {
            message += "• Focus time: \(todayMinutes)/\(goalMinutes) min (\(goalPercent)%)\n"
            if goalPercent >= 100 {
                message += "• 🏆 Daily goal achieved!\n"
            }
        } else {
            message += "• Ready to start your first session!\n"
            message += "• Daily goal: \(goalMinutes) min\n"
        }
        
        if streak > 1 {
            message += "• 🔥 \(streak)-day streak!\n"
        }
        
        message += "\n"
        
        // Tasks preview
        if !pendingTasks.isEmpty {
            message += "📋 **PENDING TASKS** (\(pendingTasks.count))\n"
            for task in pendingTasks.prefix(3) {
                let emoji = task.durationMinutes > 0 ? "⏱️" : "📌"
                message += "\(emoji) \(task.title)\n"
            }
            if pendingTasks.count > 3 {
                message += "...and \(pendingTasks.count - 3) more\n"
            }
            message += "\n"
        }
        
        // Suggestions based on context
        message += "💡 **SUGGESTIONS**\n"
        
        if todayMinutes == 0 {
            message += "• Start with a quick 15-min focus session\n"
            if !pendingTasks.isEmpty {
                message += "• Work on: \"\(pendingTasks[0].title)\"\n"
            }
        } else if goalPercent < 50 {
            let remaining = goalMinutes - todayMinutes
            message += "• \(remaining) min left to reach 50% of your goal\n"
        } else if goalPercent < 100 {
            let remaining = goalMinutes - todayMinutes
            message += "• Just \(remaining) min to hit your daily goal! 🎯\n"
        } else {
            message += "• Great job! Consider bonus sessions or take a break\n"
        }
        
        message += "\nHow can I help you today? 🚀"
        
        return message
    }
    
    // MARK: - Settings Actions
    
    private func updateSetting(setting: String, value: String) throws {
        let appSettings = AppSettings.shared
        
        // Normalize setting name for case-insensitive matching
        let normalizedSetting = setting.lowercased().replacingOccurrences(of: "_", with: "")
        
        switch normalizedSetting {
        case "dailygoal", "goal":
            guard let minutes = Int(value), minutes > 0, minutes <= 1440 else {
                throw AIActionError.invalidSettingValue
            }
            ProgressStore.shared.dailyGoalMinutes = minutes
            #if DEBUG
            print("[AIActionHandler] ✅ Daily goal set to \(minutes) minutes")
            #endif
            
        case "theme":
            guard let theme = AppTheme(rawValue: value.lowercased()) else {
                throw AIActionError.invalidSettingValue
            }
            appSettings.profileTheme = theme
            appSettings.selectedTheme = theme
            #if DEBUG
            print("[AIActionHandler] ✅ Theme changed to \(theme.displayName)")
            #endif
            
        case "soundenabled", "sound":
            let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
            appSettings.soundEnabled = enabled
            #if DEBUG
            print("[AIActionHandler] ✅ Sound \(enabled ? "enabled" : "disabled")")
            #endif
            
        case "hapticsenabled", "haptics":
            let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
            appSettings.hapticsEnabled = enabled
            #if DEBUG
            print("[AIActionHandler] ✅ Haptics \(enabled ? "enabled" : "disabled")")
            #endif
            
        case "focussound":
            if value.lowercased() == "none" || value.isEmpty {
                appSettings.selectedFocusSound = nil
            } else if let sound = FocusSound(rawValue: value) {
                appSettings.selectedFocusSound = sound
            } else {
                throw AIActionError.invalidSettingValue
            }
            #if DEBUG
            print("[AIActionHandler] ✅ Focus sound set to \(value)")
            #endif
            
        case "displayname", "name":
            guard !value.isEmpty else {
                throw AIActionError.invalidSettingValue
            }
            appSettings.displayName = value
            #if DEBUG
            print("[AIActionHandler] ✅ Display name changed to \(value)")
            #endif
            
        case "tagline":
            appSettings.tagline = value
            #if DEBUG
            print("[AIActionHandler] ✅ Tagline changed to \(value)")
            #endif
            
        default:
            throw AIActionError.unknownSetting
        }
        
        // Sync widgets after settings change
        WidgetDataManager.shared.syncAll()
    }
}

// MARK: - Error Types

enum AIActionError: LocalizedError {
    case invalidTaskTitle
    case taskNotFound
    case invalidPresetName
    case invalidPresetDuration
    case presetNotFound
    case cannotDeleteSystemPreset
    case invalidSettingValue
    case unknownSetting
    case focusSessionAlreadyActive
    
    var errorDescription: String? {
        switch self {
        case .invalidTaskTitle:
            return "Task title cannot be empty"
        case .taskNotFound:
            return "Task not found"
        case .invalidPresetName:
            return "Preset name cannot be empty"
        case .invalidPresetDuration:
            return "Preset duration must be greater than 0"
        case .presetNotFound:
            return "Preset not found"
        case .cannotDeleteSystemPreset:
            return "Cannot delete system default preset"
        case .invalidSettingValue:
            return "Invalid setting value"
        case .unknownSetting:
            return "Unknown setting"
        case .focusSessionAlreadyActive:
            return "A focus session is already in progress"
        }
    }
}
