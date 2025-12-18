import Foundation
import Combine

// MARK: - Local snapshot model (AppSettings <-> Supabase user_profiles)

struct UserProfileLocal: Equatable {
    var fullName: String?
    var displayName: String?
    var email: String?

    // Keep these optional — you may not use them yet
    var avatarURL: String?
    var preferredTheme: String?
    var timerSound: String?
    var notificationsEnabled: Bool?
}

extension UserProfileLocal {
    init(record: UserProfile) {
        self.fullName = record.fullName
        self.displayName = record.displayName
        self.email = record.email
        self.avatarURL = record.avatarURL
        self.preferredTheme = record.preferredTheme
        self.timerSound = record.timerSound
        self.notificationsEnabled = record.notificationsEnabled
    }
}

// MARK: - Sync Engine

final class UserProfileSyncEngine {

    static let shared = UserProfileSyncEngine()

    private let api: UserProfileAPI
    private let auth: AuthManager

    private let queue = DispatchQueue(label: "UserProfileSyncEngine.queue", qos: .utility)
    private var cancellables = Set<AnyCancellable>()

    private var started = false
    private var hasPulledOnce = false
    private var suppressNextPush = false

    // account isolation
    private var activeUserId: UUID?

    private init(api: UserProfileAPI = .shared, auth: AuthManager = .shared) {
        self.api = api
        self.auth = auth
    }

    /// Start once. Provide a publisher for your local profile snapshot (from AppSettings)
    /// and a closure to apply cloud -> local.
    func start(
        profilePublisher: AnyPublisher<UserProfileLocal, Never>,
        applyRemoteProfile: @escaping (UserProfileLocal) -> Void
    ) {
        guard !started else { return }
        started = true

        // 1) auth changes -> pull baseline
        auth.$state
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pullIfPossible(applyRemoteProfile: applyRemoteProfile)
            }
            .store(in: &cancellables)

        // 2) local changes -> push (debounced)
        profilePublisher
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: queue)
            .sink { [weak self] local in
                self?.handleLocalChanged(local, reason: "profileChanged")
            }
            .store(in: &cancellables)

        // boot
        pullIfPossible(applyRemoteProfile: applyRemoteProfile)
    }

    // MARK: - Mode control

    func disableSyncAndResetCloudState() {
        activeUserId = nil
        hasPulledOnce = false
        suppressNextPush = false
    }

    private func ensureActiveUser(_ userId: UUID) {
        if activeUserId != userId {
            activeUserId = userId
            hasPulledOnce = false
            suppressNextPush = false
            print("UserProfileSyncEngine: activeUser=\(userId.uuidString)")
        }
    }

    // MARK: - Local -> Cloud

    private func handleLocalChanged(_ local: UserProfileLocal, reason: String) {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)

        if suppressNextPush {
            suppressNextPush = false
            print("UserProfileSyncEngine: suppressed push after pull.")
            return
        }

        pushIfPossible(local: local, reason: reason, accessToken: token, userId: session.userId)
    }

    private func pushIfPossible(
        local: UserProfileLocal,
        reason: String,
        accessToken: String,
        userId: UUID
    ) {
        Task {
            do {
                _ = try await api.upsertProfile(
                    for: userId,
                    fullName: local.fullName,
                    displayName: local.displayName,
                    email: local.email,
                    avatarURL: local.avatarURL,
                    preferredTheme: local.preferredTheme,
                    timerSound: local.timerSound,
                    notificationsEnabled: local.notificationsEnabled,
                    accessToken: accessToken
                )

                print("UserProfileSyncEngine: pushed profile. reason=\(reason)")
            } catch {
                handleAuthExpiryIfNeeded(error)
                print("UserProfileSyncEngine: push failed. reason=\(reason) error=\(error)")
            }
        }
    }

    // MARK: - Cloud -> Local

    private func pullIfPossible(applyRemoteProfile: @escaping (UserProfileLocal) -> Void) {
        guard let session = auth.currentUserSession, session.isGuest == false else {
            print("UserProfileSyncEngine: no signed-in session (or guest). Skipping pull.")
            return
        }
        guard let token = session.accessToken, token.isEmpty == false else {
            print("UserProfileSyncEngine: missing access token. Skipping pull.")
            return
        }

        ensureActiveUser(session.userId)

        guard hasPulledOnce == false else { return }
        hasPulledOnce = true

        Task {
            do {
                if let profile = try await api.fetchProfile(for: session.userId, accessToken: token) {
                    let local = UserProfileLocal(record: profile)

                    // Avoid echoing the same pulled payload back up
                    suppressNextPush = true

                    DispatchQueue.main.async {
                        applyRemoteProfile(local)
                        print("UserProfileSyncEngine: pulled profile.")
                    }
                } else {
                    print("UserProfileSyncEngine: no profile row yet (will create on push).")
                }
            } catch {
                hasPulledOnce = false
                handleAuthExpiryIfNeeded(error)
                print("UserProfileSyncEngine: pull failed:", error)
            }
        }
    }

    // MARK: - 401 handling (JWT expired)

    private func handleAuthExpiryIfNeeded(_ error: Error) {
        if case let UserProfileAPIError.badResponse(status, _) = error, status == 401 {
            auth.clearAccessTokenButKeepUser() // will refresh if possible
        }
    }
}
