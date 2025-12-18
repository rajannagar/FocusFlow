import Foundation

enum FocusStatsSettingsAPIError: Error {
    case badURL
    case badResponse(status: Int, body: String)
}

struct FocusStatsSettingsRecord: Codable, Identifiable {
    // Identifiable conformance: use user_id as id
    var id: UUID { userId }

    let userId: UUID
    let dailyGoalMinutes: Int
    let hiddenHistorySessionIds: [UUID]
    let lifetimeFocusSeconds: Double
    let lifetimeSessionCount: Int
    let lifetimeBestStreak: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dailyGoalMinutes = "daily_goal_minutes"
        case hiddenHistorySessionIds = "hidden_history_session_ids"
        case lifetimeFocusSeconds = "lifetime_focus_seconds"
        case lifetimeSessionCount = "lifetime_session_count"
        case lifetimeBestStreak = "lifetime_best_streak"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ✅ Upsert payload used for singleton per user.
/// IMPORTANT: encodes ALL keys every time.
private struct FocusStatsSettingsUpsertPayload: Encodable {
    let userId: UUID
    let dailyGoalMinutes: Int
    let hiddenHistorySessionIds: [UUID]
    let lifetimeFocusSeconds: Double
    let lifetimeSessionCount: Int
    let lifetimeBestStreak: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dailyGoalMinutes = "daily_goal_minutes"
        case hiddenHistorySessionIds = "hidden_history_session_ids"
        case lifetimeFocusSeconds = "lifetime_focus_seconds"
        case lifetimeSessionCount = "lifetime_session_count"
        case lifetimeBestStreak = "lifetime_best_streak"
    }
}

final class FocusStatsSettingsAPI {
    private let config: SupabaseConfig

    init(config: SupabaseConfig = .shared) {
        self.config = config
    }

    private func makeRequest(
        path: String,
        method: String,
        accessToken: String,
        queryItems: [URLQueryItem] = [],
        prefer: String? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        var components = URLComponents(url: config.projectURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty { components?.queryItems = queryItems }
        guard let url = components?.url else { throw FocusStatsSettingsAPIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let prefer { request.setValue(prefer, forHTTPHeaderField: "Prefer") }
        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    /// Fetch the user's settings row (returns nil if none exists yet).
    func fetchSettings(userId: UUID, accessToken: String) async throws -> FocusStatsSettingsRecord? {
        let query: [URLQueryItem] = [
            URLQueryItem(
                name: "select",
                value: "user_id,daily_goal_minutes,hidden_history_session_ids,lifetime_focus_seconds,lifetime_session_count,lifetime_best_streak,created_at,updated_at"
            ),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let request = try makeRequest(
            path: "/rest/v1/focus_stats_settings",
            method: "GET",
            accessToken: accessToken,
            queryItems: query
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FocusStatsSettingsAPIError.badResponse(status: status, body: body)
        }

        let rows = try decode([FocusStatsSettingsRecord].self, from: data)
        return rows.first
    }

    /// Upsert the user's settings row (singleton).
    @discardableResult
    func upsertSettings(
        userId: UUID,
        dailyGoalMinutes: Int,
        hiddenHistorySessionIds: [UUID],
        lifetimeFocusSeconds: Double,
        lifetimeSessionCount: Int,
        lifetimeBestStreak: Int,
        accessToken: String
    ) async throws -> FocusStatsSettingsRecord {
        let payload = FocusStatsSettingsUpsertPayload(
            userId: userId,
            dailyGoalMinutes: dailyGoalMinutes,
            hiddenHistorySessionIds: hiddenHistorySessionIds,
            lifetimeFocusSeconds: lifetimeFocusSeconds,
            lifetimeSessionCount: lifetimeSessionCount,
            lifetimeBestStreak: lifetimeBestStreak
        )

        let body = try encode([payload]) // PostgREST accepts array payloads for bulk upsert

        let request = try makeRequest(
            path: "/rest/v1/focus_stats_settings",
            method: "POST",
            accessToken: accessToken,
            queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")],
            prefer: "resolution=merge-duplicates,return=representation",
            body: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FocusStatsSettingsAPIError.badResponse(status: status, body: body)
        }

        let rows = try decode([FocusStatsSettingsRecord].self, from: data)
        // With return=representation, we expect 1 row back
        guard let first = rows.first else {
            throw FocusStatsSettingsAPIError.badResponse(status: status, body: "Expected representation row, got empty response.")
        }
        return first
    }
}
