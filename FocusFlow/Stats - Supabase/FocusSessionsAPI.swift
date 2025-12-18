import Foundation

enum FocusSessionsAPIError: Error {
    case badURL
    case badResponse(status: Int, body: String)
}

struct FocusSessionRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let durationSeconds: Int
    let sessionName: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case durationSeconds = "duration_seconds"
        case sessionName = "session_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ✅ Upsert payload used for bulk upsert.
/// IMPORTANT: encodes ALL keys every time (null for nil) so PostgREST won't error.
struct FocusSessionUpsertRecord: Encodable, Identifiable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let durationSeconds: Int
    let sessionName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case durationSeconds = "duration_seconds"
        case sessionName = "session_name"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encode(durationSeconds, forKey: .durationSeconds)

        // Force key presence for optional (null if nil)
        if let sessionName { try c.encode(sessionName, forKey: .sessionName) }
        else { try c.encodeNil(forKey: .sessionName) }
    }
}

final class FocusSessionsAPI {
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
        guard let url = components?.url else { throw FocusSessionsAPIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Supabase REST headers
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

    /// Fetch all sessions for the current user (RLS enforces ownership).
    func fetchSessions(userId: UUID, accessToken: String) async throws -> [FocusSessionRecord] {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,user_id,started_at,duration_seconds,session_name,created_at,updated_at"),
            // Extra safety filter (RLS already protects, but this prevents accidental misuse)
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "order", value: "started_at.desc")
        ]

        let request = try makeRequest(
            path: "/rest/v1/focus_sessions",
            method: "GET",
            accessToken: accessToken,
            queryItems: query
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FocusSessionsAPIError.badResponse(status: status, body: body)
        }

        return try decode([FocusSessionRecord].self, from: data)
    }

    /// Bulk upsert sessions by id (merge duplicates).
    func upsertSessions(_ records: [FocusSessionUpsertRecord], accessToken: String) async throws -> [FocusSessionRecord] {
        let body = try encode(records)

        let request = try makeRequest(
            path: "/rest/v1/focus_sessions",
            method: "POST",
            accessToken: accessToken,
            queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
            prefer: "resolution=merge-duplicates,return=representation",
            body: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FocusSessionsAPIError.badResponse(status: status, body: body)
        }

        return try decode([FocusSessionRecord].self, from: data)
    }

    func deleteSession(id: UUID, accessToken: String) async throws {
        let request = try makeRequest(
            path: "/rest/v1/focus_sessions",
            method: "DELETE",
            accessToken: accessToken,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FocusSessionsAPIError.badResponse(status: status, body: body)
        }
    }
}
