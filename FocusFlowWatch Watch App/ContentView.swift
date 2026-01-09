import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var showLaunch = true
    
    var body: some View {
        ZStack {
            if showLaunch {
                WatchLaunchView()
                    .transition(.opacity)
            } else {
                if dataManager.isPro {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    ProRequiredView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLaunch)
        .onAppear {
            // Show launch screen for 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showLaunch = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchConnectivityManager.shared)
}
