import SwiftUI
import UserNotifications

// =========================================================
// MARK: - NotificationSettingsView
// =========================================================
// Premium notification settings screen with full user control.
// Matches the app's dark glass aesthetic.

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var prefsStore = NotificationPreferencesStore.shared
    @ObservedObject private var authService = NotificationAuthorizationService.shared
    
    @State private var showingTestSent = false
    
    private var theme: AppTheme { appSettings.profileTheme }
    private var prefs: NotificationPreferences { prefsStore.preferences }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        theme.accentPrimary.opacity(0.08),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle radial glow
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(0.12),
                        theme.accentSecondary.opacity(0.04),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with gradient icon
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [theme.accentPrimary, theme.accentSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Notifications")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    
                    // Permission banner (if denied)
                    if authService.isDenied {
                        permissionDeniedBanner
                    }
                    
                    // Master toggle
                    masterToggleSection
                    
                    if prefs.masterEnabled && authService.isAuthorized {
                        // Session notifications
                        sessionSection
                        
                        // Daily reminders
                        dailyReminderSection
                        
                        // Daily nudges
                        dailyNudgesSection
                        
                        // Smart AI Nudges (Phase 5)
                        smartNudgesSection
                        
                        // Daily recap (Journey)
                        dailyRecapSection
                        
                        // Task reminders
                        taskRemindersSection
                        
                        // Test notification
                        testNotificationSection
                        
                        // Debug (dev only - can remove in production)
                        #if DEBUG
                        debugSection
                        #endif
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.lg)
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.impact(.light)
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.accentPrimary)
                }
            }
        }
        .task {
            await authService.refreshStatus()
        }
    }
    
    
    private var permissionDeniedBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Disabled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Enable notifications in Settings to receive reminders.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            Button {
                Haptics.impact(.light)
                openSystemSettings()
            } label: {
                Text("Open Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            }
        }
        .padding(DS.Spacing.lg)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Master Toggle
    
    private var masterToggleSection: some View {
        settingsCard {
            Toggle(isOn: Binding(
                get: { prefs.masterEnabled },
                set: { newValue in
                    Haptics.impact(.light)
                    if newValue && authService.status == .notDetermined {
                        // Request permission when enabling
                        Task {
                            await authService.requestPermission()
                            if authService.isAuthorized {
                                prefsStore.setMasterEnabled(true)
                            }
                        }
                    } else {
                        prefsStore.setMasterEnabled(newValue)
                    }
                }
            )) {
                HStack(spacing: 14) {
                    iconCircle(icon: "bell.fill", color: theme.accentPrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Push Notifications")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(prefs.masterEnabled ? "All notifications enabled" : "All notifications paused")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .tint(theme.accentPrimary)
        }
    }
    
    // MARK: - Session Notifications
    
    private var sessionSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "FOCUS SESSIONS", icon: "timer")
                
                Toggle(isOn: Binding(
                    get: { prefs.sessionCompletionEnabled },
                    set: { prefsStore.setSessionCompletionEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Session Complete")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Notify when your focus session ends")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
            }
        }
    }
    
    // MARK: - Daily Reminder
    
    private var dailyReminderSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "DAILY REMINDER", icon: "clock.fill")
                
                Toggle(isOn: Binding(
                    get: { prefs.dailyReminderEnabled },
                    set: { prefsStore.setDailyReminderEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Focus Reminder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("A gentle reminder to start your focus time")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
                
                if prefs.dailyReminderEnabled {
                    Divider()
                        .background(Color.white.opacity(DS.Glass.regular))
                    
                    HStack {
                        Text("Reminder Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { prefs.dailyReminderTime },
                                set: { prefsStore.setDailyReminderTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(theme.accentPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Nudges
    
    private var dailyNudgesSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "FOCUS NUDGES", icon: "sparkles")
                
                Toggle(isOn: Binding(
                    get: { prefs.dailyNudgesEnabled },
                    set: { prefsStore.setDailyNudgesEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Motivational Nudges")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("3 daily reminders to stay on track")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
                
                if prefs.dailyNudgesEnabled {
                    Divider()
                        .background(Color.white.opacity(DS.Glass.regular))
                    
                    VStack(spacing: DS.Spacing.md) {
                        nudgeRow(label: "Morning", time: "9:00 AM", icon: "sunrise.fill")
                        nudgeRow(label: "Afternoon", time: "2:00 PM", icon: "sun.max.fill")
                        nudgeRow(label: "Evening", time: "8:00 PM", icon: "moon.fill")
                    }
                    
                    Text("Custom times coming soon")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private func nudgeRow(label: String, time: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.accentPrimary.opacity(0.8))
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(time)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Smart AI Nudges (Phase 5)
    
    private var smartNudgesSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "SMART AI NUDGES", icon: "brain.head.profile")
                
                Toggle(isOn: Binding(
                    get: { prefs.smartNudgesEnabled },
                    set: { prefsStore.setSmartNudgesEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intelligent Notifications")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("AI-powered nudges based on your patterns")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
                
                if prefs.smartNudgesEnabled {
                    Divider()
                        .background(Color.white.opacity(DS.Glass.regular))
                    
                    VStack(spacing: DS.Spacing.md) {
                        smartNudgeToggle(
                            title: "Streak Protection",
                            subtitle: "Alert when your streak is at risk",
                            icon: "flame.fill",
                            iconColor: .orange,
                            isOn: Binding(
                                get: { prefs.streakRiskNudgesEnabled },
                                set: { prefsStore.setStreakRiskNudgesEnabled($0); Haptics.impact(.light) }
                            )
                        )
                        
                        smartNudgeToggle(
                            title: "Goal Progress",
                            subtitle: "Encourage when you're close to your daily goal",
                            icon: "target",
                            iconColor: theme.accentPrimary,
                            isOn: Binding(
                                get: { prefs.goalProgressNudgesEnabled },
                                set: { prefsStore.setGoalProgressNudgesEnabled($0); Haptics.impact(.light) }
                            )
                        )
                        
                        smartNudgeToggle(
                            title: "Achievements",
                            subtitle: "Celebrate milestones and personal bests",
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            isOn: Binding(
                                get: { prefs.achievementNudgesEnabled },
                                set: { prefsStore.setAchievementNudgesEnabled($0); Haptics.impact(.light) }
                            )
                        )
                        
                        smartNudgeToggle(
                            title: "Check-ins",
                            subtitle: "Gentle nudge if you've been away for a while",
                            icon: "hand.wave.fill",
                            iconColor: .cyan,
                            isOn: Binding(
                                get: { prefs.inactivityNudgesEnabled },
                                set: { prefsStore.setInactivityNudgesEnabled($0); Haptics.impact(.light) }
                            )
                        )
                    }
                }
            }
        }
    }
    
    private func smartNudgeToggle(title: String, subtitle: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.accentPrimary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Task Reminders
    
    private var taskRemindersSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "TASK REMINDERS", icon: "checklist")
                
                Toggle(isOn: Binding(
                    get: { prefs.taskRemindersEnabled },
                    set: { prefsStore.setTaskRemindersEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Task Notifications")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Get reminded about upcoming tasks")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
            }
        }
    }
    
    // MARK: - Daily Recap (Journey)
    
    private var dailyRecapSection: some View {
        settingsCard {
            VStack(spacing: 16) {
                sectionHeader(title: "DAILY RECAP", icon: "book.pages.fill")
                
                Toggle(isOn: Binding(
                    get: { prefs.dailyRecapEnabled },
                    set: { prefsStore.setDailyRecapEnabled($0); Haptics.impact(.light) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yesterday's Summary")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Morning recap of your previous day's progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(theme.accentPrimary)
                
                if prefs.dailyRecapEnabled {
                    Divider()
                        .background(Color.white.opacity(DS.Glass.regular))
                    
                    HStack {
                        Text("Recap Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { prefs.dailyRecapTime },
                                set: { prefsStore.setDailyRecapTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(theme.accentPrimary)
                    }
                    
                    // Info text
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.accentPrimary.opacity(0.6))
                        
                        Text("Review your focus time, tasks completed, and streaks from yesterday")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Test Notification
    
    private var testNotificationSection: some View {
        settingsCard {
            Button {
                Haptics.impact(.medium)
                sendTestNotification()
            } label: {
                HStack {
                    iconCircle(icon: "paperplane.fill", color: theme.accentSecondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Send Test Notification")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(showingTestSent ? "Sent! Check your notifications." : "Make sure notifications are working")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(showingTestSent ? theme.accentPrimary : .white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        settingsCard {
            VStack(spacing: 12) {
                sectionHeader(title: "DEVELOPER", icon: "hammer.fill")
                
                Button {
                    Haptics.impact(.light)
                    Task {
                        await NotificationsCoordinator.shared.debugDumpPending()
                    }
                } label: {
                    HStack {
                        Text("Print Pending Notifications")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(DS.Glass.regular))
                
                Button {
                    Haptics.impact(.light)
                    Task {
                        await NotificationsCoordinator.shared.reconcileAll(reason: "manual debug")
                    }
                } label: {
                    HStack {
                        Text("Force Reconcile")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                HStack {
                    Text("Auth Status:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text(authStatusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(authStatusColor)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var authStatusText: String {
        switch authService.status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private var authStatusColor: Color {
        switch authService.status {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    #endif
    
    // MARK: - Helpers
    
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(DS.Spacing.lg)
            .background(Color.white.opacity(DS.Glass.ultraThin))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderSubtle), lineWidth: 1)
            )
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.accentPrimary.opacity(0.7))
            
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.2)
            
            Spacer()
        }
    }
    
    private func iconCircle(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.15))
            .clipShape(Circle())
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your FocusFlow notifications are working perfectly! 🎯"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "focusflow.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    showingTestSent = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingTestSent = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
}
