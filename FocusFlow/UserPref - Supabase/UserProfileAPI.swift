import Foundation

// MARK: - Models

struct UserProfile: Codable {
    let id: UUID
    var fullName: String?
    var displayName: String?
    var email: String?
    var avatarURL: String?
    var preferredTheme: String?
    var timerSound: String?
    var notificationsEnabled: Bool?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case displayName = "display_name"
        case email
        case avatarURL = "avatar_url"
        case preferredTheme = "preferred_theme"
        case timerSound = "timer_sound"
        case notificationsEnabled = "notifications_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum UserProfileAPIError: Error, LocalizedError {
    case invalidURL
    case badResponse(status: Int, body: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .badResponse(let status, _):
            return "Server error (\(status))."
        case .decodingError:
            return "Failed to decode profile response."
        }
    }
}

// MARK: - API client (Edge Function)

final class UserProfileAPI {

    static let shared = UserProfileAPI()
    private init() {}

    private let config: SupabaseConfig = .shared

    private var baseURL: URL {
        config.projectURL.appendingPathComponent("functions/v1")
    }

    // MARK: - Public API

    func fetchProfile(for userId: UUID, accessToken: String) async throws -> UserProfile? {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent("user-profile"),
                                        resolvingAgainstBaseURL: false) else {
            throw UserProfileAPIError.invalidURL
        }
        comps.queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]
        guard let url = comps.url else { throw UserProfileAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // ✅ IMPORTANT: apikey = anon, Authorization = USER access token
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let bodyText = String(data: data, encoding: .utf8) ?? ""

        // Treat missing row as nil
        if status == 404 || bodyText.trimmingCharacters(in: .whitespacesAndNewlines) == "null" {
            return nil
        }

        guard (200...299).contains(status) else {
            throw UserProfileAPIError.badResponse(status: status, body: bodyText)
        }

        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            throw UserProfileAPIError.decodingError
        }
    }

    @discardableResult
    func upsertProfile(
        for userId: UUID,
        fullName: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        avatarURL: String? = nil,
        preferredTheme: String? = nil,
        timerSound: String? = nil,
        notificationsEnabled: Bool? = nil,
        accessToken: String
    ) async throws -> UserProfile {

        let url = baseURL.appendingPathComponent("user-profile")

        var body: [String: Any] = ["id": userId.uuidString]

        if let fullName { body["full_name"] = fullName }
        if let displayName { body["display_name"] = displayName }
        if let email { body["email"] = email }
        if let avatarURL { body["avatar_url"] = avatarURL }
        if let preferredTheme { body["preferred_theme"] = preferredTheme }
        if let timerSound { body["timer_sound"] = timerSound }
        if let notificationsEnabled { body["notifications_enabled"] = notificationsEnabled }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // ✅ IMPORTANT: apikey = anon, Authorization = USER access token
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let bodyText = String(data: data, encoding: .utf8) ?? ""

        guard (200...299).contains(status) else {
            throw UserProfileAPIError.badResponse(status: status, body: bodyText)
        }

        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            throw UserProfileAPIError.decodingError
        }
    }
}
