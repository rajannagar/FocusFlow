import Foundation

/// Builds context string from user data for AI prompts
/// This context is sent to the Edge Function which passes it to OpenAI
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
        
        let context = buildContextInternal()
        
        // Cache the context
        cachedContext = context
        cacheTimestamp = Date()
        
        return context
    }
    
    /// Internal context building logic
    private func buildContextInternal() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let userName = AppSettings.shared.displayName ?? "there"
        let firstName = userName.components(separatedBy: " ").first ?? userName
        
        // Time-based greeting
        let hour = calendar.component(.hour, from: now)
        let timeOfDay: String
        if hour >= 5 && hour < 12 {
            timeOfDay = "morning"
        } else if hour >= 12 && hour < 17 {
            timeOfDay = "afternoon"
        } else if hour >= 17 && hour < 21 {
            timeOfDay = "evening"
        } else {
            timeOfDay = "night"
        }
        
        var context = """
        You are Focus AI, a warm, supportive, and highly capable productivity assistant for FocusFlow.
        
        PERSONALITY:
        • Be warm, friendly, and encouraging - like a supportive friend who helps you stay productive
        • Use the user's name (\(firstName)) naturally when appropriate
        • Be concise but never robotic - add personality to responses
        • Celebrate wins (big and small) with genuine enthusiasm
        • When tasks are completed, be encouraging
        • Use emojis sparingly but effectively (1-2 per message max)
        • Never be preachy or lecture the user
        
        CURRENT CONTEXT:
        • User: \(firstName)
        • Time: \(formatDateTime(now)) (\(timeOfDay))
        • Day: \(formatDayOfWeek(now))
        
        """
        
        // MARK: - User Data Section
        context += "=== USER DATA ===\n\n"
        
        // Tasks with completion status
        context += buildTasksContext(now: now, calendar: calendar)
        
        // Presets
        context += buildPresetsContext()
        
        // Recent Sessions
        context += buildSessionsContext()
        
        // Settings & Progress
        context += buildSettingsContext()
        
        // MARK: - Capabilities Section
        context += """
        
        === WHAT YOU CAN DO ===
        
        TASKS:
        • create_task - Create new tasks with optional reminder time and duration
        • update_task - Modify existing tasks (use taskID from above)
        • delete_task - Remove tasks (use taskID from above)
        • toggle_task_completion - Mark tasks complete/incomplete
        • list_future_tasks - Show all upcoming tasks
        
        PRESETS:
        • set_preset - Activate a focus preset (use presetID from above)
        • create_preset - Create new preset with name, duration (in seconds), and sound
        • update_preset - Modify existing preset
        • delete_preset - Remove a preset
        
        FOCUS:
        • start_focus - Start a focus session (specify minutes, optionally preset and session name)
        
        SETTINGS:
        • update_setting - Change app settings:
          - dailyGoal: value in minutes (e.g., "60")
          - theme: forest/neon/peach/cyber/ocean/sunrise/amber/mint/royal/slate
          - soundEnabled: true/false
          - hapticsEnabled: true/false
          - focusSound: sound ID or "none"
          - displayName: user's name
        
        STATS & ANALYTICS:
        • get_stats - Get productivity stats for: today, week, month, alltime
        • analyze_sessions - Provide detailed productivity insights
        
        SMART FEATURES:
        • generate_daily_plan - Create personalized daily plan based on tasks and patterns
        • suggest_break - Suggest appropriate breaks based on recent focus activity
        • motivate - Provide personalized motivation and encouragement
        • generate_weekly_report - Generate comprehensive weekly productivity report
        • show_welcome - Show personalized welcome with status and suggestions
        
        """
        
        // MARK: - Rules Section
        context += buildRulesContext(now: now, calendar: calendar)
        
        return context
    }
    
    // MARK: - Context Builders
    
    private func buildTasksContext(now: Date, calendar: Calendar) -> String {
        var context = "TASKS:\n"
        let allTasks = TasksStore.shared.tasks
        let today = calendar.startOfDay(for: now)
        
        if allTasks.isEmpty {
            context += "  (No tasks - user hasn't created any yet)\n\n"
            return context
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        // Separate pending and completed tasks
        var pendingTasks: [FFTaskItem] = []
        var completedTasks: [FFTaskItem] = []
        
        for task in allTasks {
            let isCompleted = TasksStore.shared.isCompleted(taskId: task.id, on: today, calendar: calendar)
            if isCompleted {
                completedTasks.append(task)
            } else {
                pendingTasks.append(task)
            }
        }
        
        // Show pending tasks first (most relevant)
        if !pendingTasks.isEmpty {
            context += "  📋 PENDING TASKS (\(pendingTasks.count)):\n"
            for task in pendingTasks.prefix(15) {
                context += "    • [\(task.id.uuidString)] \(task.title)"
                if let reminder = task.reminderDate {
                    let isPast = reminder < now
                    let timeStr = dateFormatter.string(from: reminder)
                    context += " - \(timeStr) [\(isPast ? "OVERDUE" : "UPCOMING")]"
                }
                if task.durationMinutes > 0 {
                    context += " (\(task.durationMinutes)min)"
                }
                context += "\n"
            }
        } else {
            context += "  📋 PENDING TASKS: None - all caught up! 🎉\n"
        }
        
        // Show completed tasks
        if !completedTasks.isEmpty {
            context += "\n  ✅ COMPLETED TODAY (\(completedTasks.count)):\n"
            for task in completedTasks.prefix(5) {
                context += "    • \(task.title)\n"
            }
        }
        
        context += "\n"
        return context
    }
    
    private func buildPresetsContext() -> String {
        var context = "FOCUS PRESETS:\n"
        let presets = FocusPresetStore.shared.presets
        
        if presets.isEmpty {
            context += "  (No presets)\n\n"
            return context
        }
        
        for preset in presets.prefix(15) {
            let minutes = preset.durationSeconds / 60
            let activeMarker = preset.id == FocusPresetStore.shared.activePresetID ? " [ACTIVE]" : ""
            context += "  • [\(preset.id.uuidString)] \(preset.name): \(minutes) minutes\(activeMarker)\n"
        }
        
        context += "\n"
        return context
    }
    
    private func buildSessionsContext() -> String {
        var context = "RECENT SESSIONS (last 7):\n"
        let sessions = ProgressStore.shared.sessions.suffix(7)
        
        if sessions.isEmpty {
            context += "  (No sessions yet)\n\n"
            return context
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for session in sessions {
            let minutes = Int(session.duration / 60)
            let name = session.sessionName ?? "Focus Session"
            context += "  • \(name): \(minutes)min on \(dateFormatter.string(from: session.date))\n"
        }
        
        context += "\n"
        return context
    }
    
    private func buildSettingsContext() -> String {
        let progress = ProgressStore.shared
        let settings = AppSettings.shared
        let calendar = Calendar.autoupdatingCurrent
        
        var context = "CURRENT SETTINGS:\n"
        context += "  • Daily Goal: \(progress.dailyGoalMinutes) minutes\n"
        context += "  • Theme: \(settings.profileTheme.displayName)\n"
        context += "  • Sound: \(settings.soundEnabled ? "On" : "Off")\n"
        context += "  • Haptics: \(settings.hapticsEnabled ? "On" : "Off")\n"
        if let sound = settings.selectedFocusSound {
            context += "  • Focus Sound: \(sound.rawValue)\n"
        }
        context += "\n"
        
        // Progress stats
        context += "PROGRESS:\n"
        
        // Today's progress
        let todayMinutes = Int(progress.sessions.filter {
            calendar.isDateInToday($0.date)
        }.reduce(0) { $0 + $1.duration } / 60)
        context += "  • Today: \(todayMinutes)/\(progress.dailyGoalMinutes) minutes\n"
        
        // Streak
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
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
        context += "  • Current Streak: \(streak) days\n"
        
        // Total time
        let totalMinutes = Int(progress.sessions.reduce(0) { $0 + $1.duration } / 60)
        context += "  • Total Focus Time: \(totalMinutes) minutes\n"
        
        // Pro status
        context += "  • Pro Status: \(ProEntitlementManager.shared.isPro ? "Active" : "Free")\n"
        
        context += "\n"
        return context
    }
    
    private func buildRulesContext(now: Date, calendar: Calendar) -> String {
        let todayISO = formatDateISO(now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowISO = formatDateISO(tomorrow)
        
        return """
        
        === IMPORTANT RULES ===
        
        DATE HANDLING:
        • Today's date: \(todayISO)
        • Tomorrow's date: \(tomorrowISO)
        • When user says "today"/"tonight" → use \(todayISO)
        • When user says "tomorrow" → use \(tomorrowISO)
        • Date format for reminderDate: YYYY-MM-DDTHH:MM:SS (local time, no Z suffix)
        • Convert times: 7pm=19:00, 2pm=14:00, 9am=09:00
        
        EXAMPLES:
        • "dinner at 7pm" → reminderDate: "\(todayISO)T19:00:00"
        • "meeting tomorrow at 2pm" → reminderDate: "\(tomorrowISO)T14:00:00"
        • "call mom at 9am tomorrow" → reminderDate: "\(tomorrowISO)T09:00:00"
        
        RESPONSE STYLE:
        • Be conversational and warm, not robotic
        • When showing tasks, format them nicely with bullet points
        • Always acknowledge what you're doing ("Sure! Let me..." or "Got it!")
        • After actions, give brief helpful follow-ups
        • Use natural language, not technical jargon
        
        WHEN USER ASKS ABOUT TASKS:
        • List them clearly with times if set
        • Mention which are overdue
        • If no tasks, suggest creating one
        • Don't just say "use list_future_tasks" - actually call it and format the response
        
        WHEN USER NEEDS A BREAK:
        • Always call suggest_break function
        • The app will generate personalized break suggestions
        • Don't make up break suggestions - let the function handle it
        
        BEHAVIOR:
        • ALWAYS use function calls for actions - don't just describe what you would do
        • For task/preset operations, use the exact UUID from the context above
        • If user mentions ANY time (7pm, at 7, tonight at 7, etc.), ALWAYS include reminderDate
        • Duration is in SECONDS for presets, MINUTES for tasks
        • When greeting user or they say hi/hello, use show_welcome function
        
        """
    }
    
    // MARK: - Helpers
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatDateISO(_ date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 2026,
                      components.month ?? 1,
                      components.day ?? 1)
    }
    
    /// Invalidates the context cache (call when data changes)
    func invalidateCache() {
        cachedContext = nil
        cacheTimestamp = nil
        
        #if DEBUG
        print("[AIContextBuilder] Cache invalidated")
        #endif
    }
}
