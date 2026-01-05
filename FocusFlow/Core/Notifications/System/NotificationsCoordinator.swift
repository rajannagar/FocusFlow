import Foundation
import Combine
import UserNotifications

// =========================================================
// MARK: - NotificationsCoordinator
// =========================================================
// The single brain for all notification scheduling.
// reconcileAll() makes the system correct based on preferences + auth status.

@MainActor
final class NotificationsCoordinator: ObservableObject {
    static let shared = NotificationsCoordinator()
    
    // MARK: - Dependencies
    
    private let prefsStore = NotificationPreferencesStore.shared
    private let authService = NotificationAuthorizationService.shared
    private let legacyManager = FocusLocalNotificationManager.shared
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - State
    
    @Published private(set) var lastReconcileReason: String = ""
    @Published private(set) var lastReconcileDate: Date? = nil
    
    private init() {}
    
    // MARK: - The Main Function
    
    /// Makes all scheduled notifications match current preferences + auth status.
    /// Call this:
    /// - On app launch
    /// - When preferences change
    /// - When auth status changes
    /// - When returning from Settings app
    func reconcileAll(reason: String) async {
        print("🔔 reconcileAll(\(reason))")
        lastReconcileReason = reason
        lastReconcileDate = Date()
        
        // 1. Refresh auth status silently
        await authService.refreshStatus()
        
        let prefs = prefsStore.preferences
        let canSchedule = authService.isAuthorized
        
        // 2. If master disabled OR not authorized → cancel everything
        if !prefs.masterEnabled || !canSchedule {
            await cancelAll()
            print("🔔 reconcileAll: cancelled all (master=\(prefs.masterEnabled), authorized=\(canSchedule))")
            return
        }
        
        // 3. Reconcile each notification type
        await reconcileDailyReminder(prefs: prefs)
        await reconcileDailyNudges(prefs: prefs)
        await reconcileDailyRecap(prefs: prefs)
        await reconcileTaskReminders(prefs: prefs)
        
        // Session completion is handled separately (on-demand when timer starts)
        // We don't schedule it here, but we respect the preference when FocusView asks
        
        print("🔔 reconcileAll: complete")
    }
    
    /// Cancel all notifications (master off or unauthorized)
    func cancelAll() async {
        // Cancel all known notification types
        legacyManager.cancelDailyReminder()
        legacyManager.cancelDailyNudges()
        legacyManager.cancelSessionCompletionNotification()
        cancelDailyRecap()
        
        // Cancel all task reminders by removing anything with our prefix
        let requests = await center.pendingNotificationRequests()
        let taskIds = requests
            .map { $0.identifier }
            .filter { $0.hasPrefix(NotificationIDs.taskPrefix) }
        
        if !taskIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: taskIds)
            print("🔔 Cancelled \(taskIds.count) task reminders")
        }
        
        print("🔔 cancelAll: done")
    }
    
    // MARK: - Individual Reconcilers
    
    private func reconcileDailyReminder(prefs: NotificationPreferences) async {
        if prefs.dailyReminderEnabled {
            // Schedule using hour/minute integers directly (no Date extraction)
            legacyManager.applyDailyReminderSettings(
                enabled: true,
                hour: prefs.dailyReminderHour,
                minute: prefs.dailyReminderMinute
            )
        } else {
            legacyManager.cancelDailyReminder()
        }
    }
    
    private func reconcileDailyNudges(prefs: NotificationPreferences) async {
        if prefs.dailyNudgesEnabled {
            // For now, use legacy manager's hardcoded times
            // Later we can pass custom times
            legacyManager.scheduleDailyNudges()
        } else {
            legacyManager.cancelDailyNudges()
        }
    }
    
    private func reconcileTaskReminders(prefs: NotificationPreferences) async {
        if prefs.taskRemindersEnabled {
            // TaskReminderScheduler handles individual task scheduling
            // Just make sure it reschedules everything
            TaskReminderScheduler.shared.rescheduleAllNow()
        } else {
            // Cancel all task reminders
            let requests = await center.pendingNotificationRequests()
            let taskIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(NotificationIDs.taskPrefix) }
            
            if !taskIds.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: taskIds)
                print("🔔 Cancelled \(taskIds.count) task reminders (disabled)")
            }
        }
    }
    
    // MARK: - Session Completion (On-Demand)
    
    /// Call this when a focus session starts.
    /// Only schedules if preferences allow AND authorized.
    func scheduleSessionCompletionIfEnabled(afterSeconds seconds: Int, sessionName: String) {
        let prefs = prefsStore.preferences
        
        guard prefs.masterEnabled,
              prefs.sessionCompletionEnabled,
              authService.isAuthorized else {
            print("🔔 Session completion skipped (disabled or unauthorized)")
            return
        }
        
        legacyManager.scheduleSessionCompletionNotification(
            after: seconds,
            sessionName: sessionName
        )
    }
    
    /// Cancel session completion (e.g., user stops timer early)
    func cancelSessionCompletion() {
        legacyManager.cancelSessionCompletionNotification()
    }
    
    // MARK: - Daily Recap
    
    private func reconcileDailyRecap(prefs: NotificationPreferences) async {
        if prefs.dailyRecapEnabled {
            scheduleDailyRecap(hour: prefs.dailyRecapHour, minute: prefs.dailyRecapMinute)
        } else {
            cancelDailyRecap()
        }
    }
    
    /// Schedule daily recap notification for the specified time
    private func scheduleDailyRecap(hour: Int, minute: Int) {
        // Cancel existing first
        center.removePendingNotificationRequests(withIdentifiers: [NotificationIDs.dailyRecap])
        
        // Create content - generic message, actual content generated at delivery time isn't possible
        // So we use a motivational generic message
        let content = UNMutableNotificationContent()
        content.title = "Yesterday's Focus Recap 📊"
        content.body = "See how your day went and keep the momentum going!"
        content.sound = .default
        content.categoryIdentifier = NotificationIDs.categoryGeneral
        
        // Schedule for specified time daily
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIDs.dailyRecap,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("🔔 Daily recap scheduling failed: \(error)")
            } else {
                print("🔔 Daily recap scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    /// Cancel daily recap notification
    private func cancelDailyRecap() {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationIDs.dailyRecap])
        print("🔔 Daily recap cancelled")
    }
    
    // MARK: - Debug
    
    /// Print all pending notifications (for debugging)
    func debugDumpPending() async {
        let requests = await center.pendingNotificationRequests()
        print("🔔 === Pending Notifications (\(requests.count)) ===")
        for req in requests.sorted(by: { $0.identifier < $1.identifier }) {
            let triggerDesc: String
            if let calTrigger = req.trigger as? UNCalendarNotificationTrigger {
                triggerDesc = "calendar: \(calTrigger.dateComponents)"
            } else if let timeTrigger = req.trigger as? UNTimeIntervalNotificationTrigger {
                triggerDesc = "interval: \(timeTrigger.timeInterval)s"
            } else {
                triggerDesc = "\(String(describing: req.trigger))"
            }
            print("   • \(req.identifier) → \(triggerDesc)")
        }
        print("🔔 =====================================")
    }
}
