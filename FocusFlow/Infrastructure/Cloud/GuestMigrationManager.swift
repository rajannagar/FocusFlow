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
        guard let sessionsData = defaults.data(forKey: guestSessionsKey),
              let sessions = try? JSONDecoder().decode([ProgressSession].self, from: sessionsData) else {
            #if DEBUG
            print("[GuestMigrationManager] No sessions found in UserDefaults for key: \(guestSessionsKey)")
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
    
    /// Get count of custom guest presets
    func guestPresetsCount() -> Int {
        // First check in-memory store if we're in guest mode
        if AuthManagerV2.shared.state == .guest {
            let inMemoryPresets = FocusPresetStore.shared.presets.filter { !$0.isSystemDefault }
            if !inMemoryPresets.isEmpty {
                #if DEBUG
                print("[GuestMigrationManager] Found \(inMemoryPresets.count) custom presets in memory")
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
        let customCount = presets.filter { !$0.isSystemDefault }.count
        #if DEBUG
        print("[GuestMigrationManager] Found \(customCount) custom presets in UserDefaults")
        #endif
        return customCount
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
        
        #if DEBUG
        print("[GuestMigrationManager] hasGuestData check: sessions=\(hasSessions), tasks=\(hasTasks), presets=\(hasPresets), goal=\(hasGoal)")
        #endif
        
        return hasSessions || hasTasks || hasPresets || hasGoal
    }
    
    // MARK: - Selective Migration
    
    /// Migration options for selective migration
    struct MigrationOptions {
        var migrateSessions: Bool = false
        var migrateTasks: Bool = false
        var migratePresets: Bool = false
        var migrateDailyGoal: Bool = false
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
        
        // 5. Reload stores to pick up migrated data
        // IMPORTANT: Do this on MainActor since stores are @MainActor
        await MainActor.run {
            #if DEBUG
            print("[GuestMigrationManager] Reloading stores after migration...")
            #endif
            ProgressStore.shared.applyAuthState(AuthManagerV2.shared.state)
            TasksStore.shared.applyAuthState(AuthManagerV2.shared.state)
            FocusPresetStore.shared.applyNamespace(for: AuthManagerV2.shared.state)
        }
        
        // 6. Wait a bit for stores to reload
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // 7. Push migrated data to cloud FIRST (before pulling)
        // This prevents cloud from overwriting our migrated data
        #if DEBUG
        print("[GuestMigrationManager] Pushing migrated data to cloud...")
        #endif
        await SyncCoordinator.shared.forcePushAllPending() // Push migrated data first
        
        // 8. Then pull to merge with any existing cloud data
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        #if DEBUG
        print("[GuestMigrationManager] Pulling from cloud to merge...")
        #endif
        await SyncCoordinator.shared.pullFromRemote() // Pull to merge with cloud
        
        #if DEBUG
        print("[GuestMigrationManager] Selective migration completed successfully")
        #endif
    }
    
    // MARK: - Individual Migration Methods (Merge, Never Replace)
    
    private func migrateSessions(to namespace: String) async throws {
        let guestSessionsKey = "ff_local_progress.sessions.v1_guest"
        let userSessionsKey = "ff_local_progress.sessions.v1_\(namespace)"
        
        // Get guest sessions - try UserDefaults first
        var guestSessions: [ProgressSession] = []
        
        if let guestSessionsData = defaults.data(forKey: guestSessionsKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([ProgressSession].self, from: guestSessionsData) {
                guestSessions = decoded
                #if DEBUG
                print("[GuestMigrationManager] Found \(guestSessions.count) sessions in UserDefaults")
                #endif
            } else {
                #if DEBUG
                print("[GuestMigrationManager] Failed to decode sessions from UserDefaults")
                #endif
            }
        } else {
            #if DEBUG
            print("[GuestMigrationManager] No sessions data in UserDefaults for key: \(guestSessionsKey)")
            // Try to get from in-memory if available (but this won't work after namespace switch)
            #endif
        }
        
        guard !guestSessions.isEmpty else {
            #if DEBUG
            print("[GuestMigrationManager] No guest sessions to migrate (checked UserDefaults key: \(guestSessionsKey))")
            #endif
            return
        }
        
        // Load existing user sessions
        var existingSessions: [ProgressSession] = []
        if let existingData = defaults.data(forKey: userSessionsKey),
           let decoded = try? JSONDecoder().decode([ProgressSession].self, from: existingData) {
            existingSessions = decoded
        }
        
        // Merge: add guest sessions that don't already exist (by ID)
        let existingIds = Set(existingSessions.map { $0.id })
        let newSessions = guestSessions.filter { !existingIds.contains($0.id) }
        let mergedSessions = existingSessions + newSessions
        
        // Save merged sessions
        if let encoded = try? JSONEncoder().encode(mergedSessions) {
            defaults.set(encoded, forKey: userSessionsKey)
            #if DEBUG
            print("[GuestMigrationManager] Migrated \(newSessions.count) new sessions (merged with \(existingSessions.count) existing)")
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
              let guestPresets = try? JSONDecoder().decode([FocusPreset].self, from: guestPresetsData) else {
            return
        }
        
        // Only migrate custom presets (not system defaults)
        let customGuestPresets = guestPresets.filter { !$0.isSystemDefault }
        guard !customGuestPresets.isEmpty else {
            return
        }
        
        // Load existing user presets
        var existingPresets: [FocusPreset] = []
        if let existingData = defaults.data(forKey: userPresetsKey),
           let decoded = try? JSONDecoder().decode([FocusPreset].self, from: existingData) {
            existingPresets = decoded
        }
        
        // Merge: add guest custom presets that don't already exist (by ID)
        let existingPresetIds = Set(existingPresets.map { $0.id })
        let newPresets = customGuestPresets.filter { !existingPresetIds.contains($0.id) }
        let mergedPresets = existingPresets + newPresets
        
        // Save merged presets
        if let encoded = try? JSONEncoder().encode(mergedPresets) {
            defaults.set(encoded, forKey: userPresetsKey)
            #if DEBUG
            print("[GuestMigrationManager] Migrated \(newPresets.count) new presets (merged with \(existingPresets.count) existing)")
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
