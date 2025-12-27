import SwiftUI

// ---------------------------------------------------------
// MARK: - Tab Selection
// ---------------------------------------------------------

enum AppTab: Int, Hashable {
    case focus = 0
    case tasks = 1
    case progress = 2
    case profile = 3
}

// ---------------------------------------------------------
// MARK: - Main Content View (Launch → Auth → App)
// ---------------------------------------------------------

struct ContentView: View {
    @State private var showLaunch = true
    @State private var selectedTab: AppTab = .focus
    @State private var navigateToJourney = false

    // Pro entitlement manager comes from the App root (single instance)
    @EnvironmentObject private var pro: ProEntitlementManager

    // Observe global auth state
    @ObservedObject private var authManager = AuthManager.shared

    // Password recovery manager (sheet presentation)
    @StateObject private var recovery = PasswordRecoveryManager.shared

    var body: some View {
        ZStack {

            // MARK: - Main App Layer
            Group {
                switch authManager.state {
                case .unknown:
                    Color.black.ignoresSafeArea()

                case .unauthenticated:
                    AuthLandingView()

                case .authenticated:
                    mainTabs
                }
            }
            .opacity(showLaunch ? 0 : 1)

            // MARK: - Launch Overlay
            if showLaunch {
                FocusFlowLaunchView()
                    .transition(.opacity)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.6), value: showLaunch)
        .onAppear {
            authManager.restoreSessionIfNeeded()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showLaunch = false
            }
        }
        // MARK: - Recovery Sheet
        .sheet(isPresented: $recovery.isPresenting) {
            if let token = recovery.recoveryAccessToken, !token.isEmpty {
                SetNewPasswordView(accessToken: token) {
                    recovery.clear()
                }
            } else {
                // Safety fallback
                VStack(spacing: 12) {
                    Text("Invalid recovery link.")
                        .font(.headline)
                    Button("Close") {
                        recovery.clear()
                    }
                }
                .padding()
            }
        }
        // MARK: - Notification Navigation Handler
        .onReceive(NotificationCenter.default.publisher(for: NotificationCenterManager.navigateToDestination)) { notification in
            guard let destination = notification.userInfo?["destination"] as? NotificationDestination else { return }
            
            handleNotificationNavigation(to: destination)
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(AppTab.focus)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(AppTab.tasks)

            ProgressViewV2()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(AppTab.progress)

            ProfileView(navigateToJourney: $navigateToJourney)
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(AppTab.profile)
        }
        // ✅ Keeps the whole app reacting to global sync events (session completed, task completed, etc.)
        .syncWithAppState()
    }
    
    // MARK: - Navigation Handler
    
    private func handleNotificationNavigation(to destination: NotificationDestination) {
        switch destination {
        case .journey:
            // Go to Profile tab, then trigger Journey navigation
            selectedTab = .profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigateToJourney = true
            }
            
        case .profile:
            selectedTab = .profile
            
        case .progress:
            selectedTab = .progress
            
        case .focus:
            selectedTab = .focus
            
        case .tasks:
            selectedTab = .tasks
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager())
}
