import Foundation
import Combine

// MARK: - Model

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval   // seconds
    let sessionName: String?     // user-given name for this session

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        sessionName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.sessionName = sessionName
    }
}

struct DailyFocusStat: Identifiable {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval
}

// MARK: - Stats Manager

@MainActor
final class StatsManager: ObservableObject {
    static let shared = StatsManager()

    // Session history used for charts / streaks today
    @Published private(set) var sessions: [FocusSession] = []

    /// User-configurable daily goal in minutes
    @Published var dailyGoalMinutes: Int = 60 {
        didSet {
            saveGoal()
        }
    }

    // Lifetime, all-time stats for Profile
    // These should NOT be affected by per-session deletes in Stats.
    @Published private(set) var lifetimeFocusSeconds: TimeInterval = 0
    @Published private(set) var lifetimeSessionCount: Int = 0
    @Published private(set) var lifetimeBestStreak: Int = 0

    private let storageKeySessions = "focus_sessions_v1"
    private let storageKeyGoal = "daily_goal_minutes_v1"

    private let storageKeyLifetimeFocus = "lifetime_focus_seconds_v1"
    private let storageKeyLifetimeCount = "lifetime_session_count_v1"
    private let storageKeyLifetimeBestStreak = "lifetime_best_streak_v1"

    private let calendar = Calendar.current

    private init() {
        loadSessions()
        loadGoal()
        loadLifetime()
    }

    // MARK: - Public API

    /// Add a new recorded session.
    /// Also updates lifetime stats.
    func addSession(duration: TimeInterval, sessionName: String?) {
        guard duration > 0 else { return }

        let trimmedName = sessionName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToStore = (trimmedName?.isEmpty == true) ? nil : trimmedName

        let session = FocusSession(duration: duration, sessionName: nameToStore)
        sessions.append(session)
        saveSessions()

        // Lifetime totals – all-time
        lifetimeFocusSeconds += duration
        lifetimeSessionCount += 1

        // Update lifetime best streak if current best > stored best
        let currentBest = bestStreakFromCurrentSessions()
        if currentBest > lifetimeBestStreak {
            lifetimeBestStreak = currentBest
        }

        saveLifetime()
    }

    /// Delete a single session from *current* stats.
    /// Lifetime stats are intentionally NOT touched.
    func deleteSession(_ session: FocusSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    /// Clear just the current session history (used when you want
    /// to wipe charts / recent sessions but keep lifetime achievements).
    func clearSessionHistoryOnly() {
        sessions.removeAll()
        saveSessions()
        // lifetime* stay as-is
    }

    /// Fully wipe everything – used by
    /// “Reset all focus stats” in Profile.
    func clearAll() {
        sessions.removeAll()
        saveSessions()

        lifetimeFocusSeconds = 0
        lifetimeSessionCount = 0
        lifetimeBestStreak = 0
        saveLifetime()
    }

    // MARK: - Aggregates (based on *current* sessions array)

    var totalToday: TimeInterval {
        let startOfToday = calendar.startOfDay(for: Date())
        return sessions
            .filter { $0.date >= startOfToday }
            .reduce(0) { $0 + $1.duration }
    }

    var totalThisWeek: TimeInterval {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }
        return sessions
            .filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
            .reduce(0) { $0 + $1.duration }
    }

    /// "All time" for graphs/stats based only on current retained sessions.
    /// (Profile uses lifetimeFocusSeconds instead.)
    var totalAllTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var recentSessions: [FocusSession] {
        sessions
            .sorted { $0.date > $1.date }
            .prefix(30)
            .map { $0 }
    }

    /// Last 7 days including today, oldest → newest
    var last7DaysStats: [DailyFocusStat] {
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }

            let total = sessions
                .filter { $0.date >= day && $0.date < nextDay }
                .reduce(0) { $0 + $1.duration }

            return DailyFocusStat(date: day, totalDuration: total)
        }
    }

    // MARK: - Persistence

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: storageKeySessions)
        } catch {
            print("Failed to save focus sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKeySessions) else { return }

        do {
            let decoded = try JSONDecoder().decode([FocusSession].self, from: data)
            self.sessions = decoded
        } catch {
            print("Failed to load focus sessions: \(error)")
        }
    }

    private func saveGoal() {
        UserDefaults.standard.set(dailyGoalMinutes, forKey: storageKeyGoal)
    }

    private func loadGoal() {
        let stored = UserDefaults.standard.integer(forKey: storageKeyGoal)
        // if nothing saved yet, integer() returns 0 → default to 60
        self.dailyGoalMinutes = stored > 0 ? stored : 60
    }

    private func saveLifetime() {
        let defaults = UserDefaults.standard
        defaults.set(lifetimeFocusSeconds, forKey: storageKeyLifetimeFocus)
        defaults.set(lifetimeSessionCount, forKey: storageKeyLifetimeCount)
        defaults.set(lifetimeBestStreak, forKey: storageKeyLifetimeBestStreak)
    }

    private func loadLifetime() {
        let defaults = UserDefaults.standard

        let focus = defaults.double(forKey: storageKeyLifetimeFocus)
        let count = defaults.integer(forKey: storageKeyLifetimeCount)
        let best = defaults.integer(forKey: storageKeyLifetimeBestStreak)

        // If nothing stored yet, these will be 0 by default.
        self.lifetimeFocusSeconds = focus
        self.lifetimeSessionCount = count
        self.lifetimeBestStreak = best
    }

    // MARK: - Internal helpers

    /// Compute best streak based on current sessions only.
    /// Used to *increase* lifetimeBestStreak, never decrease it.
    private func bestStreakFromCurrentSessions() -> Int {
        let daysWithFocus: Set<Date> = Set(
            sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty { return 0 }

        let sorted = daysWithFocus.sorted()
        var best = 1
        var temp = 1

        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: -1, to: sorted[i]),
               calendar.isDate(prev, inSameDayAs: sorted[i - 1]) {
                temp += 1
            } else {
                best = max(best, temp)
                temp = 1
            }
        }

        best = max(best, temp)
        return best
    }
}

// MARK: - Helpers

extension TimeInterval {
    /// "25 min", "1h 05m", "3h 00m"
    var asReadableDuration: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
}
