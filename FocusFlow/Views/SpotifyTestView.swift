import SwiftUI

struct SpotifyTestView: View {
    @ObservedObject private var spotify = SpotifyManager.shared
    @ObservedObject private var appSettings = AppSettings.shared

    // Example test track (you can change this URI later)
    private let testTrackURI = "spotify:track:20I6sIOMTCkB6w7ryavxtO"

    var body: some View {
        VStack(spacing: 24) {
            Text("Spotify Test")
                .font(.largeTitle.bold())

            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(spotify.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(spotify.isConnected ? "Connected to Spotify" : "Not connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let name = spotify.currentTrackName,
                   let artist = spotify.currentArtistName {
                    Text("Now playing:")
                        .font(.headline)
                    Text(name)
                        .font(.title3.bold())
                    Text(artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No track info yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 12) {
                Button {
                    // Mark this as the focus Spotify track
                    appSettings.spotifyEnabledForFocus = true
                    appSettings.spotifyTrackURI = testTrackURI
                    appSettings.spotifyTrackName = "FocusFlow Test Track"
                    appSettings.spotifyArtistName = "Spotify"

                    // Start playback
                    SpotifyManager.shared.play(uri: testTrackURI)
                } label: {
                    Text("Play Test Track in Spotify")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }

                HStack(spacing: 12) {
                    Button {
                        SpotifyManager.shared.pause()
                    } label: {
                        Text("Pause")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }

                    Button {
                        // Resume using the new helper
                        SpotifyManager.shared.resumeForFocus()
                    } label: {
                        Text("Resume")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }

                Button(role: .destructive) {
                    SpotifyManager.shared.stop()
                } label: {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
    }
}
