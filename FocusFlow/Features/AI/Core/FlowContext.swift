import Foundation
import Combine

// MARK: - Flow Context Builder

/// Builds rich context for Flow AI including user data, app state, and memory
@MainActor
final class FlowContext: ObservableObject {
    static let shared = FlowContext()
    
    // MARK: - Cache
    
    private var cachedContext: String?
    private var cacheTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Memory
    
    @Published private(set) var memory = FlowMemoryManager.shared.memory
    
    private init() {
        setupObservers()
        migrateLegacyMemoryIfNeeded()
        FlowMemoryManager.shared.$memory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                self?.memory = updated
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Build complete context for AI
    func buildContext() -> String {
        // Check cache validity
        if let cached = cachedContext,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < FlowConfig.contextCacheDuration {
            return cached
        }
        
        let context = buildContextInternal()
        cachedContext = context
        cacheTimestamp = Date()
        
        return context
    }
    
    /// Invalidate cached context (call after data changes)
    func invalidateCache() {
        cachedContext = nil
        cacheTimestamp = nil
    }
    
    /// Update memory with new insights
    func updateMemory(_ update: (inout FlowMemory) -> Void) {
        FlowMemoryManager.shared.updateMemory(update)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Invalidate cache when core data changes
        TasksStore.shared.$tasks
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        ProgressStore.shared.$sessions
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
        
        FocusPresetStore.shared.$presets
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateCache() }
            .store(in: &cancellables)
    }
    
    private func buildContextInternal() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        // User info
        let userName = AppSettings.shared.displayName ?? "there"
        let firstName = userName.components(separatedBy: " ").first ?? userName
        
        // Time context
        let hour = calendar.component(.hour, from: now)
        let timeOfDay = getTimeOfDay(hour: hour)
        let dayOfWeek = formatDayOfWeek(now)
        
        // Build context string
        var context = """
        You are Flow, the AI companion inside FocusFlow. You're a supportive friend who genuinely helps users achieve their goals.

        PERSONALITY:
        • Warm and encouraging, never cheesy
        • Concise - respect the user's time
        • Proactive - anticipate needs
        • Celebrate wins authentically
        • Use \(firstName)'s name naturally
        • Match their energy
        • Emojis: 1-2 max, only when natural

        RESPONSE RULES:
        • Lead with action when user wants something done
        • Keep explanations brief
        • For lists, prefer inline unless many items
        • NEVER lecture about productivity
        • NEVER make user feel guilty
        • NEVER say "I don't have access" - you DO via tools

        === CURRENT CONTEXT ===
        User: \(firstName)
        Time: \(formatDateTime(now)) (\(timeOfDay))
        Day: \(dayOfWeek)

        """
        
        // Add sections
        context += buildProfileSection()
        context += buildUserProfileSection() // Phase 7: Advanced profile
        context += buildProgressSection(now: now, calendar: calendar)
        context += FlowIntelligence.shared.buildIntelligenceContext()
        context += buildTasksSection(now: now, calendar: calendar)
        context += buildPresetsSection()
        context += buildRecentSessionsSection()
        context += buildMemorySection()
        context += buildCapabilitiesSection()
        
        return context
    }
    
    // MARK: - Context Sections
    
    /// Phase 7: Enhanced user profile with persona and preferences
    private func buildUserProfileSection() -> String {
        return FlowUserProfileManager.shared.buildProfileContext()
    }
    
    private func buildProfileSection() -> String {
        let settings = AppSettings.shared
        let progress = ProgressStore.shared
        
        return """

        === PROFILE ===
        Name: \(settings.displayName ?? "Not set")
        Theme: \(settings.profileTheme.displayName)
        Daily Goal: \(progress.dailyGoalMinutes) minutes
        Sound: \(settings.soundEnabled ? "On" : "Off")
        Haptics: \(settings.hapticsEnabled ? "On" : "Off")

        """
    }
    
    private func buildProgressSection(now: Date, calendar: Calendar) -> String {
        let progress = ProgressStore.shared
        let todaySessions = progress.sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let percentage = goalMinutes > 0 ? min(100, (todayMinutes * 100) / goalMinutes) : 0
        
        // Calculate streak
        let streak = calculateStreak(sessions: progress.sessions, calendar: calendar, now: now)
        
        // This week stats
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekSessions = progress.sessions.filter { $0.date >= weekStart }
        let weekMinutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        
        return """

        === TODAY'S PROGRESS ===
        Focused: \(todayMinutes) / \(goalMinutes) minutes (\(percentage)%)
        Sessions: \(todaySessions.count)
        Streak: \(streak) days
        This Week: \(weekMinutes) minutes (\(weekSessions.count) sessions)

        """
    }
    
    private func buildTasksSection(now: Date, calendar: Calendar) -> String {
        let store = TasksStore.shared
        let tasks = store.tasks
        
        guard !tasks.isEmpty else {
            return """

        === TASKS ===
        No tasks yet.

        """
        }
        
        var section = "\n=== TASKS ===\n"
        let today = calendar.startOfDay(for: now)
        
        // Today's tasks - use proper occurs(on:) method for recurring tasks
        let todayTasks = store.tasksVisible(on: today, calendar: calendar)
        
        if !todayTasks.isEmpty {
            section += "\nToday (\(todayTasks.count) tasks):\n"
            for task in todayTasks.prefix(10) {
                let isCompleted = store.isCompleted(taskId: task.id, on: today, calendar: calendar)
                let status = isCompleted ? "✓" : "○"
                let time = task.reminderDate.map { formatTime($0) } ?? ""
                let repeatInfo = task.repeatRule != .none ? " (repeats: \(task.repeatRule.displayName))" : ""
                section += "  \(status) \(task.title)\(time.isEmpty ? "" : " at \(time)")\(repeatInfo) [ID: \(task.id.uuidString)]\n"
            }
        }
        
        // Tomorrow's tasks
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            let tomorrowTasks = store.tasksVisible(on: tomorrow, calendar: calendar)
            
            if !tomorrowTasks.isEmpty {
                section += "\nTomorrow (\(tomorrowTasks.count) tasks):\n"
                for task in tomorrowTasks.prefix(5) {
                    let time = task.reminderDate.map { formatTime($0) } ?? ""
                    section += "  ○ \(task.title)\(time.isEmpty ? "" : " at \(time)") [ID: \(task.id.uuidString)]\n"
                }
            }
        }
        
        // Upcoming (next 7 days) - show non-repeating tasks only to avoid duplication
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
        let upcomingTasks = tasks.filter { task in
            guard let reminder = task.reminderDate, task.repeatRule == .none else { return false }
            return reminder > now && reminder <= weekFromNow && !task.occurs(on: today, calendar: calendar)
        }.sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
        
        if !upcomingTasks.isEmpty {
            section += "\nUpcoming (Next 7 days):\n"
            for task in upcomingTasks.prefix(5) {
                let date = task.reminderDate.map { formatShortDate($0) } ?? ""
                section += "  ○ \(task.title) — \(date) [ID: \(task.id.uuidString)]\n"
            }
        }
        
        // Tasks without dates (non-recurring)
        let undatedTasks = tasks.filter { $0.reminderDate == nil && $0.repeatRule == .none }
        if !undatedTasks.isEmpty {
            section += "\nNo Date Set:\n"
            for task in undatedTasks.prefix(5) {
                section += "  ○ \(task.title) [ID: \(task.id.uuidString)]\n"
            }
        }
        
        section += "\n"
        return section
    }
    
    private func buildPresetsSection() -> String {
        let presets = FocusPresetStore.shared.presets
        let activePreset = FocusPresetStore.shared.activePreset
        
        guard !presets.isEmpty else {
            return """

        === FOCUS PRESETS ===
        No presets. User can create custom focus presets.

        """
        }
        
        var section = "\n=== FOCUS PRESETS ===\n"
        
        for preset in presets {
            let isActive = preset.id == activePreset?.id ? " (ACTIVE)" : ""
            let duration = preset.durationSeconds / 60
            section += "  • \(preset.name) — \(duration) min [ID: \(preset.id.uuidString)]\(isActive)\n"
        }
        
        section += "\n"
        return section
    }
    
    private func buildRecentSessionsSection() -> String {
        let sessions = ProgressStore.shared.sessions
        let recentSessions = sessions.suffix(5).reversed()
        
        guard !recentSessions.isEmpty else {
            return """

        === RECENT SESSIONS ===
        No focus sessions yet.

        """
        }
        
        var section = "\n=== RECENT SESSIONS ===\n"
        
        for session in recentSessions {
            let date = formatShortDate(session.date)
            let duration = Int(session.duration / 60)
            let name = session.sessionName ?? "Focus"
            section += "  • \(date): \(name) (\(duration) min)\n"
        }
        
        section += "\n"
        return section
    }
    
    private func buildMemorySection() -> String {
        var section = "\n=== USER PATTERNS (Learned) ===\n"
        
        if let prefDuration = memory.preferredFocusDuration {
            section += "  • Preferred focus: \(prefDuration) minutes\n"
        }
        
        if !memory.peakProductivityHours.isEmpty {
            let hours = memory.peakProductivityHours.map { formatHour($0) }.joined(separator: ", ")
            section += "  • Peak hours: \(hours)\n"
        }
        
        if !memory.recentGoals.isEmpty {
            section += "  • Recent goals: \(memory.recentGoals.joined(separator: ", "))\n"
        }
        
        if let lastTip = memory.lastTipDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastTip, to: Date()).day ?? 0
            section += "  • Days since last tip: \(daysSince)\n"
        }
        
        section += "\n"
        return section
    }
    
    private func buildCapabilitiesSection() -> String {
        return """

        === CAPABILITIES ===

        TASKS: create_task, update_task, delete_task, toggle_task_completion, list_tasks, bulk_create_tasks, reschedule_today, smart_schedule_task

        PRESETS: set_preset, create_preset, update_preset, delete_preset

        FOCUS: start_focus, pause_focus, resume_focus, end_focus_early, extend_focus, set_focus_intention, start_focus_on_task

        NAVIGATION: navigate_to_tab (focus/tasks/progress/profile/flow), open_preset_manager, open_settings, open_notification_center

        SETTINGS: update_setting, toggle_dnd, update_daily_goal, change_theme
        - Themes: forest, neon, peach, cyber, ocean, sunrise, amber, mint, royal, slate

        STATS: get_stats (today/week/month/alltime), analyze_sessions, compare_weeks, generate_weekly_report, identify_patterns

        SMART: generate_daily_plan, suggest_optimal_focus_time, suggest_break, motivate, celebrate_achievement, provide_tip

        IMPORTANT:
        - Use taskID/presetID from the lists above (first 8 chars of UUID)
        - For times, use YYYY-MM-DDTHH:MM:SS format
        - Duration for tasks in seconds, focus in minutes
        - Today's date: \(formatDateTime(Date()))

        """
    }
    
    // MARK: - Helper Methods
    
    private func getTimeOfDay(hour: Int) -> String {
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(period)"
    }
    
    private func isTaskCompleted(_ task: FFTaskItem, completedKeys: Set<String>, calendar: Calendar) -> Bool {
        guard let reminder = task.reminderDate else { return false }
        let d = calendar.startOfDay(for: reminder)
        let comps = calendar.dateComponents([.year, .month, .day], from: d)
        let key = "\(task.id.uuidString)|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        return completedKeys.contains(key)
    }
    
    private func calculateStreak(sessions: [ProgressSession], calendar: Calendar, now: Date) -> Int {
        var streak = 0
        var checkDate = now
        
        // Check if there's a session today
        let hasTodaySession = sessions.contains { calendar.isDate($0.date, inSameDayAs: now) }
        if !hasTodaySession {
            // Start checking from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return 0 }
            checkDate = yesterday
        }
        
        for _ in 0..<365 { // Max 1 year streak
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
    
    // MARK: - Legacy Migration

    private func migrateLegacyMemoryIfNeeded() {
        let legacyKey = "flow_memory_v1"
        guard let data = UserDefaults.standard.data(forKey: legacyKey) else { return }
        if let legacy = try? JSONDecoder().decode(FlowMemory.self, from: data) {
            FlowMemoryManager.shared.updateMemory { $0 = legacy }
            UserDefaults.standard.removeObject(forKey: legacyKey)
        }
    }
}
