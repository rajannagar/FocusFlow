import Foundation

enum UserPreferencesAPIError: Error {
    case badURL
    case badResponse(status: Int, body: String)
}

/// Represents a row in `public.user_preferences`
struct UserPreferencesRecord: Codable, Identifiable {
    // Identifiable: use user_id as id
    var id: UUID { userId }

    let userId: UUID
    let displayName: String?
    let tagline: String?
    let avatarId: String?
    let selectedTheme: String?
    let profileTheme: String?
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let dailyReminderEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int
    let selectedFocusSound: String?
    let externalMusicApp: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case tagline
        case avatarId = "avatar_id"
        case selectedTheme = "selected_theme"
        case profileTheme = "profile_theme"
        case soundEnabled = "sound_enabled"
        case hapticsEnabled = "haptics_enabled"
        case dailyReminderEnabled = "daily_reminder_enabled"
        case reminderHour = "reminder_hour"
        case reminderMinute = "reminder_minute"
        case selectedFocusSound = "selected_focus_sound"
        case externalMusicApp = "external_music_app"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ✅ Upsert payload (forces all keys every time; nil -> explicit null)
private struct UserPreferencesUpsertPayload: Encodable {
    let userId: UUID
    let displayName: String?
    let tagline: String?
    let avatarId: String?
    let selectedTheme: String?
    let profileTheme: String?
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let dailyReminderEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int
    let selectedFocusSound: String?
    let externalMusicApp: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case tagline
        case avatarId = "avatar_id"
        case selectedTheme = "selected_theme"
        case profileTheme = "profile_theme"
        case soundEnabled = "sound_enabled"
        case hapticsEnabled = "haptics_enabled"
        case dailyReminderEnabled = "daily_reminder_enabled"
        case reminderHour = "reminder_hour"
        case reminderMinute = "reminder_minute"
        case selectedFocusSound = "selected_focus_sound"
        case externalMusicApp = "external_music_app"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(userId, forKey: .userId)

        if let displayName { try c.encode(displayName, forKey: .displayName) } else { try c.encodeNil(forKey: .displayName) }
        if let tagline { try c.encode(tagline, forKey: .tagline) } else { try c.encodeNil(forKey: .tagline) }
        if let avatarId { try c.encode(avatarId, forKey: .avatarId) } else { try c.encodeNil(forKey: .avatarId) }
        if let selectedTheme { try c.encode(selectedTheme, forKey: .selectedTheme) } else { try c.encodeNil(forKey: .selectedTheme) }
        if let profileTheme { try c.encode(profileTheme, forKey: .profileTheme) } else { try c.encodeNil(forKey: .profileTheme) }
        if let selectedFocusSound { try c.encode(selectedFocusSound, forKey: .selectedFocusSound) } else { try c.encodeNil(forKey: .selectedFocusSound) }
        if let externalMusicApp { try c.encode(externalMusicApp, forKey: .externalMusicApp) } else { try c.encodeNil(forKey: .externalMusicApp) }

        try c.encode(soundEnabled, forKey: .soundEnabled)
        try c.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try c.encode(dailyReminderEnabled, forKey: .dailyReminderEnabled)
        try c.encode(reminderHour, forKey: .reminderHour)
        try c.encode(reminderMinute, forKey: .reminderMinute)
    }
}

final class UserPreferencesAPI {

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
        guard let url = components?.url else { throw UserPreferencesAPIError.badURL }

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

    /// Fetch the user's preferences row (nil if none exists yet).
    func fetchPreferences(userId: UUID, accessToken: String) async throws -> UserPreferencesRecord? {
        let query: [URLQueryItem] = [
            URLQueryItem(
                name: "select",
                value: "user_id,display_name,tagline,avatar_id,selected_theme,profile_theme,sound_enabled,haptics_enabled,daily_reminder_enabled,reminder_hour,reminder_minute,selected_focus_sound,external_music_app,created_at,updated_at"
            ),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let request = try makeRequest(
            path: "/rest/v1/user_preferences",
            method: "GET",
            accessToken: accessToken,
            queryItems: query
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw UserPreferencesAPIError.badResponse(status: status, body: body)
        }

        let rows = try decode([UserPreferencesRecord].self, from: data)
        return rows.first
    }

    /// Upsert the user's preferences row (singleton).
    @discardableResult
    func upsertPreferences(
        userId: UUID,
        displayName: String?,
        tagline: String?,
        avatarId: String?,
        selectedTheme: String?,
        profileTheme: String?,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        dailyReminderEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        selectedFocusSound: String?,
        externalMusicApp: String?,
        accessToken: String
    ) async throws -> UserPreferencesRecord {
        let payload = UserPreferencesUpsertPayload(
            userId: userId,
            displayName: displayName,
            tagline: tagline,
            avatarId: avatarId,
            selectedTheme: selectedTheme,
            profileTheme: profileTheme,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            dailyReminderEnabled: dailyReminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            selectedFocusSound: selectedFocusSound,
            externalMusicApp: externalMusicApp
        )

        let body = try encode([payload])

        let request = try makeRequest(
            path: "/rest/v1/user_preferences",
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
            throw UserPreferencesAPIError.badResponse(status: status, body: body)
        }

        let rows = try decode([UserPreferencesRecord].self, from: data)
        guard let first = rows.first else {
            throw UserPreferencesAPIError.badResponse(status: status, body: "Expected representation row, got empty response.")
        }
        return first
    }
}
