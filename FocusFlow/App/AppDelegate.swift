import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

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
}
