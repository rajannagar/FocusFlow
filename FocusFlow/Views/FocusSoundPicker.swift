import SwiftUI

struct FocusSoundPicker: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Tabs

    private enum Tab: String, CaseIterable, Identifiable {
        case builtin
        case spotify

        var id: String { rawValue }
        var title: String {
            switch self {
            case .builtin: return "Focus Sounds"
            case .spotify: return "Spotify"
            }
        }
    }

    @State private var selectedTab: Tab = .builtin

    var body: some View {
        let theme = appSettings.selectedTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // Sheet handle
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                // Header
                header

                // Segmented tabs
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                // Tab content
                VStack {
                    switch selectedTab {
                    case .builtin:
                        BuiltInSoundsTab(
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary
                        )
                    case .spotify:
                        SpotifySoundsTab()
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 8)
            }
            .padding(.bottom, 8)
        }
        .onDisappear {
            let manager = SpotifyManager.shared

            // If NO focus track is playing, any Spotify audio is just a preview → stop it.
            // If a Spotify focus track is playing, do NOT touch it; just let it keep going.
            if !manager.isPlayingFocusTrack {
                manager.stopPreview()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Focus Sound")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("Preview and choose the sound that will loop quietly while your focus timer is running.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }
}

// ============================================================
// MARK: - BUILT-IN SOUND TAB
// ============================================================

private struct BuiltInSoundsTab: View {
    @ObservedObject private var appSettings = AppSettings.shared

    let accentPrimary: Color
    let accentSecondary: Color

    var body: some View {
        VStack(spacing: 12) {
            // Current selection pill
            HStack(spacing: 8) {
                Image(systemName: appSettings.selectedFocusSound == nil ? "speaker.slash" : "waveform")
                    .imageScale(.small)
                    .foregroundColor(.white.opacity(0.9))

                Text(currentSelectionLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())

            // List of built-in sounds
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(FocusSound.allCases) { sound in
                        soundRow(sound)
                    }

                    noSoundRow()
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var currentSelectionLabel: String {
        if appSettings.spotifyEnabledForFocus {
            return "Using Spotify for focus sound."
        }
        if let sound = appSettings.selectedFocusSound {
            return "Currently: \(sound.displayName)"
        }
        return "Currently: No sound"
    }

    private func soundRow(_ sound: FocusSound) -> some View {
        let isSelected = appSettings.selectedFocusSound == sound && !appSettings.spotifyEnabledForFocus

        return Button {
            Haptics.impact(.light)

            // Switch back to built-in → fully stop Spotify
            appSettings.spotifyEnabledForFocus = false
            appSettings.spotifyTrackURI = nil
            appSettings.spotifyTrackName = nil
            appSettings.spotifyArtistName = nil
            SpotifyManager.shared.stopAll()

            // Select this built-in sound and play a short preview
            appSettings.selectedFocusSound = sound
            FocusSoundManager.shared.play(sound: sound)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white)

                    Text("Plays while your focus timer is running.")
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .black.opacity(0.55) : .white.opacity(0.55))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.black.opacity(0.9))
                        .shadow(radius: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.10)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func noSoundRow() -> some View {
        let isSelected = appSettings.selectedFocusSound == nil && !appSettings.spotifyEnabledForFocus

        return Button {
            Haptics.impact(.light)

            // No sound → stop both built-in and Spotify
            appSettings.selectedFocusSound = nil
            appSettings.spotifyEnabledForFocus = false
            appSettings.spotifyTrackURI = nil
            appSettings.spotifyTrackName = nil
            appSettings.spotifyArtistName = nil

            FocusSoundManager.shared.stop()
            SpotifyManager.shared.stopAll()
        } label: {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.slash.fill")
                        .imageScale(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Sound")
                            .font(.system(size: 15, weight: .semibold))

                        Text("Focus in complete silence.")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .foregroundColor(isSelected ? .black : .red.opacity(0.9))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.black.opacity(0.9))
                        .shadow(radius: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.95),
                                Color.red.opacity(0.75)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.red.opacity(0.12)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - SPOTIFY TAB
// ============================================================

private struct SpotifySoundsTab: View {
    @ObservedObject private var spotify = SpotifyManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @StateObject private var webService = SpotifyWebService.shared

    @State private var searchText: String = ""
    @State private var localError: String?

    // Sub-tabs for Spotify: Search / Last played / Library
    private enum SpotifyMode: String, CaseIterable, Identifiable {
        case search
        case recent
        case library

        var id: String { rawValue }

        var title: String {
            switch self {
            case .search:  return "Search"
            case .recent:  return "Last Played"
            case .library: return "Library"
            }
        }
    }

    @State private var selectedMode: SpotifyMode = .search

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            if !spotify.hasValidToken {
                // FIRST-TIME CONNECT STATE
                connectCard
            } else {
                // Already authorized → show header + sub-modes
                connectedHeader

                spotifyModeCapsules

                switch selectedMode {
                case .search:
                    searchContent
                case .recent:
                    recentContent
                case .library:
                    libraryContent
                }
            }
        }
    }

    // MARK: - Connect card

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)

                Text("Connect to Spotify")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            Text("Link FocusFlow with your Spotify account once to search Spotify and pick any track as your focus sound.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))

            Button {
                Haptics.impact(.medium)
                // First-time or repeat: always use full auth bounce.
                SpotifyManager.shared.authorizeIfNeeded()
            } label: {
                HStack {
                    Image(systemName: "music.note")
                    Text("Connect to Spotify")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // Header with status + reconnect button
    private var connectedHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(spotify.isConnected ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            Text(spotify.isConnected ? "Connected to Spotify" : "Ready to connect")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            if !spotify.isConnected {
                Button {
                    Haptics.impact(.light)
                    // Use the same behaviour as first connect: full auth bounce.
                    SpotifyManager.shared.authorizeIfNeeded()
                } label: {
                    Text("Connect")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mode capsules

    private var spotifyModeCapsules: some View {
        HStack(spacing: 8) {
            ForEach(SpotifyMode.allCases) { mode in
                Button {
                    Haptics.impact(.light)
                    selectedMode = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedMode == mode ? .black : .white.opacity(0.8))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Group {
                                if selectedMode == mode {
                                    Color.white
                                } else {
                                    Color.white.opacity(0.12)
                                }
                            }
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - SEARCH CONTENT

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appSettings.spotifyEnabledForFocus,
               let name = appSettings.spotifyTrackName {
                selectedSpotifyRow(
                    name: name,
                    subtitle: appSettings.spotifyArtistName ?? "",
                    uri: appSettings.spotifyTrackURI ?? ""
                )
            }

            searchBar

            if let message = localError ?? webService.lastError {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if webService.isSearching {
                        Text("Searching Spotify…")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    } else if !webService.tracks.isEmpty {
                        Text("Tracks")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))

                        ForEach(webService.tracks) { track in
                            spotifyTrackRow(track)
                        }
                    } else if !(searchText.trimmingCharacters(in: .whitespaces).isEmpty) {
                        Text("No results found.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - RECENT CONTENT

    private var recentContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appSettings.spotifyEnabledForFocus,
               let name = appSettings.spotifyTrackName {

                let artistName = appSettings.spotifyArtistName ?? ""
                let uri = appSettings.spotifyTrackURI ?? ""

                Text("Last used in FocusFlow")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                recentSpotifyRow(name: name, subtitle: artistName, uri: uri)

            } else {
                Text("Once you use a Spotify track as your focus sound, it will appear here as your last played.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - LIBRARY CONTENT

    private var libraryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spotify Library")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("In a future step, this tab can list your Spotify playlists and saved albums so you can pick a whole playlist as your focus sound. For now, you can search any track from the Search tab.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - UI components

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))

            TextField("Search Spotify", text: $searchText, onCommit: {
                performSearch()
            })
            .foregroundColor(.white)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    webService.tracks = []
                    localError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func spotifyTrackRow(_ track: SpotifyTrack) -> some View {
        Button {
            Haptics.impact(.light)

            let manager = SpotifyManager.shared
            let wasFocusPlaying = manager.isPlayingFocusTrack

            // Mark Spotify as the focus engine
            appSettings.spotifyEnabledForFocus = true
            appSettings.spotifyTrackURI = track.uri
            appSettings.spotifyTrackName = track.name
            appSettings.spotifyArtistName = track.artistNames

            // Configure focus track
            manager.setFocusTrack(uri: track.uri)

            if wasFocusPlaying {
                // Timer is running & Spotify focus was playing:
                // Immediately switch focus playback to this track (no "preview-only").
                manager.startFocusPlayback(using: track.uri)
            } else {
                // Timer not running (or not using Spotify):
                // Just preview; closing the sheet will stop it.
                manager.playPreview(uri: track.uri)
            }

        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading) {
                    Text(track.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(track.artistNames)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                if appSettings.spotifyTrackURI == track.uri && appSettings.spotifyEnabledForFocus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func recentSpotifyRow(name: String, subtitle: String, uri: String) -> some View {
        Button {
            Haptics.impact(.light)

            let manager = SpotifyManager.shared
            let wasFocusPlaying = manager.isPlayingFocusTrack

            appSettings.spotifyEnabledForFocus = true
            appSettings.spotifyTrackURI = uri
            appSettings.spotifyTrackName = name
            appSettings.spotifyArtistName = subtitle

            manager.setFocusTrack(uri: uri)

            if wasFocusPlaying {
                manager.startFocusPlayback(using: uri)
            } else {
                manager.playPreview(uri: uri)
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Spacer()

                if appSettings.spotifyTrackURI == uri && appSettings.spotifyEnabledForFocus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func selectedSpotifyRow(name: String, subtitle: String, uri: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            Button {
                Haptics.impact(.light)

                // Turning off Spotify → stop everything in SpotifyManager
                appSettings.spotifyEnabledForFocus = false
                appSettings.spotifyTrackURI = nil
                appSettings.spotifyTrackName = nil
                appSettings.spotifyArtistName = nil

                SpotifyManager.shared.setFocusTrack(uri: nil)
                SpotifyManager.shared.stopAll()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Search hook

    private func performSearch() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            webService.tracks = []
            localError = nil
            return
        }

        guard spotify.hasValidToken, SpotifyManager.shared.apiAccessToken != nil else {
            localError = "Please connect Spotify first."
            return
        }

        localError = nil
        webService.searchTracks(query: q)
    }
}

#Preview {
    FocusSoundPicker()
}
