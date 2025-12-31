//
//  SettingsSyncEngine.swift
//  FocusFlow
//
//  Syncs AppSettings ↔ user_settings table.
//  Safe for first-time users (0 rows) and avoids .single() PGRST116.
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Model

/// Matches the `user_settings` table schema
struct UserSettingsDTO: Codable {
    let userId: UUID
    var displayName: String?
    var tagline: String?
    var avatarId: String?
    var selectedTheme: String?
    var profileTheme: String?
    var soundEnabled: Bool?
    var hapticsEnabled: Bool?
    var dailyReminderEnabled: Bool?
    var dailyReminderHour: Int?
    var dailyReminderMinute: Int?
    var selectedFocusSound: String?
    var externalMusicApp: String?
    var dailyGoalMinutes: Int?
    var goalHistory: [String: Int]? // date string -> goal minutes
    var notificationPreferences: NotificationPreferences?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case tagline
        case avatarId = "avatar_id"
        case selectedTheme = "selected_theme"
        case profileTheme = "profile_theme"
        case soundEnabled = "sound_enabled"
        case hapticsEnabled = "haptics_enabled"
        case dailyReminderEnabled = "daily_reminder_enabled"
        case dailyReminderHour = "daily_reminder_hour"
        case dailyReminderMinute = "daily_reminder_minute"
        case selectedFocusSound = "selected_focus_sound"
        case externalMusicApp = "external_music_app"
        case dailyGoalMinutes = "daily_goal_minutes"
        case goalHistory = "goal_history"
        case notificationPreferences = "notification_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initializers
    
    /// Manual initializer for creating DTO when pushing to remote
    init(
        userId: UUID,
        displayName: String? = nil,
        tagline: String? = nil,
        avatarId: String? = nil,
        selectedTheme: String? = nil,
        profileTheme: String? = nil,
        soundEnabled: Bool? = nil,
        hapticsEnabled: Bool? = nil,
        dailyReminderEnabled: Bool? = nil,
        dailyReminderHour: Int? = nil,
        dailyReminderMinute: Int? = nil,
        selectedFocusSound: String? = nil,
        externalMusicApp: String? = nil,
        dailyGoalMinutes: Int? = nil,
        goalHistory: [String: Int]? = nil,
        notificationPreferences: NotificationPreferences? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userId = userId
        self.displayName = displayName
        self.tagline = tagline
        self.avatarId = avatarId
        self.selectedTheme = selectedTheme
        self.profileTheme = profileTheme
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderHour = dailyReminderHour
        self.dailyReminderMinute = dailyReminderMinute
        self.selectedFocusSound = selectedFocusSound
        self.externalMusicApp = externalMusicApp
        self.dailyGoalMinutes = dailyGoalMinutes
        self.goalHistory = goalHistory
        self.notificationPreferences = notificationPreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Custom Decoding
    
    /// Custom decoder to handle empty JSON objects for notification_preferences and goal_history
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required field
        userId = try container.decode(UUID.self, forKey: .userId)
        
        // Optional fields
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline)
        avatarId = try container.decodeIfPresent(String.self, forKey: .avatarId)
        selectedTheme = try container.decodeIfPresent(String.self, forKey: .selectedTheme)
        profileTheme = try container.decodeIfPresent(String.self, forKey: .profileTheme)
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled)
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled)
        dailyReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyReminderEnabled)
        dailyReminderHour = try container.decodeIfPresent(Int.self, forKey: .dailyReminderHour)
        dailyReminderMinute = try container.decodeIfPresent(Int.self, forKey: .dailyReminderMinute)
        selectedFocusSound = try container.decodeIfPresent(String.self, forKey: .selectedFocusSound)
        externalMusicApp = try container.decodeIfPresent(String.self, forKey: .externalMusicApp)
        dailyGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .dailyGoalMinutes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        
        // Handle goal_history - decode as dictionary, skip if empty
        if let goalHistoryData = try container.decodeIfPresent([String: Int].self, forKey: .goalHistory),
           !goalHistoryData.isEmpty {
            goalHistory = goalHistoryData
        } else {
            goalHistory = nil
        }
        
        // Handle notification_preferences - decode with fallback to nil if empty or invalid
        // Empty JSON {} will fail to decode, so we catch and set to nil (will use local defaults)
        do {
            if let prefsData = try container.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) {
                notificationPreferences = prefsData
            } else {
                notificationPreferences = nil
            }
        } catch {
            // If decoding fails (empty JSON {} or invalid), set to nil
            // The app will use local defaults from NotificationPreferencesStore
            #if DEBUG
            print("[SettingsSyncEngine] Failed to decode notification_preferences: \(error). Using local defaults.")
            #endif
            notificationPreferences = nil
        }
    }
}

// MARK: - Sync Engine

@MainActor
final class SettingsSyncEngine {

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?
    private var isApplyingRemote = false

    // MARK: - Start / Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        try await pullFromRemote(userId: userId)
        observeLocalChanges()
    }

    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
    }

    // MARK: - Pull

    func pullFromRemote(userId: UUID) async throws {
        let client = SupabaseManager.shared.client

        // ✅ Avoid .single() so first-time users (0 rows) don't throw PGRST116
        let rows: [UserSettingsDTO] = try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let remote = rows.first {
            #if DEBUG
            print("[SettingsSyncEngine] 📥 Pulling settings from cloud...")
            if let goalHistory = remote.goalHistory, !goalHistory.isEmpty {
                print("[SettingsSyncEngine]   - Goal history: \(goalHistory.count) entries")
            }
            if remote.notificationPreferences != nil {
                print("[SettingsSyncEngine]   - Notification preferences: present")
            }
            #endif
            applyRemoteToLocal(remote)
        } else {
            // No settings row yet — totally fine. It will be created on first push.
            #if DEBUG
            print("[SettingsSyncEngine] ℹ️ No remote user_settings row yet (first-time user)")
            #endif
        }

        #if DEBUG
        print("[SettingsSyncEngine] ✅ Pulled settings from remote")
        #endif
    }

    // MARK: - Push

    /// Force immediate push (bypasses debounce) - use when app is entering background/terminating
    func forcePushNow() async {
        guard isRunning else { return }
        await pushToRemote()
    }

    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }

        let settings = AppSettings.shared
        
        // Get goal history from local storage
        let goalHistory = loadGoalHistory()
        
        // Get notification preferences
        let notificationPrefs = NotificationPreferencesStore.shared.preferences

        #if DEBUG
        // Log what we're pushing
        var changes: [String] = []
        if !goalHistory.isEmpty {
            let goalCount = goalHistory.count
            let recentGoals = goalHistory.sorted(by: { $0.key > $1.key }).prefix(3)
            let recentStr = recentGoals.map { "\($0.key): \($0.value)m" }.joined(separator: ", ")
            changes.append("goal_history: \(goalCount) entries (\(recentStr)\(goalCount > 3 ? "..." : ""))")
        }
        if notificationPrefs != NotificationPreferences.default {
            changes.append("notification_preferences: customized")
        }
        if !changes.isEmpty {
            print("[SettingsSyncEngine] 📤 Pushing to cloud: \(changes.joined(separator: ", "))")
        }
        #endif

        let dto = UserSettingsDTO(
            userId: userId,
            displayName: settings.displayName,
            tagline: settings.tagline,
            avatarId: settings.avatarID,
            selectedTheme: settings.selectedTheme.rawValue,
            profileTheme: settings.profileTheme.rawValue,
            soundEnabled: settings.soundEnabled,
            hapticsEnabled: settings.hapticsEnabled,
            dailyReminderEnabled: settings.dailyReminderEnabled,
            dailyReminderHour: settings.dailyReminderHour,
            dailyReminderMinute: settings.dailyReminderMinute,
            selectedFocusSound: settings.selectedFocusSound?.rawValue,
            externalMusicApp: settings.externalMusicApp?.rawValue,
            dailyGoalMinutes: settings.dailyGoalMinutes,
            goalHistory: goalHistory.isEmpty ? nil : goalHistory,
            notificationPreferences: notificationPrefs
        )

        do {
            try await SupabaseManager.shared.client
                .from("user_settings")
                .upsert(dto, onConflict: "user_id")
                .execute()

            #if DEBUG
            print("[SettingsSyncEngine] ✅ Pushed settings to remote successfully")
            #endif
        } catch {
            #if DEBUG
            print("[SettingsSyncEngine] ❌ Push error: \(error)")
            #endif
        }
    }

    // MARK: - Apply Remote

    private func applyRemoteToLocal(_ remote: UserSettingsDTO) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let settings = AppSettings.shared
        guard let userId = userId else { return }
        let namespace = userId.uuidString
        let remoteTimestamp = remote.updatedAt ?? remote.createdAt

        // ✅ NEW: Field-level conflict resolution using timestamps
        // Only apply remote values if local is NOT newer

        if let name = remote.displayName {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "displayName", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                // Only set if value actually changed to prevent unnecessary publisher fires
                if settings.displayName != name {
                    settings.displayName = name
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "displayName", namespace: namespace)
            }
        }

        if let tag = remote.tagline {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "tagline", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.tagline != tag {
                    settings.tagline = tag
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "tagline", namespace: namespace)
            }
        }

        if let avatar = remote.avatarId {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "avatarID", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.avatarID != avatar {
                    settings.avatarID = avatar
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "avatarID", namespace: namespace)
            }
        }

        if let themeRaw = remote.selectedTheme, let theme = AppTheme(rawValue: themeRaw) {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "selectedTheme", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.selectedTheme != theme {
                    settings.selectedTheme = theme
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "selectedTheme", namespace: namespace)
            }
        }

        if let profileThemeRaw = remote.profileTheme, let theme = AppTheme(rawValue: profileThemeRaw) {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "profileTheme", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.profileTheme != theme {
                    settings.profileTheme = theme
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "profileTheme", namespace: namespace)
            }
        }

        if let soundEnabled = remote.soundEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "soundEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.soundEnabled != soundEnabled {
                    settings.soundEnabled = soundEnabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "soundEnabled", namespace: namespace)
            }
        }

        if let hapticsEnabled = remote.hapticsEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "hapticsEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.hapticsEnabled != hapticsEnabled {
                    settings.hapticsEnabled = hapticsEnabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "hapticsEnabled", namespace: namespace)
            }
        }

        if let enabled = remote.dailyReminderEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyReminderEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.dailyReminderEnabled != enabled {
                    settings.dailyReminderEnabled = enabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyReminderEnabled", namespace: namespace)
            }
        }

        // ✅ dailyReminderHour/minute are get-only accessors; set dailyReminderTime
        let reminderHour = remote.dailyReminderHour
        let reminderMinute = remote.dailyReminderMinute
        if reminderHour != nil || reminderMinute != nil {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyReminderTime", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                let cal = Calendar.current
                var comps = cal.dateComponents([.year, .month, .day], from: settings.dailyReminderTime)
                comps.hour = reminderHour ?? settings.dailyReminderHour
                comps.minute = reminderMinute ?? settings.dailyReminderMinute
                if let newTime = cal.date(from: comps) {
                    // Only set if time actually changed
                    let oldComps = cal.dateComponents([.hour, .minute], from: settings.dailyReminderTime)
                    if oldComps.hour != comps.hour || oldComps.minute != comps.minute {
                        settings.dailyReminderTime = newTime
                    }
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyReminderTime", namespace: namespace)
            }
        }

        // ✅ Sound should only be restored from session persistence, not from remote sync
        // Skip applying sound from remote - it will be restored by timer restoration if session is active

        // ✅ Sound and external app should only be restored from session persistence, not from remote sync
        // Check if there's an active session - if not, don't apply sound/app from remote
        let defaults = UserDefaults.standard
        let isSessionActive = defaults.bool(forKey: "FocusFlow.focusSession.isActive")
        
        if !isSessionActive {
            // No session active - clear sound/app (they should only exist during sessions)
            settings.selectedFocusSound = nil
            settings.selectedExternalMusicApp = nil
        }
        // If session is active, sound/app will be restored by timer restoration, not from remote sync

        if let goal = remote.dailyGoalMinutes {
            // ✅ Check if local is newer before applying remote daily goal
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyGoalMinutes", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.dailyGoalMinutes != goal {
                    settings.dailyGoalMinutes = goal
                    
                    // ✅ Store the remote goal in goal history for today
                    // This ensures today's goal is preserved in the per-day goal history,
                    // so past dates won't be affected if the user changes the goal later
                    let calendar = Calendar.autoupdatingCurrent
                    let today = calendar.startOfDay(for: Date())
                    storeGoalInHistory(goalMinutes: goal, for: today, calendar: calendar)
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyGoalMinutes", namespace: namespace)
            }
        }
        
        // ✅ Apply goal history from remote (merge with local)
        if let remoteGoalHistory = remote.goalHistory, !remoteGoalHistory.isEmpty {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "goalHistory", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                let localBefore = loadGoalHistory()
                mergeGoalHistory(remote: remoteGoalHistory)
                let localAfter = loadGoalHistory()
                
                #if DEBUG
                // Log what changed
                let added = Set(remoteGoalHistory.keys).subtracting(Set(localBefore.keys))
                let updated = remoteGoalHistory.filter { localBefore[$0.key] != $0.value && localBefore[$0.key] != nil }
                if !added.isEmpty || !updated.isEmpty {
                    var changes: [String] = []
                    if !added.isEmpty {
                        let addedStr = added.sorted().map { "\($0): \(remoteGoalHistory[$0] ?? 0)m" }.joined(separator: ", ")
                        changes.append("added: \(addedStr)")
                    }
                    if !updated.isEmpty {
                        let updatedStr = updated.map { "\($0.key): \(localBefore[$0.key] ?? 0)m → \($0.value)m" }.joined(separator: ", ")
                        changes.append("updated: \(updatedStr)")
                    }
                    print("[SettingsSyncEngine] 📥 Applied goal history from cloud: \(changes.joined(separator: "; "))")
                }
                #endif
                
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "goalHistory", namespace: namespace)
            }
        }
        
        // ✅ Apply notification preferences from remote
        // Note: If remote.notificationPreferences is nil, it means the database has empty JSON {}
        // In that case, we don't overwrite local preferences (they may have been set locally)
        if let remotePrefs = remote.notificationPreferences {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "notificationPreferences", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                let prefsStore = NotificationPreferencesStore.shared
                let localBefore = prefsStore.preferences
                
                // Use applyRemotePreferences to avoid triggering sync notification loop
                prefsStore.applyRemotePreferences(remotePrefs)
                
                #if DEBUG
                // Log what changed
                var changes: [String] = []
                if localBefore.masterEnabled != remotePrefs.masterEnabled {
                    changes.append("masterEnabled: \(localBefore.masterEnabled) → \(remotePrefs.masterEnabled)")
                }
                if localBefore.dailyReminderEnabled != remotePrefs.dailyReminderEnabled {
                    changes.append("dailyReminder: \(localBefore.dailyReminderEnabled) → \(remotePrefs.dailyReminderEnabled)")
                }
                if localBefore.dailyNudgesEnabled != remotePrefs.dailyNudgesEnabled {
                    changes.append("dailyNudges: \(localBefore.dailyNudgesEnabled) → \(remotePrefs.dailyNudgesEnabled)")
                }
                if localBefore.taskRemindersEnabled != remotePrefs.taskRemindersEnabled {
                    changes.append("taskReminders: \(localBefore.taskRemindersEnabled) → \(remotePrefs.taskRemindersEnabled)")
                }
                if localBefore.dailyRecapEnabled != remotePrefs.dailyRecapEnabled {
                    changes.append("dailyRecap: \(localBefore.dailyRecapEnabled) → \(remotePrefs.dailyRecapEnabled)")
                }
                if !changes.isEmpty {
                    print("[SettingsSyncEngine] 📥 Applied notification preferences from cloud: \(changes.joined(separator: ", "))")
                }
                #endif
                
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "notificationPreferences", namespace: namespace)
            }
        }
        // If remote.notificationPreferences is nil (empty JSON {}), we keep local preferences
        // This is correct behavior - empty JSON means "not set yet", not "reset to defaults"

        // ✅ Sync to Home Screen widgets after applying remote settings
        WidgetDataManager.shared.syncAll()
        
        #if DEBUG
        print("[SettingsSyncEngine] Applied remote settings to local (with conflict resolution)")
        #endif
    }

    // MARK: - Goal History Helpers
    
    /// Loads goal history from local storage
    private func loadGoalHistory() -> [String: Int] {
        let storeKey = "focusflow.pv2.dailyGoalHistory.v1"
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    /// Merges remote goal history with local (remote takes precedence for conflicts)
    private func mergeGoalHistory(remote: [String: Int]) {
        let storeKey = "focusflow.pv2.dailyGoalHistory.v1"
        var local = loadGoalHistory()
        
        // Merge: remote values take precedence, but keep local values that aren't in remote
        for (date, goal) in remote {
            local[date] = max(0, goal)
        }
        
        // Save merged history
        if let data = try? JSONEncoder().encode(local) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
        
        #if DEBUG
        print("[SettingsSyncEngine] 💾 Merged goal history: \(local.count) total entries")
        #endif
    }
    
    /// Stores a goal in the per-day goal history (same storage as PV2GoalHistory/GoalHistory)
    /// This ensures that when a remote goal is applied, it's preserved in the goal history
    /// so that past dates maintain their original goals even if the user changes the goal later
    private func storeGoalInHistory(goalMinutes: Int, for date: Date, calendar: Calendar) {
        let storeKey = "focusflow.pv2.dailyGoalHistory.v1"
        let targetDay = calendar.startOfDay(for: date)
        
        // Create date key (same format as PV2GoalHistory/GoalHistory)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: targetDay)
        
        // Load existing history
        var dict = loadGoalHistory()
        
        // Only store if this date doesn't already have a goal (preserve user's explicit goal settings)
        if dict[dateKey] == nil {
            dict[dateKey] = max(0, goalMinutes)
            if let data = try? JSONEncoder().encode(dict) {
                UserDefaults.standard.set(data, forKey: storeKey)
            }
        }
    }

    // MARK: - Observe Local Changes

    private func observeLocalChanges() {
        let settings = AppSettings.shared
        let progress = ProgressStore.shared

        let notificationPrefs = NotificationPreferencesStore.shared
        
        let publishers: [AnyPublisher<Void, Never>] = [
            settings.$displayName.map { _ in () }.eraseToAnyPublisher(),
            settings.$tagline.map { _ in () }.eraseToAnyPublisher(),
            settings.$avatarID.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedTheme.map { _ in () }.eraseToAnyPublisher(),
            settings.$profileTheme.map { _ in () }.eraseToAnyPublisher(),
            settings.$soundEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$hapticsEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$dailyReminderEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$dailyReminderTime.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedFocusSound.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedExternalMusicApp.map { _ in () }.eraseToAnyPublisher(),
            progress.$dailyGoalMinutes.map { _ in () }.eraseToAnyPublisher(),
            notificationPrefs.$preferences.map { _ in () }.eraseToAnyPublisher(),
            // Watch for goal history changes
            NotificationCenter.default.publisher(for: NSNotification.Name("GoalHistoryDidChange"))
                .map { _ in () }
                .eraseToAnyPublisher()
        ]

        Publishers.MergeMany(publishers)
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced from 1s to 0.5s for faster sync
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                
                // ✅ NEW: Enqueue change in sync queue for reliability
                // This ensures changes are never lost, even if app is killed
                // The queue will process and push automatically
                Task { @MainActor in
                    guard AuthManagerV2.shared.state.userId != nil else { return }
                    
                    // Create a simple marker data (just to track that settings changed)
                    // The actual sync will read from AppSettings directly
                    struct SettingsMarker: Codable {
                        let settingsChanged: Bool
                        let timestamp: Double
                    }
                    let marker = SettingsMarker(settingsChanged: true, timestamp: Date().timeIntervalSince1970)
                    if let data = try? JSONEncoder().encode(marker) {
                        SyncQueue.shared.enqueueSettingsChange(data: data)
                    }
                }
                
                // ✅ REMOVED: Immediate push - let the queue handle it to prevent loops
                // The queue will process and push, avoiding double-push cycles
            }
            .store(in: &cancellables)
    }
}
