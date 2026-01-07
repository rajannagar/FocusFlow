//
//  OnboardingTourPage.swift
//  FocusFlow
//
//  Brief tour highlighting core pillars.
//

import SwiftUI

struct OnboardingTourPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    private let cards: [TourCard] = [
        .init(icon: "checklist", title: "Plan", subtitle: "Organize tasks, set a daily focus goal, and add AI help when needed."),
        .init(icon: "timer", title: "Focus", subtitle: "Start guided sessions with soundscapes and gentle reminders."),
        .init(icon: "chart.bar", title: "Progress", subtitle: "See streaks, time spent, and trends that keep you improving.")
    ]
    
    @State private var selection = 0
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DS.Spacing.sm) {
                Text("How FocusFlow works")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("A quick tour of the essentials")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
            
            TabView(selection: $selection) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    TourCardView(card: card, theme: theme)
                        .padding(.horizontal, DS.Spacing.xl)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 280)
            
            Button {
                Haptics.impact(.medium)
                manager.nextPage()
            } label: {
                Text(selection == cards.count - 1 ? "Next" : "Continue")
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
            
            Spacer()
        }
    }
}

private struct TourCard {
    let icon: String
    let title: String
    let subtitle: String
}

private struct TourCardView: View {
    let card: TourCard
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: card.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(card.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(card.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(DS.Glass.thin))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
    }
}

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        OnboardingTourPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
