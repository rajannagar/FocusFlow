//
//  OnboardingView.swift
//  FocusFlow
//
//  Premium onboarding experience
//

import SwiftUI

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    var body: some View {
        ZStack {
            // Premium background
            PremiumAppBackground(theme: theme, particleCount: 10)
            
            // Welcome page glow - at root level so it's not clipped by TabView
            if manager.currentPage == 0 {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.25))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(y: -UIScreen.main.bounds.height * 0.15)
                    .transition(.opacity)
            }
            
            VStack(spacing: 0) {
                // Skip button (top right)
                HStack {
                    Spacer()
                    if manager.currentPage < manager.totalPages - 1 {
                        Button {
                            manager.skipOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 44)
                
                // Page content
                TabView(selection: $manager.currentPage) {
                    WelcomePage(theme: theme)
                        .tag(0)
                    
                    FeaturesPage(theme: theme)
                        .tag(1)
                    
                    FlowAIPage(theme: theme)
                        .tag(2)
                    
                    NotificationsPage(theme: theme, onContinue: { manager.nextPage() })
                        .tag(3)
                    
                    GetStartedPage(theme: theme)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom section: dots + button
                VStack(spacing: 24) {
                    // Page indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<manager.totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == manager.currentPage ? theme.accentPrimary : Color.white.opacity(0.3))
                                .frame(width: index == manager.currentPage ? 10 : 8, height: index == manager.currentPage ? 10 : 8)
                                .animation(.spring(response: 0.3), value: manager.currentPage)
                        }
                    }
                    
                    // Continue button (not shown on notifications page - it has its own, or last page)
                    if manager.currentPage != 3 && manager.currentPage != 4 {
                        Button {
                            manager.nextPage()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    let theme: AppTheme
    
    @State private var logoAppeared = false
    @State private var textAppeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo
            Image("Focusflow_Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .scaleEffect(logoAppeared ? 1 : 0.5)
                .opacity(logoAppeared ? 1 : 0)
                .padding(.bottom, 24)
            
            // App name
            Text("FocusFlow")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(logoAppeared ? 1 : 0)
                .padding(.bottom, 32)
            
            // Title
            Text("Your Mind Deserves\nFocus")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 20)
            
            // Subtitle
            Text("Beautiful focus sessions, smart tasks,\nand AI coaching to help you\ndo your best work.")
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 16)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 20)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                logoAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textAppeared = true
            }
        }
    }
}

// MARK: - Page 2: Features

private struct FeaturesPage: View {
    let theme: AppTheme
    
    @State private var appeared = false
    
    private let features: [(icon: String, title: String, description: String)] = [
        ("timer", "Focus Timer", "Beautiful countdown with ambient sounds & themes"),
        ("checkmark.circle.fill", "Smart Tasks", "Manage tasks with reminders and recurring schedules"),
        ("chart.bar.fill", "Track Progress", "Streaks, XP, levels, and detailed statistics")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Everything You Need")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        theme: theme
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.2), value: appeared)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(theme.accentPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Page 3: Flow AI

private struct FlowAIPage: View {
    let theme: AppTheme
    
    @State private var appeared = false
    @State private var typingText = ""
    private let fullText = "Start a 25 minute focus session"
    
    private let capabilities = [
        "Start sessions with voice",
        "Create tasks naturally",
        "Get productivity insights",
        "Personalized motivation"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Meet Flow, Your AI Coach")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 32)
            
            // Chat bubble preview
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // User message
                    Text(typingText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(theme.accentPrimary.opacity(0.8))
                        )
                        .opacity(appeared ? 1 : 0)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            
            // AI response
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Done! ⏱️ Started a 25-minute focus session. Let's crush it!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                Spacer()
            }
            .padding(.horizontal, 32)
            .opacity(appeared && typingText == fullText ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: typingText)
            
            // Capabilities list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(capabilities.enumerated()), id: \.offset) { index, capability in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.accentPrimary)
                        
                        Text(capability)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -20)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.1 + 0.8), value: appeared)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            
            // Pro badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Pro Feature")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(theme.accentPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.accentPrimary.opacity(0.15))
            )
            .padding(.top, 24)
            .opacity(appeared ? 1 : 0)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
            // Typing animation
            typeText()
        }
    }
    
    private func typeText() {
        typingText = ""
        for (index, char) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(index) * 0.03) {
                typingText += String(char)
            }
        }
    }
}

// MARK: - Page 4: Notifications

private struct NotificationsPage: View {
    let theme: AppTheme
    let onContinue: () -> Void
    
    @State private var appeared = false
    
    private let benefits = [
        ("target", "Daily focus reminders"),
        ("checkmark.circle", "Task due notifications"),
        ("flame.fill", "Streak protection alerts")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Bell icon
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(theme.accentPrimary)
            }
            .opacity(appeared ? 1 : 0)
            
            Text("Stay on Track")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
            
            Text("Get gentle reminders for:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
            
            // Benefits
            VStack(spacing: 12) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(theme.accentPrimary.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: benefit.0)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.accentPrimary)
                        }
                        
                        Text(benefit.1)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.1 + 0.3), value: appeared)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            Spacer()
            
            // Enable button
            Button {
                requestNotifications()
            } label: {
                Text("Enable Notifications")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            
            // Skip button
            Button {
                onContinue()
            } label: {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 12)
            .opacity(appeared ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
    
    private func requestNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                await MainActor.run {
                    if granted {
                        Haptics.notification(.success)
                    }
                    onContinue()
                }
            } catch {
                await MainActor.run {
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Page 5: Get Started / Pro

private struct GetStartedPage: View {
    let theme: AppTheme
    @ObservedObject private var manager = OnboardingManager.shared
    @ObservedObject private var pro = ProEntitlementManager.shared
    
    @State private var appeared = false
    @State private var showPaywall = false
    
    private let proFeatures = [
        ("sparkles", "Flow AI Assistant"),
        ("paintpalette.fill", "10 Premium Themes"),
        ("cloud.fill", "Cloud Sync"),
        ("chart.line.uptrend.xyaxis", "Advanced Stats"),
        ("infinity", "Unlimited Presets")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Pro badge - highlighted
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                Text("FocusFlow Pro")
                    .font(.system(size: 28, weight: .bold))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [theme.accentPrimary, theme.accentSecondary, theme.accentPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [theme.accentPrimary.opacity(0.6), theme.accentSecondary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: theme.accentPrimary.opacity(0.3), radius: 12, y: 4)
            .opacity(appeared ? 1 : 0)
            
            Text("Unlock Your Full Potential")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
            
            // Pro features list
            VStack(spacing: 12) {
                ForEach(Array(proFeatures.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.0)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.accentPrimary)
                            .frame(width: 24)
                        
                        Text(feature.1)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.accentPrimary.opacity(0.7))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -20)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.08 + 0.2), value: appeared)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.accentPrimary.opacity(0.5), theme.accentSecondary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            // Trial note
            Text("Free 3-day trial included")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
            
            Spacer()
            
            // Start trial button
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Start Free Trial")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            
            // Continue free button
            Button {
                manager.completeOnboarding()
            } label: {
                Text("Continue with Free")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            // After paywall closes, check if user became pro
            if pro.isPro {
                manager.completeOnboarding()
            }
        }) {
            PaywallView(context: .general)
                .environmentObject(pro)
        }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro {
                showPaywall = false
                manager.completeOnboarding()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
