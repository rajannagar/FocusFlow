//
//  OnboardingSetupStackPage.swift
//  FocusFlow
//
//  Card-based setup flow for personalization
//

import SwiftUI

struct OnboardingSetupStackPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var currentCardIndex: Int = 0
    @FocusState private var nameFieldFocused: Bool
    
    private let totalCards = 4
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalCards, id: \.self) { index in
                    Capsule()
                        .fill(
                            index <= currentCardIndex
                                ? theme.accentPrimary
                                : Color.white.opacity(0.2)
                        )
                        .frame(
                            width: index == currentCardIndex ? 32 : 8,
                            height: 4
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentCardIndex)
                }
            }
            .padding(.top, DS.Spacing.xl)
            
            // Card stack
            ZStack {
                switch currentCardIndex {
                case 0:
                    NameCard(
                        theme: theme,
                        manager: manager,
                        nameFieldFocused: $nameFieldFocused,
                        onNext: advanceCard
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case 1:
                    DailyGoalCard(
                        theme: theme,
                        manager: manager,
                        onNext: advanceCard
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case 2:
                    ThemeSelectionCard(
                        theme: theme,
                        manager: manager,
                        onNext: advanceCard
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case 3:
                    NotificationStyleCard(
                        theme: theme,
                        manager: manager,
                        onNext: advanceCard
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            
            Spacer()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            nameFieldFocused = false
        }
    }
    
    private func advanceCard() {
        if currentCardIndex < totalCards - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentCardIndex += 1
            }
            Haptics.impact(.light)
        } else {
            // Move to next onboarding page
            manager.nextPage()
        }
    }
}

// MARK: - Card 1: Name

private struct NameCard: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    @FocusState.Binding var nameFieldFocused: Bool
    let onNext: () -> Void
    
    var body: some View {
        SetupCard(theme: theme) {
            VStack(spacing: DS.Spacing.xxl) {
                // Header
                VStack(spacing: DS.Spacing.md) {
                    Text("What should we call you?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Optional, but makes it more personal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Name input
                TextField("Your name", text: $manager.onboardingData.displayName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(DS.Spacing.lg)
                    .background(Color.white.opacity(DS.Glass.regular))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                    )
                    .tint(theme.accentPrimary)
                    .focused($nameFieldFocused)
                
                // Action buttons
                VStack(spacing: DS.Spacing.md) {
                    OnboardingContinueButton(title: "Continue", theme: theme) {
                        nameFieldFocused = false
                        onNext()
                    }
                    
                    Button("Skip for now") {
                        nameFieldFocused = false
                        Haptics.impact(.light)
                        onNext()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Card 2: Daily Goal

private struct DailyGoalCard: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    let onNext: () -> Void
    
    private let goalOptions = [
        (minutes: 30, label: "Light", subtitle: "1 session"),
        (minutes: 60, label: "Balanced", subtitle: "2 sessions"),
        (minutes: 90, label: "Deep", subtitle: "3+ sessions"),
    ]
    
    var body: some View {
        SetupCard(theme: theme) {
            VStack(spacing: DS.Spacing.xxl) {
                // Header
                VStack(spacing: DS.Spacing.md) {
                    Text("How much focus time feels right?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Daily goal to work towards")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Goal options
                VStack(spacing: DS.Spacing.md) {
                    ForEach(goalOptions, id: \.minutes) { option in
                        GoalOptionButton(
                            minutes: option.minutes,
                            label: option.label,
                            subtitle: option.subtitle,
                            isSelected: manager.onboardingData.dailyGoalMinutes == option.minutes,
                            theme: theme
                        ) {
                            manager.selectGoal(option.minutes)
                        }
                    }
                }
                
                // Continue button
                OnboardingContinueButton(title: "Continue", theme: theme) {
                    onNext()
                }
            }
        }
    }
}

private struct GoalOptionButton: View {
    let minutes: Int
    let label: String
    let subtitle: String
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.lg) {
                // Left: Minutes
                VStack(spacing: 2) {
                    Text("\(minutes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? theme.accentPrimary : .white)
                    
                    Text("min/day")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 70)
                
                // Right: Label
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if label == "Balanced" {
                            Text("✨")
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.accentPrimary)
                }
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.12 : DS.Glass.regular))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(
                                isSelected ? theme.accentPrimary : Color.white.opacity(DS.Glass.borderSubtle),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - Card 3: Theme

private struct ThemeSelectionCard: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    let onNext: () -> Void
    
    var body: some View {
        SetupCard(theme: theme) {
            VStack(spacing: DS.Spacing.xxl) {
                // Header
                VStack(spacing: DS.Spacing.md) {
                    Text("Choose your atmosphere")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Changes background throughout app")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Theme grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.md), count: 5),
                    spacing: DS.Spacing.md
                ) {
                    ForEach(AppTheme.allCases) { appTheme in
                        ThemeOptionCircle(
                            theme: appTheme,
                            isSelected: manager.onboardingData.selectedTheme == appTheme,
                            currentTheme: theme
                        ) {
                            manager.selectTheme(appTheme)
                        }
                    }
                }
                
                // Continue button
                OnboardingContinueButton(title: "Continue", theme: theme) {
                    onNext()
                }
            }
        }
    }
}

private struct ThemeOptionCircle: View {
    let theme: AppTheme
    let isSelected: Bool
    let currentTheme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Theme gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(
                    color: isSelected ? theme.accentPrimary.opacity(0.5) : .clear,
                    radius: 8
                )
                
                Text(theme.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - Card 4: Notifications

private struct NotificationStyleCard: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    let onNext: () -> Void
    
    var body: some View {
        SetupCard(theme: theme) {
            VStack(spacing: DS.Spacing.xxl) {
                // Header
                VStack(spacing: DS.Spacing.md) {
                    Text("How should we nudge you?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("You can change this anytime")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Notification options
                VStack(spacing: DS.Spacing.md) {
                    ForEach(NotificationStyle.allCases) { style in
                        NotificationOptionButton(
                            style: style,
                            isSelected: manager.onboardingData.notificationStyle == style,
                            theme: theme
                        ) {
                            manager.setNotificationStyle(style)
                        }
                    }
                }
                
                // Continue button
                OnboardingContinueButton(title: "Continue", theme: theme) {
                    onNext()
                }
            }
        }
    }
}

private struct NotificationOptionButton: View {
    let style: NotificationStyle
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? theme.accentPrimary.opacity(0.15)
                                : Color.white.opacity(0.05)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: style.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? theme.accentPrimary : .white.opacity(0.6))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(style.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if style == .balanced {
                            Text("✨")
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(style.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.accentPrimary)
                }
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.12 : DS.Glass.regular))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(
                                isSelected ? theme.accentPrimary : Color.white.opacity(DS.Glass.borderSubtle),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - Card Container

private struct SetupCard<Content: View>: View {
    let theme: AppTheme
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            content()
                .padding(DS.Spacing.xxl)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.thin))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                        .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                )
        )
        .shadow(color: theme.accentPrimary.opacity(0.1), radius: 20, y: 10)
    }
}

// MARK: - Helper Button

private struct OnboardingContinueButton: View {
    let title: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        
        OnboardingSetupStackPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
