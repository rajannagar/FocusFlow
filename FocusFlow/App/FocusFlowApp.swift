import SwiftUI
import UserNotifications

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var pro = ProEntitlementManager()

    init() {
        // Restore auth session as early as possible
        AuthManager.shared.restoreSessionIfNeeded()

        // ✅ Keep these alive early so they observe and broadcast app-wide updates
        _ = AppSyncManager.shared
        _ = JourneyManager.shared

        // ✅ Ensure task reminders are scheduled even if Tasks tab is never opened.
        _ = TaskReminderScheduler.shared

        // Ensure UNUserNotificationCenter delegate is set (foreground behavior)
        UNUserNotificationCenter.current().delegate = appDelegate

        // ✅ Premium notification bootstrap:
        FocusLocalNotificationManager.shared.requestAuthorizationIfNeeded { auth in
            // Only schedule repeating things if allowed (authorized/provisional)
            switch auth {
            case .authorized, .provisional:
                FocusLocalNotificationManager.shared.scheduleDailyNudges()

                // Apply user-configured daily reminder from saved AppSettings
                let settings = AppSettings.shared
                FocusLocalNotificationManager.shared.applyDailyReminderSettings(
                    enabled: settings.dailyReminderEnabled,
                    time: settings.dailyReminderTime
                )

            case .denied, .notDetermined, .unknown:
                // Do nothing – user can enable later in settings.
                break
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppSettings.shared)
                .environmentObject(pro)
                // ✅ Catch password recovery deep links here (works anywhere in app)
                .onOpenURL { url in
                    PasswordRecoveryManager.shared.handle(url: url)
                }
        }
    }
}
