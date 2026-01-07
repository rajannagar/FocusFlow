import Foundation

// MARK: - Flow Action

/// All actions that Flow AI can execute within the app
/// This is a comprehensive enum covering every app capability
enum FlowAction: Codable, Equatable {
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Task Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Create a new task (optionally recurring)
    case createTask(title: String, reminderDate: Date?, duration: TimeInterval?, repeatRule: FFTaskRepeatRule?)
    
    /// Update an existing task
    case updateTask(taskID: UUID, title: String?, reminderDate: Date?, duration: TimeInterval?)
    
    /// Delete a task
    case deleteTask(taskID: UUID)
    
    /// Toggle task completion status
    case toggleTaskCompletion(taskID: UUID)
    
    /// List all future/upcoming tasks
    case listFutureTasks
    
    /// List tasks for a specific period
    case listTasks(period: TaskPeriod)
    
    /// Create multiple tasks at once
    case bulkCreateTasks(tasks: [BulkTask])
    
    /// Reschedule all tasks from today to tomorrow
    case rescheduleToday
    
    /// Smart schedule - find optimal time for a task
    case smartScheduleTask(title: String, estimatedMinutes: Int)
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Preset Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Activate/select a preset
    case setPreset(presetID: UUID)
    
    /// Create a new preset
    case createPreset(name: String, durationSeconds: Int, soundID: String?)
    
    /// Update an existing preset
    case updatePreset(presetID: UUID, name: String?, durationSeconds: Int?)
    
    /// Delete a preset
    case deletePreset(presetID: UUID)
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Focus Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Start a focus session
    case startFocus(minutes: Int, presetID: UUID?, sessionName: String?)
    
    /// Pause the current focus session
    case pauseFocus
    
    /// Resume a paused focus session
    case resumeFocus
    
    /// End focus session early
    case endFocusEarly
    
    /// Extend current focus session
    case extendFocus(additionalMinutes: Int)
    
    /// Set intention/name for current session
    case setFocusIntention(text: String)
    
    /// Start focus specifically for a task
    case startFocusOnTask(taskID: UUID, minutes: Int?)
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Navigation Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Navigate to a specific tab
    case navigateToTab(tab: AppTabDestination)
    
    /// Open preset manager
    case openPresetManager
    
    /// Open settings
    case openSettings
    
    /// Open notification center
    case openNotificationCenter
    
    /// Show paywall
    case showPaywall(context: PaywallTrigger)
    
    /// Go back in navigation
    case goBack
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Settings Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Update a specific setting
    case updateSetting(setting: SettingKey, value: String)
    
    /// Toggle do not disturb
    case toggleDoNotDisturb(enabled: Bool)
    
    /// Update daily goal
    case updateDailyGoal(minutes: Int)
    
    /// Change app theme
    case changeTheme(themeName: String)
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Stats & Analytics Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Get stats for a period
    case getStats(period: StatsPeriod)
    
    /// Analyze focus sessions
    case analyzeSessions
    
    /// Compare weeks (this vs last)
    case compareWeeks
    
    /// Generate weekly report
    case generateWeeklyReport
    
    /// Identify productivity patterns
    case identifyPatterns
    
    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Smart/AI Actions
    // ═══════════════════════════════════════════════════════════════════
    
    /// Generate a daily plan
    case generateDailyPlan
    
    /// Suggest optimal focus time
    case suggestOptimalFocusTime
    
    /// Suggest a break
    case suggestBreak
    
    /// Provide motivation
    case motivate
    
    /// Show welcome message
    case showWelcome
    
    /// Celebrate an achievement
    case celebrateAchievement(type: AchievementType)
    
    /// Provide a personalized tip
    case provideTip
}

// MARK: - Supporting Types

enum TaskPeriod: String, Codable {
    case today
    case tomorrow
    case yesterday
    case thisWeek = "this_week"
    case nextWeek = "next_week"
    case upcoming
    case all
}

struct BulkTask: Codable, Equatable {
    let title: String
    let reminderDate: Date?
    let duration: TimeInterval?
}

enum AppTabDestination: String, Codable {
    case focus
    case tasks
    case progress
    case profile
    case flow  // AI tab
}

enum PaywallTrigger: String, Codable {
    case ai
    case preset
    case theme
    case stats
    case general
}

enum SettingKey: String, Codable {
    case dailyGoal
    case theme
    case soundEnabled
    case hapticsEnabled
    case focusSound
    case displayName
    case tagline
    case notificationsEnabled
}

enum StatsPeriod: String, Codable {
    case today
    case week
    case month
    case allTime = "alltime"
}

enum AchievementType: String, Codable {
    case dailyGoal
    case streak
    case milestone
    case firstSession
    case perfectWeek
}

// MARK: - FlowAction Codable

extension FlowAction {
    
    enum CodingKeys: String, CodingKey {
        case type
        case title, reminderDate, duration, taskID, repeatRule
        case period, tasks
        case presetID, name, durationSeconds, soundID
        case minutes, sessionName, additionalMinutes, text, estimatedMinutes
        case tab, context
        case setting, value, enabled, themeName
        case achievementType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        // Task Actions
        case "create_task", "createTask":
            let title = try container.decode(String.self, forKey: .title)
            let reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
            let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
            let repeatRuleStr = try container.decodeIfPresent(String.self, forKey: .repeatRule)
            let repeatRule = repeatRuleStr.flatMap { FFTaskRepeatRule(rawValue: $0) }
            self = .createTask(title: title, reminderDate: reminderDate, duration: duration, repeatRule: repeatRule)
            
        case "update_task", "updateTask":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            let title = try container.decodeIfPresent(String.self, forKey: .title)
            let reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
            let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
            self = .updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case "delete_task", "deleteTask":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            self = .deleteTask(taskID: taskID)
            
        case "toggle_task_completion", "toggleTaskCompletion":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            self = .toggleTaskCompletion(taskID: taskID)
            
        case "list_future_tasks", "listFutureTasks":
            self = .listFutureTasks
            
        case "list_tasks", "listTasks":
            let period = try container.decode(TaskPeriod.self, forKey: .period)
            self = .listTasks(period: period)
            
        case "bulk_create_tasks", "bulkCreateTasks":
            let tasks = try container.decode([BulkTask].self, forKey: .tasks)
            self = .bulkCreateTasks(tasks: tasks)
            
        case "reschedule_today", "rescheduleToday":
            self = .rescheduleToday
            
        case "smart_schedule_task", "smartScheduleTask":
            let title = try container.decode(String.self, forKey: .title)
            let estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
            self = .smartScheduleTask(title: title, estimatedMinutes: estimatedMinutes)
            
        // Preset Actions
        case "set_preset", "setPreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            self = .setPreset(presetID: presetID)
            
        case "create_preset", "createPreset":
            let name = try container.decode(String.self, forKey: .name)
            let durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
            let soundID = try container.decodeIfPresent(String.self, forKey: .soundID)
            self = .createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case "update_preset", "updatePreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            let name = try container.decodeIfPresent(String.self, forKey: .name)
            let durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            self = .updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case "delete_preset", "deletePreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            self = .deletePreset(presetID: presetID)
            
        // Focus Actions
        case "start_focus", "startFocus":
            let minutes = try container.decode(Int.self, forKey: .minutes)
            let presetID = try container.decodeIfPresent(UUID.self, forKey: .presetID)
            let sessionName = try container.decodeIfPresent(String.self, forKey: .sessionName)
            self = .startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
        case "pause_focus", "pauseFocus":
            self = .pauseFocus
            
        case "resume_focus", "resumeFocus":
            self = .resumeFocus
            
        case "end_focus_early", "endFocusEarly":
            self = .endFocusEarly
            
        case "extend_focus", "extendFocus":
            let additionalMinutes = try container.decode(Int.self, forKey: .additionalMinutes)
            self = .extendFocus(additionalMinutes: additionalMinutes)
            
        case "set_focus_intention", "setFocusIntention":
            let text = try container.decode(String.self, forKey: .text)
            self = .setFocusIntention(text: text)
            
        case "start_focus_on_task", "startFocusOnTask":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            let minutes = try container.decodeIfPresent(Int.self, forKey: .minutes)
            self = .startFocusOnTask(taskID: taskID, minutes: minutes)
            
        // Navigation Actions
        case "navigate_to_tab", "navigateToTab":
            let tab = try container.decode(AppTabDestination.self, forKey: .tab)
            self = .navigateToTab(tab: tab)
            
        case "open_preset_manager", "openPresetManager":
            self = .openPresetManager
            
        case "open_settings", "openSettings":
            self = .openSettings
            
        case "open_notification_center", "openNotificationCenter":
            self = .openNotificationCenter
            
        case "show_paywall", "showPaywall":
            let context = try container.decode(PaywallTrigger.self, forKey: .context)
            self = .showPaywall(context: context)
            
        case "go_back", "goBack":
            self = .goBack
            
        // Settings Actions
        case "update_setting", "updateSetting":
            let setting = try container.decode(SettingKey.self, forKey: .setting)
            let value = try container.decode(String.self, forKey: .value)
            self = .updateSetting(setting: setting, value: value)
            
        case "toggle_dnd", "toggleDoNotDisturb":
            let enabled = try container.decode(Bool.self, forKey: .enabled)
            self = .toggleDoNotDisturb(enabled: enabled)
            
        case "update_daily_goal", "updateDailyGoal":
            let minutes = try container.decode(Int.self, forKey: .minutes)
            self = .updateDailyGoal(minutes: minutes)
            
        case "change_theme", "changeTheme":
            let themeName = try container.decode(String.self, forKey: .themeName)
            self = .changeTheme(themeName: themeName)
            
        // Stats Actions
        case "get_stats", "getStats":
            let period = try container.decode(StatsPeriod.self, forKey: .period)
            self = .getStats(period: period)
            
        case "analyze_sessions", "analyzeSessions":
            self = .analyzeSessions
            
        case "compare_weeks", "compareWeeks":
            self = .compareWeeks
            
        case "generate_weekly_report", "generateWeeklyReport":
            self = .generateWeeklyReport
            
        case "identify_patterns", "identifyPatterns":
            self = .identifyPatterns
            
        // Smart Actions
        case "generate_daily_plan", "generateDailyPlan":
            self = .generateDailyPlan
            
        case "suggest_optimal_focus_time", "suggestOptimalFocusTime":
            self = .suggestOptimalFocusTime
            
        case "suggest_break", "suggestBreak":
            self = .suggestBreak
            
        case "motivate":
            self = .motivate
            
        case "show_welcome", "showWelcome":
            self = .showWelcome
            
        case "celebrate_achievement", "celebrateAchievement":
            let achievementType = try container.decode(AchievementType.self, forKey: .achievementType)
            self = .celebrateAchievement(type: achievementType)
            
        case "provide_tip", "provideTip":
            self = .provideTip
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown action type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .createTask(let title, let reminderDate, let duration, let repeatRule):
            try container.encode("create_task", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
            try container.encodeIfPresent(duration, forKey: .duration)
            try container.encodeIfPresent(repeatRule?.rawValue, forKey: .repeatRule)
            
        case .updateTask(let taskID, let title, let reminderDate, let duration):
            try container.encode("update_task", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
            try container.encodeIfPresent(title, forKey: .title)
            try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
            try container.encodeIfPresent(duration, forKey: .duration)
            
        case .deleteTask(let taskID):
            try container.encode("delete_task", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
            
        case .toggleTaskCompletion(let taskID):
            try container.encode("toggle_task_completion", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
            
        case .listFutureTasks:
            try container.encode("list_future_tasks", forKey: .type)
            
        case .listTasks(let period):
            try container.encode("list_tasks", forKey: .type)
            try container.encode(period, forKey: .period)
            
        case .bulkCreateTasks(let tasks):
            try container.encode("bulk_create_tasks", forKey: .type)
            try container.encode(tasks, forKey: .tasks)
            
        case .rescheduleToday:
            try container.encode("reschedule_today", forKey: .type)
            
        case .smartScheduleTask(let title, let estimatedMinutes):
            try container.encode("smart_schedule_task", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(estimatedMinutes, forKey: .estimatedMinutes)
            
        case .setPreset(let presetID):
            try container.encode("set_preset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
            
        case .createPreset(let name, let durationSeconds, let soundID):
            try container.encode("create_preset", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(durationSeconds, forKey: .durationSeconds)
            try container.encodeIfPresent(soundID, forKey: .soundID)
            
        case .updatePreset(let presetID, let name, let durationSeconds):
            try container.encode("update_preset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
            
        case .deletePreset(let presetID):
            try container.encode("delete_preset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
            
        case .startFocus(let minutes, let presetID, let sessionName):
            try container.encode("start_focus", forKey: .type)
            try container.encode(minutes, forKey: .minutes)
            try container.encodeIfPresent(presetID, forKey: .presetID)
            try container.encodeIfPresent(sessionName, forKey: .sessionName)
            
        case .pauseFocus:
            try container.encode("pause_focus", forKey: .type)
            
        case .resumeFocus:
            try container.encode("resume_focus", forKey: .type)
            
        case .endFocusEarly:
            try container.encode("end_focus_early", forKey: .type)
            
        case .extendFocus(let additionalMinutes):
            try container.encode("extend_focus", forKey: .type)
            try container.encode(additionalMinutes, forKey: .additionalMinutes)
            
        case .setFocusIntention(let text):
            try container.encode("set_focus_intention", forKey: .type)
            try container.encode(text, forKey: .text)
            
        case .startFocusOnTask(let taskID, let minutes):
            try container.encode("start_focus_on_task", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
            try container.encodeIfPresent(minutes, forKey: .minutes)
            
        case .navigateToTab(let tab):
            try container.encode("navigate_to_tab", forKey: .type)
            try container.encode(tab, forKey: .tab)
            
        case .openPresetManager:
            try container.encode("open_preset_manager", forKey: .type)
            
        case .openSettings:
            try container.encode("open_settings", forKey: .type)
            
        case .openNotificationCenter:
            try container.encode("open_notification_center", forKey: .type)
            
        case .showPaywall(let context):
            try container.encode("show_paywall", forKey: .type)
            try container.encode(context, forKey: .context)
            
        case .goBack:
            try container.encode("go_back", forKey: .type)
            
        case .updateSetting(let setting, let value):
            try container.encode("update_setting", forKey: .type)
            try container.encode(setting, forKey: .setting)
            try container.encode(value, forKey: .value)
            
        case .toggleDoNotDisturb(let enabled):
            try container.encode("toggle_dnd", forKey: .type)
            try container.encode(enabled, forKey: .enabled)
            
        case .updateDailyGoal(let minutes):
            try container.encode("update_daily_goal", forKey: .type)
            try container.encode(minutes, forKey: .minutes)
            
        case .changeTheme(let themeName):
            try container.encode("change_theme", forKey: .type)
            try container.encode(themeName, forKey: .themeName)
            
        case .getStats(let period):
            try container.encode("get_stats", forKey: .type)
            try container.encode(period, forKey: .period)
            
        case .analyzeSessions:
            try container.encode("analyze_sessions", forKey: .type)
            
        case .compareWeeks:
            try container.encode("compare_weeks", forKey: .type)
            
        case .generateWeeklyReport:
            try container.encode("generate_weekly_report", forKey: .type)
            
        case .identifyPatterns:
            try container.encode("identify_patterns", forKey: .type)
            
        case .generateDailyPlan:
            try container.encode("generate_daily_plan", forKey: .type)
            
        case .suggestOptimalFocusTime:
            try container.encode("suggest_optimal_focus_time", forKey: .type)
            
        case .suggestBreak:
            try container.encode("suggest_break", forKey: .type)
            
        case .motivate:
            try container.encode("motivate", forKey: .type)
            
        case .showWelcome:
            try container.encode("show_welcome", forKey: .type)
            
        case .celebrateAchievement(let type):
            try container.encode("celebrate_achievement", forKey: .type)
            try container.encode(type, forKey: .achievementType)
            
        case .provideTip:
            try container.encode("provide_tip", forKey: .type)
        }
    }
}

// MARK: - Action Display Info

extension FlowAction {
    
    /// Human-readable title for the action
    var displayTitle: String {
        switch self {
        case .createTask(let title, _, _, let repeatRule):
            let repeatStr = repeatRule != nil && repeatRule != .none ? " (\(repeatRule!.displayName))" : ""
            return "Create: \(title.prefix(25))\(title.count > 25 ? "..." : "")\(repeatStr)"
        case .updateTask:
            return "Update Task"
        case .deleteTask:
            return "Delete Task"
        case .toggleTaskCompletion:
            return "Toggle Complete"
        case .listFutureTasks:
            return "View Tasks"
        case .listTasks(let period):
            return "View \(period.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) Tasks"
        case .bulkCreateTasks(let tasks):
            return "Create \(tasks.count) Tasks"
        case .rescheduleToday:
            return "Reschedule to Tomorrow"
        case .smartScheduleTask(let title, _):
            return "Schedule: \(title.prefix(20))"
        case .setPreset:
            return "Use Preset"
        case .createPreset(let name, _, _):
            return "Create: \(name)"
        case .updatePreset:
            return "Update Preset"
        case .deletePreset:
            return "Delete Preset"
        case .startFocus(let minutes, _, _):
            return "Start \(minutes)m Focus"
        case .pauseFocus:
            return "Pause Focus"
        case .resumeFocus:
            return "Resume Focus"
        case .endFocusEarly:
            return "End Session"
        case .extendFocus(let minutes):
            return "Extend +\(minutes)m"
        case .setFocusIntention:
            return "Set Intention"
        case .startFocusOnTask:
            return "Focus on Task"
        case .navigateToTab(let tab):
            return "Go to \(tab.rawValue.capitalized)"
        case .openPresetManager:
            return "Open Presets"
        case .openSettings:
            return "Open Settings"
        case .openNotificationCenter:
            return "Open Notifications"
        case .showPaywall:
            return "View Pro"
        case .goBack:
            return "Go Back"
        case .updateSetting(let setting, _):
            return "Update \(setting.rawValue)"
        case .toggleDoNotDisturb(let enabled):
            return enabled ? "Enable DND" : "Disable DND"
        case .updateDailyGoal(let minutes):
            return "Set Goal: \(minutes)m"
        case .changeTheme(let name):
            return "Theme: \(name.capitalized)"
        case .getStats(let period):
            return "\(period.rawValue.capitalized) Stats"
        case .analyzeSessions:
            return "Analyze Sessions"
        case .compareWeeks:
            return "Compare Weeks"
        case .generateWeeklyReport:
            return "Weekly Report"
        case .identifyPatterns:
            return "Find Patterns"
        case .generateDailyPlan:
            return "Plan My Day"
        case .suggestOptimalFocusTime:
            return "Best Focus Time"
        case .suggestBreak:
            return "Break Time"
        case .motivate:
            return "Get Motivated"
        case .showWelcome:
            return "Welcome"
        case .celebrateAchievement:
            return "Celebrate!"
        case .provideTip:
            return "Pro Tip"
        }
    }
    
    /// SF Symbol icon for the action
    var icon: String {
        switch self {
        case .createTask:
            return "plus.circle.fill"
        case .updateTask:
            return "pencil.circle.fill"
        case .deleteTask:
            return "trash.circle.fill"
        case .toggleTaskCompletion:
            return "checkmark.circle.fill"
        case .listFutureTasks, .listTasks:
            return "list.bullet"
        case .bulkCreateTasks:
            return "plus.square.on.square"
        case .rescheduleToday:
            return "arrow.right.circle"
        case .smartScheduleTask:
            return "sparkles"
        case .setPreset:
            return "slider.horizontal.3"
        case .createPreset:
            return "plus.rectangle.fill"
        case .updatePreset:
            return "pencil"
        case .deletePreset:
            return "trash"
        case .startFocus:
            return "play.circle.fill"
        case .pauseFocus:
            return "pause.circle.fill"
        case .resumeFocus:
            return "play.fill"
        case .endFocusEarly:
            return "stop.circle.fill"
        case .extendFocus:
            return "plus.circle"
        case .setFocusIntention:
            return "text.quote"
        case .startFocusOnTask:
            return "target"
        case .navigateToTab:
            return "arrow.right.square"
        case .openPresetManager:
            return "slider.horizontal.3"
        case .openSettings:
            return "gearshape.fill"
        case .openNotificationCenter:
            return "bell.fill"
        case .showPaywall:
            return "star.fill"
        case .goBack:
            return "arrow.left"
        case .updateSetting:
            return "gearshape"
        case .toggleDoNotDisturb:
            return "moon.fill"
        case .updateDailyGoal:
            return "target"
        case .changeTheme:
            return "paintpalette.fill"
        case .getStats:
            return "chart.bar.fill"
        case .analyzeSessions:
            return "chart.xyaxis.line"
        case .compareWeeks:
            return "arrow.left.arrow.right"
        case .generateWeeklyReport:
            return "doc.text.fill"
        case .identifyPatterns:
            return "waveform.path.ecg"
        case .generateDailyPlan:
            return "calendar.badge.clock"
        case .suggestOptimalFocusTime:
            return "clock.badge.checkmark"
        case .suggestBreak:
            return "cup.and.saucer.fill"
        case .motivate:
            return "flame.fill"
        case .showWelcome:
            return "hand.wave.fill"
        case .celebrateAchievement:
            return "party.popper.fill"
        case .provideTip:
            return "lightbulb.fill"
        }
    }
}
