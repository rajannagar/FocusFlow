import Foundation
import Combine

// MARK: - Local snapshot model (AppSettings <-> Supabase user_preferences)

struct UserPreferencesLocal: Equatable {
    var displayName: String
    var tagline: String

    // Will wire this in Step 6 (move avatarID into AppSettings)
    var avatarId: String?

    var selectedThemeRaw: String
    var profileThemeRaw: String

    var soundEnabled: Bool
    var hapticsEnabled: Bool

    var dailyReminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int

    var selectedFocusSoundRaw: String?
    var externalMusicAppRaw: String?
}

extension UserPreferencesLocal {
    init(record: UserPreferencesRecord) {
        self.displayName = record.displayName ?? ""
        self.tagline = record.tagline ?? ""
        self.avatarId = record.avatarId

        self.selectedThemeRaw = record.selectedTheme ?? AppTheme.forest.rawValue
        self.profileThemeRaw = record.profileTheme ?? (record.selectedTheme ?? AppTheme.forest.rawValue)

        self.soundEnabled = record.soundEnabled
        self.hapticsEnabled = record.hapticsEnabled

        self.dailyReminderEnabled = record.dailyReminderEnabled
        self.reminderHour = record.reminderHour
        self.reminderMinute = record.reminderMinute

        self.selectedFocusSoundRaw = record.selectedFocusSound
        self.externalMusicAppRaw = record.externalMusicApp
    }
}

// MARK: - Sync Engine

final class UserPreferencesSyncEngine {

    static let shared = UserPreferencesSyncEngine()

    private let api: UserPreferencesAPI
    private let auth: AuthManager

    private let queue = DispatchQueue(label: "UserPreferencesSyncEngine.queue", qos: .utility)
    private var cancellables = Set<AnyCancellable>()

    private var started = false

    private var hasPulledOnce = false
    private var suppressNextPush = false

    // account isolation
    private var activeUserId: UUID?

    private init(api: UserPreferencesAPI = UserPreferencesAPI(), auth: AuthManager = .shared) {
        self.api = api
        self.auth = auth
    }

    /// Start once. Provide a publisher for your local prefs snapshot (from AppSettings)
    /// and a closure to apply cloud -> local.
    func start(
        preferencesPublisher: AnyPublisher<UserPreferencesLocal, Never>,
        applyRemotePreferences: @escaping (UserPreferencesLocal) -> Void
    ) {
        guard !started else { return }
        started = true

        // 1) auth changes -> pull baseline
        auth.$state
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pullIfPossible(applyRemotePreferences: applyRemotePreferences)
            }
            .store(in: &cancellables)

        // 2) local changes -> push (debounced)
        preferencesPublisher
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: queue)
            .sink { [weak self] prefs in
                self?.handleLocalChanged(prefs, reason: "preferencesChanged")
            }
            .store(in: &cancellables)

        // boot
        pullIfPossible(applyRemotePreferences: applyRemotePreferences)
    }

    // MARK: - Mode control

    func disableSyncAndResetCloudState() {
        activeUserId = nil
        hasPulledOnce = false
        suppressNextPush = false
    }

    func resetPullState() {
        hasPulledOnce = false
        suppressNextPush = false
    }

    // MARK: - Active user switching

    private func ensureActiveUser(_ userId: UUID) {
        if activeUserId != userId {
            activeUserId = userId
            hasPulledOnce = false
            suppressNextPush = false
            print("UserPreferencesSyncEngine: activeUser=\(userId.uuidString)")
        }
    }

    // MARK: - Local -> Cloud

    private func handleLocalChanged(_ prefs: UserPreferencesLocal, reason: String) {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)

        if suppressNextPush {
            suppressNextPush = false
            print("UserPreferencesSyncEngine: suppressed push after pull.")
            return
        }

        pushIfPossible(prefs: prefs, reason: reason, accessToken: token, userId: session.userId)
    }

    private func pushIfPossible(
        prefs: UserPreferencesLocal,
        reason: String,
        accessToken: String,
        userId: UUID
    ) {
        Task {
            do {
                let _ = try await api.upsertPreferences(
                    userId: userId,
                    displayName: prefs.displayName.isEmpty ? nil : prefs.displayName,
                    tagline: prefs.tagline.isEmpty ? nil : prefs.tagline,
                    avatarId: prefs.avatarId,
                    selectedTheme: prefs.selectedThemeRaw,
                    profileTheme: prefs.profileThemeRaw,
                    soundEnabled: prefs.soundEnabled,
                    hapticsEnabled: prefs.hapticsEnabled,
                    dailyReminderEnabled: prefs.dailyReminderEnabled,
                    reminderHour: prefs.reminderHour,
                    reminderMinute: prefs.reminderMinute,
                    selectedFocusSound: prefs.selectedFocusSoundRaw,
                    externalMusicApp: prefs.externalMusicAppRaw,
                    accessToken: accessToken
                )

                print("UserPreferencesSyncEngine: pushed prefs. reason=\(reason)")
            } catch {
                handleAuthExpiryIfNeeded(error)
                print("UserPreferencesSyncEngine: push failed. reason=\(reason) error=\(error)")
            }
        }
    }

    // MARK: - Cloud -> Local

    private func pullIfPossible(applyRemotePreferences: @escaping (UserPreferencesLocal) -> Void) {
        guard let session = auth.currentUserSession, session.isGuest == false else {
            print("UserPreferencesSyncEngine: no signed-in session (or guest). Skipping pull.")
            return
        }
        guard let token = session.accessToken, token.isEmpty == false else {
            print("UserPreferencesSyncEngine: missing access token. Skipping pull.")
            return
        }

        ensureActiveUser(session.userId)
        guard hasPulledOnce == false else { return }
        hasPulledOnce = true

        Task {
            do {
                if let record = try await api.fetchPreferences(userId: session.userId, accessToken: token) {
                    let local = UserPreferencesLocal(record: record)

                    // Avoid echoing the same pulled payload back up
                    suppressNextPush = true

                    DispatchQueue.main.async {
                        applyRemotePreferences(local)
                        print("UserPreferencesSyncEngine: pulled prefs.")
                    }
                } else {
                    // First login: no row yet. We'll create it on first local change/push.
                    print("UserPreferencesSyncEngine: no prefs row yet (will create on push).")
                }
            } catch {
                hasPulledOnce = false
                handleAuthExpiryIfNeeded(error)
                print("UserPreferencesSyncEngine: pull failed:", error)
            }
        }
    }

    // MARK: - 401 handling (JWT expired)

    private func handleAuthExpiryIfNeeded(_ error: Error) {
        // We only know status if it's our API error
        if case let UserPreferencesAPIError.badResponse(status, _) = error, status == 401 {
            // Keep user signed-in, but disable sync until fresh login
            auth.clearAccessTokenButKeepUser()
        }
    }
}
