import Foundation
import UserNotifications

final class FocusLocalNotificationManager {
    static let shared = FocusLocalNotificationManager()

    private let center = UNUserNotificationCenter.current()

    // Scheduled session completion (background / killed)
    private let scheduledSessionNotificationId = "focusflow.sessionCompletion"

    // Immediate completion (foreground banner)
    private let immediateSessionNotificationId = "focusflow.sessionCompletion.immediate"

    // Repeating daily nudges (3x per day)
    private let dailyNudgeIds = [
        "focusflow.nudge.morning",
        "focusflow.nudge.afternoon",
        "focusflow.nudge.evening"
    ]

    // Single user-configurable daily reminder (Profile → Daily focus reminder)
    private let dailyReminderId = "focusflow.dailyReminder"

    // Per-habit reminder prefix
    private let habitReminderPrefix = "focusflow.habit."

    private init() {}

    // MARK: - Permission

    /// Ask for notification permission if not decided yet
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            if settings.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("🔔 Notification permission error: \(error)")
                    } else {
                        print("🔔 Notification permission granted: \(granted)")
                    }
                }
            }
        }
    }

    // MARK: - Session completion notifications

    /// Schedule a notification for session completion after `seconds` (works if app is backgrounded or terminated).
    func scheduleSessionCompletionNotification(after seconds: Int, sessionName: String) {
        guard seconds > 0 else { return }

        // Make sure we've requested permission at least once.
        requestAuthorizationIfNeeded()

        // ✅ Important: only cancel the scheduled one here.
        // (Do NOT cancel the immediate one, or it can race-cancel your foreground banner.)
        cancelScheduledSessionCompletionNotification()

        let content = UNMutableNotificationContent()
        content.title = "Session complete"
        content.body = "Your focus session ended: \(sessionName)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

        let request = UNNotificationRequest(
            identifier: scheduledSessionNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule session notification: \(error)")
            } else {
                print("🔔 Scheduled session notification in \(seconds)s")
            }
        }
    }

    /// Cancel ONLY the scheduled completion notification.
    func cancelScheduledSessionCompletionNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [scheduledSessionNotificationId])
        center.removeDeliveredNotifications(withIdentifiers: [scheduledSessionNotificationId])
    }

    /// Cancel ONLY the immediate completion notification.
    func cancelImmediateSessionCompletionNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [immediateSessionNotificationId])
        center.removeDeliveredNotifications(withIdentifiers: [immediateSessionNotificationId])
    }

    /// Cancel both scheduled + immediate completion notifications.
    func cancelSessionCompletionNotification() {
        cancelScheduledSessionCompletionNotification()
        cancelImmediateSessionCompletionNotification()
    }

    /// Deliver an immediate completion notification (useful when the app is in the foreground and we still
    /// want a banner/sound).
    func deliverImmediateSessionCompletionNotification(sessionName: String) {
        requestAuthorizationIfNeeded()

        // Replace any previous immediate notification.
        cancelImmediateSessionCompletionNotification()

        let content = UNMutableNotificationContent()
        content.title = "Session complete"
        content.body = "Your focus session ended: \(sessionName)"
        content.sound = .default

        // Fire quickly so it feels immediate, but not 0s (0 can be flaky on some devices).
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.35, repeats: false)

        let request = UNNotificationRequest(
            identifier: immediateSessionNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to deliver immediate session notification: \(error)")
            } else {
                print("🔔 Delivered immediate session notification")
            }
        }
    }

    // MARK: - Daily nudges (3× per day, repeating)

    /// Schedule three repeating daily nudges (morning, afternoon, evening).
    /// Safe to call multiple times – requests with same identifiers will be replaced.
    func scheduleDailyNudges() {
        center.removePendingNotificationRequests(withIdentifiers: dailyNudgeIds)

        // Morning – 9:00
        scheduleDailyNudge(
            id: dailyNudgeIds[0],
            hour: 9,
            minute: 0,
            title: "Set your focus for today",
            body: "Take 2 minutes to set your intention and start a FocusFlow session."
        )

        // Afternoon – 2:00 PM
        scheduleDailyNudge(
            id: dailyNudgeIds[1],
            hour: 14,
            minute: 0,
            title: "Midday check-in",
            body: "How’s your energy? A short focus block now can move something important forward."
        )

        // Evening – 8:00 PM
        scheduleDailyNudge(
            id: dailyNudgeIds[2],
            hour: 20,
            minute: 0,
            title: "Close the loop",
            body: "Wrap up the day with one last calm, focused session or review your stats in FocusFlow."
        )
    }

    /// Cancel all daily nudges (if you ever add a setting to turn them off)
    func cancelDailyNudges() {
        center.removePendingNotificationRequests(withIdentifiers: dailyNudgeIds)
        center.removeDeliveredNotifications(withIdentifiers: dailyNudgeIds)
    }

    // MARK: - User-configurable daily reminder (Profile setting)

    /// Apply the "Daily focus reminder" setting from the Profile screen.
    /// - enabled == true → schedule a repeating notification at the selected time
    /// - enabled == false → cancel that reminder
    func applyDailyReminderSettings(enabled: Bool, time: Date) {
        if enabled {
            requestAuthorizationIfNeeded()
            scheduleDailyReminder(at: time)
        } else {
            cancelDailyReminder()
        }
    }

    /// Schedule one repeating daily reminder at the given time of day.
    private func scheduleDailyReminder(at time: Date) {
        cancelDailyReminder()

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour ?? 9
        dateComponents.minute = comps.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Time to focus"
        content.body = "Take a moment to start your focus goal in FocusFlow."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule daily reminder: \(error)")
            } else {
                let h = dateComponents.hour ?? 0
                let m = dateComponents.minute ?? 0
                print("🔔 Scheduled daily reminder at \(h):\(String(format: "%02d", m))")
            }
        }
    }

    /// Cancel the user-configurable daily reminder only.
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
        center.removeDeliveredNotifications(withIdentifiers: [dailyReminderId])
    }

    // MARK: - Habit reminders (per-habit)

    /// Schedule a reminder for a specific habit with optional repeat.
    func scheduleHabitReminder(
        habitId: UUID,
        habitName: String,
        date: Date,
        repeatOption: HabitRepeat
    ) {
        requestAuthorizationIfNeeded()

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .weekday],
            from: date
        )

        let trigger: UNCalendarNotificationTrigger

        switch repeatOption {
        case .none:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        case .daily:
            dateComponents = DateComponents(hour: dateComponents.hour, minute: dateComponents.minute)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .weekly:
            dateComponents = DateComponents(hour: dateComponents.hour, minute: dateComponents.minute, weekday: dateComponents.weekday)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .monthly:
            dateComponents = DateComponents(day: dateComponents.day, hour: dateComponents.hour, minute: dateComponents.minute)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .yearly:
            dateComponents = DateComponents(month: dateComponents.month, day: dateComponents.day, hour: dateComponents.hour, minute: dateComponents.minute)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "It’s time for: \(habitName)"
        content.sound = .default

        let identifier = habitReminderPrefix + habitId.uuidString

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule habit reminder for \(habitName): \(error)")
            } else {
                print("🔔 Scheduled habit reminder for \(habitName) with id \(identifier)")
            }
        }
    }

    /// Cancel all pending reminders for a specific habit.
    func cancelHabitReminder(habitId: UUID) {
        let identifier = habitReminderPrefix + habitId.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    // MARK: - Internal helper for fixed nudges

    private func scheduleDailyNudge(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule daily nudge (\(id)): \(error)")
            } else {
                print("🔔 Scheduled daily nudge \(id) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}
