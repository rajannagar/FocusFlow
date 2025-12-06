import SwiftUI
import PhotosUI

// MARK: - Glass group card (matches Focus/Habits aesthetic)

private struct ProfileGlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

struct ProfileView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingEditProfile = false
    @State private var showingResetSheet = false

    // Header icon animation
    @State private var iconPulse = false

    private let calendar = Calendar.current

    // MARK: - Lifetime totals shown in hero card
    // Backed by StatsManager lifetime properties – only reset via clearAll().
    private var lifetimeFocusReadable: String {
        stats.lifetimeFocusSeconds.asReadableDuration
    }

    private var lifetimeSessionCount: Int {
        stats.lifetimeSessionCount
    }

    private var lifetimeBestStreak: Int {
        stats.lifetimeBestStreak
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = settings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Blurred halos – match FocusView & HabitsView
                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        heroProfile
                            .padding(.horizontal, 22)
                            .padding(.top, 4)

                        preferencesGroup
                            .padding(.horizontal, 22)
                            .padding(.top, 4)

                        dataAboutGroup
                            .padding(.horizontal, 22)
                            .padding(.top, 4)

                        Spacer(minLength: 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(
                name: $settings.displayName,
                tagline: $settings.tagline
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingResetSheet) {
            ResetStatsSheet(isPresented: $showingResetSheet) {
                // Wipe sessions + lifetime aggregates + best streak.
                stats.clearAll()
            }
        }
        .onAppear {
            iconPulse = true

            // Re-apply the user's daily reminder preference on open
            FocusLocalNotificationManager.shared.applyDailyReminderSettings(
                enabled: settings.dailyReminderEnabled,
                time: settings.dailyReminderTime
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        let theme = settings.selectedTheme
        let accentPrimary = theme.accentPrimary

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true),
                            value: iconPulse
                        )

                    Text("Profile")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    if streaks.current > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .imageScale(.small)
                            Text("\(streaks.current)d")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundColor(accentPrimary)
                    }
                }

                // Small, personal, one line, no name
                Text("Your focus, reflected back.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            // Theme chip
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.accentPrimary,
                                theme.accentSecondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )

                Text(theme.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
            .foregroundColor(.white.opacity(0.9))
        }
    }

    // MARK: - Hero profile card (lifetime stats)

    private var heroProfile: some View {
        let name = settings.displayName.trimmingCharacters(in: .whitespaces)
        let displayName = name.isEmpty ? "Your name" : name

        return ProfileGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 18) {
                    profileImageView

                    // Lifetime stats trio (not affected by per-session deletions)
                    HStack(spacing: 18) {
                        statColumn(
                            value: lifetimeFocusReadable,
                            label: "Focus time"
                        )
                        statColumn(
                            value: "\(lifetimeSessionCount)",
                            label: "Sessions"
                        )
                        statColumn(
                            value: lifetimeBestStreak > 0 ? "\(lifetimeBestStreak)d" : "--",
                            label: "Best streak"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    if !settings.tagline.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(settings.tagline)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.82))
                    } else {
                        Text("Add a short line about how you like to focus.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    simpleTap()
                    showingEditProfile = true
                }

                HStack(spacing: 10) {
                    Button {
                        simpleTap()
                        showingEditProfile = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .imageScale(.small)
                            Text("Edit profile")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.16))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    if streaks.current > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .imageScale(.small)
                            Text("\(streaks.current)-day streak")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.orange.opacity(0.20))
                        )
                        .foregroundColor(.orange.opacity(0.95))
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 64)
    }

    // MARK: - Avatar

    private var profileImageView: some View {
        let size: CGFloat = 86
        let theme = settings.selectedTheme

        return PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
            ZStack {
                if let img = profileImage {
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: theme.accentPrimary.opacity(0.4), radius: 10)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.accentPrimary.opacity(0.55),
                                    theme.accentSecondary.opacity(0.35)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.9))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.30), lineWidth: 1)
                        )
                }

                // camera badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.black.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black.opacity(0.9))
                                    )
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: photoPickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        settings.profileImageData = data
                        Haptics.impact(.light)
                    }
                }
            }
        }
    }

    private var profileImage: Image? {
        guard let data = settings.profileImageData,
              let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }

    // MARK: - Preferences group

    private var preferencesGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .imageScale(.small)
                    .foregroundColor(.white.opacity(0.8))
                Text("Preferences")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 4)

            ProfileGlassCard {
                VStack(spacing: 0) {
                    // Appearance — subtitle is theme name
                    settingsRow(
                        icon: "paintpalette.fill",
                        iconColor: settings.selectedTheme.accentPrimary,
                        title: "Appearance",
                        subtitle: settings.selectedTheme.displayName
                    ) {
                        themeChips
                    }

                    divider

                    // Timer sounds — no subtitle
                    toggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "Timer sounds",
                        subtitle: nil,
                        binding: $settings.soundEnabled
                    )

                    divider

                    // Haptics — no subtitle
                    toggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptics",
                        subtitle: nil,
                        binding: $settings.hapticsEnabled
                    )

                    divider

                    // Focus goal (short title, no subtitle)
                    dailyGoalRow

                    divider

                    // Daily focus reminder — no subtitle
                    reminderRow
                }
            }
        }
    }

    private var themeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppTheme.allCases) { theme in
                    let isSelected = settings.selectedTheme == theme

                    Button {
                        simpleTap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            settings.profileTheme = theme      // 👈 base theme
                            settings.selectedTheme = theme     // 👈 currently applied theme
                        }
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.accentColor.opacity(0.95),
                                        theme.accentColor.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: isSelected ? 24 : 18, height: isSelected ? 24 : 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func settingsRow<Accessory: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            accessory()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String?,
        binding: Binding<Bool>
    ) -> some View {
        // Wrap binding so we can trigger haptics when the value changes
        let hapticBinding = Binding<Bool>(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                simpleTap()
            }
        )

        return settingsRow(
            icon: icon,
            iconColor: settings.selectedTheme.accentPrimary,
            title: title,
            subtitle: subtitle
        ) {
            Toggle("", isOn: hapticBinding)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: settings.selectedTheme.accentColor))
        }
    }

    // MARK: - Focus goal row (no subtitle, short title)

    private var dailyGoalRow: some View {
        settingsRow(
            icon: "target",
            iconColor: settings.selectedTheme.accentPrimary,
            title: "Focus goal",
            subtitle: nil
        ) {
            HStack(spacing: 8) {
                Button {
                    simpleTap()
                    stats.dailyGoalMinutes = max(stats.dailyGoalMinutes - 5, 15)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 24, height: 24)
                }

                Text("\(stats.dailyGoalMinutes) min")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(minWidth: 60)

                Button {
                    simpleTap()
                    stats.dailyGoalMinutes = min(stats.dailyGoalMinutes + 5, 240)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
        }
    }

    // MARK: - Daily reminder row (no subtitle, themed bell icon)

    private var reminderRow: some View {
        // Wrapped binding so toggling reminder also triggers a haptic tap
        let reminderBinding = Binding<Bool>(
            get: { settings.dailyReminderEnabled },
            set: { newValue in
                settings.dailyReminderEnabled = newValue
                simpleTap()
            }
        )

        return VStack(spacing: 6) {
            settingsRow(
                icon: "bell.fill",
                iconColor: settings.selectedTheme.accentSecondary,
                title: "Daily focus reminder",
                subtitle: nil
            ) {
                Toggle("", isOn: reminderBinding)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: settings.selectedTheme.accentColor))
            }

            if settings.dailyReminderEnabled {
                HStack {
                    Text("Reminder time")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))

                    Spacer()

                    DatePicker(
                        "",
                        selection: $settings.dailyReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                Text("FocusFlow will nudge you once a day at this time. Make sure notifications are enabled in Settings.")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
        }
        // Wiring to real notifications
        .onChange(of: settings.dailyReminderEnabled) { _, newValue in
            FocusLocalNotificationManager.shared.applyDailyReminderSettings(
                enabled: newValue,
                time: settings.dailyReminderTime
            )
        }
        .onChange(of: settings.dailyReminderTime) { _, newTime in
            FocusLocalNotificationManager.shared.applyDailyReminderSettings(
                enabled: settings.dailyReminderEnabled,
                time: newTime
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color.white.opacity(0.08))
            .padding(.leading, 52) // align under text, not icon
    }

    // MARK: - Data / About group

    private var dataAboutGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .imageScale(.small)
                    .foregroundColor(.white.opacity(0.8))
                Text("Data & info")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 4)

            ProfileGlassCard {
                VStack(spacing: 0) {
                    Button {
                        simpleTap()
                        showingResetSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.16))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.95))
                            }

                            Text("Reset all focus stats")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.red.opacity(0.95))

                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    divider

                    VStack(alignment: .leading, spacing: 6) {
                        Text("About FocusFlow")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))

                        Text("FocusFlow helps you protect deep work time, build small supporting habits, and actually see how your focus adds up. The timer powers your sessions, Habits keeps your pre- and post-work rituals on track, and Stats turns everything into a clear story you can come back to.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))

                        Text("You control your data — you can clear all focus stats from here at any time.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.70))
                            .padding(.top, 4)

                        Text("Version 1.0")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Streak helper (current streak only depends on existing sessions)

    private var streaks: (current: Int, best: Int) {
        let daysWithFocus: Set<Date> = Set(
            stats.sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty { return (0, 0) }

        // current streak
        var current = 0
        var cursor = calendar.startOfDay(for: Date())
        while daysWithFocus.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // best streak (may differ from lifetimeBestStreak if user has reset before)
        let sorted = daysWithFocus.sorted()
        var best = 1
        var temp = 1
        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: -1, to: sorted[i]),
               calendar.isDate(prev, inSameDayAs: sorted[i - 1]) {
                temp += 1
            } else {
                best = max(best, temp)
                temp = 1
            }
        }
        best = max(best, temp)
        return (current, best)
    }

    // MARK: - Haptics helper

    private func simpleTap() {
        Haptics.impact(.light)
    }
}

// MARK: - Edit Profile Sheet

private struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var tagline: String

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.11),
                    Color(red: 0.15, green: 0.16, blue: 0.22)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Edit profile")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    TextField("Your name", text: $name)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tagline")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    TextField("How do you like to focus?", text: $tagline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Reset stats confirmation sheet

private struct ResetStatsSheet: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @State private var typed = ""

    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        let theme = settings.selectedTheme

        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 4)
                    .padding(.top, 8)

                Text("Reset all focus stats?")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("This will permanently delete every focus session, streak, and lifetime stat in FocusFlow. It cannot be undone.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type **reset** to confirm.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))

                    TextField("reset", text: $typed)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.16))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                }
                .padding(.horizontal)

                HStack {
                    Button("Cancel") {
                        Haptics.impact(.light)
                        isPresented = false
                    }
                    .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        onConfirm()
                        isPresented = false
                    } label: {
                        Text("Reset everything")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(Color.red.opacity(typedMatches ? 0.9 : 0.5))
                            .clipShape(Capsule())
                    }
                    .disabled(!typedMatches)
                }
                .padding(.horizontal)

                Spacer(minLength: 16)
            }
            .padding(.bottom, 16)
        }
        .presentationDetents([.fraction(0.40)])
        .presentationDragIndicator(.visible)
    }

    private var typedMatches: Bool {
        typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "reset"
    }
}

#Preview {
    ProfileView()
}
