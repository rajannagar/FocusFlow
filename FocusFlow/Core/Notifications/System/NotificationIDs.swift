import Foundation

// =========================================================
// MARK: - NotificationIDs
// =========================================================
// Centralized notification identifiers.
// These match the existing prefixes in FocusLocalNotificationManager
// so cancellation works correctly during transition.

enum NotificationIDs {
    
    // MARK: - Session Completion
    static let sessionCompletion = "focusflow.sessionCompletion"
    
    // MARK: - Daily Nudges (3x per day)
    static let nudgeMorning = "focusflow.nudge.morning"
    static let nudgeAfternoon = "focusflow.nudge.afternoon"
    static let nudgeEvening = "focusflow.nudge.evening"
    
    static let allNudges = [nudgeMorning, nudgeAfternoon, nudgeEvening]
    
    // MARK: - Daily Reminder (user-configurable time)
    static let dailyReminder = "focusflow.dailyReminder"
    
    // MARK: - Daily Recap (Journey summary)
    static let dailyRecap = "focusflow.dailyRecap"
    
    // MARK: - Task Reminders
    static let taskPrefix = "focusflow.task."
    
    /// Returns all possible identifiers for a task (base + weekday variants)
    static func taskIdentifiers(for taskId: UUID) -> [String] {
        let base = taskPrefix + taskId.uuidString
        return [base] + (1...7).map { base + ".w\($0)" }
    }
    
    // MARK: - Categories (flat, not nested)
    static let categorySessionComplete = "focusflow.category.sessionComplete"
    static let categoryTaskReminder = "focusflow.category.taskReminder"
    static let categoryGeneral = "focusflow.category.general"
}
