//
//  OnboardingFinishPage.swift
//  FocusFlow
//
//  Final onboarding page with recap and auth options
//

import SwiftUI

struct OnboardingFinishPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var isAnimated = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Spacing.xxl) {
                Spacer()
                    .frame(height: DS.Spacing.xl)
                
                // Success icon with particles
                ZStack {
                    // Particle ring
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(theme.accentPrimary.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: isAnimated ? cos(Double(index) * .pi / 4) * 60 : 0,
                                y: isAnimated ? sin(Double(index) * .pi / 4) * 60 : 0
                            )
                            .opacity(isAnimated ? 0 : 1)
                    }
                    
                    // Main icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: theme.accentPrimary.opacity(0.5), radius: 20, y: 10)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isAnimated ? 1.0 : 0.5)
                }
                .frame(height: 120)
                
                // Headline
                VStack(spacing: DS.Spacing.md) {
                    Text("You're all set!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(headlineText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
                
                // Recap chips
                RecapSection(manager: manager, theme: theme)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 20)
                
                // Primary CTA
                VStack(spacing: DS.Spacing.lg) {
                    Button {
                        Haptics.impact(.medium)
                        manager.completeOnboarding()
                    } label: {
                        HStack(spacing: DS.Spacing.md) {
                            Text(primaryCTAText)
                                .font(.system(size: 17, weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                        .shadow(color: theme.accentPrimary.opacity(0.4), radius: 16, y: 6)
                    }
                    .buttonStyle(FFPressButtonStyle())
                    
                    // Auth options (if not signed in)
                    if !AuthManagerV2.shared.state.isSignedIn {
                        AuthOptionsSection(theme: theme)
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .opacity(isAnimated ? 1 : 0)
                
                Spacer()
                    .frame(height: DS.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
    
    // Dynamic text based on intent
    private var headlineText: String {
        guard let intent = manager.onboardingData.selectedIntent else {
            return "FocusFlow is ready to help you accomplish more"
        }
        
        switch intent {
        case .deepFocus:
            return "Your distraction-free sanctuary awaits"
        case .smartTasks:
            return "Your intelligent task orchestrator is ready"
        case .aiPlanning:
            return "Your AI planning copilot is standing by"
        case .ambientStudy:
            return "Your ambient study haven is prepared"
        }
    }
    
    private var primaryCTAText: String {
        if AuthManagerV2.shared.state.isSignedIn {
            return "Start Focusing"
        } else if let intent = manager.onboardingData.selectedIntent {
            switch intent {
            case .deepFocus:
                return "Enter Deep Work"
            case .smartTasks:
                return "Organize My Tasks"
            case .aiPlanning:
                return "Plan My Day"
            case .ambientStudy:
                return "Start Studying"
            }
        } else {
            return "Start Focusing"
        }
    }
}

// MARK: - Recap Section

private struct RecapSection: View {
    @ObservedObject var manager: OnboardingManager
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("Here's what you chose")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: DS.Spacing.sm) {
                // Intent chip
                if let intent = manager.onboardingData.selectedIntent {
                    RecapChip(
                        icon: intent.icon,
                        label: intent.rawValue,
                        theme: theme
                    )
                }
                
                // Goal chip
                if manager.onboardingData.dailyGoalMinutes > 0 {
                    RecapChip(
                        icon: "target",
                        label: "\(manager.onboardingData.dailyGoalMinutes) min/day goal",
                        theme: theme
                    )
                }
                
                // Theme chip
                RecapChip(
                    icon: "paintbrush.fill",
                    label: manager.onboardingData.selectedTheme.displayName,
                    theme: theme
                )
                
                // Notifications chip
                let notificationsEnabled = manager.onboardingData.remindersEnabled
                let notificationsLabel = notificationsEnabled ? manager.onboardingData.notificationStyle.rawValue : "Notifications off"
                let notificationsIcon = notificationsEnabled ? manager.onboardingData.notificationStyle.icon : "bell.slash"
                RecapChip(
                    icon: notificationsIcon,
                    label: notificationsLabel,
                    theme: theme
                )
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
    }
}

private struct RecapChip: View {
    let icon: String
    let label: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.accentPrimary)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.regular))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                        .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                )
        )
    }
}

// MARK: - Auth Options Section

private struct AuthOptionsSection: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Divider with text
            HStack(spacing: DS.Spacing.md) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                Text("or sign in to sync")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            }
            
            // Auth buttons
            VStack(spacing: DS.Spacing.sm) {
                AuthButton(
                    icon: "applelogo",
                    title: "Continue with Apple",
                    theme: theme
                ) {
                    Task {
                        Haptics.impact(.light)
                        try? await AuthManagerV2.shared.signInWithApple()
                        OnboardingManager.shared.completeOnboarding()
                    }
                }
                
                AuthButton(
                    icon: "envelope.fill",
                    title: "Continue with Email",
                    theme: theme
                ) {
                    Haptics.impact(.light)
                    // Navigate to email sign in flow
                    // (Implementation depends on your auth flow architecture)
                }
            }
            
            Text("Sync across devices • Cloud backups • Pro features")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
}

private struct AuthButton: View {
    let icon: String
    let title: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .padding(.horizontal, DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.white.opacity(DS.Glass.regular))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        
        OnboardingFinishPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
