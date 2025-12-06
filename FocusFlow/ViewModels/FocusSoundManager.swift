import Foundation
import AVFoundation

final class FocusSoundManager: NSObject {
    static let shared = FocusSoundManager()

    private var audioPlayer: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    private var isSessionConfigured = false

    private override init() {
        super.init()
    }

    private func prepareSessionIfNeeded() {
        guard !isSessionConfigured else { return }

        do {
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: [.mixWithOthers])
            try session.setActive(true)
            isSessionConfigured = true
        } catch {
            print("Sound session error:", error)
        }
    }

    // MARK: - Play selected sound (fresh)
    func play(sound: FocusSound) {
        stop() // fully reset first

        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            print("❌ Missing sound file:", sound.fileName)
            return
        }

        prepareSessionIfNeeded()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // infinite loop
            player.prepareToPlay()
            player.play()

            audioPlayer = player
        } catch {
            print("Audio error:", error)
        }
    }

    // MARK: - Pause (keep playback position)
    func pause() {
        audioPlayer?.pause()
    }

    // MARK: - Resume (continue from last position)
    func resume() {
        audioPlayer?.play()
    }

    // MARK: - Full stop (reset position)
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
