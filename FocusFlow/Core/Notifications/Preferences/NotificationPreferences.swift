import Foundation

// =========================================================
// MARK: - NotificationPreferences
// =========================================================
// All user-controllable notification settings in one place.
// This is the "what the user wants" model.

struct NotificationPreferences: Codable, Equatable {
    
    // MARK: - Master Toggle
    /// If false, all notifications are disabled and reconcileAll() cancels everything.
    var masterEnabled: Bool = true
    
    // MARK: - Session Completion
    /// Notify when a focus session ends (while app is in background)
    var sessionCompletionEnabled: Bool = true
    
    // MARK: - Daily Reminder (user-configurable time)
    /// Single daily reminder at a specific time
    var dailyReminderEnabled: Bool = false
    var dailyReminderHour: Int = 9
    var dailyReminderMinute: Int = 0
    
    // MARK: - Daily Nudges (3x per day motivational)
    /// Morning, afternoon, evening nudges
    var dailyNudgesEnabled: Bool = false
    
    // Individual nudge times (optional customization for later)
    var morningNudgeHour: Int = 9
    var morningNudgeMinute: Int = 0
    
    var afternoonNudgeHour: Int = 14
    var afternoonNudgeMinute: Int = 0
    
    var eveningNudgeHour: Int = 20
    var eveningNudgeMinute: Int = 0
    
    // MARK: - Task Reminders
    /// Enable/disable all task-based reminders
    var taskRemindersEnabled: Bool = true
    
    // MARK: - Daily Recap (Journey summary from yesterday)
    /// Send a recap notification in the morning about yesterday's progress
    var dailyRecapEnabled: Bool = true
    var dailyRecapHour: Int = 9
    var dailyRecapMinute: Int = 0
    
    // MARK: - Smart AI Nudges (Phase 5)
    /// Proactive AI-powered notifications based on behavior patterns
    var smartNudgesEnabled: Bool = true
    
    /// Individual smart nudge types
    var streakRiskNudgesEnabled: Bool = true       // "Your streak is at risk!"
    var goalProgressNudgesEnabled: Bool = true     // "Just 15 min to hit your goal!"
    var inactivityNudgesEnabled: Bool = false      // "Haven't seen you in a while" (opt-in)
    var achievementNudgesEnabled: Bool = true      // "New personal best!"
    
    // MARK: - Quiet Hours (Phase 5 - future)
    // var quietHoursEnabled: Bool = false
    // var quietHoursStart: Int = 22  // 10 PM
    // var quietHoursEnd: Int = 7     // 7 AM
    
    // MARK: - Helpers
    
    /// Convenience: daily reminder time as Date (today at that hour/minute)
    var dailyReminderTime: Date {
        get {
            makeTime(hour: dailyReminderHour, minute: dailyReminderMinute)
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyReminderHour = comps.hour ?? 9
            dailyReminderMinute = comps.minute ?? 0
        }
    }
    
    /// Convenience: daily recap time as Date (today at that hour/minute)
    var dailyRecapTime: Date {
        get {
            makeTime(hour: dailyRecapHour, minute: dailyRecapMinute)
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyRecapHour = comps.hour ?? 9
            dailyRecapMinute = comps.minute ?? 0
        }
    }
    
    private func makeTime(hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps) ?? now
    }
}

// MARK: - Default Instance

extension NotificationPreferences {
    /// Default preferences for new users
    static let `default` = NotificationPreferences()
}
