import Foundation

// MARK: - Cloud payloads

struct FocusPresetCloud: Codable, Equatable {
    let id: UUID
    var name: String
    var durationSeconds: Int
    var soundID: String
    var emoji: String?
    var isSystemDefault: Bool
    var themeRaw: String?
    var externalMusicAppRaw: String?
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationSeconds = "duration_seconds"
        case soundID = "sound_id"
        case emoji
        case isSystemDefault = "is_system_default"
        case themeRaw = "theme_raw"
        case externalMusicAppRaw = "external_music_app_raw"
        case sortOrder = "sort_order"
    }
}

struct FocusPresetStateResponse: Codable {
    var presets: [FocusPresetCloud]
    var activePresetID: UUID?

    enum CodingKeys: String, CodingKey {
        case presets
        case activePresetID = "active_preset_id"
    }
}

struct FocusPresetStateRequest: Codable {
    var presets: [FocusPresetCloud]
    var activePresetID: UUID?

    enum CodingKeys: String, CodingKey {
        case presets
        case activePresetID = "active_preset_id"
    }
}

enum FocusPresetAPIError: Error, LocalizedError {
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
            return "Failed to decode presets response."
        }
    }
}

// MARK: - API client (Edge Function)

final class FocusPresetAPI {
    static let shared = FocusPresetAPI()
    private init() {}

    private let config: SupabaseConfig = .shared

    private var baseURL: URL {
        config.projectURL.appendingPathComponent("functions/v1")
    }

    func fetchState(accessToken: String) async throws -> FocusPresetStateResponse {
        let url = baseURL.appendingPathComponent("focus-presets")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let bodyText = String(data: data, encoding: .utf8) ?? ""

        guard (200...299).contains(status) else {
            throw FocusPresetAPIError.badResponse(status: status, body: bodyText)
        }

        do {
            return try JSONDecoder().decode(FocusPresetStateResponse.self, from: data)
        } catch {
            throw FocusPresetAPIError.decodingError
        }
    }

    @discardableResult
    func upsertState(_ payload: FocusPresetStateRequest, accessToken: String) async throws -> FocusPresetStateResponse {
        let url = baseURL.appendingPathComponent("focus-presets")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let bodyText = String(data: data, encoding: .utf8) ?? ""

        guard (200...299).contains(status) else {
            throw FocusPresetAPIError.badResponse(status: status, body: bodyText)
        }

        do {
            return try JSONDecoder().decode(FocusPresetStateResponse.self, from: data)
        } catch {
            throw FocusPresetAPIError.decodingError
        }
    }
}
