import Foundation

// MARK: - FocusSession <-> Supabase records

extension FocusSession {

    static func fromRecord(_ record: FocusSessionRecord) -> FocusSession {
        FocusSession(
            id: record.id,
            date: record.startedAt,
            duration: TimeInterval(record.durationSeconds),
            sessionName: record.sessionName
        )
    }

    func toUpsertRecord(userId: UUID) -> FocusSessionUpsertRecord {
        FocusSessionUpsertRecord(
            id: id,
            userId: userId,
            startedAt: date,
            durationSeconds: max(0, Int(duration.rounded())),
            sessionName: sessionName
        )
    }
}

extension Array where Element == FocusSessionRecord {
    func toLocalSessions() -> [FocusSession] {
        map { FocusSession.fromRecord($0) }
    }
}

extension Array where Element == FocusSession {
    func toUpsertRecords(userId: UUID) -> [FocusSessionUpsertRecord] {
        map { $0.toUpsertRecord(userId: userId) }
    }
}
