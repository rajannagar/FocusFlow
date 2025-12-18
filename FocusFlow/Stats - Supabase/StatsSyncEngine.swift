import Foundation
import Combine

final class StatsSyncEngine {

    static let shared = StatsSyncEngine()

    private let api: FocusSessionsAPI
    private let auth: AuthManager

    private var cancellables = Set<AnyCancellable>()

    private var syncEnabled: Bool = false
    private var suppressPush: Bool = false

    private var currentUserId: UUID?
    private var currentAccessToken: String?

    private init(
        api: FocusSessionsAPI = FocusSessionsAPI(),
        auth: AuthManager = .shared
    ) {
        self.api = api
        self.auth = auth
    }

    // MARK: - Public

    func start() {
        // Auth state changes -> enable/disable sync + pull
        auth.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                self.handleAuthStateChange(newState)
            }
            .store(in: &cancellables)

        // Local session changes -> push
        StatsManager.shared.$sessions
            .dropFirst()
            .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pushAll(reason: "sessionsChanged")
            }
            .store(in: &cancellables)
    }

    // MARK: - Auth handling

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .authenticated(let session):
            if session.isGuest {
                syncEnabled = false
                currentUserId = nil
                currentAccessToken = nil
                print("StatsSyncEngine: mode=GUEST (sync disabled)")
                return
            }

            guard let token = session.accessToken, !token.isEmpty else {
                syncEnabled = false
                currentUserId = session.userId
                currentAccessToken = nil
                print("StatsSyncEngine: AUTH but missing access token (sync disabled)")
                return
            }

            syncEnabled = true
            currentUserId = session.userId
            currentAccessToken = token
            print("StatsSyncEngine: mode=AUTH (sync enabled)")

            pullFromCloud()

        case .unauthenticated, .unknown:
            syncEnabled = false
            currentUserId = nil
            currentAccessToken = nil
            print("StatsSyncEngine: mode=UNAUTH (sync disabled)")
        }
    }

    // MARK: - Pull

    private func pullFromCloud() {
        guard syncEnabled, let userId = currentUserId, let token = currentAccessToken else { return }

        Task {
            do {
                suppressPush = true

                let records = try await api.fetchSessions(userId: userId, accessToken: token)

                let mapped: [FocusSession] = records.map { r in
                    FocusSession(
                        id: r.id,
                        date: r.startedAt,
                        duration: TimeInterval(r.durationSeconds),
                        sessionName: r.sessionName
                    )
                }

                await MainActor.run {
                    StatsManager.shared.replaceSessionsFromSyncEngine(mapped)
                    StatsManager.shared.bumpLifetimeToAtLeastCurrentSessions()
                }

                print("StatsSyncEngine: pulled \(mapped.count) sessions.")
                print("StatsSyncEngine: suppressed push after pull.")
            } catch {
                print("StatsSyncEngine: pull failed:", error)
            }

            suppressPush = false
        }
    }

    // MARK: - Push

    private func pushAll(reason: String) {
        guard syncEnabled, !suppressPush, let userId = currentUserId, let token = currentAccessToken else { return }

        Task {
            let sessions: [FocusSession] = await MainActor.run { StatsManager.shared.sessions }

            // If there’s nothing to push, do nothing (we’ll handle deletes later when you add reset/account wipe)
            if sessions.isEmpty { return }

            let upserts: [FocusSessionUpsertRecord] = sessions.map { s in
                FocusSessionUpsertRecord(
                    id: s.id,
                    userId: userId,
                    startedAt: s.date,
                    durationSeconds: Int(s.duration.rounded()),
                    sessionName: s.sessionName
                )
            }

            do {
                _ = try await api.upsertSessions(upserts, accessToken: token)
                print("StatsSyncEngine: pushed \(upserts.count) sessions. reason=\(reason)")
            } catch {
                print("StatsSyncEngine: push failed. reason=\(reason) error=\(error)")
            }
        }
    }
}
