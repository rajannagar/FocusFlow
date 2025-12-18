import Foundation
import Combine

final class HabitsSyncEngine {

    static let shared = HabitsSyncEngine()

    private let api: HabitsAPI
    private let auth: AuthManager

    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "HabitsSyncEngine.queue", qos: .utility)

    private var hasPulledOnce = false
    private var suppressNextPush = false
    private var lastKnownIDs: Set<UUID> = []

    // ✅ User-scoped tombstones (so deletes never cross accounts)
    private var activeUserId: UUID?
    private var pendingDeletes: Set<UUID> = []

    private init(api: HabitsAPI = HabitsAPI(), auth: AuthManager = .shared) {
        self.api = api
        self.auth = auth
    }

    func start(
        habitsPublisher: AnyPublisher<[Habit], Never>,
        applyRemoteHabits: @escaping ([Habit]) -> Void
    ) {
        auth.$state
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pullIfPossible(applyRemoteHabits: applyRemoteHabits)
                self.flushPendingDeletesIfPossible()
            }
            .store(in: &cancellables)

        habitsPublisher
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: queue)
            .sink { [weak self] habits in
                self?.handleHabitsChanged(habits, reason: "habitsChanged")
            }
            .store(in: &cancellables)

        pullIfPossible(applyRemoteHabits: applyRemoteHabits)
        flushPendingDeletesIfPossible()
    }

    // MARK: - Mode control

    func enableSync() {
        print("HabitsSyncEngine: mode=AUTH (sync enabled)")
    }

    func disableSyncAndResetCloudState() {
        print("HabitsSyncEngine: mode=GUEST/UNAUTH (sync disabled)")
        // Drop any “current user” state so nothing can leak
        activeUserId = nil
        hasPulledOnce = false
        suppressNextPush = false
        lastKnownIDs = []
        pendingDeletes = []
    }

    func resetPullState() {
        hasPulledOnce = false
        suppressNextPush = false
        lastKnownIDs = []
    }

    // MARK: - Internals: active user switching

    private func ensureActiveUser(_ userId: UUID) {
        if activeUserId != userId {
            activeUserId = userId
            hasPulledOnce = false
            suppressNextPush = false
            lastKnownIDs = []
            pendingDeletes = loadPendingDeletes(for: userId)
            print("HabitsSyncEngine: activeUser=\(userId.uuidString)")
        }
    }

    private func pendingDeletesKey(for userId: UUID) -> String {
        "focusflow_habits_pending_deletes_\(userId.uuidString)"
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

    // MARK: - Change handling

    private func handleHabitsChanged(_ habits: [Habit], reason: String) {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)

        // Diff deletions
        let currentIDs = Set(habits.map(\.id))
        let removed = lastKnownIDs.subtracting(currentIDs)
        lastKnownIDs = currentIDs

        if !removed.isEmpty {
            pendingDeletes.formUnion(removed)
            savePendingDeletes(for: session.userId, pendingDeletes)
            print("HabitsSyncEngine: queued \(removed.count) deletes.")
        }

        if suppressNextPush {
            suppressNextPush = false
            print("HabitsSyncEngine: suppressed push after pull.")
            flushPendingDeletesIfPossible()
            return
        }

        flushPendingDeletesIfPossible()
        pushIfPossible(habits: habits, reason: reason, accessToken: token, userId: session.userId)
    }

    // MARK: - Pull

    private func pullIfPossible(applyRemoteHabits: @escaping ([Habit]) -> Void) {
        guard let session = auth.currentUserSession, session.isGuest == false else {
            print("HabitsSyncEngine: no signed-in session (or guest). Skipping pull.")
            return
        }
        guard let token = session.accessToken, token.isEmpty == false else {
            print("HabitsSyncEngine: missing access token. Skipping pull.")
            return
        }

        ensureActiveUser(session.userId)
        guard hasPulledOnce == false else { return }
        hasPulledOnce = true

        Task {
            do {
                let records = try await api.fetchHabits(accessToken: token)
                let remoteHabits = records
                    .sorted(by: { $0.sortIndex < $1.sortIndex })
                    .map { Habit.fromRecord($0) }

                // Update baseline IDs BEFORE applying
                lastKnownIDs = Set(remoteHabits.map(\.id))

                // Avoid echoing the same pulled payload back up
                suppressNextPush = true

                DispatchQueue.main.async {
                    applyRemoteHabits(remoteHabits)
                    print("HabitsSyncEngine: pulled \(remoteHabits.count) habits.")
                }
            } catch {
                hasPulledOnce = false
                print("HabitsSyncEngine: pull failed:", error)
            }
        }
    }

    // MARK: - Push

    private func pushIfPossible(habits: [Habit], reason: String, accessToken: String, userId: UUID) {
        let records: [HabitRecord] = habits.enumerated().map { idx, h in
            h.toRecord(userId: userId, sortIndex: idx)
        }

        Task {
            do {
                _ = try await api.upsertHabits(records, accessToken: accessToken)
                print("HabitsSyncEngine: pushed \(records.count) habits. reason=\(reason)")
            } catch {
                print("HabitsSyncEngine: push failed. reason=\(reason) error=\(error)")
            }
        }
    }

    // MARK: - Deletes

    private func flushPendingDeletesIfPossible() {
        guard let session = auth.currentUserSession, session.isGuest == false else { return }
        guard let token = session.accessToken, token.isEmpty == false else { return }

        ensureActiveUser(session.userId)
        guard !pendingDeletes.isEmpty else { return }

        let idsToDelete = Array(pendingDeletes)

        Task {
            var succeeded: [UUID] = []

            for id in idsToDelete {
                do {
                    try await api.deleteHabit(id: id, accessToken: token)
                    succeeded.append(id)
                } catch {
                    print("HabitsSyncEngine: remote delete failed for \(id): \(error)")
                }
            }

            if !succeeded.isEmpty {
                pendingDeletes.subtract(succeeded)
                savePendingDeletes(for: session.userId, pendingDeletes)
                print("HabitsSyncEngine: flushed \(succeeded.count) deletes to Supabase.")
            }
        }
    }
}
