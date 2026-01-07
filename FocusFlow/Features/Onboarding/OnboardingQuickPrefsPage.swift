//
//  OnboardingQuickPrefsPage.swift
//  FocusFlow
//
//  Lightweight preference capture for goal, reminders, and theme.
//

import SwiftUI

struct OnboardingQuickPrefsPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    private let goalOptions: [Int] = [30, 60, 90]
    private let featuredThemes: [AppTheme] = [.ocean, .forest, .royal, .sunrise, .mint, .slate]
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
                .frame(height: DS.Spacing.sm)
            
            VStack(spacing: DS.Spacing.sm) {
                Text("Dial in your basics")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Pick a goal, keep reminders on, and choose a look you love.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            
            VStack(spacing: DS.Spacing.lg) {
                GoalSelector(goalOptions: goalOptions, selected: manager.onboardingData.dailyGoalMinutes) { minutes in
                    manager.selectGoal(minutes)
                }
                
                ReminderToggle(isOn: manager.onboardingData.remindersEnabled) { enabled in
                    manager.setRemindersEnabled(enabled)
                }
                
                ThemePicker(themes: featuredThemes, selected: manager.onboardingData.selectedTheme) { theme in
                    manager.selectTheme(theme)
                }
            }
            .padding(DS.Spacing.xl)
            .background(Color.white.opacity(DS.Glass.thin))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            
            Button {
                Haptics.impact(.medium)
                manager.nextPage()
            } label: {
                Text("Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .shadow(color: theme.accentPrimary.opacity(0.35), radius: 14, y: 6)
            }
            .buttonStyle(FFPressButtonStyle())
            .padding(.horizontal, DS.Spacing.xl)
            
            Spacer()
        }
    }
}

private struct GoalSelector: View {
    let goalOptions: [Int]
    let selected: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Daily goal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            HStack(spacing: DS.Spacing.sm) {
                ForEach(goalOptions, id: \.self) { minutes in
                    Button {
                        Haptics.impact(.light)
                        onSelect(minutes)
                    } label: {
                        Text("\(minutes) min")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selected == minutes ? .black : .white)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(
                                Group {
                                    if selected == minutes {
                                        LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    } else {
                                        Color.white.opacity(DS.Glass.regular)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    }
                    .buttonStyle(FFPressButtonStyle())
                }
            }
        }
    }
}

private struct ReminderToggle: View {
    let isOn: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Smart reminders")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOn ? "On" : "Off")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Stay on track with gentle nudges")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { newValue in
                        Haptics.impact(.light)
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(.white)
                .frame(width: 60)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(Color.white.opacity(DS.Glass.regular))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        }
    }
}

private struct ThemePicker: View {
    let themes: [AppTheme]
    let selected: AppTheme
    let onSelect: (AppTheme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Theme")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.md) {
                    ForEach(themes, id: \.self) { item in
                        Button {
                            Haptics.impact(.light)
                            onSelect(item)
                        } label: {
                            VStack(spacing: DS.Spacing.sm) {
                                LinearGradient(colors: [item.accentPrimary, item.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                                            .stroke(Color.white.opacity(selected == item ? 0.9 : DS.Glass.borderSubtle), lineWidth: selected == item ? 2 : 1)
                                    )
                                Text(item.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(FFPressButtonStyle())
                    }
                }
                .padding(.horizontal, DS.Spacing.sm)
            }
        }
    }
}

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        OnboardingQuickPrefsPage(theme: .ocean, manager: OnboardingManager.shared)
            .padding(.horizontal, DS.Spacing.xl)
    }
}
