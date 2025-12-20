import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        // Ensure notifications are shown even while the app is in the foreground.
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // App came to foreground (unlocking phone, returning from home, etc).

        // ⬇️ IMPORTANT:
        // Do NOT consume the FocusSessionBridge here anymore,
        // otherwise we eat the update before FocusView can see it.

        // If you add analytics / refresh later, this is still a good hook.
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // App is about to move to the background.
        // Pause/save lightweight state here if needed.
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound even when the app is open.
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
