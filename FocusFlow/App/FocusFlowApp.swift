import SwiftUI
import UserNotifications

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var pro = ProEntitlementManager()

    init() {
        // Restore auth session as early as possible
        AuthManager.shared.restoreSessionIfNeeded()

        // Extra safety: ensure foreground notifications can show banner/sound.
        // (AppDelegate also sets this, but this guarantees it even if lifecycle timing changes.)
        UNUserNotificationCenter.current().delegate = appDelegate
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
