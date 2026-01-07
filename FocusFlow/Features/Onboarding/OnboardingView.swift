//
//  OnboardingView.swift
//  FocusFlow
//
//  Main onboarding container with page navigation and controls.
//

import SwiftUI

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager.shared
    @State private var dragOffset: CGFloat = 0
    @ObservedObject private var authManager = AuthManagerV2.shared
    
    var body: some View {
        ZStack {
            // Dynamic background based on selected theme
            PremiumAppBackground(theme: manager.onboardingData.selectedTheme)
                .ignoresSafeArea()
            
            // Floating particles
            FloatingParticlesView(theme: manager.onboardingData.selectedTheme)
                .ignoresSafeArea()
                .opacity(0.6)
            
            VStack(spacing: 0) {
                // Skip button (top right)
                HStack {
                    Spacer()
                    
                    if manager.currentPage < manager.totalPages - 1 {
                        Button(action: {
                            manager.skipOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, DS.Spacing.lg)
                                .padding(.vertical, DS.Spacing.sm)
                        }
                        .buttonStyle(FFPressButtonStyle())
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.top, DS.Spacing.sm)
                
                // Page content
                TabView(selection: $manager.currentPage) {
                    // Page 0: Simple intro
                    OnboardingIntroPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(0)

                    // Page 1: Quick tour of pillars
                    OnboardingTourPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(1)

                    // Page 2: Quick preferences (goal, reminders, theme)
                    OnboardingQuickPrefsPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(2)

                    // Page 3: Notifications permission step
                    OnboardingNotificationPermissionPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(3)

                    // Page 4: Finish (recap + CTA + auth)
                    OnboardingFinishPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.currentPage)

            }
        }
    }
}

// MARK: - Floating Particles View

private struct FloatingParticlesView: View {
    let theme: AppTheme
    
    @State private var particles: [FloatingParticle] = []
    private let particleCount = 15
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size / 4)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                startAnimation(in: geo.size)
            }
            .onChange(of: theme) { _, _ in
                updateParticleColors()
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { i in
            FloatingParticle(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.1...0.3),
                color: [theme.accentPrimary, theme.accentSecondary, .white].randomElement()!.opacity(0.6)
            )
        }
    }
    
    private func updateParticleColors() {
        for i in particles.indices {
            particles[i].color = [theme.accentPrimary, theme.accentSecondary, .white].randomElement()!.opacity(0.6)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 3...6))) {
                    particles[i].position = CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    particles[i].opacity = Double.random(in: 0.1...0.3)
                }
            }
        }
    }
}

private struct FloatingParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
    var color: Color
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
