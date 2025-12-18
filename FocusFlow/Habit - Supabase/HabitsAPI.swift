import Foundation

enum HabitsAPIError: Error {
    case badURL
    case badResponse(status: Int, body: String)
}

struct HabitRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let isDoneToday: Bool
    let reminderAt: Date?
    let repeatOption: String
    let durationMinutes: Int?
    let sortIndex: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case isDoneToday = "is_done_today"
        case reminderAt = "reminder_at"
        case repeatOption = "repeat_option"
        case durationMinutes = "duration_minutes"
        case sortIndex = "sort_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ✅ Write payload used for bulk upsert.
/// IMPORTANT: encodes ALL keys every time (null for nil) so PostgREST won't error.
private struct HabitUpsertPayload: Encodable {
    let id: UUID
    let userId: UUID
    let name: String
    let isDoneToday: Bool
    let reminderAt: Date?
    let repeatOption: String
    let durationMinutes: Int?
    let sortIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case isDoneToday = "is_done_today"
        case reminderAt = "reminder_at"
        case repeatOption = "repeat_option"
        case durationMinutes = "duration_minutes"
        case sortIndex = "sort_index"
    }

    init(from record: HabitRecord) {
        self.id = record.id
        self.userId = record.userId
        self.name = record.name
        self.isDoneToday = record.isDoneToday
        self.reminderAt = record.reminderAt
        self.repeatOption = record.repeatOption
        self.durationMinutes = record.durationMinutes
        self.sortIndex = record.sortIndex
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(name, forKey: .name)
        try c.encode(isDoneToday, forKey: .isDoneToday)
        try c.encode(repeatOption, forKey: .repeatOption)
        try c.encode(sortIndex, forKey: .sortIndex)

        // Force key presence for optionals (null if nil)
        if let reminderAt { try c.encode(reminderAt, forKey: .reminderAt) }
        else { try c.encodeNil(forKey: .reminderAt) }

        if let durationMinutes { try c.encode(durationMinutes, forKey: .durationMinutes) }
        else { try c.encodeNil(forKey: .durationMinutes) }
    }
}

final class HabitsAPI {
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
        guard let url = components?.url else { throw HabitsAPIError.badURL }

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

    func fetchHabits(accessToken: String) async throws -> [HabitRecord] {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,user_id,name,is_done_today,reminder_at,repeat_option,duration_minutes,sort_index,created_at,updated_at"),
            URLQueryItem(name: "order", value: "sort_index.asc")
        ]

        let request = try makeRequest(
            path: "/rest/v1/habits",
            method: "GET",
            accessToken: accessToken,
            queryItems: query
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HabitsAPIError.badResponse(status: status, body: body)
        }
        return try decode([HabitRecord].self, from: data)
    }

    func upsertHabits(_ records: [HabitRecord], accessToken: String) async throws -> [HabitRecord] {
        // ✅ Convert to payload that always has matching keys across array elements
        let payload = records.map { HabitUpsertPayload(from: $0) }
        let body = try encode(payload)

        let request = try makeRequest(
            path: "/rest/v1/habits",
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
            throw HabitsAPIError.badResponse(status: status, body: body)
        }

        return try decode([HabitRecord].self, from: data)
    }

    func deleteHabit(id: UUID, accessToken: String) async throws {
        let request = try makeRequest(
            path: "/rest/v1/habits",
            method: "DELETE",
            accessToken: accessToken,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HabitsAPIError.badResponse(status: status, body: body)
        }
    }
}
