import SwiftUI
import WatchConnectivity

@main
struct FocusFlowWatchApp: App {
    
    @StateObject private var dataManager = WatchDataManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(connectivityManager)
        }
    }
}
