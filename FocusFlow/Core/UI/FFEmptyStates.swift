import SwiftUI

// MARK: - Empty & Error States
// Beautiful placeholders for empty content and error handling

// MARK: - FFEmptyState

struct FFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Animated icon
            ZStack {
                // Outer circle
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 140, height: 140)
                
                // Middle circle
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .offset(y: isAnimating ? -8 : 8)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            // Text content
            VStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            
            // Action button
            if let actionTitle, let action {
                FFSecondaryButton(
                    title: actionTitle,
                    icon: actionIcon,
                    action: action
                )
                .padding(.horizontal, DS.Spacing.huge)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Spacing.xl)
    }
}

// MARK: - FFErrorState

struct FFErrorState: View {
    let title: String
    let message: String
    var retryTitle: String = "Try Again"
    var retryAction: (() -> Void)? = nil
    
    @State private var isShaking = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Error icon with shake effect
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.orange)
            }
            .offset(x: isShaking ? -8 : 0)
            .animation(
                isShaking
                    ? .linear(duration: 0.06).repeatCount(5, autoreverses: true)
                    : .default,
                value: isShaking
            )
            .onAppear {
                // Initial shake
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShaking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShaking = false
                    }
                }
            }
            
            // Text content
            VStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            
            // Retry button
            if let retryAction {
                FFSecondaryButton(
                    title: retryTitle,
                    icon: "arrow.clockwise",
                    action: retryAction
                )
                .padding(.horizontal, DS.Spacing.huge)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Spacing.xl)
    }
}

// MARK: - FFNoConnectionState

struct FFNoConnectionState: View {
    var retryAction: (() -> Void)? = nil
    
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Animated wifi icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 120, height: 120)
                
                // Wave effect
                ForEach(0..<3, id: \.self) { index in
                    WifiWave(index: index, offset: waveOffset)
                }
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = 1
                }
            }
            
            VStack(spacing: DS.Spacing.sm) {
                Text("No Connection")
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Please check your internet connection and try again.")
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            
            if let retryAction {
                FFSecondaryButton(
                    title: "Retry",
                    icon: "arrow.clockwise",
                    action: retryAction
                )
                .padding(.horizontal, DS.Spacing.huge)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Spacing.xl)
    }
}

struct WifiWave: View {
    let index: Int
    let offset: CGFloat
    
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.1), lineWidth: 2)
            .frame(
                width: CGFloat(40 + index * 25),
                height: CGFloat(40 + index * 25)
            )
            .scaleEffect(1 + offset * 0.2)
            .opacity(1 - offset * 0.5)
    }
}

// MARK: - FFSearchEmptyState

struct FFSearchEmptyState: View {
    let searchTerm: String
    var clearAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(spacing: DS.Spacing.sm) {
                Text("No Results")
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("No results found for \"\(searchTerm)\"")
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            if let clearAction {
                FFTextButton(title: "Clear Search", icon: "xmark.circle", action: clearAction)
                    .padding(.top, DS.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Spacing.xl)
    }
}

// MARK: - Prebuilt Empty States

extension FFEmptyState {
    /// Empty tasks state
    static func noTasks(action: @escaping () -> Void) -> FFEmptyState {
        FFEmptyState(
            icon: "checklist",
            title: "No Tasks Yet",
            message: "Add your first task to start organizing your day.",
            actionTitle: "Add Task",
            actionIcon: "plus",
            action: action
        )
    }
    
    /// Empty sessions state
    static func noSessions(action: @escaping () -> Void) -> FFEmptyState {
        FFEmptyState(
            icon: "timer",
            title: "No Sessions Yet",
            message: "Start your first focus session to track your progress.",
            actionTitle: "Start Focus",
            actionIcon: "play.fill",
            action: action
        )
    }
    
    /// Empty notifications state
    static var noNotifications: FFEmptyState {
        FFEmptyState(
            icon: "bell.slash",
            title: "All Caught Up",
            message: "You have no new notifications."
        )
    }
    
    /// Empty chat state
    static func noMessages(action: @escaping () -> Void) -> FFEmptyState {
        FFEmptyState(
            icon: "bubble.left.and.bubble.right",
            title: "Start a Conversation",
            message: "Ask Flow anything about focus, productivity, or your goals.",
            actionTitle: "Say Hello",
            actionIcon: "hand.wave",
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TabView {
            FFEmptyState.noTasks {}
                .tabItem { Text("Tasks") }
            
            FFEmptyState.noSessions {}
                .tabItem { Text("Sessions") }
            
            FFErrorState(
                title: "Something Went Wrong",
                message: "We couldn't load your data. Please try again."
            ) {}
                .tabItem { Text("Error") }
            
            FFNoConnectionState {}
                .tabItem { Text("Offline") }
            
            FFSearchEmptyState(searchTerm: "meditation") {}
                .tabItem { Text("Search") }
        }
    }
}
