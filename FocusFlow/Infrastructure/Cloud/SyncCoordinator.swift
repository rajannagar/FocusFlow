//
//  SyncCoordinator.swift
//  FocusFlow
//
//  Orchestrates sync engines based on authentication state.
//  Starts/stops engines when user signs in/out.
//  ✅ PRO GATING: Sync requires Pro subscription + signed in.
//  ✅ MERGE STRATEGY: When resubscribing after >7 days, merges local+remote data.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SyncCoordinator: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SyncCoordinator()
    
    // MARK: - Sync Engines
    
    private let settingsEngine = SettingsSyncEngine()
    private let tasksEngine = TasksSyncEngine()
    private let sessionsEngine = SessionsSyncEngine()
    private let presetsEngine = PresetsSyncEngine()
    
    // MARK: - State
    
    @Published private(set) var isSyncing = false
    @Published private(set) var isMerging = false  // ✅ NEW: Track merge state separately
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: Error?
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var periodicSyncTask: Task<Void, Never>?
    
    // ✅ Track last push time to prevent immediate pulls after push
    private var lastPushTime: Date = Date.distantPast
    
    // ✅ NEW: Persist last successful sync date for merge detection
    @AppStorage("ff_lastSuccessfulSyncTimestamp") private var lastSuccessfulSyncTimestamp: Double = 0
    
    // ✅ NEW: Days threshold to trigger merge sync (when gap is larger than this)
    private let mergeTriggerDays = 7
    
    // MARK: - Init
    
    private init() {
        observeAuthState()
        observeProStatus()  // ✅ NEW: Observe Pro status changes
        // Don't start periodic sync here - it will start when engines start
    }
    
    // MARK: - Periodic Sync
    
    /// Start periodic sync to detect changes from other devices
    /// Syncs every 60 seconds when app is active and user is signed in
    /// Has cooldown to prevent loops after pushes
    private func startPeriodicSync() {
        // Cancel any existing periodic sync
        periodicSyncTask?.cancel()
        
        // Start new periodic sync
        periodicSyncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // ✅ Increased to 60 seconds
                
                // Only sync if app is running and user is signed in
                guard isRunning, AuthManagerV2.shared.state.userId != nil else { continue }
                
                // ✅ Don't pull if we just pushed in the last 15 seconds (cooldown)
                let timeSinceLastPush = Date().timeIntervalSince(lastPushTime)
                guard timeSinceLastPush > 15 else {
                    #if DEBUG
                    print("[SyncCoordinator] Skipping periodic pull - cooldown active (pushed \(Int(timeSinceLastPush))s ago)")
                    #endif
                    continue
                }
                
                // Pull latest changes from remote
                await pullFromRemote()
            }
        }
    }
    
    private func stopPeriodicSync() {
        periodicSyncTask?.cancel()
        periodicSyncTask = nil
    }
    
    // MARK: - Auth State Observation
    
    private func observeAuthState() {
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Pro Status Observation
    
    /// ✅ NEW: Observe Pro subscription status changes
    /// Handles: Free → Pro (start sync with merge), Pro → Free (stop sync)
    private func observeProStatus() {
        ProEntitlementManager.shared.$isPro
            .dropFirst() // Skip initial value (handled by auth state)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                self?.handleProStatusChange(isPro: isPro)
            }
            .store(in: &cancellables)
    }
    
    /// ✅ NEW: Handle Pro → Free or Free → Pro transitions
    private func handleProStatusChange(isPro: Bool) {
        #if DEBUG
        print("[SyncCoordinator] Pro status changed: \(isPro)")
        #endif
        
        if isPro && AuthManagerV2.shared.state.isSignedIn {
            // User just got Pro while signed in - start sync with merge if needed
            if let userId = AuthManagerV2.shared.state.userId, !isRunning {
                Task {
                    await startSyncWithMergeIfNeeded(userId: userId)
                }
            }
        } else if !isPro && isRunning {
            // User lost Pro - stop sync gracefully
            #if DEBUG
            print("[SyncCoordinator] Pro expired - stopping sync")
            #endif
            stopAllEngines()
        }
    }
    
    private func handleAuthStateChange(_ state: CloudAuthState) {
        switch state {
        case .unknown:
            // Still loading, do nothing
            break
            
        case .guest:
            // Guest mode - stop all sync
            stopAllEngines()
            #if DEBUG
            print("[SyncCoordinator] Guest mode - sync disabled")
            #endif
            
        case .signedIn(let userId):
            // ✅ MODIFIED: Only start sync if user has Pro
            if ProGatingHelper.shared.isPro {
                Task {
                    await startSyncWithMergeIfNeeded(userId: userId)
                }
                #if DEBUG
                print("[SyncCoordinator] Signed in with Pro - starting sync for \(userId)")
                #endif
            } else {
                #if DEBUG
                print("[SyncCoordinator] Signed in but no Pro - sync disabled")
                #endif
            }
            
        case .signedOut:
            // Signed out - stop all sync
            stopAllEngines()
            #if DEBUG
            print("[SyncCoordinator] Signed out - sync stopped")
            #endif
        }
    }
    
    // MARK: - Engine Control
    
    /// ✅ NEW: Check if merge is needed and start sync accordingly
    private func startSyncWithMergeIfNeeded(userId: UUID) async {
        // Check Pro status first
        guard ProGatingHelper.shared.canUseCloudSync else {
            #if DEBUG
            print("[SyncCoordinator] Cannot sync - requires Pro + SignedIn")
            #endif
            return
        }
        
        guard !isRunning else { return }
        
        // Check gap since last sync
        let lastSync = lastSuccessfulSyncTimestamp > 0 
            ? Date(timeIntervalSince1970: lastSuccessfulSyncTimestamp) 
            : Date.distantPast
        let gapDays = Calendar.current.dateComponents([.day], from: lastSync, to: Date()).day ?? Int.max
        
        #if DEBUG
        print("[SyncCoordinator] Last sync: \(lastSync), gap: \(gapDays) days")
        #endif
        
        if gapDays > mergeTriggerDays && lastSuccessfulSyncTimestamp > 0 {
            // Long gap - perform merge sync to preserve local data
            #if DEBUG
            print("[SyncCoordinator] Gap > \(mergeTriggerDays) days - performing MERGE sync")
            #endif
            await performMergeSync(userId: userId)
        } else {
            // Normal sync
            startAllEngines(userId: userId)
        }
    }
    
    private func startAllEngines(userId: UUID) {
        // ✅ MODIFIED: Check Pro status before starting
        guard ProGatingHelper.shared.canUseCloudSync else {
            #if DEBUG
            print("[SyncCoordinator] Sync disabled - requires Pro subscription")
            #endif
            return
        }
        
        // ✅ Process sync queue when engines start
        Task {
            await SyncQueue.shared.processQueue()
        }
        guard !isRunning else { return }
        isRunning = true
        
        // ✅ Start periodic sync to detect changes from other devices
        startPeriodicSync()
        
        Task {
            await performInitialSync(userId: userId)
        }
    }
    
    private func stopAllEngines() {
        isRunning = false
        stopPeriodicSync()
        settingsEngine.stop()
        tasksEngine.stop()
        sessionsEngine.stop()
        presetsEngine.stop()
    }
    
    // MARK: - Merge Sync (Resubscription)
    
    /// ✅ NEW: Performs merge sync when user resubscribes after a gap
    /// Strategy:
    /// - Sessions: UNION (keep all from both local and remote)
    /// - Tasks: Timestamp merge (keep newer version, local deletions win)
    /// - Presets: Timestamp merge (keep newer version)
    /// - Settings: Local wins (current device preference)
    private func performMergeSync(userId: UUID) async {
        guard !isRunning else { return }
        isRunning = true
        isSyncing = true
        isMerging = true
        syncError = nil
        
        #if DEBUG
        print("[SyncCoordinator] 🔄 Starting MERGE sync for resubscription...")
        #endif
        
        do {
            // Step 1: Settings - Local wins (just push local, then pull for any missing)
            #if DEBUG
            print("[SyncCoordinator] Step 1: Merging settings (local wins)...")
            #endif
            try await settingsEngine.start(userId: userId)
            await settingsEngine.forcePushNow() // Push local settings first
            
            guard isRunning else { return }
            
            // Step 2: Presets - Timestamp merge
            #if DEBUG
            print("[SyncCoordinator] Step 2: Merging presets (timestamp-based)...")
            #endif
            try await presetsEngine.mergeWithRemote(userId: userId)
            
            guard isRunning else { return }
            
            // Step 3: Sessions - UNION (keep all)
            #if DEBUG
            print("[SyncCoordinator] Step 3: Merging sessions (UNION - keep all)...")
            #endif
            try await sessionsEngine.mergeAllSessions(userId: userId)
            
            guard isRunning else { return }
            
            // Step 4: Tasks - Timestamp merge with local deletions winning
            #if DEBUG
            print("[SyncCoordinator] Step 4: Merging tasks (timestamp-based, local deletions win)...")
            #endif
            try await tasksEngine.mergeWithRemote(userId: userId)
            
            // Update last sync timestamp
            lastSyncDate = Date()
            lastSuccessfulSyncTimestamp = Date().timeIntervalSince1970
            
            // Start periodic sync now that merge is complete
            startPeriodicSync()
            
            // Start observing local changes
            try await settingsEngine.start(userId: userId)
            try await presetsEngine.start(userId: userId)
            try await sessionsEngine.start(userId: userId)
            try await tasksEngine.start(userId: userId)
            
            // Sync widgets
            WidgetDataManager.shared.syncAll()
            
            #if DEBUG
            print("[SyncCoordinator] ✅ MERGE sync completed successfully!")
            #endif
            
        } catch {
            syncError = error
            #if DEBUG
            print("[SyncCoordinator] ❌ MERGE sync error: \(error)")
            #endif
        }
        
        isSyncing = false
        isMerging = false
    }
    
    // MARK: - Initial Sync
    
    /// Performs initial sync when user signs in.
    /// Order matters: settings first, then data.
    private func performInitialSync(userId: UUID) async {
        guard isRunning else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Step 1: Sync settings (may affect other syncs)
            try await settingsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 2: Sync presets (needed for sessions)
            try await presetsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 3: Sync sessions
            try await sessionsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 4: Sync tasks and completions
            try await tasksEngine.start(userId: userId)
            
            lastSyncDate = Date()
            
            // ✅ NEW: Record successful sync timestamp for merge detection
            lastSuccessfulSyncTimestamp = Date().timeIntervalSince1970
            
            // ✅ Sync widgets after all remote data is pulled (ensures presets, theme, etc. are up-to-date)
            WidgetDataManager.shared.syncAll()
            
            #if DEBUG
            print("[SyncCoordinator] Initial sync completed successfully")
            #endif
            
        } catch {
            // Check if error is network-related
            let isNetworkError = Self.isNetworkError(error)
            syncError = error
            
            #if DEBUG
            print("[SyncCoordinator] Initial sync error: \(error)")
            if isNetworkError {
                print("[SyncCoordinator] Network error detected - sync requires internet connection")
            }
            #endif
        }
        
        isSyncing = false
    }
    
    // MARK: - Manual Sync
    
    /// Manually trigger a full sync (e.g., on pull-to-refresh)
    func syncNow() async {
        // ✅ MODIFIED: Check Pro status
        guard ProGatingHelper.shared.canUseCloudSync else {
            #if DEBUG
            print("[SyncCoordinator] Cannot sync - requires Pro + SignedIn")
            #endif
            return
        }
        
        guard let userId = AuthManagerV2.shared.state.userId else {
            #if DEBUG
            print("[SyncCoordinator] Cannot sync - not signed in")
            #endif
            return
        }
        
        await performInitialSync(userId: userId)
    }
    
    /// Sync a specific data type (pulls from remote)
    func syncSettings() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await settingsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Settings sync error: \(error)")
            #endif
        }
    }
    
    /// Push settings to remote (without pulling) - used by sync queue
    func pushSettingsOnly() async {
        lastPushTime = Date() // ✅ Record push time
        await settingsEngine.forcePushNow()
    }
    
    /// Push presets to remote (without pulling) - used by sync queue
    func pushPresetsOnly() async {
        lastPushTime = Date() // ✅ Record push time
        await presetsEngine.forcePushNow()
    }
    
    /// Pull all data types from remote (for detecting changes from other devices)
    /// Call this when app becomes active to get latest changes
    func pullFromRemote() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        guard isRunning else { return }
        
        // ✅ Don't pull if we just pushed in the last 10 seconds (cooldown)
        let timeSinceLastPush = Date().timeIntervalSince(lastPushTime)
        guard timeSinceLastPush > 10 else {
            #if DEBUG
            print("[SyncCoordinator] Skipping pull - cooldown active (pushed \(Int(timeSinceLastPush))s ago)")
            #endif
            return
        }
        
        // Pull all data types to get latest changes from other devices
        // This is lightweight - only pulls, doesn't push
        do {
            try await settingsEngine.pullFromRemote(userId: userId)
            try await presetsEngine.pullFromRemote(userId: userId)
            try await tasksEngine.pullFromRemote(userId: userId)
            try await sessionsEngine.pullFromRemote(userId: userId)
            
            #if DEBUG
            print("[SyncCoordinator] Pulled latest changes from remote")
            #endif
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Pull from remote error: \(error)")
            #endif
        }
    }
    
    func syncTasks() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await tasksEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Tasks sync error: \(error)")
            #endif
        }
    }
    
    /// Push tasks to remote (without pulling) - used by sync queue
    func pushTasksOnly() async {
        lastPushTime = Date() // ✅ Record push time
        await tasksEngine.forcePushNow()
    }
    
    /// Push sessions to remote (without pulling) - used by sync queue
    func pushSessionsOnly() async {
        lastPushTime = Date() // ✅ Record push time
        await sessionsEngine.forcePushNow()
    }
    
    /// Delete preset from remote - used by sync queue
    func deletePresetRemote(presetId: UUID) async {
        await presetsEngine.deletePresetRemote(presetId: presetId)
    }
    
    /// Delete task from remote - used by sync queue
    func deleteTaskRemote(taskId: UUID) async {
        await tasksEngine.deleteTaskRemote(taskId: taskId)
    }
    
    func syncSessions() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await sessionsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Sessions sync error: \(error)")
            #endif
        }
    }
    
    func syncPresets() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await presetsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Presets sync error: \(error)")
            #endif
        }
    }
    
    // MARK: - Force Push (for app lifecycle)
    
    /// Force immediate push of all pending changes (bypasses debounce)
    /// Call this when app enters background or is about to terminate
    func forcePushAllPending() async {
        guard AuthManagerV2.shared.state.userId != nil else { return }
        
        // ✅ Record push time to prevent immediate pulls
        lastPushTime = Date()
        
        // Push settings and presets immediately (they use debounce)
        await settingsEngine.forcePushNow()
        await presetsEngine.forcePushNow()
        
        // ✅ Process sync queue to ensure all queued changes are synced
        await SyncQueue.shared.processQueue()
        
        // Tasks and sessions push immediately on change, but we can trigger a push if needed
        // (They don't use debounce, so they should already be synced)
        
        #if DEBUG
        print("[SyncCoordinator] Force pushed all pending changes and processed sync queue")
        #endif
    }
}

// MARK: - Sync Status

extension SyncCoordinator {
    
    /// Human-readable sync status
    var statusMessage: String {
        if isSyncing {
            return "Syncing..."
        }
        
        if let error = syncError {
            if Self.isNetworkError(error) {
                return "Sync failed - No internet connection"
            }
            return "Sync error: \(error.localizedDescription)"
        }
        
        if let date = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        }
        
        return "Not synced"
    }
    
    /// Check if error is network-related
    static func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorCallIsActive,
            NSURLErrorDataNotAllowed
        ]
        return networkErrorCodes.contains(nsError.code)
    }
}
