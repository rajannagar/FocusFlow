import SwiftUI

// ---------------------------------------------------------
// MARK: - Main Content View (launch + auth + tabs)
// ---------------------------------------------------------

struct ContentView: View {
    @State private var showSplash = true

    // Observe global auth state
    @ObservedObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            // Main layer: either login screen or main app.
            Group {
                switch authManager.state {
                case .unknown:
                    // While we’re restoring session, keep a neutral background
                    Color.black.ignoresSafeArea()

                case .unauthenticated:
                    // New login screen that matches the app theme
                    AuthLandingView()

                case .authenticated:
                    // Your existing main tabs
                    mainTabs
                }
            }
            .opacity(showSplash ? 0 : 1)   // hidden while splash is visible

            // Intro: starts visible, then fades / slightly zooms out
            FocusBarLaunchView()
                .opacity(showSplash ? 1 : 0)
                .scaleEffect(showSplash ? 1.0 : 1.03)
        }
        .background(Color.black.ignoresSafeArea()) // safety net behind everything
        .animation(.easeInOut(duration: 0.7), value: showSplash)
        .onAppear {
            // 1) Try to restore a previous session (if user logged in before)
            authManager.restoreSessionIfNeeded()

            // 2) Let the intro play, then blend into auth / app
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                showSplash = false
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}


// ---------------------------------------------------------
// MARK: - FocusBarLaunchView
// Minimal, premium launch: logo + one subtitle
// ---------------------------------------------------------

struct FocusBarLaunchView: View {
    @ObservedObject private var appSettings = AppSettings.shared

    // Background + glow
    @State private var bgOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 0.85

    // Logo
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.94

    // Subtitle at bottom
    @State private var subtitleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 16

    var body: some View {
        let theme = appSettings.selectedTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            // Theme gradient background
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(bgOpacity)
            .ignoresSafeArea()

            // Soft centre glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            accentPrimary.opacity(0.75),
                            accentSecondary.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 45)

            VStack {
                Spacer()

                // LOGO / NAME (center)
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    Text("FocusFlow")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                Spacer()

                // One subtle subtitle at bottom
                Text("A calmer way to get serious work done.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            runAnimation()
        }
    }

    // MARK: - Animation

    private func runAnimation() {
        // Background fade
        withAnimation(.easeInOut(duration: 0.5)) {
            bgOpacity = 1.0
        }

        // Glow fade + gentle breathe
        withAnimation(.easeInOut(duration: 0.9).delay(0.1)) {
            glowOpacity = 1.0
            glowScale = 1.05
        }

        // Logo pop-in (scale + fade)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.25)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        // Subtitle from bottom
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
    }
}

