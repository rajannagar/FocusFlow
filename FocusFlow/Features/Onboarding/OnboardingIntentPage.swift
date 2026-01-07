//
//  OnboardingIntentPage.swift
//  FocusFlow
//
//  Intent discovery - branches experience based on user needs
//

import SwiftUI

struct OnboardingIntentPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var cardsVisible: [Bool] = Array(repeating: false, count: 4)
    @State private var headerOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("What brings you to FocusFlow?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("We'll personalize your experience")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, DS.Spacing.huge)
            .padding(.horizontal, DS.Spacing.xxxl)
            .opacity(headerOpacity)
            
            Spacer()
                .frame(height: 40)
            
            // Intent grid (2x2)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.lg),
                    GridItem(.flexible(), spacing: DS.Spacing.lg)
                ],
                spacing: DS.Spacing.lg
            ) {
                ForEach(Array(OnboardingIntent.allCases.enumerated()), id: \.offset) { index, intent in
                    IntentCard(
                        intent: intent,
                        isSelected: manager.onboardingData.selectedIntent == intent,
                        theme: theme
                    ) {
                        selectIntent(intent)
                    }
                    .opacity(cardsVisible[index] ? 1 : 0)
                    .offset(y: cardsVisible[index] ? 0 : 20)
                }
            }
            .padding(.horizontal, DS.Spacing.xxl)
            
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Header fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            headerOpacity = 1.0
        }
        
        // Staggered card animation
        for i in 0..<4 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4 + Double(i) * 0.1)) {
                cardsVisible[i] = true
            }
        }
    }
    
    private func selectIntent(_ intent: OnboardingIntent) {
        manager.selectIntent(intent)
        
        // Auto-advance after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.nextPage()
        }
    }
}

// MARK: - Intent Card

private struct IntentCard: View {
    let intent: OnboardingIntent
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [theme.accentPrimary.opacity(0.2), theme.accentSecondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: intent.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isSelected ? theme.accentPrimary : .white.opacity(0.7))
                }
                
                // Text
                VStack(spacing: 6) {
                    Text(intent.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(intent.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, DS.Spacing.xl)
            .padding(.horizontal, DS.Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.12 : DS.Glass.regular))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                            .stroke(
                                isSelected ? theme.accentPrimary : Color.white.opacity(DS.Glass.borderSubtle),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.97 : 1.0))
            .shadow(
                color: isSelected ? theme.accentPrimary.opacity(0.3) : .clear,
                radius: 12,
                y: 6
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
        
        OnboardingIntentPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
