import Foundation
import Combine

@MainActor
final class NotificationPreferencesStore: ObservableObject {
    static let shared = NotificationPreferencesStore()

    // MARK: - Published State
    @Published private(set) var preferences: NotificationPreferences = .default

    // MARK: - Private
    private let storageKey = "ff_notificationPreferences"
    private var activeNamespace: String = "guest"
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingNamespace = false
    private var isApplyingRemote = false // Track when applying remote sync to avoid notification loops
    private var hasInitialized = false

    private init() {
        observeAuthChanges()
        applyNamespace(for: AuthManagerV2.shared.state)
        hasInitialized = true
    }

    // MARK: - Namespace Management
    private func namespace(for state: CloudAuthState) -> String {
        switch state {
        case .signedIn(let userId): return userId.uuidString
        case .guest, .unknown, .signedOut: return "guest"
        }
    }

    private func key(_ base: String) -> String {
        "\(base)_\(activeNamespace)"
    }

    private func observeAuthChanges() {
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.applyNamespace(for: newState)
            }
            .store(in: &cancellables)
    }

    private func applyNamespace(for state: CloudAuthState) {
        let newNamespace = namespace(for: state)

        if hasInitialized, newNamespace == activeNamespace { return }

        // ✅ CRITICAL: Cancel ALL notifications BEFORE switching namespace
        // This prevents old account's notifications from showing to new account
        if hasInitialized && activeNamespace != newNamespace {
            Task {
                print("🔔 Cancelling all notifications before namespace switch: \(activeNamespace) → \(newNamespace)")
                await NotificationsCoordinator.shared.cancelAll()
            }
        }

        activeNamespace = newNamespace
        isApplyingNamespace = true
        defer { isApplyingNamespace = false }

        load()
        print("NotificationPreferencesStore: namespace → \(activeNamespace)")

        // Reconcile AFTER namespace switch completes
        // This ensures notifications are scheduled with the new account's preferences and tasks
        Task {
            // Wait a bit to ensure all stores have switched namespaces
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await NotificationsCoordinator.shared.reconcileAll(reason: "namespace changed")
        }
    }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: key(storageKey)),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.preferences = decoded
            return
        }

        // Migration default: hydrate from AppSettings only when no stored prefs exist
        let appSettings = AppSettings.shared
        var prefs = NotificationPreferences.default
        prefs.dailyReminderEnabled = appSettings.dailyReminderEnabled
        prefs.dailyReminderTime = appSettings.dailyReminderTime

        self.preferences = prefs
    }

    private func save() {
        guard !isApplyingNamespace else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key(storageKey))
            
            // ✅ Notify that notification preferences changed (for cloud sync)
            // Only notify if we're signed in (not guest mode) and not applying remote sync
            if activeNamespace != "guest" && !isApplyingRemote {
                NotificationCenter.default.post(name: NSNotification.Name("NotificationPreferencesDidChange"), object: nil)
            }
        }
    }
    
    /// Internal method to apply remote preferences without triggering sync notification
    func applyRemotePreferences(_ prefs: NotificationPreferences) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        preferences = prefs
        save() // Save but won't post notification due to isApplyingRemote flag
    }

    // MARK: - Public API

    func update(_ transform: (inout NotificationPreferences) -> Void) {
        var copy = preferences
        let before = copy
        transform(&copy)
        guard copy != preferences else { return }

        #if DEBUG
        // Log what changed
        var changes: [String] = []
        if before.masterEnabled != copy.masterEnabled {
            changes.append("masterEnabled: \(before.masterEnabled) → \(copy.masterEnabled)")
        }
        if before.dailyReminderEnabled != copy.dailyReminderEnabled {
            changes.append("dailyReminder: \(before.dailyReminderEnabled) → \(copy.dailyReminderEnabled)")
        }
        if before.dailyNudgesEnabled != copy.dailyNudgesEnabled {
            changes.append("dailyNudges: \(before.dailyNudgesEnabled) → \(copy.dailyNudgesEnabled)")
        }
        if before.taskRemindersEnabled != copy.taskRemindersEnabled {
            changes.append("taskReminders: \(before.taskRemindersEnabled) → \(copy.taskRemindersEnabled)")
        }
        if before.dailyRecapEnabled != copy.dailyRecapEnabled {
            changes.append("dailyRecap: \(before.dailyRecapEnabled) → \(copy.dailyRecapEnabled)")
        }
        if before.dailyReminderHour != copy.dailyReminderHour || before.dailyReminderMinute != copy.dailyReminderMinute {
            changes.append("dailyReminderTime: \(before.dailyReminderHour):\(String(format: "%02d", before.dailyReminderMinute)) → \(copy.dailyReminderHour):\(String(format: "%02d", copy.dailyReminderMinute))")
        }
        if before.dailyRecapHour != copy.dailyRecapHour || before.dailyRecapMinute != copy.dailyRecapMinute {
            changes.append("dailyRecapTime: \(before.dailyRecapHour):\(String(format: "%02d", before.dailyRecapMinute)) → \(copy.dailyRecapHour):\(String(format: "%02d", copy.dailyRecapMinute))")
        }
        if !changes.isEmpty {
            print("[NotificationPreferences] 📝 Changed: \(changes.joined(separator: ", "))")
        }
        #endif

        preferences = copy
        save()

        Task { await NotificationsCoordinator.shared.reconcileAll(reason: "preferences changed") }
    }

    func setMasterEnabled(_ enabled: Bool) { update { $0.masterEnabled = enabled } }
    func setSessionCompletionEnabled(_ enabled: Bool) { update { $0.sessionCompletionEnabled = enabled } }
    func setDailyReminderEnabled(_ enabled: Bool) { update { $0.dailyReminderEnabled = enabled } }
    func setDailyReminderTime(_ time: Date) { update { $0.dailyReminderTime = time } }
    func setDailyNudgesEnabled(_ enabled: Bool) { update { $0.dailyNudgesEnabled = enabled } }
    func setTaskRemindersEnabled(_ enabled: Bool) { update { $0.taskRemindersEnabled = enabled } }
    func setDailyRecapEnabled(_ enabled: Bool) { update { $0.dailyRecapEnabled = enabled } }
    func setDailyRecapTime(_ time: Date) { update { $0.dailyRecapTime = time } }
    
    // Smart AI Nudges (Phase 5)
    func setSmartNudgesEnabled(_ enabled: Bool) { update { $0.smartNudgesEnabled = enabled } }
    func setStreakRiskNudgesEnabled(_ enabled: Bool) { update { $0.streakRiskNudgesEnabled = enabled } }
    func setGoalProgressNudgesEnabled(_ enabled: Bool) { update { $0.goalProgressNudgesEnabled = enabled } }
    func setInactivityNudgesEnabled(_ enabled: Bool) { update { $0.inactivityNudgesEnabled = enabled } }
    func setAchievementNudgesEnabled(_ enabled: Bool) { update { $0.achievementNudgesEnabled = enabled } }

    func reset() {
        preferences = .default
        save()
        Task { await NotificationsCoordinator.shared.reconcileAll(reason: "preferences reset") }
    }
}
