import SwiftUI

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Restore any previously saved auth session (if the user has logged in before)
        AuthManager.shared.restoreSessionIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppSettings.shared)
        }
    }
}
