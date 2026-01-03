//
//  GuestMigrationManager.swift
//  FocusFlow
//
//  Handles migration of guest data to signed-in account
//

import Foundation
import Combine

@MainActor
final class GuestMigrationManager: ObservableObject {
    static let shared = GuestMigrationManager()
    
    @Published var isMigrating = false
    @Published var migrationError: Error?
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Guest Data Info
    
    /// Get count of guest sessions
    func guestSessionsCount() -> Int {
        // First check in-memory store if we're in guest mode
        if AuthManagerV2.shared.state == .guest {
            let inMemoryCount = ProgressStore.shared.sessions.count
            if inMemoryCount > 0 {
                #if DEBUG
                print("[GuestMigrationManager] Found \(inMemoryCount) sessions in memory")
                #endif
                return inMemoryCount
            }
        }
        
        // Fall back to checking UserDefaults
        let guestSessionsKey = "ff_local_progress.sessions.v1_guest"
        guard let sessionsData = defaults.data(forKey: guestSessionsKey) else {
            #if DEBUG
            print("[GuestMigrationManager] No sessions data in UserDefaults for key: \(guestSessionsKey)")
            #endif
            return 0
        }
        
        // IMPORTANT: Use iso8601 date decoding to match how sessions are encoded
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let sessions = try? decoder.decode([ProgressSession].self, from: sessionsData) else {
            #if DEBUG
            print("[GuestMigrationManager] Failed to decode sessions data (decoding error)")
            #endif
            return 0
        }
        #if DEBUG
        print("[GuestMigrationManager] Found \(sessions.count) sessions in UserDefaults")
        #endif
        return sessions.count
    }
    
    /// Get count of guest tasks
    func guestTasksCount() -> Int {
        // First check in-memory store if we're in guest mode
        if AuthManagerV2.shared.state == .guest {
            let inMemoryCount = TasksStore.shared.tasks.count
            if inMemoryCount > 0 {
                #if DEBUG
                print("[GuestMigrationManager] Found \(inMemoryCount) tasks in memory")
                #endif
                return inMemoryCount
            }
        }
        
        // Fall back to checking UserDefaults
        let guestTasksKey = "focusflow_tasks_state_guest"
        guard let tasksData = defaults.data(forKey: guestTasksKey) else {
            #if DEBUG
            print("[GuestMigrationManager] No tasks data found in UserDefaults for key: \(guestTasksKey)")
            #endif
            return 0
        }
        
        // Try to decode with date decoding strategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let tasksState = try? decoder.decode(TasksStore.LocalState.self, from: tasksData) else {
            #if DEBUG
            print("[GuestMigrationManager] Failed to decode tasks data")
            #endif
            return 0
        }
        #if DEBUG
        print("[GuestMigrationManager] Found \(tasksState.tasks.count) tasks in UserDefaults")
        #endif
        return tasksState.tasks.count
    }
    
    /// Get count of guest presets (all presets - will replace account defaults with guest's versions)
    func guestPresetsCount() -> Int {
        // First check in-memory store if we're in guest mode
        if AuthManagerV2.shared.state == .guest {
            let inMemoryPresets = FocusPresetStore.shared.presets
            if !inMemoryPresets.isEmpty {
                #if DEBUG
                print("[GuestMigrationManager] Found \(inMemoryPresets.count) presets in memory (\(inMemoryPresets.filter { !$0.isSystemDefault }.count) custom)")
                #endif
                return inMemoryPresets.count
            }
        }
        
        // Fall back to checking UserDefaults
        let guestPresetsKey = "ff_focus_presets_guest"
        guard let presetsData = defaults.data(forKey: guestPresetsKey),
              let presets = try? JSONDecoder().decode([FocusPreset].self, from: presetsData) else {
            #if DEBUG
            print("[GuestMigrationManager] No presets found in UserDefaults for key: \(guestPresetsKey)")
            #endif
            return 0
        }
        #if DEBUG
        print("[GuestMigrationManager] Found \(presets.count) presets in UserDefaults (\(presets.filter { !$0.isSystemDefault }.count) custom)")
        #endif
        return presets.count
    }
    
    /// Get guest daily goal (returns nil if default or 0)
    func guestDailyGoal() -> Int? {
        // First check in-memory store if we're in guest mode
        if AuthManagerV2.shared.state == .guest {
            let inMemoryGoal = ProgressStore.shared.dailyGoalMinutes
            if inMemoryGoal > 0 && inMemoryGoal != 60 {
                #if DEBUG
                print("[GuestMigrationManager] Found daily goal in memory: \(inMemoryGoal)")
                #endif
                return inMemoryGoal
            }
        }
        
        // Fall back to checking UserDefaults
        let guestGoalKey = "ff_local_progress.goalMinutes.v1_guest"
        let guestGoal = defaults.integer(forKey: guestGoalKey)
        if guestGoal > 0 && guestGoal != 60 {
            #if DEBUG
            print("[GuestMigrationManager] Found daily goal in UserDefaults: \(guestGoal)")
            #endif
            return guestGoal
        }
        #if DEBUG
        print("[GuestMigrationManager] No custom daily goal found (value: \(guestGoal))")
        #endif
        return nil
    }
    
    /// Check if guest namespace has any data worth migrating
    func hasGuestData() -> Bool {
        let hasSessions = guestSessionsCount() > 0
        let hasTasks = guestTasksCount() > 0
        let hasPresets = guestPresetsCount() > 0
        let hasGoal = guestDailyGoal() != nil
        let hasSettings = hasGuestSettings()
        
        #if DEBUG
        print("[GuestMigrationManager] hasGuestData check: sessions=\(hasSessions), tasks=\(hasTasks), presets=\(hasPresets), goal=\(hasGoal), settings=\(hasSettings)")
        #endif
        
        return hasSessions || hasTasks || hasPresets || hasGoal || hasSettings
    }
    
    // MARK: - Selective Migration
    
    /// Migration options for selective migration
    struct MigrationOptions {
        var migrateSessions: Bool = false
        var migrateTasks: Bool = false
        var migratePresets: Bool = false
        var migrateDailyGoal: Bool = false
        var migrateSettings: Bool = false  // Theme, sound preferences, etc.
    }
    
    // MARK: - Additional Guest Data Info
    
    /// Check if guest has custom settings (theme, sound, etc.)
    func hasGuestSettings() -> Bool {
        // Check for non-default theme
        let guestThemeKey = "ff_selectedTheme_guest"
        if let themeRaw = defaults.string(forKey: guestThemeKey), 
           themeRaw != "forest" {
            #if DEBUG
            print("[GuestMigrationManager] Found guest theme: \(themeRaw)")
            #endif
            return true
        }
        
        // Check for selected sound
        let guestSoundKey = "ff_selectedFocusSound_guest"
        if defaults.string(forKey: guestSoundKey) != nil {
            #if DEBUG
            print("[GuestMigrationManager] Found guest sound preference")
            #endif
            return true
        }
        
        // Check for profile theme
        let guestProfileThemeKey = "ff_profileTheme_guest"
        if let profileTheme = defaults.string(forKey: guestProfileThemeKey),
           profileTheme != "forest" {
            #if DEBUG
            print("[GuestMigrationManager] Found guest profile theme: \(profileTheme)")
            #endif
            return true
        }
        
        return false
    }
    
    /// Migrate selected guest data to signed-in account (merges with existing data)
    func migrateSelectedData(to userId: UUID, options: MigrationOptions) async throws {
        guard case .signedIn = AuthManagerV2.shared.state else {
            throw MigrationError.notSignedIn
        }
        
        isMigrating = true
        migrationError = nil
        defer { 
            isMigrating = false
        }
        
        let namespace = userId.uuidString
        
        #if DEBUG
        print("[GuestMigrationManager] Starting selective migration for user \(userId)")
        #endif
        
        // 0. IMPORTANT: Persist guest data to UserDefaults before migration
        // This ensures we can read it even after stores switch namespaces
        await MainActor.run {
            #if DEBUG
            print("[GuestMigrationManager] Persisting guest data before migration...")
            #endif
            // Force save current guest data
            ProgressStore.shared.persist()
            TasksStore.shared.save()
            FocusPresetStore.shared.savePresets()
        }
        
        // Small delay to ensure persistence completes
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // 1. Migrate sessions (merge with existing)
        if options.migrateSessions {
            try await migrateSessions(to: namespace)
        }
        
        // 2. Migrate tasks (merge with existing)
        if options.migrateTasks {
            try await migrateTasks(to: namespace)
        }
        
        // 3. Migrate presets (merge with existing)
        if options.migratePresets {
            try await migratePresets(to: namespace)
        }
        
        // 4. Migrate daily goal (only if user doesn't have a custom goal)
        if options.migrateDailyGoal {
            try await migrateDailyGoal(to: namespace)
        }
        
        // 5. Migrate settings (theme, sound, preferences)
        if options.migrateSettings {
            try await migrateSettings(to: namespace)
        }
        
        // 6. Update in-memory stores directly with migrated data
        // (Don't rely on reload which may have early returns)
        await MainActor.run {
            #if DEBUG
            print("[GuestMigrationManager] Updating in-memory stores with migrated data...")
            #endif
            
            // Load and apply migrated sessions
            if let sessionsData = defaults.data(forKey: "ff_local_progress.sessions.v1_\(namespace)") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let sessions = try? decoder.decode([ProgressSession].self, from: sessionsData) {
                    ProgressStore.shared.applyMergedSessions(sessions)
                    #if DEBUG
                    print("[GuestMigrationManager] Applied \(sessions.count) sessions to in-memory store")
                    #endif
                }
            }
            
            // Load and apply migrated tasks (including completions)
            if let tasksData = defaults.data(forKey: "focusflow_tasks_state_cloud_\(namespace)") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let state = try? decoder.decode(TasksStore.LocalState.self, from: tasksData) {
                    // IMPORTANT: Mark timestamps BEFORE applying state, so conflict resolution can find them
                    for task in state.tasks {
                        LocalTimestampTracker.shared.recordLocalChange(field: "task_\(task.id.uuidString)", namespace: namespace)
                    }
                    // Mark completion timestamps (format: "taskID|year-month-day")
                    for completionKey in state.completedKeys {
                        if let taskIDString = completionKey.split(separator: "|").first,
                           let taskID = UUID(uuidString: String(taskIDString)) {
                            LocalTimestampTracker.shared.recordLocalChange(field: "task_completion_\(taskID.uuidString)", namespace: namespace)
                        }
                    }
                    
                    TasksStore.shared.applyRemoteState(tasks: state.tasks, completionKeys: Set(state.completedKeys))
                    // IMPORTANT: Manually save after applyRemoteState (it sets isApplyingState which blocks auto-save)
                    TasksStore.shared.save()
                    #if DEBUG
                    print("[GuestMigrationManager] Applied \(state.tasks.count) tasks with \(state.completedKeys.count) completions to in-memory store and persisted")
                    print("[GuestMigrationManager] Marked timestamps for \(state.tasks.count) tasks and \(state.completedKeys.count) completions")
                    #endif
                }
            }
            
            // Load and apply migrated presets
            if let presetsData = defaults.data(forKey: "ff_focus_presets_\(namespace)") {
                if let presets = try? JSONDecoder().decode([FocusPreset].self, from: presetsData) {
                    FocusPresetStore.shared.applyRemoteState(presets: presets, activePresetId: nil)
                    #if DEBUG
                    print("[GuestMigrationManager] Applied \(presets.count) presets to in-memory store")
                    #endif
                }
            }
            
            // IMPORTANT: Reload AppSettings to apply migrated settings (theme, sound, etc.)
            // Since namespace hasn't changed, manually reload from UserDefaults
            let settings = AppSettings.shared
            let settingsDefaults = UserDefaults.standard
            
            // Reload display name
            if let displayName = settingsDefaults.string(forKey: "ff_displayName_\(namespace)"),
               !displayName.isEmpty {
                settings.displayName = displayName
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated display name: \(displayName)")
                #endif
            }
            
            // Reload tagline
            if let tagline = settingsDefaults.string(forKey: "ff_tagline_\(namespace)"),
               !tagline.isEmpty {
                settings.tagline = tagline
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated tagline: \(tagline)")
                #endif
            }
            
            // Reload avatar ID
            if let avatarID = settingsDefaults.string(forKey: "ff_avatarID_\(namespace)"),
               !avatarID.isEmpty {
                settings.avatarID = avatarID
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated avatar ID: \(avatarID)")
                #endif
            }
            
            // Reload profile image
            if let profileImageData = settingsDefaults.data(forKey: "ff_profileImageData_\(namespace)") {
                settings.profileImageData = profileImageData
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated profile image")
                #endif
            }
            
            // Reload theme (read from migrated user namespace key)
            if let themeRaw = settingsDefaults.string(forKey: "ff_selectedTheme_\(namespace)"),
               let theme = AppTheme(rawValue: themeRaw) {
                // Temporarily disable timestamp tracking to avoid sync conflicts
                settings.selectedTheme = theme
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated theme: \(themeRaw)")
                #endif
            }
            
            // Reload profile theme
            if let profileThemeRaw = settingsDefaults.string(forKey: "ff_profileTheme_\(namespace)"),
               let profileTheme = AppTheme(rawValue: profileThemeRaw) {
                settings.profileTheme = profileTheme
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated profile theme: \(profileThemeRaw)")
                #endif
            }
            
            // Reload sound preference
            if let soundRaw = settingsDefaults.string(forKey: "ff_selectedFocusSound_\(namespace)"),
               let sound = FocusSound(rawValue: soundRaw) {
                settings.selectedFocusSound = sound
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated sound: \(soundRaw)")
                #endif
            }
            
            // Reload external music app
            if let musicAppRaw = settingsDefaults.string(forKey: "ff_externalMusicApp_\(namespace)"),
               let musicApp = AppSettings.ExternalMusicApp(rawValue: musicAppRaw) {
                settings.selectedExternalMusicApp = musicApp
                #if DEBUG
                print("[GuestMigrationManager] Applied migrated music app: \(musicAppRaw)")
                #endif
            }
            
            // Reload other settings
            if let soundEnabled = settingsDefaults.object(forKey: "ff_soundEnabled_\(namespace)") as? Bool {
                settings.soundEnabled = soundEnabled
            }
            if let hapticsEnabled = settingsDefaults.object(forKey: "ff_hapticsEnabled_\(namespace)") as? Bool {
                settings.hapticsEnabled = hapticsEnabled
            }
            if let dailyReminderEnabled = settingsDefaults.object(forKey: "ff_dailyReminderEnabled_\(namespace)") as? Bool {
                settings.dailyReminderEnabled = dailyReminderEnabled
            }
            if let askToRecord = settingsDefaults.object(forKey: "ff_askToRecordIncompleteSessions_\(namespace)") as? Bool {
                settings.askToRecordIncompleteSessions = askToRecord
            }
            
            // Reload reminder time
            if let hour = settingsDefaults.object(forKey: "ff_reminderHour_\(namespace)") as? Int,
               let minute = settingsDefaults.object(forKey: "ff_reminderMinute_\(namespace)") as? Int {
                let comps = DateComponents(hour: hour, minute: minute)
                if let date = Calendar.current.date(from: comps) {
                    settings.dailyReminderTime = date
                }
            }
            
            #if DEBUG
            print("[GuestMigrationManager] Reloaded AppSettings to apply migrated preferences")
            #endif
        }
        
        // 7. Wait a bit for UI to update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // 8. Push migrated data to cloud FIRST (before any pull can happen)
        #if DEBUG
        print("[GuestMigrationManager] Pushing migrated data to cloud...")
        #endif
        await SyncCoordinator.shared.forcePushAllPending()
        
        // 9. Wait for push to complete, then mark timestamps to prevent overwrite
        try? await Task.sleep(nanoseconds: 1000_000_000) // 1 second
        
        // 10. Mark all migrated data as "just updated" to prevent cloud from overwriting
        // (Tasks and completions are already marked in step 6, so just mark sessions here)
        await MainActor.run {
            let namespace = namespace
            // Mark sessions as recently changed
            if let sessionsData = defaults.data(forKey: "ff_local_progress.sessions.v1_\(namespace)") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let sessions = try? decoder.decode([ProgressSession].self, from: sessionsData) {
                    for session in sessions {
                        LocalTimestampTracker.shared.recordLocalChange(field: "session_\(session.id.uuidString)", namespace: namespace)
                    }
                    #if DEBUG
                    print("[GuestMigrationManager] Marked \(sessions.count) sessions with timestamps")
                    #endif
                }
            }
            #if DEBUG
            print("[GuestMigrationManager] Marked migrated data timestamps to prevent cloud overwrite")
            #endif
        }
        
        // 11. DON'T pull immediately - the migrated data should take precedence
        // The next time the user opens the app, a pull will happen naturally
        #if DEBUG
        print("[GuestMigrationManager] Skipping pull to preserve migrated data")
        #endif
        
        #if DEBUG
        print("[GuestMigrationManager] Selective migration completed successfully")
        #endif
    }
    
    // MARK: - Individual Migration Methods (Merge, Never Replace)
    
    private func migrateSessions(to namespace: String) async throws {
        let guestSessionsKey = "ff_local_progress.sessions.v1_guest"
        let userSessionsKey = "ff_local_progress.sessions.v1_\(namespace)"
        
        // Get guest sessions from UserDefaults
        var guestSessions: [ProgressSession] = []
        
        if let guestSessionsData = defaults.data(forKey: guestSessionsKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([ProgressSession].self, from: guestSessionsData) {
                guestSessions = decoded
                #if DEBUG
                print("[GuestMigrationManager] Found \(guestSessions.count) sessions to migrate")
                #endif
            } else {
                #if DEBUG
                print("[GuestMigrationManager] Failed to decode sessions from UserDefaults")
                #endif
            }
        } else {
            #if DEBUG
            print("[GuestMigrationManager] No sessions data in UserDefaults for key: \(guestSessionsKey)")
            #endif
        }
        
        guard !guestSessions.isEmpty else {
            #if DEBUG
            print("[GuestMigrationManager] No guest sessions to migrate")
            #endif
            return
        }
        
        // Load existing user sessions (with proper date decoding)
        var existingSessions: [ProgressSession] = []
        if let existingData = defaults.data(forKey: userSessionsKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([ProgressSession].self, from: existingData) {
                existingSessions = decoded
            }
        }
        
        // Merge: add guest sessions that don't already exist (by ID)
        let existingIds = Set(existingSessions.map { $0.id })
        let newSessions = guestSessions.filter { !existingIds.contains($0.id) }
        let mergedSessions = existingSessions + newSessions
        
        // Save merged sessions (with proper date encoding)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(mergedSessions) {
            defaults.set(encoded, forKey: userSessionsKey)
            #if DEBUG
            print("[GuestMigrationManager] ✅ Migrated \(newSessions.count) new sessions (merged with \(existingSessions.count) existing)")
            #endif
        } else {
            #if DEBUG
            print("[GuestMigrationManager] Failed to encode merged sessions")
            #endif
        }
    }
    
    private func migrateTasks(to namespace: String) async throws {
        let guestTasksKey = "focusflow_tasks_state_guest"
        let userTasksKey = "focusflow_tasks_state_cloud_\(namespace)"
        
        guard let guestTasksData = defaults.data(forKey: guestTasksKey) else {
            #if DEBUG
            print("[GuestMigrationManager] No guest tasks data found")
            #endif
            return
        }
        
        // Decode with date strategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let guestState = try? decoder.decode(TasksStore.LocalState.self, from: guestTasksData),
              !guestState.tasks.isEmpty else {
            #if DEBUG
            print("[GuestMigrationManager] Failed to decode guest tasks or tasks are empty")
            #endif
            return
        }
        
        // Load existing user tasks
        var existingState = TasksStore.LocalState(tasks: [], completedKeys: [])
        if let existingData = defaults.data(forKey: userTasksKey) {
            let userDecoder = JSONDecoder()
            userDecoder.dateDecodingStrategy = .iso8601
            if let decoded = try? userDecoder.decode(TasksStore.LocalState.self, from: existingData) {
                existingState = decoded
            }
        }
        
        // Merge tasks: add guest tasks that don't already exist (by ID)
        let existingTaskIds = Set(existingState.tasks.map { $0.id })
        let newTasks = guestState.tasks.filter { !existingTaskIds.contains($0.id) }
        let mergedTasks = existingState.tasks + newTasks
        
        // Merge completed occurrences (union of both sets)
        let mergedCompletions = Set(existingState.completedKeys)
            .union(guestState.completedKeys)
        
        // Save merged state
        let mergedState = TasksStore.LocalState(tasks: mergedTasks, completedKeys: Array(mergedCompletions))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(mergedState) {
            defaults.set(encoded, forKey: userTasksKey)
            #if DEBUG
            print("[GuestMigrationManager] Migrated \(newTasks.count) new tasks (merged with \(existingState.tasks.count) existing)")
            #endif
        } else {
            #if DEBUG
            print("[GuestMigrationManager] Failed to encode merged tasks")
            #endif
        }
    }
    
    private func migratePresets(to namespace: String) async throws {
        let guestPresetsKey = "ff_focus_presets_guest"
        let userPresetsKey = "ff_focus_presets_\(namespace)"
        
        guard let guestPresetsData = defaults.data(forKey: guestPresetsKey),
              let guestPresets = try? JSONDecoder().decode([FocusPreset].self, from: guestPresetsData),
              !guestPresets.isEmpty else {
            #if DEBUG
            print("[GuestMigrationManager] No guest presets to migrate")
            #endif
            return
        }
        
        // Migrate ALL guest presets (including system defaults that may have been modified)
        // This replaces the new account's default presets with the guest's versions
        // which preserves any customizations the user made to duration, theme, sound, etc.
        
        if let encoded = try? JSONEncoder().encode(guestPresets) {
            defaults.set(encoded, forKey: userPresetsKey)
            let customCount = guestPresets.filter { !$0.isSystemDefault }.count
            let systemCount = guestPresets.filter { $0.isSystemDefault }.count
            #if DEBUG
            print("[GuestMigrationManager] Migrated \(guestPresets.count) presets (\(systemCount) system, \(customCount) custom)")
            #endif
        }
    }
    
    private func migrateDailyGoal(to namespace: String) async throws {
        let guestGoalKey = "ff_local_progress.goalMinutes.v1_guest"
        let userGoalKey = "ff_local_progress.goalMinutes.v1_\(namespace)"
        
        let guestGoal = defaults.integer(forKey: guestGoalKey)
        guard guestGoal > 0 && guestGoal != 60 else {
            return
        }
        
        // Only migrate if user doesn't already have a custom goal
        let existingGoal = defaults.integer(forKey: userGoalKey)
        if existingGoal == 0 || existingGoal == 60 {
            // User has default goal, migrate guest goal
            defaults.set(guestGoal, forKey: userGoalKey)
            #if DEBUG
            print("[GuestMigrationManager] Migrated daily goal: \(guestGoal) minutes")
            #endif
        } else {
            // User already has a custom goal, keep it (don't overwrite)
            #if DEBUG
            print("[GuestMigrationManager] User already has custom goal (\(existingGoal)), keeping it instead of migrating guest goal")
            #endif
        }
    }
    
    private func migrateSettings(to namespace: String) async throws {
        #if DEBUG
        print("[GuestMigrationManager] Starting settings migration...")
        #endif
        
        // Settings keys to migrate - ALWAYS migrate if guest has them (user explicitly chose to migrate)
        let settingsToMigrate = [
            "ff_selectedTheme",
            "ff_profileTheme",
            "ff_selectedFocusSound",
            "ff_externalMusicApp",
            "ff_soundEnabled",
            "ff_hapticsEnabled",
            "ff_dailyReminderEnabled",
            "ff_reminderHour",
            "ff_reminderMinute",
            "ff_askToRecordIncompleteSessions"
        ]
        
        var migratedCount = 0
        
        for baseKey in settingsToMigrate {
            let guestKey = "\(baseKey)_guest"
            let userKey = "\(baseKey)_\(namespace)"
            
            // Check if guest has this setting
            guard let guestValue = defaults.object(forKey: guestKey) else { continue }
            
            // ALWAYS migrate (overwrite user's defaults with guest's preferences)
            defaults.set(guestValue, forKey: userKey)
            migratedCount += 1
            #if DEBUG
            print("[GuestMigrationManager] Migrated setting: \(baseKey) = \(guestValue)")
            #endif
        }
        
        // Migrate profile image - ALWAYS migrate if guest has it
        let guestImageKey = "ff_profileImageData_guest"
        let userImageKey = "ff_profileImageData_\(namespace)"
        if let guestImageData = defaults.data(forKey: guestImageKey) {
            defaults.set(guestImageData, forKey: userImageKey)
            migratedCount += 1
            #if DEBUG
            print("[GuestMigrationManager] Migrated profile image")
            #endif
        }
        
        // Migrate display name - ALWAYS migrate if guest has it (user explicitly chose to migrate)
        let guestNameKey = "ff_displayName_guest"
        let userNameKey = "ff_displayName_\(namespace)"
        if let guestName = defaults.string(forKey: guestNameKey),
           !guestName.isEmpty {
            defaults.set(guestName, forKey: userNameKey)
            migratedCount += 1
            #if DEBUG
            print("[GuestMigrationManager] Migrated display name: \(guestName)")
            #endif
        }
        
        // Migrate tagline - ALWAYS migrate if guest has it
        let guestTaglineKey = "ff_tagline_guest"
        let userTaglineKey = "ff_tagline_\(namespace)"
        if let guestTagline = defaults.string(forKey: guestTaglineKey),
           !guestTagline.isEmpty {
            defaults.set(guestTagline, forKey: userTaglineKey)
            migratedCount += 1
            #if DEBUG
            print("[GuestMigrationManager] Migrated tagline: \(guestTagline)")
            #endif
        }
        
        // Migrate avatar ID - ALWAYS migrate if guest has it
        let guestAvatarKey = "ff_avatarID_guest"
        let userAvatarKey = "ff_avatarID_\(namespace)"
        if let guestAvatar = defaults.string(forKey: guestAvatarKey),
           !guestAvatar.isEmpty {
            defaults.set(guestAvatar, forKey: userAvatarKey)
            migratedCount += 1
            #if DEBUG
            print("[GuestMigrationManager] Migrated avatar ID: \(guestAvatar)")
            #endif
        }
        
        #if DEBUG
        print("[GuestMigrationManager] Settings migration complete: \(migratedCount) settings migrated")
        #endif
    }
    
    // MARK: - Errors
    
    enum MigrationError: LocalizedError {
        case notSignedIn
        case noDataToMigrate
        
        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "You must be signed in to migrate data"
            case .noDataToMigrate:
                return "No guest data available to migrate"
            }
        }
    }
}
