import Foundation

struct SpotifyConfig {
    // New Spotify app Client ID
    static let clientID: String = "fd346e78ce0740228b4964d89a524d14"

    // Must match the Redirect URI in the Spotify dashboard
    static let redirectURI: URL = URL(string: "focusflow-spotify://callback")!
}
