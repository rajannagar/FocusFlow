import Foundation

/// Builds context string from user data for AI prompts
@MainActor
final class AIContextBuilder {
    static let shared = AIContextBuilder()
    
    private var cachedContext: String?
    private var cacheTimestamp: Date?
    
    private init() {}
    
    /// Builds context string from current user data
    func buildContext() -> String {
        // Check cache
        if let cached = cachedContext,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < AIConfig.contextCacheDuration {
            return cached
        }
        
        // Get current date/time at the start (used throughout)
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        var context = "You are Focus AI, an intelligent productivity assistant for FocusFlow, a focus timer and productivity app.\n\n"
        context += "User Context:\n"
        
        // Recent Sessions (last 10)
        let sessions = ProgressStore.shared.sessions.suffix(10)
        if !sessions.isEmpty {
            context += "- Recent Sessions:\n"
            for session in sessions {
                let durationMinutes = Int(session.duration / 60)
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let dateStr = dateFormatter.string(from: session.date)
                let name = session.sessionName ?? "Untitled"
                context += "  * \(name): \(durationMinutes) minutes on \(dateStr)\n"
            }
        } else {
            context += "- Recent Sessions: None yet\n"
        }
        
        // All Tasks with IDs (for modification/deletion)
        let allTasks = TasksStore.shared.tasks
        if !allTasks.isEmpty {
            context += "- All Tasks (with IDs for reference):\n"
            for task in allTasks.prefix(20) { // Limit to 20 tasks
                var taskInfo = "  * [\(task.id.uuidString)] \(task.title)"
                if let reminder = task.reminderDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    let reminderStr = dateFormatter.string(from: reminder)
                    let isFuture = reminder > now
                    let isPast = reminder <= now
                    if isFuture {
                        taskInfo += " (reminder: \(reminderStr) - FUTURE)"
                    } else if isPast {
                        taskInfo += " (reminder: \(reminderStr) - PAST)"
                    } else {
                        taskInfo += " (reminder: \(reminderStr))"
                    }
                } else {
                    taskInfo += " (no reminder date)"
                }
                if task.durationMinutes > 0 {
                    taskInfo += " (duration: \(task.durationMinutes) min)"
                }
                context += taskInfo + "\n"
            }
        } else {
            context += "- Tasks: None\n"
        }
        
        // Future Tasks (tasks with reminders in the future) - for quick reference
        let futureTasks = allTasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return reminder > now
        }
        if !futureTasks.isEmpty {
            context += "- Future Tasks (upcoming reminders, sorted by date):\n"
            for task in futureTasks.sorted(by: { ($0.reminderDate ?? Date.distantFuture) < ($1.reminderDate ?? Date.distantFuture) }) {
                if let reminder = task.reminderDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    context += "  * [\(task.id.uuidString)] \(task.title) - \(dateFormatter.string(from: reminder))"
                    if task.durationMinutes > 0 {
                        context += " (\(task.durationMinutes) min)"
                    }
                    context += "\n"
                }
            }
        } else {
            context += "- Future Tasks: None (no tasks with future reminders)\n"
        }
        
        // Available Presets with IDs
        let presets = FocusPresetStore.shared.presets
        if !presets.isEmpty {
            context += "- Available Presets (with IDs for reference):\n"
            for preset in presets.prefix(20) { // Limit to 20 presets
                let durationMinutes = preset.durationSeconds / 60
                context += "  * [\(preset.id.uuidString)] \(preset.name): \(durationMinutes) minutes\n"
            }
        } else {
            context += "- Available Presets: None\n"
        }
        
        // Progress Stats
        let progressStore = ProgressStore.shared
        
        // Current Settings
        let appSettings = AppSettings.shared
        context += "- Current Settings:\n"
        context += "  * Daily Goal: \(progressStore.dailyGoalMinutes) minutes\n"
        context += "  * Theme: \(appSettings.profileTheme.displayName)\n"
        context += "  * Sound Enabled: \(appSettings.soundEnabled ? "Yes" : "No")\n"
        context += "  * Haptics Enabled: \(appSettings.hapticsEnabled ? "Yes" : "No")\n"
        if let sound = appSettings.selectedFocusSound {
            context += "  * Focus Sound: \(sound.rawValue)\n"
        }
        
        context += "- Progress:\n"
        context += "  * Daily Goal: \(progressStore.dailyGoalMinutes) minutes\n"
        
        // Calculate streak (simplified - count consecutive days with sessions)
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        for dayOffset in 0..<365 {
            let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate)!
            let hasSession = progressStore.sessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: checkDate)
            }
            if hasSession {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
        }
        context += "  * Current Streak: \(streak) days\n"
        
        // Total focus time
        let totalMinutes = Int(progressStore.sessions.reduce(0) { $0 + $1.duration } / 60)
        context += "  * Total Focus Time: \(totalMinutes) minutes\n"
        
        // Pro Status
        let isPro = ProEntitlementManager.shared.isPro
        context += "  * Pro Status: \(isPro ? "Active" : "Not Active")\n"
        
        context += "\nYou can help with:\n"
        context += "TASKS:\n"
        context += "- Creating tasks (use create_task function)\n"
        context += "- Updating tasks (use update_task function with task ID from context)\n"
        context += "- Deleting tasks (use delete_task function with task ID from context)\n"
        context += "- Listing future tasks (use list_future_tasks function)\n"
        context += "\nPRESETS:\n"
        context += "- Setting active preset (use set_preset function with preset ID)\n"
        context += "- Creating presets (use create_preset function)\n"
        context += "- Updating presets (use update_preset function with preset ID)\n"
        context += "- Deleting presets (use delete_preset function with preset ID)\n"
        context += "\nSETTINGS:\n"
        context += "- Changing daily goal (use update_setting with setting='dailyGoal' and value in minutes)\n"
        context += "- Changing theme (use update_setting with setting='theme' and value=theme name)\n"
        context += "- Toggling sound/haptics (use update_setting with setting='soundEnabled' or 'hapticsEnabled' and value='true'/'false')\n"
        context += "\nSTATS & ANALYSIS:\n"
        context += "- Getting stats (use get_stats function with period: 'today', 'week', '7days', 'month', '30days')\n"
        context += "- Analyzing sessions (provide insights based on context data)\n"
        // Get current date info for context (reuse existing calendar and now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        let currentDateString = dateFormatter.string(from: now)
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)
        
        // Calculate tomorrow's date for reference
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowYear = calendar.component(.year, from: tomorrow)
        let tomorrowMonth = calendar.component(.month, from: tomorrow)
        let tomorrowDay = calendar.component(.day, from: tomorrow)
        
        // Format today's date in ISO format for examples
        let todayISO = String(format: "%04d-%02d-%02d", currentYear, currentMonth, currentDay)
        let tomorrowISO = String(format: "%04d-%02d-%02d", tomorrowYear, tomorrowMonth, tomorrowDay)
        
        context += "\nIMPORTANT RULES:\n"
        context += "- When user asks to create/modify/delete, ALWAYS use the appropriate function\n"
        context += "- For task/preset operations, use IDs from the context above\n"
        context += "\nCRITICAL DATE & TIME HANDLING:\n"
        context += "- Current date and time: \(currentDateString)\n"
        context += "- TODAY's date (YYYY-MM-DD): \(todayISO)\n"
        context += "- TOMORROW's date (YYYY-MM-DD): \(tomorrowISO)\n"
        context += "\nTIME PARSING RULES:\n"
        context += "- When user says 'today', 'tonight', 'this evening', use TODAY's date: \(todayISO)\n"
        context += "- When user says 'tomorrow', use TOMORROW's date: \(tomorrowISO)\n"
        context += "- If user mentions ANY time (7pm, 7 PM, 7:00 PM, at 7pm, tonight at 7, etc.), you MUST include reminderDate\n"
        context += "- Time format: Convert to 24-hour format (7pm = 19, 2pm = 14, 11pm = 23, 9am = 09)\n"
        context += "- ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ (always use Z for UTC timezone)\n"
        context += "- ALWAYS use TODAY or FUTURE dates for reminders, NEVER use past dates\n"
        context += "\nEXAMPLES:\n"
        context += "- User: 'dinner tonight at 7pm' → reminderDate: '\(todayISO)T19:00:00Z'\n"
        context += "- User: 'dinner at 7 PM' → reminderDate: '\(todayISO)T19:00:00Z'\n"
        context += "- User: 'meeting tomorrow at 2pm' → reminderDate: '\(tomorrowISO)T14:00:00Z'\n"
        context += "- User: 'task at 7:00 PM' → reminderDate: '\(todayISO)T19:00:00Z'\n"
        context += "- User: 'breakfast at 9am tomorrow' → reminderDate: '\(tomorrowISO)T09:00:00Z'\n"
        context += "\nOTHER RULES:\n"
        context += "- When user asks 'what tasks do I have?', 'show my tasks', 'list my tasks', or 'upcoming tasks', ALWAYS use list_future_tasks function\n"
        context += "- The list_future_tasks function will automatically format and display all tasks with future reminders\n"
        context += "- When user asks for stats/overview, use get_stats with appropriate period\n"
        context += "- Keep responses concise and helpful\n"
        context += "- When listing tasks, always show the reminder dates and times clearly\n"
        
        // Cache the context
        cachedContext = context
        cacheTimestamp = Date()
        
        return context
    }
    
    /// Invalidates the context cache (call when data changes)
    func invalidateCache() {
        cachedContext = nil
        cacheTimestamp = nil
    }
}

