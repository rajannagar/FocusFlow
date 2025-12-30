import Foundation

/// Simple bridge between the Live Activity extension and the main app,
/// using App Group–backed UserDefaults.
enum FocusSessionBridge {
    // ✅ MUST be your App Group ID (with "group." prefix),
    // AND it must be enabled in both app + widget targets.
    private static let suiteName = "group.ca.softcomputers.FocusFlow"  // <— update to match Xcode

    private static var defaults: UserDefaults? {
        let d = UserDefaults(suiteName: suiteName)
        if d == nil {
            print("FocusSessionBridge: ❌ Failed to load UserDefaults for suite \(suiteName)")
        }
        return d
    }

    // Keys
    private static let keyIsPaused       = "focus.isPausedFromIsland"
    private static let keyRemainingSecs  = "focus.remainingSecondsFromIsland"
    private static let keyLastUpdateTime = "focus.lastIslandUpdateTime"

    /// Called from the Live Activity intent when user taps pause/play.
    static func writeFromLiveActivity(isPaused: Bool, remainingSeconds: Int) {
        guard let defaults else {
            print("FocusSessionBridge: ❌ No defaults in writeFromLiveActivity")
            return
        }

        defaults.set(isPaused, forKey: keyIsPaused)
        defaults.set(remainingSeconds, forKey: keyRemainingSecs)
        defaults.set(Date().timeIntervalSince1970, forKey: keyLastUpdateTime)
        defaults.synchronize()

        print("FocusSessionBridge: ✅ wrote isPaused=\(isPaused), remaining=\(remainingSeconds)")
    }

    /// Peek at the bridge state without consuming it (for background monitoring)
    static func peekState() -> (isPaused: Bool, remainingSeconds: Int, lastUpdateTime: TimeInterval)? {
        guard let defaults else { return nil }
        
        let lastUpdate = defaults.double(forKey: keyLastUpdateTime)
        if lastUpdate == 0 {
            return nil
        }
        
        let isPaused = defaults.bool(forKey: keyIsPaused)
        let remaining = defaults.integer(forKey: keyRemainingSecs)
        
        return (isPaused, remaining, lastUpdate)
    }

    /// Called from the app when it comes into foreground / timer view opens.
    /// Returns the latest toggle info once and then clears it.
    static func consumeInApp() -> (isPaused: Bool, remainingSeconds: Int)? {
        guard let defaults else {
            print("FocusSessionBridge: ❌ No defaults in consumeInApp")
            return nil
        }

        let lastUpdate = defaults.double(forKey: keyLastUpdateTime)
        if lastUpdate == 0 {
            return nil
        }

        let isPaused = defaults.bool(forKey: keyIsPaused)
        let remaining = defaults.integer(forKey: keyRemainingSecs)

        // Clear so we don't apply twice
        defaults.removeObject(forKey: keyIsPaused)
        defaults.removeObject(forKey: keyRemainingSecs)
        defaults.removeObject(forKey: keyLastUpdateTime)

        print("FocusSessionBridge: ✅ consumed toggle isPaused=\(isPaused), remaining=\(remaining)")
        return (isPaused, remaining)
    }
}
