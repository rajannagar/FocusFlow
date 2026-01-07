//
//  OnboardingHeroPage.swift
//  FocusFlow
//
//  Premium hero moment for onboarding - establishes positioning
//

import SwiftUI

struct OnboardingHeroPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var cycleIndex: Int = 0
    
    // Auto-cycle through 3 themes for preview
    private let previewThemes: [AppTheme] = [.forest, .cyber, .ocean, .neon]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo + Headlines
            VStack(spacing: 32) {
                // Logo with shadow
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .shadow(
                        color: theme.accentPrimary.opacity(0.5),
                        radius: 30,
                        x: 0,
                        y: 10
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Headlines
                VStack(spacing: 16) {
                    Text("Your day, orchestrated.")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        FeaturePill(text: "AI planning", theme: theme)
                        FeaturePill(text: "Deep focus", theme: theme)
                        FeaturePill(text: "Sync everywhere", theme: theme)
                    }
                }
                .opacity(textOpacity)
            }
            
            Spacer()
            
            // CTA Button
            VStack(spacing: 16) {
                Button(action: {
                    Haptics.impact(.medium)
                    manager.nextPage()
                }) {
                    HStack(spacing: 12) {
                        Text("Begin")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
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
                    .shadow(
                        color: theme.accentPrimary.opacity(0.4),
                        radius: 16,
                        y: 8
                    )
                }
                .buttonStyle(FFPressButtonStyle())
                .opacity(buttonOpacity)
                
                // Micro-copy
                Text("Designed for iOS 26")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)
                    .opacity(buttonOpacity)
            }
            .padding(.horizontal, DS.Spacing.xxxl)
            .padding(.bottom, DS.Spacing.huge)
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Logo entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            textOpacity = 1.0
        }
        
        // Button fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            buttonOpacity = 1.0
        }
    }
}

// MARK: - Feature Pill

private struct FeaturePill: View {
    let text: String
    let theme: AppTheme
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(DS.Glass.thin))
                    .overlay(
                        Capsule()
                            .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: .forest)
            .ignoresSafeArea()
        
        OnboardingHeroPage(theme: .forest, manager: OnboardingManager.shared)
    }
}
