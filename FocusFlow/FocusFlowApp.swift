import SwiftUI

@main
struct FocusFlowApp: App {
    // Hook in our UIKit AppDelegate for Spotify + notifications / other lifecycle work
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Share AppSettings across the app
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                // Forward Spotify redirect URLs (OAuth callback)
                .onOpenURL { url in
                    SpotifyManager.shared.handleOpenURL(url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // When app becomes active, reconnect if we have a token
                SpotifyManager.shared.connectIfNeeded()

            case .background:
                // Only disconnect Spotify if we're NOT playing a focus track
                // and NOT previewing. This lets the timer stop Spotify in
                // the background when it finishes.
                if !SpotifyManager.shared.isPlayingFocusTrack &&
                    !SpotifyManager.shared.isPreviewing {
                    SpotifyManager.shared.disconnect()
                }

            case .inactive:
                // No special handling needed right now
                break

            @unknown default:
                break
            }
        }
    }
}
