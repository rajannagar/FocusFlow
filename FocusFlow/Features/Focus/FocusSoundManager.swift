import Foundation
import Combine
import AVFoundation

final class FocusSoundManager: NSObject {
    static let shared = FocusSoundManager()

    private let session = AVAudioSession.sharedInstance()
    private var audioPlayer: AVAudioPlayer?
    private var isSessionConfigured = false
    private var shouldResumeAfterInterruption = false
    private var currentSound: FocusSound?

    // MARK: - Init / deinit

    private override init() {
        super.init()

        // Listen for system audio interruptions (phone calls, Siri, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVAudioSession

    /// Configure the audio session for FocusFlow ambience.
    ///
    /// We *do not* use `.mixWithOthers` here because:
    /// - When FocusFlow plays a sound (preview or session), we want other music apps to stop.
    private func prepareSessionIfNeeded() {
        do {
            // Always set category and activate session when playing
            // This ensures the session is active even if it was deactivated
            try session.setCategory(
                .playback,
                mode: .default,
                options: []              // no .mixWithOthers → we take audio focus
            )
            try session.setActive(true)
            isSessionConfigured = true
            print("🎵 Audio session activated")
        } catch {
            print("🎧 FocusSoundManager – session error:", error)
            isSessionConfigured = false
        }
    }

    // MARK: - Public API

    /// Play a given focus sound from the start, looping forever.
    /// This is used for both previews (in the picker) and actual focus sessions.
    /// Either way, it will interrupt external music.
    func play(sound: FocusSound) {
        print("🎵 FocusSoundManager.play() called for sound: \(sound.fileName)")
        print("🎵 Current sound: \(currentSound?.fileName ?? "nil"), player exists: \(audioPlayer != nil), isPlaying: \(audioPlayer?.isPlaying ?? false)")
        
        // If the same sound is already playing, don't restart it
        // This prevents music from restarting when returning to FocusView from another tab
        if let current = currentSound, current == sound, let player = audioPlayer, player.isPlaying {
            print("🎵 Sound already playing, skipping")
            return
        }
        
        // If the same sound is loaded but paused, resume it instead of restarting
        if let current = currentSound, current == sound, let player = audioPlayer, !player.isPlaying {
            print("🎵 Sound loaded but paused, resuming")
            resume()
            return
        }
        
        print("🎵 Starting new sound playback")
        stop() // fully reset first

        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            print("❌ FocusSoundManager – missing sound file:", sound.fileName)
            return
        }

        prepareSessionIfNeeded()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // infinite loop
            player.volume = 1.0                // default volume; can be changed via setVolume(_:)
            player.prepareToPlay()
            let didPlay = player.play()
            
            print("🎵 Player created, play() returned: \(didPlay), isPlaying: \(player.isPlaying)")

            audioPlayer = player
            currentSound = sound
        } catch {
            print("🎧 FocusSoundManager – audio error:", error)
        }
    }

    /// Pause (keep playback position)
    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
    }

    /// Resume (continue from last position)
    func resume() {
        guard let player = audioPlayer else { return }

        // Make sure session is active again if needed
        prepareSessionIfNeeded()
        player.play()
    }

    /// Full stop (reset position and release player).
    func stop() {
        print("🎵 FocusSoundManager.stop() called")
        audioPlayer?.stop()
        audioPlayer = nil
        currentSound = nil
        shouldResumeAfterInterruption = false
        // Note: We don't deactivate the audio session here to avoid issues
        // The session will be reused when play() is called again
    }
    
    /// Check if a specific sound is currently playing
    func isPlaying(sound: FocusSound) -> Bool {
        return currentSound == sound && audioPlayer?.isPlaying == true
    }
    
    /// Check if a specific sound is loaded (playing or paused)
    func isLoaded(sound: FocusSound) -> Bool {
        return currentSound == sound && audioPlayer != nil
    }
    
    /// Check if any sound is currently playing
    var isAnySoundPlaying: Bool {
        return audioPlayer?.isPlaying == true
    }

    /// Optional: external volume control (0.0 – 1.0)
    func setVolume(_ value: Float) {
        let clamped = max(0.0, min(1.0, value))
        audioPlayer?.volume = clamped
    }

    // MARK: - Interruption handling

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            if let player = audioPlayer, player.isPlaying {
                shouldResumeAfterInterruption = true
                player.pause()
            } else {
                shouldResumeAfterInterruption = false
            }

        case .ended:
            guard
                let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt
            else { return }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume), shouldResumeAfterInterruption {
                shouldResumeAfterInterruption = false
                resume()
            }

        @unknown default:
            break
        }
    }
}
