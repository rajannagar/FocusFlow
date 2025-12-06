import Foundation
import Combine

// MARK: - Models

/// Single track result from Spotify's /v1/search API.
struct SpotifyTrack: Identifiable, Decodable {
    let id: String
    let name: String
    let uri: String
    let artists: [Artist]
    let album: Album?

    struct Artist: Decodable {
        let name: String
    }

    struct Album: Decodable {
        let images: [AlbumImage]?
    }

    struct AlbumImage: Decodable {
        let url: String
        let height: Int?
        let width: Int?
    }

    /// Convenience: "Artist 1, Artist 2"
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }

    /// Convenience: best album artwork URL if available
    var artworkURL: URL? {
        guard let urlString = album?.images?.first?.url else { return nil }
        return URL(string: urlString)
    }
}

/// Top-level search response from Spotify.
private struct SpotifySearchResponse: Decodable {
    struct TrackContainer: Decodable {
        let items: [SpotifyTrack]
    }

    let tracks: TrackContainer?
}

// MARK: - Web service

/// Thin wrapper over Spotify Web API for search / playlists.
final class SpotifyWebService: ObservableObject {

    static let shared = SpotifyWebService()

    /// Latest search results (tracks only for now).
    @Published var tracks: [SpotifyTrack] = []

    /// True while a search request is in flight.
    @Published var isSearching: Bool = false

    /// Last error message (for debugging / UI badges).
    @Published var lastError: String?

    private init() {}

    // MARK: - Search

    /// Search for tracks by query string.
    func searchTracks(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async {
                self.tracks = []
                self.lastError = nil
            }
            return
        }

        guard let token = SpotifyManager.shared.apiAccessToken else {
            DispatchQueue.main.async {
                self.lastError = "Not connected to Spotify."
                self.tracks = []
            }
            print("Spotify search error: missing access token")
            return
        }

        guard let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=25")
        else {
            DispatchQueue.main.async {
                self.lastError = "Invalid search query."
                self.tracks = []
            }
            print("Spotify search error: invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        isSearching = true
        lastError = nil

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSearching = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                    self.tracks = []
                }
                print("Spotify search error:", error)
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.lastError = "Empty response from Spotify."
                    self.tracks = []
                }
                print("Spotify search error: empty data")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
                let items = decoded.tracks?.items ?? []
                DispatchQueue.main.async {
                    self.tracks = items
                    self.lastError = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Failed to read Spotify response."
                    self.tracks = []
                }
                print("Spotify search error: decodingError", error)
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw Spotify response:\n\(raw)")
                }
            }
        }.resume()
    }
}
