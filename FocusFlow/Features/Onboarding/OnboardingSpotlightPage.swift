//
//  OnboardingSpotlightPage.swift
//  FocusFlow
//
//  Showcase Pro features with interactive carousel
//

import SwiftUI

struct OnboardingSpotlightPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var currentIndex: Int = 0
    
    private let features: [ProFeature] = [
        ProFeature(
            icon: "sparkles",
            gradient: [Color(hex: "FF6B9D"), Color(hex: "FEC163")],
            title: "AI Focus Copilot",
            description: "GPT-4o powered assistant analyzes your goals, suggests optimal schedules, and adapts to your work patterns",
            benefits: ["Smart task breakdown", "Context-aware planning", "Daily insights"]
        ),
        ProFeature(
            icon: "arrow.triangle.2.circlepath",
            gradient: [Color(hex: "667EEA"), Color(hex: "764BA2")],
            title: "Cloud Sync",
            description: "Seamlessly sync tasks, sessions, and journey data across all your devices in real-time",
            benefits: ["iPhone + Mac sync", "Real-time updates", "Offline support"]
        ),
        ProFeature(
            icon: "chart.line.uptrend.xyaxis",
            gradient: [Color(hex: "12C2E9"), Color(hex: "C471ED")],
            title: "Journey Analytics",
            description: "Comprehensive productivity insights with weekly summaries, streak tracking, and performance trends",
            benefits: ["Weekly deep dive", "Streak milestones", "Category breakdown"]
        ),
        ProFeature(
            icon: "square.stack.3d.up",
            gradient: [Color(hex: "F093FB"), Color(hex: "F5576C")],
            title: "Widgets & Live Activities",
            description: "Lock Screen widgets and Dynamic Island integration keep your focus session visible at a glance",
            benefits: ["Lock Screen timer", "Dynamic Island", "Home Screen widgets"]
        ),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DS.Spacing.md) {
                HStack {
                    Spacer()
                    
                    // Pro badge
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text("Pro Features")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.xl)
                
                Text("Level up your focus")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureSpotlightCard(feature: feature, theme: theme)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 500)
            .padding(.vertical, DS.Spacing.xl)
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentIndex
                                ? Color.white
                                : Color.white.opacity(0.3)
                        )
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .padding(.bottom, DS.Spacing.lg)
            
            // Actions
            VStack(spacing: DS.Spacing.md) {
                Button {
                    Haptics.impact(.medium)
                    manager.nextPage()
                } label: {
                    Text("Continue")
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
                
                Button {
                    Haptics.impact(.light)
                    manager.nextPage()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.xxl)
        }
    }
}

// MARK: - Feature Model

private struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    let benefits: [String]
}

// MARK: - Spotlight Card

private struct FeatureSpotlightCard: View {
    let feature: ProFeature
    let theme: AppTheme
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: feature.gradient[0].opacity(0.5), radius: 20, y: 10)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isVisible)
            
            // Title & Description
            VStack(spacing: DS.Spacing.md) {
                Text(feature.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
            
            // Benefits list
            VStack(spacing: DS.Spacing.sm) {
                ForEach(Array(feature.benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitRow(text: benefit, theme: theme)
                        .opacity(isVisible ? 1 : 0)
                        .offset(x: isVisible ? 0 : -20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.3 + Double(index) * 0.1),
                            value: isVisible
                        )
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.thin))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
                )
        )
        .padding(.horizontal, DS.Spacing.lg)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

private struct BenefitRow: View {
    let text: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.accentPrimary)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        
        OnboardingSpotlightPage(theme: .ocean, manager: OnboardingManager.shared)
    }
}
