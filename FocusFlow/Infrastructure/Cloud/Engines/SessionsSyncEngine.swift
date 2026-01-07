//
//  SessionsSyncEngine.swift
//  FocusFlow
//
//  Syncs ProgressSession ↔ focus_sessions table
//  Updates user_stats table with aggregated data
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `focus_sessions` table schema
struct FocusSessionDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var startedAt: Date
    var durationSeconds: Int
    var sessionName: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case durationSeconds = "duration_seconds"
        case sessionName = "session_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `user_stats` table schema
struct UserStatsDTO: Codable {
    let userId: UUID
    var lifetimeFocusSeconds: Int
    var lifetimeSessionCount: Int
    var lifetimeBestStreak: Int
    var currentStreak: Int
    var lastFocusDate: String? // Date as "YYYY-MM-DD"
    var totalXp: Int
    var currentLevel: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lifetimeFocusSeconds = "lifetime_focus_seconds"
        case lifetimeSessionCount = "lifetime_session_count"
        case lifetimeBestStreak = "lifetime_best_streak"
        case currentStreak = "current_streak"
        case lastFocusDate = "last_focus_date"
        case totalXp = "total_xp"
        case currentLevel = "current_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class SessionsSyncEngine {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?

    private var isApplyingRemote = false

    /// Track which session IDs we've already synced
    private var syncedSessionIds = Set<UUID>()

    // MARK: - Start/Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        // Initial pull
        try await pullFromRemote(userId: userId)

        // Observe local changes
        observeLocalChanges()
    }

    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
        syncedSessionIds.removeAll()
    }

    // MARK: - Pull from Remote

    func pullFromRemote(userId: UUID) async throws {
        // ✅ CRITICAL: Set userId in case pullFromRemote is called directly (non-Pro initial pull)
        self.userId = userId
        
        let client = SupabaseManager.shared.client

        // Fetch all sessions
        let remoteSessions: [FocusSessionDTO] = try await client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .execute()
            .value

        // Fetch user stats (optional - may not exist yet)
        let remoteStats: UserStatsDTO? = try? await client
            .from("user_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        applyRemoteToLocal(sessions: remoteSessions, stats: remoteStats)

        // Track synced IDs
        syncedSessionIds = Set(remoteSessions.map { $0.id })

        #if DEBUG
        print("[SessionsSyncEngine] Pulled \(remoteSessions.count) sessions")
        #endif
    }

    // MARK: - Push Single Session

    /// Push a newly completed session to remote
    func pushSession(_ session: ProgressSession) async {
        guard isRunning, let userId = userId else { return }
        guard !syncedSessionIds.contains(session.id) else { return }

        let dto = FocusSessionDTO(
            id: session.id,
            userId: userId,
            startedAt: session.date,
            durationSeconds: Int(session.duration),
            sessionName: session.sessionName
        )

        do {
            try await SupabaseManager.shared.client
                .from("focus_sessions")
                .insert(dto)
                .execute()

            syncedSessionIds.insert(session.id)
            
            // ✅ Clear local timestamp after successful push
            let namespace = userId.uuidString
            LocalTimestampTracker.shared.clearLocalTimestamp(field: "session_\(session.id.uuidString)", namespace: namespace)

            // Update stats after adding session
            await updateRemoteStats()

            #if DEBUG
            print("[SessionsSyncEngine] Pushed session \(session.id)")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Push session error: \(error)")
            #endif
        }
    }

    // MARK: - Update Remote Stats

    private func updateRemoteStats() async {
        guard let userId = userId else { return }

        let store = ProgressStore.shared

        // ProgressStore computes these as derived properties
        let dto = UserStatsDTO(
            userId: userId,
            lifetimeFocusSeconds: Int(store.lifetimeFocusSeconds),
            lifetimeSessionCount: store.lifetimeSessionCount,
            lifetimeBestStreak: store.lifetimeBestStreak,
            currentStreak: 0, // TODO: Compute current streak
            lastFocusDate: lastFocusDateString(from: store),
            totalXp: 0, // TODO: XP system
            currentLevel: 1 // TODO: Level system
        )

        do {
            try await SupabaseManager.shared.client
                .from("user_stats")
                .upsert(dto, onConflict: "user_id")
                .execute()

            #if DEBUG
            print("[SessionsSyncEngine] Updated remote stats")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Stats update error: \(error)")
            #endif
        }
    }

    private func lastFocusDateString(from store: ProgressStore) -> String? {
        guard let lastSession = store.sessions.first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: lastSession.date)
    }

    // MARK: - Push All Local (for migration)

    /// Push all local sessions to remote (used for initial sync after sign-in)
    func pushAllLocalSessions() async {
        guard isRunning, let userId = userId else { return }

        let store = ProgressStore.shared
        let localSessions = store.sessions

        // Filter out already synced
        let newSessions = localSessions.filter { !syncedSessionIds.contains($0.id) }
        guard !newSessions.isEmpty else { return }

        let dtos = newSessions.map { session in
            FocusSessionDTO(
                id: session.id,
                userId: userId,
                startedAt: session.date,
                durationSeconds: Int(session.duration),
                sessionName: session.sessionName
            )
        }

        do {
            try await SupabaseManager.shared.client
                .from("focus_sessions")
                .upsert(dtos, onConflict: "id")
                .execute()

            syncedSessionIds.formUnion(newSessions.map { $0.id })
            await updateRemoteStats()

            #if DEBUG
            print("[SessionsSyncEngine] Pushed \(newSessions.count) local sessions to remote")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Push all error: \(error)")
            #endif
        }
    }
    
    // MARK: - Merge All Sessions (UNION Strategy)
    
    /// ✅ NEW: Merge strategy for resubscription - UNION all sessions
    /// This ensures no sessions are ever lost when user resubscribes after a gap.
    /// Strategy: Combine all sessions from both local and remote (no duplicates by ID)
    func mergeAllSessions(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true
        
        let client = SupabaseManager.shared.client
        let store = ProgressStore.shared
        
        #if DEBUG
        print("[SessionsSyncEngine] 🔄 Starting UNION merge for sessions...")
        #endif
        
        // Step 1: Fetch all remote sessions
        let remoteSessions: [FocusSessionDTO] = try await client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .execute()
            .value
        
        #if DEBUG
        print("[SessionsSyncEngine] Remote has \(remoteSessions.count) sessions")
        print("[SessionsSyncEngine] Local has \(store.sessions.count) sessions")
        #endif
        
        // Step 2: Build a map of all sessions by ID (UNION)
        var sessionMap: [UUID: ProgressSession] = [:]
        
        // Add all remote sessions first
        for dto in remoteSessions {
            let session = ProgressSession(
                id: dto.id,
                date: dto.startedAt,
                duration: TimeInterval(dto.durationSeconds),
                sessionName: dto.sessionName
            )
            sessionMap[dto.id] = session
        }
        
        // Add/merge local sessions (local wins for duplicates since user was using locally)
        for local in store.sessions {
            if let existing = sessionMap[local.id] {
                // Session exists in both - keep local if it has more info or is newer
                // For sessions, we prefer local since user was actively using the app
                if local.duration > 0 {
                    sessionMap[local.id] = local
                    #if DEBUG
                    print("[SessionsSyncEngine] Keeping local version of session \(local.id)")
                    #endif
                }
            } else {
                // Local-only session - add it (this is data created while user was free)
                sessionMap[local.id] = local
                #if DEBUG
                print("[SessionsSyncEngine] Adding local-only session \(local.id) to merge")
                #endif
            }
        }
        
        // Step 3: Sort by date (newest first)
        let mergedSessions = Array(sessionMap.values).sorted { $0.date > $1.date }
        
        #if DEBUG
        print("[SessionsSyncEngine] Merged total: \(mergedSessions.count) sessions")
        #endif
        
        // Step 4: Apply merged sessions to local store
        store.applyMergedSessions(mergedSessions)
        
        // Step 5: Push all local-only sessions to remote
        let remoteIds = Set(remoteSessions.map { $0.id })
        let localOnlySessions = mergedSessions.filter { !remoteIds.contains($0.id) }
        
        if !localOnlySessions.isEmpty {
            let dtos = localOnlySessions.map { session in
                FocusSessionDTO(
                    id: session.id,
                    userId: userId,
                    startedAt: session.date,
                    durationSeconds: Int(session.duration),
                    sessionName: session.sessionName
                )
            }
            
            try await client
                .from("focus_sessions")
                .upsert(dtos, onConflict: "id")
                .execute()
            
            #if DEBUG
            print("[SessionsSyncEngine] Pushed \(localOnlySessions.count) local-only sessions to remote")
            #endif
        }
        
        // Step 6: Update remote stats
        await updateRemoteStats()
        
        // Track all synced IDs
        syncedSessionIds = Set(mergedSessions.map { $0.id })
        
        #if DEBUG
        print("[SessionsSyncEngine] ✅ UNION merge complete - \(mergedSessions.count) total sessions")
        #endif
    }

    // MARK: - Apply Remote to Local

    private func applyRemoteToLocal(sessions: [FocusSessionDTO], stats: UserStatsDTO?) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let store = ProgressStore.shared
        guard let userId = userId else { return }
        let namespace = userId.uuidString

        // ✅ NEW: Merge remote sessions with local, preserving newer local changes
        var mergedSessions: [ProgressSession] = []
        
        // Start with local sessions
        var localSessionsMap: [UUID: ProgressSession] = Dictionary(uniqueKeysWithValues: store.sessions.map { ($0.id, $0) })
        
        // Process remote sessions
        for dto in sessions {
            let remoteSession = ProgressSession(
                id: dto.id,
                date: dto.startedAt,
                duration: TimeInterval(dto.durationSeconds),
                sessionName: dto.sessionName
            )
            
            // Check if local version is newer
            let fieldKey = "session_\(dto.id.uuidString)"
            let remoteTimestamp = dto.updatedAt ?? dto.createdAt
            
            if let localSession = localSessionsMap[dto.id] {
                // Session exists locally - check if local is newer
                if LocalTimestampTracker.shared.isLocalNewer(field: fieldKey, namespace: namespace, remoteTimestamp: remoteTimestamp) {
                    // Local is newer - keep local version
                    mergedSessions.append(localSession)
                    #if DEBUG
                    print("[SessionsSyncEngine] Keeping local session \(localSession.id) (local is newer)")
                    #endif
                } else {
                    // Remote is newer or same - use remote
                    mergedSessions.append(remoteSession)
                    LocalTimestampTracker.shared.clearLocalTimestamp(field: fieldKey, namespace: namespace)
                    #if DEBUG
                    print("[SessionsSyncEngine] Using remote session \(remoteSession.id) (remote is newer)")
                    #endif
                }
            } else {
                // New session from remote - add it
                mergedSessions.append(remoteSession)
                #if DEBUG
                print("[SessionsSyncEngine] Adding new remote session \(remoteSession.id)")
                #endif
            }
            
            // Remove from local map (so we know which local sessions weren't in remote)
            localSessionsMap.removeValue(forKey: dto.id)
        }
        
        // Add any local sessions that weren't in remote (if they're newer)
        for (_, localSession) in localSessionsMap {
            let fieldKey = "session_\(localSession.id.uuidString)"
            // If local session has a timestamp, it means it was created locally
            // Keep it even if not in remote (it will be pushed on next sync)
            if LocalTimestampTracker.shared.getLocalTimestamp(field: fieldKey, namespace: namespace) != nil {
                mergedSessions.append(localSession)
                #if DEBUG
                print("[SessionsSyncEngine] Keeping local-only session \(localSession.id) (will be pushed)")
                #endif
            }
        }
        
        // Sort by date (newest first)
        mergedSessions.sort { $0.date > $1.date }
        
        // Apply merged state using public method
        store.applyMergedSessions(mergedSessions)

        #if DEBUG
        print("[SessionsSyncEngine] Applied \(mergedSessions.count) sessions to local (with conflict resolution)")
        #endif
    }

    // MARK: - Push to Remote
    
    /// Force push immediately (bypasses debounce) - used by sync queue
    func forcePushNow() async {
        await pushToRemote()
    }
    
    private func pushToRemote() async {
        guard isRunning, userId != nil else { return }
        guard !isApplyingRemote else { return }
        
        let store = ProgressStore.shared
        
        // Push all local sessions that haven't been synced
        let unsyncedSessions = store.sessions.filter { !syncedSessionIds.contains($0.id) }
        
        for session in unsyncedSessions {
            await pushSession(session)
        }
        
        // Update stats
        await updateRemoteStats()
    }
    
    // MARK: - Observe Local Changes
    
    private func observeLocalChanges() {
        let store = ProgressStore.shared

        // Observe sessions array changes
        store.$sessions
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced to 0.5s for faster sync
            .sink { [weak self] sessions in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }

                // ✅ NEW: Enqueue new sessions in sync queue
                Task { @MainActor in
                    guard let userId = AuthManagerV2.shared.state.userId else { return }
                    let namespace = userId.uuidString
                    
                    // Find new sessions
                    let newSessions = sessions.filter { !self.syncedSessionIds.contains($0.id) }
                    for session in newSessions {
                        if let timestamp = LocalTimestampTracker.shared.getLocalTimestamp(
                            field: "session_\(session.id.uuidString)",
                            namespace: namespace
                        ) {
                            SyncQueue.shared.enqueueSessionChange(
                                operation: .create,
                                session: session,
                                localTimestamp: timestamp
                            )
                        }
                    }
                    
                    // Process queue (will push if online)
                    await SyncQueue.shared.processQueue()
                }
            }
            .store(in: &cancellables)
    }
}

// Note:
// ProgressStore already implements `mergeRemoteSessions(_:)` and
// `applyRemoteSessionState(_:)` in Features/Progress/ProgressStore.swift.
// (Keeping those helpers in one place avoids duplicate symbol / redeclaration errors.)
