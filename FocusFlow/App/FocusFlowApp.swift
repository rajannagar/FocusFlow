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
        
        // ✅ Initialize notification preferences store (namespace-aware)
        _ = NotificationPreferencesStore.shared
        
        // ✅ Initialize in-app notifications bridge (listens to AppSyncManager events)
        _ = InAppNotificationsBridge.shared

        // Ensure UNUserNotificationCenter delegate is set (foreground behavior)
        UNUserNotificationCenter.current().delegate = appDelegate

        // ✅ Reconcile notifications on launch (no prompting, respects preferences)
        Task { @MainActor in
            // 🧹 Nuclear cleanup: remove ALL old notifications and start fresh
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            
            // Now reschedule only what we want
            await NotificationsCoordinator.shared.reconcileAll(reason: "launch")
            
            // ✅ Generate daily recap in-app notification if needed
            InAppNotificationsBridge.shared.generateDailyRecapIfNeeded()
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
