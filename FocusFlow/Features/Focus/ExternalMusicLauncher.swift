import UIKit

struct ExternalMusicLauncher {
    static func openSelectedApp(_ app: AppSettings.ExternalMusicApp?) {
        guard let app else { return }
        
        // Gate external music apps for Pro users only
        guard ProGatingHelper.shared.isPro else {
            #if DEBUG
            print("[ExternalMusicLauncher] 🔒 External music apps require Pro subscription")
            #endif
            // Post notification to show paywall
            NotificationCenter.default.post(
                name: Notification.Name("FocusFlow.showPaywall"),
                object: nil,
                userInfo: ["context": PaywallContext.externalMusic]
            )
            return
        }

        let scheme: String
        let appStoreURLString: String?

        switch app {
        case .spotify:
            scheme = "spotify://"
            appStoreURLString = "https://apps.apple.com/app/id324684580"
        case .appleMusic:
            scheme = "music://"
            appStoreURLString = nil   // system app
        case .youtubeMusic:
            scheme = "youtubemusic://"
            appStoreURLString = "https://apps.apple.com/app/id1017492454"
        }

        guard let schemeURL = URL(string: scheme) else { return }

        if UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL, options: [:], completionHandler: nil)
        } else if let storeString = appStoreURLString,
                  let storeURL = URL(string: storeString) {
            UIApplication.shared.open(storeURL, options: [:], completionHandler: nil)
        }
    }
}
