//
//  OnboardingIntroPage.swift
//  FocusFlow
//
//  Simple welcome page highlighting core value.
//

import SwiftUI

struct OnboardingIntroPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DS.Spacing.md) {
                Text("Your day, orchestrated")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Plan with clarity, focus without friction, and see your progress across devices.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                FeatureRow(icon: "calendar", title: "Plan", subtitle: "Tasks, schedules, and AI help if you want it.")
                FeatureRow(icon: "timer", title: "Focus", subtitle: "Sessions with soundscapes and reminders.")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress", subtitle: "Streaks, insights, and sync everywhere.")
            }
            .padding(DS.Spacing.xl)
            .background(Color.white.opacity(DS.Glass.thin))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            
            Spacer()
            
            Button {
                Haptics.impact(.medium)
                manager.nextPage()
            } label: {
                Text("Continue")
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
        }
        .padding(.horizontal, DS.Spacing.xl)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        OnboardingIntroPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
