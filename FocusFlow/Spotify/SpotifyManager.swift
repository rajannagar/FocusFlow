import Foundation
import UIKit
import SpotifyiOS
import Combine

/// Global Spotify integration for FocusFlow.
/// Uses the Spotify app as the actual player (App Remote).
final class SpotifyManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = SpotifyManager()

    // MARK: - Published state (for SwiftUI)

    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTrackName: String?
    @Published private(set) var currentArtistName: String?
    /// True if we currently have a usable access token (for Web API + App Remote).
    @Published private(set) var hasValidToken: Bool = false

    /// True when the *focus* track (tied to timer) is playing.
    @Published private(set) var isPlayingFocusTrack: Bool = false

    /// True when we’re doing a short preview (from the picker sheet).
    @Published private(set) var isPreviewing: Bool = false

    // MARK: - Spotify SDK objects

    private let configuration: SPTConfiguration
    let appRemote: SPTAppRemote

    /// Last URI we wanted to play as a focus track (for auto-play after connect).
    private var pendingPlayURI: String?

    /// When true, we should resume focus playback once connection is established.
    private var shouldResumeAfterConnect: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private let tokenKey = "ff.spotify.accessToken"

    // MARK: - Access token for Web API calls

    /// Re-used by SpotifyWebService for search + playlists.
    var apiAccessToken: String? {
        if let token = appRemote.connectionParameters.accessToken {
            return token
        }
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    // MARK: - Focus playback state

    /// Currently configured focus URI (track / playlist) for the timer.
    private var focusURI: String?

    /// Last known playback position in ms for the focus track.
    private var focusPositionMs: Int = 0

    // MARK: - Preview state

    private var previewURI: String?
    private var previewTimer: Timer?
    private let previewDuration: TimeInterval = 8

    // MARK: - Init

    private override init() {
        let config = SPTConfiguration(
            clientID: SpotifyConfig.clientID,
            redirectURL: SpotifyConfig.redirectURI
        )

        // We will pass URIs directly to playerAPI, so this can stay nil.
        config.playURI = nil

        self.configuration = config
        self.appRemote = SPTAppRemote(configuration: config, logLevel: .debug)

        super.init()

        self.appRemote.delegate = self

        // Restore token so user doesn't have to approve every launch.
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey) {
            appRemote.connectionParameters.accessToken = savedToken
            hasValidToken = true
        }
    }

    // MARK: - Public convenience

    /// Check if Spotify app is installed.
    var isSpotifyInstalled: Bool {
        guard let url = URL(string: "spotify:") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Authorization / connect flow.
    ///
    /// Simplified + robust:
    /// - ALWAYS bounce via authorizeAndPlayURI("") when user taps "Connect".
    /// - Spotify wakes up, handles auth, and sends us back to the redirect URI.
    /// - In handleOpenURL we grab the token and call connectIfNeeded().
    func authorizeIfNeeded() {
        guard isSpotifyInstalled else {
            print("SpotifyManager.authorizeIfNeeded() – Spotify not installed.")
            return
        }

        // This button always does a clean auth bounce.
        pendingPlayURI = nil
        shouldResumeAfterConnect = false

        print("SpotifyManager.authorizeIfNeeded() – starting auth bounce with authorizeAndPlayURI(\"\")")
        appRemote.authorizeAndPlayURI("") { success in
            if !success {
                print("Spotify authorizeAndPlayURI(\"\") failed when trying to connect.")
            }
        }
    }

    // MARK: - Focus playback API (used by Focus timer + high level)

    /// Configure which URI should be used as the focus track.
    /// Call this when user confirms a selection in the picker.
    func setFocusTrack(uri: String?) {
        focusURI = uri
        focusPositionMs = 0
    }

    /// Start focus playback (used when timer starts, or when user picks Spotify while timer is running).
    func startFocusPlayback(using uriOverride: String? = nil) {
        guard let uri = uriOverride ?? focusURI else {
            print("SpotifyManager: startFocusPlayback called without a URI.")
            return
        }

        focusURI = uri
        isPreviewing = false
        stopPreviewTimer()

        internalPlay(uri: uri, forFocus: true)
    }

    /// Pause focus playback (used when timer pauses).
    func pauseFocusPlayback() {
        guard appRemote.isConnected, isPlayingFocusTrack else { return }

        // Capture current position so we can *theoretically* resume later.
        appRemote.playerAPI?.getPlayerState { [weak self] result, error in
            guard let self else { return }

            if let state = result as? SPTAppRemotePlayerState {
                self.focusPositionMs = Int(state.playbackPosition)
            } else if let error = error {
                print("Spotify getPlayerState error:", error.localizedDescription)
            }

            self.appRemote.playerAPI?.pause { _, pauseError in
                if let pauseError = pauseError {
                    print("Spotify pause error:", pauseError.localizedDescription)
                }
                self.isPlaying = false
                self.isPlayingFocusTrack = false
            }
        }
    }

    /// Resume focus playback from last known position (used when timer resumes).
    /// Note: without playbackOptions we rely on Spotify's own pause/resume behaviour.
    func resumeFocusPlayback() {
        if appRemote.isConnected {
            appRemote.playerAPI?.resume { [weak self] _, error in
                guard let self else { return }

                if let error = error {
                    print("Spotify resume error:", error.localizedDescription)
                    // Fallback: if resume fails, try to play the track again.
                    if let uri = self.focusURI {
                        self.internalPlay(uri: uri, forFocus: true)
                    }
                } else {
                    self.isPlaying = true
                    self.isPlayingFocusTrack = true
                }
            }
        } else if apiAccessToken != nil {
            shouldResumeAfterConnect = true
            connectIfNeeded()
        } else {
            print("Spotify: resume failed — no token available")
        }
    }

    /// Stop focus playback completely (used when timer resets / finishes).
    func stopFocusPlayback() {
        focusPositionMs = 0
        isPlayingFocusTrack = false

        if appRemote.isConnected {
            appRemote.playerAPI?.pause { [weak self] _, error in
                if let error = error {
                    print("Spotify stopFocusPlayback pause error:", error.localizedDescription)
                }
                self?.isPlaying = false
            }
        } else {
            isPlaying = false
        }
    }

    /// Fully stop anything Spotify is doing (focus + preview).
    func stopAll() {
        stopPreview()
        stopFocusPlayback()
    }

    // MARK: - Preview playback API (used by FocusSoundPicker)

    /// Short preview when user taps a search result in the Spotify picker.
    func playPreview(uri: String) {
        // Stop any previous preview
        stopPreview()

        previewURI = uri
        isPreviewing = true
        isPlayingFocusTrack = false   // this is just a preview

        guard appRemote.isConnected else {
            print("SpotifyManager: cannot preview, not connected. Ask user to connect first.")
            return
        }

        internalPlay(uri: uri, forFocus: false, isPreview: true)
        startPreviewTimer()
    }

    /// Called when sheet disappears or user confirms selection.
    func stopPreview() {
        stopPreviewTimer()
        isPreviewing = false

        // Only stop Spotify if we're not in an active focus session.
        if !isPlayingFocusTrack, appRemote.isConnected {
            appRemote.playerAPI?.pause { [weak self] _, error in
                if let error = error {
                    print("Spotify stopPreview pause error:", error.localizedDescription)
                }
                self?.isPlaying = false
            }
        }
    }

    // MARK: - Backwards-compatible public methods

    /// OLD API: Play a URI. Now treated as "start focus playback for this URI".
    func play(uri: String) {
        setFocusTrack(uri: uri)
        startFocusPlayback(using: uri)
    }

    /// OLD API: pause. Now pauses focus playback.
    func pause() {
        pauseFocusPlayback()
    }

    /// OLD API: resume for focus. Now resumes focus playback.
    func resumeForFocus() {
        resumeFocusPlayback()
    }

    /// OLD API: stop. Now stops focus playback.
    func stop() {
        stopFocusPlayback()
        pendingPlayURI = nil
    }

    // MARK: - URL handling for redirect

    func handleOpenURL(_ url: URL) {
        print("SpotifyManager.handleOpenURL:", url)

        guard let params = appRemote.authorizationParameters(from: url) else {
            print("Spotify: no auth params in URL")
            return
        }

        if let token = params[SPTAppRemoteAccessTokenKey] {
            print("Spotify: received access token")
            appRemote.connectionParameters.accessToken = token
            hasValidToken = true
            UserDefaults.standard.set(token, forKey: tokenKey)
            connectIfNeeded()
        } else if let error = params[SPTAppRemoteErrorDescriptionKey] {
            print("Spotify auth error:", error)
        } else {
            print("Spotify: unexpected auth parameters:", params)
        }
    }

    // MARK: - Connection helpers

    /// Called after we have a token (e.g. from handleOpenURL) or when
    /// FocusFlow becomes active and we already know we’re authorized.
    func connectIfNeeded() {
        guard appRemote.connectionParameters.accessToken != nil || hasValidToken else {
            print("SpotifyManager.connectIfNeeded() – no token yet")
            return
        }

        guard !appRemote.isConnected else {
            print("SpotifyManager.connectIfNeeded() – already connected")
            return
        }

        print("SpotifyManager.connectIfNeeded() – attempting App Remote connect")
        appRemote.connect()
    }

    func disconnect() {
        if appRemote.isConnected {
            print("SpotifyManager.disconnect() – disconnecting App Remote")
            appRemote.disconnect()
        }
    }

    // MARK: - Internal playback helper

    /// Centralized helper that handles connection / pending URIs.
    private func internalPlay(
        uri: String,
        forFocus: Bool,
        isPreview: Bool = false
    ) {
        if forFocus {
            isPlayingFocusTrack = true
            isPreviewing = false
        } else if isPreview {
            isPlayingFocusTrack = false
            isPreviewing = true
        }

        if appRemote.isConnected {
            appRemote.playerAPI?.play(uri, callback: { [weak self] _, error in
                guard let self else { return }

                if let error = error {
                    print("Spotify play error:", error.localizedDescription)
                    if forFocus {
                        self.isPlayingFocusTrack = false
                    }
                    self.isPlaying = false
                } else {
                    self.isPlaying = true
                    if forFocus {
                        self.focusURI = uri
                    }
                }
            })
        } else {
            if forFocus {
                // For focus playback we want the classic "connect then auto play" behaviour.
                pendingPlayURI = uri
                shouldResumeAfterConnect = false
                if apiAccessToken != nil {
                    connectIfNeeded()
                } else {
                    print("Spotify: no token, call authorizeIfNeeded() from the UI first.")
                }
            } else if isPreview {
                print("SpotifyManager: cannot preview, not connected.")
            }
        }
    }

    // MARK: - Preview timer

    private func startPreviewTimer() {
        stopPreviewTimer()
        previewTimer = Timer.scheduledTimer(withTimeInterval: previewDuration,
                                            repeats: false) { [weak self] _ in
            self?.stopPreview()
        }
    }

    private func stopPreviewTimer() {
        previewTimer?.invalidate()
        previewTimer = nil
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyManager: SPTAppRemoteDelegate {

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Spotify: Connected")
        isConnected = true

        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("Spotify subscribe error:", error.localizedDescription)
            }
        })

        // If this connection was just for auth (no pending URI, no resume),
        // make sure we are not leaving anything playing that we triggered.
        if pendingPlayURI == nil && !shouldResumeAfterConnect {
            appRemote.playerAPI?.pause { _, _ in }
        }

        // Auto-play if a focus URI was pending (user picked something before connect).
        if let uri = pendingPlayURI {
            appRemote.playerAPI?.play(uri, callback: { [weak self] _, error in
                if let error = error {
                    print("Play after connect error:", error.localizedDescription)
                } else {
                    self?.isPlaying = true
                    self?.isPlayingFocusTrack = true
                }
            })
        }

        // Auto-resume after reconnect (legacy behaviour)
        if shouldResumeAfterConnect {
            shouldResumeAfterConnect = false
            appRemote.playerAPI?.resume { [weak self] _, error in
                if let error = error {
                    print("Resume-after-connect error:", error.localizedDescription)
                } else {
                    self?.isPlaying = true
                    self?.isPlayingFocusTrack = true
                }
            }
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Spotify: Disconnected:", error?.localizedDescription ?? "nil")
        isConnected = false
        isPlaying = false
        isPlayingFocusTrack = false
        isPreviewing = false
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Spotify: Connection failed:", error?.localizedDescription ?? "nil")
        isConnected = false
        isPlaying = false
        isPlayingFocusTrack = false
        isPreviewing = false
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        currentTrackName = playerState.track.name
        currentArtistName = playerState.track.artist.name
        isPlaying = !playerState.isPaused

        // If this is the focus URI, keep our position roughly up to date.
        if let focusURI = focusURI, playerState.track.uri == focusURI {
            focusPositionMs = Int(playerState.playbackPosition)
        }
    }
}
