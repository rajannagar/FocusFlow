import Foundation
import Combine

final class FocusStatsSyncEngine {

    static let shared = FocusStatsSyncEngine()

    private let sessionsAPI: FocusSessionsAPI
    private let settingsAPI: FocusStatsSettingsAPI
    private let auth: AuthManager

    private let queue = DispatchQueue(label: "FocusStatsSyncEngine.queue", qos: .utility)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Pull/push guards

    private var hasPulledSessionsOnce = false
    private var hasPulledSettingsOnce = false

    private var suppressNextSessionsPush = false
    private var suppressNextSettingsPush = false

    // MARK: - Session delete tracking (tombstones)

    private var activeUserId: UUID?
    private var lastKnownSessionIDs: Set<UUID> = []
    private var pendingSessionDeletes: Set<UUID> = []

    // MARK: - Wiring

    private var started = false

    private var sessionsPublisher: AnyPublisher<[FocusSession], Never>?
    private var settingsPublisher: AnyPublisher<FocusStatsSettingsLocal, Never>?

    private var applyRemoteSessions: (([FocusSession]) -> Void)?
    private var applyRemoteSettings: ((FocusStatsSettingsLocal) -> Void)?

    // MARK: - Logging

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    private func log(_ message: String) {
        let ts = Self.isoFormatter.string(from: Date())
        print("SYNC[STATS] \(ts) \(message)")
    }

    private func describe(_ error: Error) -> String {
        // Try to print the most useful details without changing your error types.
        if let e = error as? FocusSessionsAPIError {
            switch e {
            case .badURL:
                return "badURL"
            case .badResponse(let status, let body):
                return "badResponse(status:\(status), body:\(body))"
            }
        }
        if let e = error as? FocusStatsSettingsAPIError {
            switch e {
            case .badURL:
                return "badURL"
            case .badResponse(let status, let body):
                return "badResponse(status:\(status), body:\(body))"
            }
        }
        return String(describing: error)
    }

    private init(
        sessionsAPI: FocusSessionsAPI = FocusSessionsAPI(),
        settingsAPI: FocusStatsSettingsAPI = FocusStatsSettingsAPI(),
        auth: AuthManager = .shared
    ) {
        self.sessionsAPI = sessionsAPI
        self.settingsAPI = settingsAPI
        self.auth = auth
    }

    // MARK: - Start

    /// Start once. Pass in publishers from your local store (StatsManager) and closures
    /// to apply cloud -> local updates.
    func start(
        sessionsPublisher: AnyPublisher<[FocusSession], Never>,
        settingsPublisher: AnyPublisher<FocusStatsSettingsLocal, Never>,
        applyRemoteSessions: @escaping ([FocusSession]) -> Void,
        applyRemoteSettings: @escaping (FocusStatsSettingsLocal) -> Void
    ) {
        guard !started else { return }
        started = true

        self.sessionsPublisher = sessionsPublisher
        self.settingsPublisher = settingsPublisher
        self.applyRemoteSessions = applyRemoteSessions
        self.applyRemoteSettings = applyRemoteSettings

        // 1) Auth changes -> pull baseline + flush deletes (if possible)
        auth.$state
            .receive(on: queue)
            .sink { [weak self] newState in
                guard let self else { return }
                self.handleAuthStateChange(newState)
                self.pullIfPossible()
                self.flushPendingDeletesIfPossible()
            }
            .store(in: &cancellables)

        // 2) Local sessions changes -> push (after debounce), plus detect deletes
        sessionsPublisher
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: queue)
            .sink { [weak self] sessions in
                self?.handleSessionsChanged(sessions, reason: "sessionsChanged")
            }
            .store(in: &cancellables)

        // 3) Local settings changes -> push (after debounce)
        settingsPublisher
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: queue)
            .sink { [weak self] settings in
                self?.handleSettingsChanged(settings, reason: "settingsChanged")
            }
            .store(in: &cancellables)

        // Boot immediately
        handleAuthStateChange(auth.state)
        pullIfPossible()
        flushPendingDeletesIfPossible()
    }

    // MARK: - Mode control

    func disableSyncAndResetCloudState() {
        // Drop any “current user” state so nothing can leak across accounts
        activeUserId = nil

        hasPulledSessionsOnce = false
        hasPulledSettingsOnce = false

        suppressNextSessionsPush = false
        suppressNextSettingsPush = false

        lastKnownSessionIDs = []
        pendingSessionDeletes = []
    }

    func resetPullState() {
        hasPulledSessionsOnce = false
        hasPulledSettingsOnce = false

        suppressNextSessionsPush = false
        suppressNextSettingsPush = false

        lastKnownSessionIDs = []
    }

    // MARK: - Auth logging + safety reset

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .authenticated(let session):
            if session.isGuest {
                log("mode=GUEST/UNAUTH (sync disabled)")
                disableSyncAndResetCloudState()
                return
            }
            guard let token = session.accessToken, token.isEmpty == false else {
                log("mode=AUTH but missing access token (sync disabled)")
                // Keep state clean so nothing “sticks” until user re-logins.
                disableSyncAndResetCloudState()
                return
            }
            log("mode=AUTH (sync enabled)")
        case .unauthenticated, .unknown:
            log("mode=GUEST/UNAUTH (sync disabled)")
            disableSyncAndResetCloudState()
        }
    }

    // MARK: - Active user switching

    private func ensureActiveUser(_ userId: UUID) {
        if activeUserId != userId {
            activeUserId = userId

            hasPulledSessionsOnce = false
            hasPulledSettingsOnce = false

            suppressNextSessionsPush = false
            suppressNextSettingsPush = false

            lastKnownSessionIDs = []
            pendingSessionDeletes = loadPendingDeletes(for: userId)

            log("activeUser=\(userId.uuidString)")
        }
    }

    private func pendingDeletesKey(for userId: UUID) -> String {
        "focusflow_focus_sessions_pending_deletes_\(userId.uuidString)"
    }

    private func loadPendingDeletes(for userId: UUID) -> Set<UUID> {
        let key = pendingDeletesKey(for: userId)
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return Set(arr.compactMap { UUID(uuidString: $0) })
    }

    private func savePendingDeletes(for userId: UUID, _ set: Set<UUID>) {
        let key = pendingDeletesKey(for: userId)
        UserDefaults.standard.set(set.map { $0.uuidString }, forKey: key)
    }

    // MARK: - Change handling (sessions)

    private func handleSessionsChanged(_ sessions: [FocusSession], reason: String) {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)

        // Diff deletions (local removed IDs -> queue remote deletes)
        let currentIDs = Set(sessions.map(\.id))
        let removed = lastKnownSessionIDs.subtracting(currentIDs)
        lastKnownSessionIDs = currentIDs

        if !removed.isEmpty {
            pendingSessionDeletes.formUnion(removed)
            savePendingDeletes(for: session.userId, pendingSessionDeletes)
            log("queuedSessionDeletes=\(removed.count)")
        }

        if suppressNextSessionsPush {
            suppressNextSessionsPush = false
            log("suppressedSessionsPush=true (after pull)")
            flushPendingDeletesIfPossible()
            return
        }

        flushPendingDeletesIfPossible()
        pushSessionsIfPossible(sessions: sessions, reason: reason, accessToken: token, userId: session.userId)
    }

    // MARK: - Change handling (settings)

    private func handleSettingsChanged(_ settings: FocusStatsSettingsLocal, reason: String) {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)

        if suppressNextSettingsPush {
            suppressNextSettingsPush = false
            log("suppressedSettingsPush=true (after pull)")
            return
        }

        pushSettingsIfPossible(settings: settings, reason: reason, accessToken: token, userId: session.userId)
    }

    // MARK: - Pull baseline (sessions + settings)

    private func pullIfPossible() {
        guard let session = auth.currentUserSession, session.isGuest == false else {
            // Mode logging is handled in handleAuthStateChange; keep this quiet.
            return
        }
        guard let token = session.accessToken, token.isEmpty == false else {
            // Mode logging is handled in handleAuthStateChange; keep this quiet.
            return
        }

        ensureActiveUser(session.userId)

        // Sessions
        if hasPulledSessionsOnce == false {
            hasPulledSessionsOnce = true

            Task {
                do {
                    let records = try await sessionsAPI.fetchSessions(userId: session.userId, accessToken: token)

                    // Stable order in storage: oldest -> newest
                    let mapped = records
                        .map { FocusSession.fromRecord($0) }
                        .sorted { $0.date < $1.date }

                    // Baseline IDs BEFORE applying
                    lastKnownSessionIDs = Set(mapped.map(\.id))

                    // Suppress echo push
                    suppressNextSessionsPush = true

                    DispatchQueue.main.async { [weak self] in
                        self?.applyRemoteSessions?(mapped)
                        self?.log("pulledSessions=\(mapped.count)")
                    }
                } catch {
                    hasPulledSessionsOnce = false
                    log("sessionsPullFailed=\(describe(error))")
                }
            }
        }

        // Settings
        if hasPulledSettingsOnce == false {
            hasPulledSettingsOnce = true

            Task {
                do {
                    if let record = try await settingsAPI.fetchSettings(userId: session.userId, accessToken: token) {
                        let local = FocusStatsSettingsLocal(record: record)

                        suppressNextSettingsPush = true

                        DispatchQueue.main.async { [weak self] in
                            self?.applyRemoteSettings?(local)
                            self?.log("pulledSettings=true goal=\(local.dailyGoalMinutes)")
                        }
                    } else {
                        // No row yet (first login). We'll create it on first local change/push.
                        log("pulledSettings=false (no row yet; will create on push)")
                    }
                } catch {
                    hasPulledSettingsOnce = false
                    log("settingsPullFailed=\(describe(error))")
                }
            }
        }
    }

    // MARK: - Push sessions

    private func pushSessionsIfPossible(
        sessions: [FocusSession],
        reason: String,
        accessToken: String,
        userId: UUID
    ) {
        let upserts = sessions.toUpsertRecords(userId: userId)

        Task {
            do {
                _ = try await sessionsAPI.upsertSessions(upserts, accessToken: accessToken)
                log("pushedSessions=\(upserts.count) reason=\(reason)")
            } catch {
                log("sessionsPushFailed reason=\(reason) error=\(describe(error))")
            }
        }
    }

    // MARK: - Push settings

    private func pushSettingsIfPossible(
        settings: FocusStatsSettingsLocal,
        reason: String,
        accessToken: String,
        userId: UUID
    ) {
        let args = settings.toUpsertArguments(userId: userId)

        Task {
            do {
                _ = try await settingsAPI.upsertSettings(
                    userId: args.userId,
                    dailyGoalMinutes: args.dailyGoalMinutes,
                    hiddenHistorySessionIds: args.hiddenHistorySessionIds,
                    lifetimeFocusSeconds: args.lifetimeFocusSeconds,
                    lifetimeSessionCount: args.lifetimeSessionCount,
                    lifetimeBestStreak: args.lifetimeBestStreak,
                    accessToken: accessToken
                )
                log("pushedSettings=true reason=\(reason)")
            } catch {
                log("settingsPushFailed reason=\(reason) error=\(describe(error))")
            }
        }
    }

    // MARK: - Flush queued deletes (sessions)

    private func flushPendingDeletesIfPossible() {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)
        guard !pendingSessionDeletes.isEmpty else { return }

        let idsToDelete = Array(pendingSessionDeletes)

        Task {
            var succeeded: [UUID] = []

            for id in idsToDelete {
                do {
                    try await sessionsAPI.deleteSession(id: id, accessToken: token)
                    succeeded.append(id)
                } catch {
                    log("remoteSessionDeleteFailed id=\(id.uuidString) error=\(describe(error))")
                }
            }

            if !succeeded.isEmpty {
                pendingSessionDeletes.subtract(succeeded)
                savePendingDeletes(for: session.userId, pendingSessionDeletes)
                log("flushedSessionDeletes=\(succeeded.count)")
            }
        }
    }
}
