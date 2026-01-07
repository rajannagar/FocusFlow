//
//  OnboardingNotificationsPage.swift
//  FocusFlow
//
//  Requests notification permission with contextual education.
//

import SwiftUI
import UserNotifications

struct OnboardingNotificationPermissionPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var status: UNAuthorizationStatus? = nil
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
                .frame(height: DS.Spacing.sm)
            
            VStack(spacing: DS.Spacing.sm) {
                Text("Keep you on track")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Enable gentle reminders for sessions, goals, and daily nudges.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            
            VStack(spacing: DS.Spacing.md) {
                InfoRow(icon: "bell.badge", title: "Session reminders", subtitle: "Start and wrap-up nudges for focus sessions.")
                InfoRow(icon: "calendar", title: "Daily goal", subtitle: "One daily nudge to stay consistent.")
                InfoRow(icon: "sparkles", title: "Progress tips", subtitle: "Short, respectful insights only when helpful.")
            }
            .padding(DS.Spacing.xl)
            .background(Color.white.opacity(DS.Glass.thin))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            
            VStack(spacing: DS.Spacing.md) {
                Button {
                    requestPermission()
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .shadow(color: theme.accentPrimary.opacity(0.35), radius: 14, y: 6)
                }
                .disabled(isRequesting)
                .buttonStyle(FFPressButtonStyle())
                
                Button {
                    Haptics.impact(.light)
                    manager.setRemindersEnabled(false)
                    manager.nextPage()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.lg)
                }
                .buttonStyle(FFPressButtonStyle())
                
                if let status {
                    StatusBadge(status: status)
                        .padding(.top, DS.Spacing.sm)
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            
            Spacer()
        }
        .task {
            await fetchStatus()
        }
    }
    
    private var buttonTitle: String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return "Notifications enabled"
        case .denied:
            return "Enable in Settings"
        default:
            return "Enable notifications"
        }
    }
    
    private func fetchStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            status = settings.authorizationStatus
            manager.setRemindersEnabled(settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral)
        }
    }
    
    private func requestPermission() {
        guard isRequesting == false else { return }
        isRequesting = true
        Haptics.impact(.medium)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.status = granted ? .authorized : .denied
                manager.setRemindersEnabled(granted)
                self.isRequesting = false
                manager.nextPage()
            }
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
        }
    }
}

private struct StatusBadge: View {
    let status: UNAuthorizationStatus
    
    private var label: String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Denied"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }
    
    private var color: Color {
        switch status {
        case .authorized, .provisional, .ephemeral: return Color.green.opacity(0.85)
        case .denied: return Color.red.opacity(0.75)
        case .notDetermined: return Color.yellow.opacity(0.85)
        @unknown default: return Color.gray
        }
    }
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(Color.white.opacity(DS.Glass.regular))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }
}

#Preview {
    ZStack {
        PremiumAppBackground(theme: .ocean)
            .ignoresSafeArea()
        OnboardingNotificationPermissionPage(theme: .ocean, manager: OnboardingManager.shared)
            .padding(.horizontal, DS.Spacing.xl)
    }
}
