import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    // Called when your app becomes active (after coming back from Spotify, or from background)
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Whenever FocusFlow becomes active, quietly reconnect if we have a token.
        SpotifyManager.shared.connectIfNeeded()
    }

    // Called when app is about to go to background (home button, lock, switch apps)
    func applicationWillResignActive(_ application: UIApplication) {
        // Courtesy disconnect when going to background.
        SpotifyManager.shared.disconnect()
    }

    // Handle incoming URLs (Spotify auth redirect)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        // Handle Spotify auth redirect
        if url.absoluteString.hasPrefix(SpotifyConfig.redirectURI.absoluteString) {
            SpotifyManager.shared.handleOpenURL(url)
            return true
        }

        return false
    }
}
