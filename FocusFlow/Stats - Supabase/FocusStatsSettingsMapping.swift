import Foundation

/// Local “settings snapshot” for Stats that matches what lives in Supabase `focus_stats_settings`.
/// (We keep this separate from StatsManager so the sync engine can work with a simple value type.)
struct FocusStatsSettingsLocal: Equatable {
    var dailyGoalMinutes: Int
    var hiddenHistorySessionIDs: Set<UUID>
    var lifetimeFocusSeconds: TimeInterval
    var lifetimeSessionCount: Int
    var lifetimeBestStreak: Int
}

// MARK: - Local <-> Record

extension FocusStatsSettingsLocal {

    init(record: FocusStatsSettingsRecord) {
        self.dailyGoalMinutes = record.dailyGoalMinutes
        self.hiddenHistorySessionIDs = Set(record.hiddenHistorySessionIds)
        self.lifetimeFocusSeconds = record.lifetimeFocusSeconds
        self.lifetimeSessionCount = record.lifetimeSessionCount
        self.lifetimeBestStreak = record.lifetimeBestStreak
    }

    /// Values formatted for `FocusStatsSettingsAPI.upsertSettings(...)`
    func toUpsertArguments(userId: UUID) -> (
        userId: UUID,
        dailyGoalMinutes: Int,
        hiddenHistorySessionIds: [UUID],
        lifetimeFocusSeconds: Double,
        lifetimeSessionCount: Int,
        lifetimeBestStreak: Int
    ) {
        (
            userId: userId,
            dailyGoalMinutes: dailyGoalMinutes,
            hiddenHistorySessionIds: Array(hiddenHistorySessionIDs),
            lifetimeFocusSeconds: Double(lifetimeFocusSeconds),
            lifetimeSessionCount: lifetimeSessionCount,
            lifetimeBestStreak: lifetimeBestStreak
        )
    }
}

// MARK: - StatsManager snapshot helpers

extension StatsManager {

    /// Read current local stats settings as a value type (for sync).
    func makeStatsSettingsLocalSnapshot() -> FocusStatsSettingsLocal {
        FocusStatsSettingsLocal(
            dailyGoalMinutes: dailyGoalMinutes,
            hiddenHistorySessionIDs: hiddenHistorySessionIDs,
            lifetimeFocusSeconds: lifetimeFocusSeconds,
            lifetimeSessionCount: lifetimeSessionCount,
            lifetimeBestStreak: lifetimeBestStreak
        )
    }
}
