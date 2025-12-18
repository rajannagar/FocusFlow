import Foundation

@available(iOS 18.0, *)
final class FocusSessionStore {
    static let shared = FocusSessionStore()

    // Your existing properties…
    // var isPaused: Bool
    // var remainingSeconds: Int
    // ...

    /// Call this when the app becomes active or when focus screen appears,
    /// to reflect any pause/resume that happened from the Dynamic Island.
    func applyExternalToggleIfNeeded() {
        guard let change = FocusSessionBridge.consumeInApp() else {
            return
        }

        let isPaused = change.isPaused
        let remaining = change.remainingSeconds

        print("FocusSessionStore: applying external toggle from island (paused=\(isPaused), remaining=\(remaining)s)")

        // TODO: adapt to your own timer implementation:
        if isPaused {
            // e.g.
            pauseFromExternal(remainingSeconds: remaining)
        } else {
            resumeFromExternal(remainingSeconds: remaining)
        }
    }

    // MARK: - Example handlers (replace with your real ones)

    func pauseFromExternal(remainingSeconds: Int) {
        // stop your timer, store remainingSeconds, set isPaused true, etc.
    }

    func resumeFromExternal(remainingSeconds: Int) {
        // restart your timer from remainingSeconds, set isPaused false, etc.
    }
}
