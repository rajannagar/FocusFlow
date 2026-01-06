import Foundation
import Combine

/// Builds context string from user data for AI prompts
/// This context is sent to the Edge Function which passes it to OpenAI
@MainActor
final class AIContextBuilder {
    static let shared = AIContextBuilder()
    
    private var cachedContext: String?
    private var cacheTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Keep cache fresh when core data changes
        TasksStore.shared.$tasks
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        TasksStore.shared.$completedOccurrenceKeys
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        ProgressStore.shared.$sessions
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        ProgressStore.shared.$dailyGoalMinutes
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        FocusPresetStore.shared.$presets
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
    }
    
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
        let stats = computeFocusStats(now: now, calendar: calendar)
        
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
        context += "=== PROFILE & SETTINGS ===\n\n"
        context += buildProfileContext(firstName: firstName, stats: stats)
        
        context += "=== PROGRESS SNAPSHOT ===\n\n"
        context += buildProgressContext(stats: stats)
        
        // Tasks with completion status
        context += buildTasksContext(now: now, calendar: calendar)
        
        // Presets
        context += buildPresetsContext()
        
        // Recent Sessions
        context += buildSessionsContext()
        
        // Patterns & achievements
        context += buildPatternsContext(stats: stats)
        context += buildAchievementsContext(stats: stats)
        
        // MARK: - Capabilities Section
        context += """
        
        === WHAT YOU CAN DO ===
        
        TASKS:
        • create_task - Create new tasks with optional reminder time and duration
        • update_task - Modify existing tasks (use taskID from above)
        • delete_task - Remove tasks (use taskID from above)
        • toggle_task_completion - Mark tasks complete/incomplete
        • list_future_tasks - Show all upcoming tasks
        • list_tasks - Show tasks for a period: today, tomorrow, yesterday, this_week, next_week, upcoming, all
        
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
    
    private struct FocusStats {
        let todayMinutes: Int
        let todaySessions: Int
        let weekMinutes: Int
        let monthMinutes: Int
        let lifetimeMinutes: Int
        let lifetimeSessions: Int
        let bestStreak: Int
        let longestSessionMinutes: Int
        let bestHour: (hour: Int, minutes: Int)?
        let bestDay: (day: String, minutes: Int)?
        let tasksCompleted: Int
        let goalsHit: Int
        let morningSessions: Int
        let nightSessions: Int
        let dailyGoalMinutes: Int
        let isPro: Bool
    }
    
    private func computeFocusStats(now: Date, calendar: Calendar) -> FocusStats {
        let progress = ProgressStore.shared
        let sessions = progress.sessions
        let startOfToday = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Group minutes
        var todayMinutes = 0
        var todaySessions = 0
        var weekMinutes = 0
        var monthMinutes = 0
        var lifetimeMinutes = 0
        var longestSessionMinutes = 0
        var hourBuckets: [Int: Int] = [:]
        var dayBuckets: [Int: Int] = [:]
        var morningSessions = 0
        var nightSessions = 0
        
        for session in sessions {
            let minutes = Int(session.duration / 60)
            lifetimeMinutes += minutes
            longestSessionMinutes = max(longestSessionMinutes, minutes)
            
            if calendar.isDate(session.date, inSameDayAs: startOfToday) {
                todayMinutes += minutes
                todaySessions += 1
            }
            if session.date >= weekAgo { weekMinutes += minutes }
            if session.date >= monthAgo { monthMinutes += minutes }
            
            let hour = calendar.component(.hour, from: session.date)
            hourBuckets[hour, default: 0] += minutes
            
            let weekday = calendar.component(.weekday, from: session.date) // 1 = Sunday
            dayBuckets[weekday, default: 0] += minutes
            
            if hour < 8 { morningSessions += 1 }
            if hour >= 22 { nightSessions += 1 }
        }
        
        let bestHour = hourBuckets.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let bestDay = dayBuckets.max(by: { $0.value < $1.value }).map { (dayNames[($0.key - 1 + 7) % 7], $0.value) }
        
        // Goals hit (per day)
        var minutesPerDay: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            minutesPerDay[day, default: 0] += Int(session.duration / 60)
        }
        let goal = progress.dailyGoalMinutes
        let goalsHit = minutesPerDay.values.filter { $0 >= goal && goal > 0 }.count
        
        let tasksCompleted = TasksStore.shared.completedOccurrenceKeys.count
        
        return FocusStats(
            todayMinutes: todayMinutes,
            todaySessions: todaySessions,
            weekMinutes: weekMinutes,
            monthMinutes: monthMinutes,
            lifetimeMinutes: lifetimeMinutes,
            lifetimeSessions: sessions.count,
            bestStreak: progress.lifetimeBestStreak,
            longestSessionMinutes: longestSessionMinutes,
            bestHour: bestHour,
            bestDay: bestDay,
            tasksCompleted: tasksCompleted,
            goalsHit: goalsHit,
            morningSessions: morningSessions,
            nightSessions: nightSessions,
            dailyGoalMinutes: goal,
            isPro: ProEntitlementManager.shared.isPro
        )
    }
    
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
    
    private func buildProfileContext(firstName: String, stats: FocusStats) -> String {
        let settings = AppSettings.shared
        var context = ""
        context += "USER: \(firstName)\n"
        if !settings.tagline.isEmpty {
            context += "• Tagline: \(settings.tagline)\n"
        }
        context += "• Pro Status: \(stats.isPro ? "Active" : "Free")\n"
        context += "• Daily Goal: \(stats.dailyGoalMinutes) minutes\n"
        context += "• Theme: \(settings.profileTheme.displayName)\n"
        context += "• Sound: \(settings.soundEnabled ? "On" : "Off") | Haptics: \(settings.hapticsEnabled ? "On" : "Off")\n"
        if let sound = settings.selectedFocusSound {
            context += "• Focus Sound: \(sound.rawValue)\n"
        }
        context += "\n"
        return context
    }
    
    private func buildProgressContext(stats: FocusStats) -> String {
        var context = ""
        context += "TODAY: \(stats.todayMinutes) min across \(stats.todaySessions) sessions (goal \(stats.dailyGoalMinutes) min)\n"
        context += "THIS WEEK: \(stats.weekMinutes) min | THIS MONTH: \(stats.monthMinutes) min\n"
        context += "LIFETIME: \(stats.lifetimeMinutes) min across \(stats.lifetimeSessions) sessions\n"
        context += "BEST STREAK: \(stats.bestStreak) days | LONGEST SESSION: \(stats.longestSessionMinutes) min\n\n"
        return context
    }
    
    private func buildPatternsContext(stats: FocusStats) -> String {
        var context = "PATTERNS:\n"
        
        if let bestHour = stats.bestHour {
            context += "  • Peak hour: \(formatHourLabel(bestHour.hour)) (\(bestHour.minutes) min)\n"
        } else {
            context += "  • Peak hour: Not enough data yet\n"
        }
        
        if let bestDay = stats.bestDay {
            context += "  • Best day: \(bestDay.day) (\(bestDay.minutes) min)\n"
        }
        
        let morningVsNight: String
        if stats.morningSessions >= stats.nightSessions * 2 {
            morningVsNight = "Morning-focused (\(stats.morningSessions) morning vs \(stats.nightSessions) night sessions)"
        } else if stats.nightSessions >= stats.morningSessions * 2 {
            morningVsNight = "Night-focused (\(stats.nightSessions) night vs \(stats.morningSessions) morning sessions)"
        } else {
            morningVsNight = "Balanced (\(stats.morningSessions) morning vs \(stats.nightSessions) night sessions)"
        }
        context += "  • Chronotype: \(morningVsNight)\n"
        context += "  • Goals hit: \(stats.goalsHit) days\n\n"
        return context
    }
    
    private func buildAchievementsContext(stats: FocusStats) -> String {
        var context = "ACHIEVEMENTS & NEXT GOALS:\n"
        
        func nextTargets(current: Int, milestones: [Int]) -> String {
            guard let target = milestones.first(where: { current < $0 }) else {
                return "Max milestone reached"
            }
            return "\(target - current) to next milestone (\(target))"
        }
        
        // Focus time badges
        let focusMilestones = [60, 600, 3000, 6000] // minutes
        context += "  • Focus Time: \(stats.lifetimeMinutes) min (\(nextTargets(current: stats.lifetimeMinutes, milestones: focusMilestones)))\n"
        
        // Streak badges
        let streakMilestones = [3, 7, 30]
        context += "  • Streak: \(stats.bestStreak) days (\(nextTargets(current: stats.bestStreak, milestones: streakMilestones)))\n"
        
        // Session count badges
        let sessionMilestones = [25, 100]
        context += "  • Sessions: \(stats.lifetimeSessions) (\(nextTargets(current: stats.lifetimeSessions, milestones: sessionMilestones)))\n"
        
        // Task badges
        let taskMilestones = [10, 50, 200]
        context += "  • Tasks completed: \(stats.tasksCompleted) (\(nextTargets(current: stats.tasksCompleted, milestones: taskMilestones)))\n"
        
        // Goal crusher badge
        let goalMilestones = [10]
        context += "  • Goals hit: \(stats.goalsHit) (\(nextTargets(current: stats.goalsHit, milestones: goalMilestones)))\n\n"
        
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
        • Be concise, professional, friendly; skip filler
        • Answer only what the user asked for; do not add unrelated stats
        • Use short bullets when they improve clarity; otherwise plain sentences
        • Emojis are okay but sparing (0–2) and only if they fit naturally
        • After actions, briefly confirm what was done
        
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
    
    private func formatHourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour == 12 { return "12pm" }
        return hour < 12 ? "\(hour)am" : "\(hour - 12)pm"
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
