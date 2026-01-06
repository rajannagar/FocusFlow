import Foundation

/// Builds comprehensive context string from user data for AI prompts
@MainActor
final class AIContextBuilder {
    static let shared = AIContextBuilder()
    
    private var cachedContext: String?
    private var cacheTimestamp: Date?
    private let cacheLock = NSLock()
    
    private init() {}
    
    /// Builds rich context string from current user data
    func buildContext() -> String {
        // Check cache with lock
        cacheLock.lock()
        if let cached = cachedContext,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < AIConfig.contextCacheDuration {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let progressStore = ProgressStore.shared
        let appSettings = AppSettings.shared
        let tasksStore = TasksStore.shared
        let presetStore = FocusPresetStore.shared
        let isPro = ProEntitlementManager.shared.isPro
        
        var context = buildSystemPrompt()
        
        // ═══════════════════════════════════════════════════════════════════
        // USER PROFILE & PROGRESS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ USER PROFILE ═══\n"
        context += "• Name: \(appSettings.displayName)\n"
        context += "• Tagline: \(appSettings.tagline)\n"
        context += "• Pro Status: \(isPro ? "✓ Active" : "Not Active")\n"
        
        // Calculate XP and Level
        let totalXP = Int(progressStore.lifetimeFocusSeconds / 60) // 1 XP per minute
        let level = calculateLevel(fromXP: totalXP)
        let levelTitle = getLevelTitle(level: level)
        let currentLevelXP = xpForLevel(level)
        let nextLevelXP = xpForLevel(level + 1)
        let xpProgress = totalXP - currentLevelXP
        let xpNeeded = nextLevelXP - currentLevelXP
        
        context += "• Level: \(level) (\(levelTitle))\n"
        context += "• Total XP: \(totalXP) (need \(xpNeeded - xpProgress) more for level \(level + 1))\n"
        
        // ═══════════════════════════════════════════════════════════════════
        // FOCUS STATISTICS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ FOCUS STATISTICS ═══\n"
        
        // Today's progress
        let todayStart = calendar.startOfDay(for: now)
        let todaySessions = progressStore.sessions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let dailyGoal = progressStore.dailyGoalMinutes
        let goalProgress = dailyGoal > 0 ? min(100, (todayMinutes * 100) / dailyGoal) : 0
        
        context += "TODAY:\n"
        context += "  • Focus time: \(todayMinutes) minutes\n"
        context += "  • Sessions: \(todaySessions.count)\n"
        context += "  • Daily goal: \(dailyGoal) min (\(goalProgress)% complete)\n"
        if let longest = todaySessions.max(by: { $0.duration < $1.duration }) {
            context += "  • Longest session: \(Int(longest.duration / 60)) min\n"
        }
        
        // This week
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let weekSessions = progressStore.sessions.filter { $0.date >= weekStart }
        let weekMinutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        let weekHours = weekMinutes / 60
        let weekRemainingMins = weekMinutes % 60
        
        context += "THIS WEEK:\n"
        context += "  • Focus time: \(weekHours)h \(weekRemainingMins)m\n"
        context += "  • Sessions: \(weekSessions.count)\n"
        if weekSessions.count > 0 {
            context += "  • Average per session: \(weekMinutes / weekSessions.count) min\n"
        }
        
        // All-time stats
        let totalMinutes = Int(progressStore.lifetimeFocusSeconds / 60)
        let totalHours = totalMinutes / 60
        let totalSessions = progressStore.lifetimeSessionCount
        
        context += "ALL-TIME:\n"
        context += "  • Total focus time: \(totalHours) hours (\(totalMinutes) min)\n"
        context += "  • Total sessions: \(totalSessions)\n"
        if totalSessions > 0 {
            context += "  • Average session: \(totalMinutes / totalSessions) min\n"
        }
        
        // Streaks
        let currentStreak = calculateCurrentStreak(sessions: progressStore.sessions, calendar: calendar, now: now)
        let bestStreak = progressStore.lifetimeBestStreak
        context += "  • Current streak: \(currentStreak) days\n"
        context += "  • Best streak: \(bestStreak) days\n"
        
        // ═══════════════════════════════════════════════════════════════════
        // PRODUCTIVITY PATTERNS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ PRODUCTIVITY PATTERNS ═══\n"
        let patterns = analyzeProductivityPatterns(sessions: progressStore.sessions, calendar: calendar)
        context += patterns
        
        // ═══════════════════════════════════════════════════════════════════
        // BADGES & ACHIEVEMENTS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ ACHIEVEMENTS ═══\n"
        let badges = calculateEarnedBadges(progressStore: progressStore, tasksStore: tasksStore, calendar: calendar)
        if badges.isEmpty {
            context += "No badges earned yet. Keep focusing!\n"
        } else {
            context += "Earned badges: \(badges.joined(separator: ", "))\n"
        }
        
        // Next achievements
        let nextBadges = getNextAchievements(progressStore: progressStore, tasksStore: tasksStore, calendar: calendar)
        if !nextBadges.isEmpty {
            context += "Next achievements:\n"
            for badge in nextBadges.prefix(3) {
                context += "  • \(badge)\n"
            }
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // TASKS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ TASKS ═══\n"
        let allTasks = tasksStore.tasks
        
        // Today's tasks
        let todayTasks = allTasks.filter { task in
            if let reminder = task.reminderDate {
                return calendar.isDate(reminder, inSameDayAs: now)
            }
            return false
        }
        let completedToday = todayTasks.filter { tasksStore.isCompleted(taskId: $0.id, on: now, calendar: calendar) }
        
        context += "TODAY: \(completedToday.count)/\(todayTasks.count) completed\n"
        
        if !allTasks.isEmpty {
            context += "ALL TASKS (use IDs for modifications):\n"
            for task in allTasks.prefix(25) {
                let isCompleted = tasksStore.isCompleted(taskId: task.id, on: now, calendar: calendar)
                var taskLine = "  [\(task.id.uuidString)] "
                taskLine += isCompleted ? "✓ " : "○ "
                taskLine += task.title
                
                if let reminder = task.reminderDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    let when = reminder > now ? " (upcoming: \(formatter.string(from: reminder)))" : " (past: \(formatter.string(from: reminder)))"
                    taskLine += when
                }
                
                if task.durationMinutes > 0 {
                    taskLine += " [\(task.durationMinutes) min]"
                }
                
                if task.repeatRule != .none {
                    taskLine += " [repeats: \(task.repeatRule.rawValue)]"
                }
                
                context += taskLine + "\n"
            }
            
            if allTasks.count > 25 {
                context += "  ... and \(allTasks.count - 25) more tasks\n"
            }
        } else {
            context += "No tasks created yet.\n"
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // PRESETS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ FOCUS PRESETS ═══\n"
        let presets = presetStore.presets
        let activePreset = presetStore.activePreset
        
        if !presets.isEmpty {
            for preset in presets.prefix(15) {
                let isActive = activePreset?.id == preset.id
                let minutes = preset.durationSeconds / 60
                var presetLine = "  [\(preset.id.uuidString)] "
                presetLine += isActive ? "▶ " : "  "
                presetLine += "\(preset.emoji ?? "🎯") \(preset.name): \(minutes) min"
                
                if preset.soundID != "none" && !preset.soundID.isEmpty {
                    presetLine += " [sound: \(preset.soundID)]"
                }
                
                context += presetLine + "\n"
            }
        } else {
            context += "No presets created. Consider creating some!\n"
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // SETTINGS
        // ═══════════════════════════════════════════════════════════════════
        context += "\n═══ CURRENT SETTINGS ═══\n"
        context += "• Daily Goal: \(dailyGoal) minutes\n"
        context += "• Theme: \(appSettings.profileTheme.displayName) [\(appSettings.profileTheme.rawValue)]\n"
        context += "• Sound: \(appSettings.soundEnabled ? "On" : "Off")\n"
        context += "• Haptics: \(appSettings.hapticsEnabled ? "On" : "Off")\n"
        if let focusSound = appSettings.selectedFocusSound {
            context += "• Focus Sound: \(focusSound.displayName) [\(focusSound.rawValue)]\n"
        }
        if appSettings.dailyReminderEnabled {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            context += "• Daily Reminder: \(formatter.string(from: appSettings.dailyReminderTime))\n"
        }
        
        // Available themes
        context += "\nAVAILABLE THEMES: forest, neon, peach, cyber, ocean, sunrise, amber, mint, royal, slate\n"
        
        // Available sounds
        context += "AVAILABLE SOUNDS: angelsbymyside, fireplace, floatinggarden, hearty, light-rain-ambient, longnight, sound-ambience, street-market-gap-france, thelightbetweenus, underwater, yesterday\n"
        
        // ═══════════════════════════════════════════════════════════════════
        // DATE/TIME CONTEXT
        // ═══════════════════════════════════════════════════════════════════
        context += buildDateTimeContext(calendar: calendar, now: now)
        
        // ═══════════════════════════════════════════════════════════════════
        // AVAILABLE ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        context += buildActionsGuide()
        
        // Cache the context
        cacheLock.lock()
        cachedContext = context
        cacheTimestamp = Date()
        cacheLock.unlock()
        
        return context
    }
    
    // MARK: - System Prompt
    
    private func buildSystemPrompt() -> String {
        return """
        You are Focus AI, an advanced intelligent productivity assistant for FocusFlow - a premium focus timer and task management app.
        
        YOUR CORE MISSION:
        Help users achieve their goals through intelligent task management, insightful analytics, and personalized productivity strategies. Be proactive, accurate, and efficient in executing user requests.
        
        YOUR PERSONALITY:
        • Highly professional and intelligent - like an expert productivity consultant
        • Efficient and action-oriented - execute requests without unnecessary questions
        • Proactive with suggestions - anticipate user needs based on their patterns
        • Celebrate achievements authentically - recognize progress and milestones
        • Communicates clearly and directly - respects user time and attention
        • Learns from conversation - remember what was done and don't repeat actions
        
        YOUR ADVANCED CAPABILITIES:
        1. INTELLIGENT TASK MANAGEMENT
           - Create tasks with smart defaults (date, time, duration)
           - Batch create multiple tasks from plans or lists
           - Update existing tasks (title, reminders, duration)
           - Batch update multiple tasks
           - Delete tasks individually or in batches
           - Toggle task completion status
           - Understand natural language: "finish the report by 3pm tomorrow" = create task with reminder
        
        2. PRESET MANAGEMENT
           - Create focus presets with custom durations and sounds
           - Modify existing presets
           - Delete presets
           - Activate presets for immediate use
        
        3. FOCUS SESSIONS
           - Start focus sessions with specific durations
           - Use presets for quick session setup
           - Name sessions for tracking
        
        4. ANALYTICS & INSIGHTS
           - Analyze productivity patterns by time of day
           - Identify peak focus hours
           - Track streaks and milestones
           - Provide actionable recommendations
           - Compare performance across periods
        
        5. SETTINGS MANAGEMENT
           - Adjust theme, daily goal, sounds
           - Enable/disable notifications and haptics
           - Customize app behavior
        
        CRITICAL FORMATTING RULES:
        • NEVER use markdown syntax (no **, ###, -, •, or other markdown formatting)
        • Use plain text with natural line breaks for readability
        • Use numbered lists (1., 2., 3.) for sequences
        • Write in complete sentences with proper structure
        • Use emoji sparingly and naturally (✓, ✨, 📊, 🎯, 🔥)
        • Format data clearly: "Focus Time: 53 minutes (5 sessions)" NOT "**Focus Time:** 53 minutes"
        • Structure complex information with clear section breaks
        
        BATCH OPERATIONS - EXECUTE IMMEDIATELY:
        When user asks to create, update, or delete multiple items:
        
        BATCH CREATE:
        • Call create_task multiple times for all items
        • Do NOT ask for confirmation between tasks
        • Execute all creations in sequence
        • Confirm: "Created 5 tasks: [Name1], [Name2], [Name3], [Name4], [Name5] ✓"
        
        BATCH UPDATE:
        • Call update_task multiple times for all changes
        • Combine related updates
        • Execute without pausing for confirmation
        • Confirm: "Updated 3 tasks: [Name1], [Name2], [Name3] ✓"
        
        BATCH DELETE:
        • Call delete_task for each item to remove
        • Only delete if user explicitly confirms they want deletion
        • Confirm deletion with count
        • Confirm: "Deleted 2 tasks: [Name1], [Name2] ✓"
        
        BATCH TOGGLE:
        • Call toggle_task_completion for multiple tasks
        • Mark complete or incomplete as requested
        • Confirm all changes
        
        MULTI-STEP OPERATIONS:
        If user wants a complete workflow (e.g., plan day, create tasks, set preset):
        1. Understand the full request
        2. Ask clarifying questions ONLY if truly necessary
        3. Execute all steps in proper sequence
        4. Provide one summary at the end
        Example: "Plan my day" → Create tasks → Set daily goal → Suggest best focus time
        
        TASK AWARENESS:
        • Remember what tasks you've created in this conversation
        • Don't recreate tasks that already exist
        • When user says "create the rest", only create NEW items, not duplicates
        • Track state: "You already created [Task], creating the remaining 4"
        
        ERROR PREVENTION:
        • Validate task titles are not empty
        • Confirm dates make sense (don't schedule in the past)
        • Check for duplicate task names - suggest alternatives if found
        • Verify update targets exist before updating
        • Ask before major operations (delete multiple, modify all)
        
        SMART DEFAULTS:
        • No date mentioned → assume "today" or "tomorrow" based on context
        • No time mentioned → suggest optimal times based on user's patterns
        • No duration → suggest 25min (Pomodoro) or 50min (deep work)
        • Multiple tasks → space them with 5-15 min breaks
        
        RESPONSE STYLE GUIDE:
        For Simple Queries (2-4 sentences):
        "Created task 'Review Report' for tomorrow at 3:00 PM with 30 min duration. ✓"
        
        For Complex Operations (confirm all actions):
        "Created 6 tasks:
        1. Morning Focus (8:00 AM)
        2. Breakfast Break (8:30 AM)
        3. Gym Workout (9:00 AM)
        4. Mid-Morning Task (10:00 AM)
        5. Lunch (12:00 PM)
        6. Afternoon Focus (1:00 PM)
        
        All tasks set for tomorrow. Ready to crush it! 🎯"
        
        For Analysis/Insights (data-driven):
        "Your best focus hour is 8 AM (3 sessions, 144 minutes total). Tuesday is your most productive day with 285 total minutes. To maintain your streak, schedule deep work during these peak times."
        
        AVOID:
        • Asking permission for obvious operations ("Should I create this task?" - just do it)
        • Creating single tasks when user wants multiple (from a list or plan)
        • Repeating the same action twice
        • Markdown formatting in any form
        • Robotic responses ("I have processed your request")
        • Over-explaining simple actions
        
        ALWAYS:
        • Confirm what you did with specific details
        • Use action count in summaries (created X, updated Y, deleted Z)
        • Show item names in confirmations
        • Be encouraging but genuine
        • Respect the user's time
        
        """
    }
    
    // MARK: - Date/Time Context
    
    private func buildDateTimeContext(calendar: Calendar, now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowYear = calendar.component(.year, from: tomorrow)
        let tomorrowMonth = calendar.component(.month, from: tomorrow)
        let tomorrowDay = calendar.component(.day, from: tomorrow)
        
        let todayISO = String(format: "%04d-%02d-%02d", currentYear, currentMonth, currentDay)
        let tomorrowISO = String(format: "%04d-%02d-%02d", tomorrowYear, tomorrowMonth, tomorrowDay)
        
        return """
        
        ═══ DATE & TIME ═══
        Current: \(dateFormatter.string(from: now))
        TODAY: \(todayISO)
        TOMORROW: \(tomorrowISO)
        
        TIME PARSING (CRITICAL):
        • "today/tonight/this evening" → \(todayISO)
        • "tomorrow" → \(tomorrowISO)
        • Format: YYYY-MM-DDTHH:MM:SS (local time, no timezone)
        • 7pm = 19:00:00, 2pm = 14:00:00, 9am = 09:00:00
        • ALWAYS include reminderDate if user mentions ANY time
        
        EXAMPLES:
        • "dinner at 7pm" → reminderDate: '\(todayISO)T19:00:00'
        • "meeting tomorrow 2pm" → reminderDate: '\(tomorrowISO)T14:00:00'
        • "call mom at 6:30pm" → reminderDate: '\(todayISO)T18:30:00'
        
        """
    }
    
    // MARK: - Actions Guide
    
    private func buildActionsGuide() -> String {
        return """
        
        ═══ AVAILABLE ACTIONS ═══
        
        TASKS:
        • create_task: Create new task (title required, reminderDate/durationMinutes optional)
        • update_task: Modify task (taskID required, other fields optional)
        • delete_task: Remove task (taskID required)
        • toggle_task_completion: Mark complete/incomplete (taskID required)
        • list_future_tasks: Show upcoming tasks
        
        PRESETS:
        • create_preset: New preset (name, durationSeconds required; soundID optional)
        • update_preset: Modify preset (presetID required)
        • delete_preset: Remove preset (presetID required)
        • set_preset: Activate a preset (presetID required)
        
        SETTINGS:
        • update_setting: Change settings
          - dailyGoal: value in minutes (e.g., "60")
          - theme: theme name (e.g., "ocean", "neon", "cyber")
          - soundEnabled: "true" or "false"
          - hapticsEnabled: "true" or "false"
          - focusSound: sound ID (e.g., "light-rain-ambient")
          - displayName: user's name
        
        FOCUS:
        • start_focus: Begin focus session (minutes required, presetID/sessionName optional)
        
        STATS:
        • get_stats: Get statistics (period: 'today', 'week', 'month', 'alltime')
        
        RULES:
        • ALWAYS use functions for actions - don't just describe what you would do
        • Use task/preset IDs from context above
        • For dates, ALWAYS use local time format: YYYY-MM-DDTHH:MM:SS
        • Be proactive - if user says "I need to study" suggest creating a task or starting focus
        
        """
    }
    
    // MARK: - Productivity Analysis
    
    private func analyzeProductivityPatterns(sessions: [ProgressSession], calendar: Calendar) -> String {
        guard sessions.count >= 5 else {
            return "Not enough data yet for pattern analysis. Complete more sessions!\n"
        }
        
        var result = ""
        
        // Best hours
        var hourCounts: [Int: (count: Int, totalMinutes: Int)] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            let minutes = Int(session.duration / 60)
            let existing = hourCounts[hour] ?? (0, 0)
            hourCounts[hour] = (existing.count + 1, existing.totalMinutes + minutes)
        }
        
        if let bestHour = hourCounts.max(by: { $0.value.totalMinutes < $1.value.totalMinutes }) {
            let hourStr = bestHour.key < 12 ? "\(bestHour.key)am" : (bestHour.key == 12 ? "12pm" : "\(bestHour.key - 12)pm")
            result += "• Best focus hour: \(hourStr) (\(bestHour.value.count) sessions, \(bestHour.value.totalMinutes) min total)\n"
        }
        
        // Best days
        var dayCounts: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            let minutes = Int(session.duration / 60)
            dayCounts[weekday, default: 0] += minutes
        }
        
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        if let bestDay = dayCounts.max(by: { $0.value < $1.value }) {
            result += "• Most productive day: \(dayNames[bestDay.key]) (\(bestDay.value) min total)\n"
        }
        
        // Morning vs Evening
        let morningSessions = sessions.filter { calendar.component(.hour, from: $0.date) < 12 }
        let eveningSessions = sessions.filter { calendar.component(.hour, from: $0.date) >= 17 }
        let morningMinutes = Int(morningSessions.reduce(0) { $0 + $1.duration } / 60)
        let eveningMinutes = Int(eveningSessions.reduce(0) { $0 + $1.duration } / 60)
        
        if morningMinutes > eveningMinutes * 2 {
            result += "• You're a morning person! 🌅 Most focus before noon.\n"
        } else if eveningMinutes > morningMinutes * 2 {
            result += "• Night owl detected! 🦉 Most focus in evenings.\n"
        }
        
        // Average session length trend
        let recentSessions = sessions.suffix(10)
        let olderSessions = sessions.prefix(10)
        if recentSessions.count >= 5 && olderSessions.count >= 5 {
            let recentAvg = recentSessions.reduce(0) { $0 + $1.duration } / Double(recentSessions.count)
            let olderAvg = olderSessions.reduce(0) { $0 + $1.duration } / Double(olderSessions.count)
            if recentAvg > olderAvg * 1.2 {
                result += "• Session length trending UP! 📈 Great improvement.\n"
            }
        }
        
        return result
    }
    
    // MARK: - Badges
    
    private func calculateEarnedBadges(progressStore: ProgressStore, tasksStore: TasksStore, calendar: Calendar) -> [String] {
        var badges: [String] = []
        
        let totalMinutes = Int(progressStore.lifetimeFocusSeconds / 60)
        let totalHours = totalMinutes / 60
        let totalSessions = progressStore.lifetimeSessionCount
        let bestStreak = progressStore.lifetimeBestStreak
        
        // Focus time badges
        if totalMinutes >= 60 { badges.append("🕐 First Hour") }
        if totalHours >= 10 { badges.append("⏱️ Dedicated (10h)") }
        if totalHours >= 50 { badges.append("🏆 Committed (50h)") }
        if totalHours >= 100 { badges.append("👑 Centurion (100h)") }
        
        // Streak badges
        if bestStreak >= 3 { badges.append("🔥 Warming Up (3-day)") }
        if bestStreak >= 7 { badges.append("🔥🔥 On Fire (7-day)") }
        if bestStreak >= 30 { badges.append("🔥🔥🔥 Unstoppable (30-day)") }
        
        // Session badges
        if totalSessions >= 25 { badges.append("🎯 Getting Started (25)") }
        if totalSessions >= 100 { badges.append("⭐ Veteran (100)") }
        
        // Check for marathon (2+ hour session)
        if progressStore.sessions.contains(where: { $0.duration >= 7200 }) {
            badges.append("🏃 Marathon (2h session)")
        }
        
        // Task badges
        let completedTasks = tasksStore.completedOccurrenceKeys.count
        if completedTasks >= 10 { badges.append("✅ Task Starter (10)") }
        if completedTasks >= 50 { badges.append("✅✅ Task Master (50)") }
        if completedTasks >= 200 { badges.append("✅✅✅ Task Legend (200)") }
        
        return badges
    }
    
    private func getNextAchievements(progressStore: ProgressStore, tasksStore: TasksStore, calendar: Calendar) -> [String] {
        var next: [String] = []
        
        let totalMinutes = Int(progressStore.lifetimeFocusSeconds / 60)
        let totalHours = totalMinutes / 60
        let totalSessions = progressStore.lifetimeSessionCount
        let bestStreak = progressStore.lifetimeBestStreak
        let completedTasks = tasksStore.completedOccurrenceKeys.count
        
        // Next focus badge
        if totalMinutes < 60 {
            next.append("First Hour: \(60 - totalMinutes) min to go")
        } else if totalHours < 10 {
            next.append("Dedicated: \((10 - totalHours) * 60 - (totalMinutes % 60)) min to 10h")
        } else if totalHours < 50 {
            next.append("Committed: \(50 - totalHours) hours to 50h")
        } else if totalHours < 100 {
            next.append("Centurion: \(100 - totalHours) hours to 100h")
        }
        
        // Next streak badge
        if bestStreak < 3 {
            next.append("Warming Up: \(3 - bestStreak) more days for 3-day streak")
        } else if bestStreak < 7 {
            next.append("On Fire: \(7 - bestStreak) more days for 7-day streak")
        } else if bestStreak < 30 {
            next.append("Unstoppable: \(30 - bestStreak) more days for 30-day streak")
        }
        
        // Next session badge
        if totalSessions < 25 {
            next.append("Getting Started: \(25 - totalSessions) more sessions")
        } else if totalSessions < 100 {
            next.append("Veteran: \(100 - totalSessions) more sessions")
        }
        
        return next
    }
    
    // MARK: - Helpers
    
    private func calculateCurrentStreak(sessions: [ProgressSession], calendar: Calendar, now: Date) -> Int {
        var streak = 0
        var currentDate = calendar.startOfDay(for: now)
        
        for dayOffset in 0..<365 {
            let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate)!
            let hasSession = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            
            if hasSession {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLevel(fromXP xp: Int) -> Int {
        var level = 1
        while xpForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }
    
    private func xpForLevel(_ level: Int) -> Int {
        return Int(pow(Double(level), 2.2) * 50)
    }
    
    private func getLevelTitle(level: Int) -> String {
        switch level {
        case 1...4: return "Beginner"
        case 5...9: return "Apprentice"
        case 10...14: return "Focused"
        case 15...19: return "Dedicated"
        case 20...24: return "Committed"
        case 25...29: return "Expert"
        case 30...34: return "Master"
        case 35...39: return "Grandmaster"
        case 40...44: return "Legend"
        case 45...49: return "Mythic"
        default: return "Transcendent"
        }
    }
    
    /// Invalidates the context cache (call when data changes)
    func invalidateCache() {
        cacheLock.lock()
        cachedContext = nil
        cacheTimestamp = nil
        cacheLock.unlock()
    }
}

