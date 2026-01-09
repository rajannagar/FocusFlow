import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Focus (Orb)
            WatchFocusView()
                .tag(0)
            
            // Tab 2: Presets
            WatchPresetsView()
                .tag(1)
            
            // Tab 3: Tasks
            WatchTasksView()
                .tag(2)
            
            // Tab 4: Progress
            WatchProgressView()
                .tag(3)
            
            // Tab 5: Profile
            WatchProfileView()
                .tag(4)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    MainTabView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchConnectivityManager.shared)
}
