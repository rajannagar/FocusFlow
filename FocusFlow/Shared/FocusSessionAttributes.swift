import Foundation
import ActivityKit

@available(iOS 18.0, *)
struct FocusSessionAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// When this session is expected to finish (used for live countdown).
        var endDate: Date

        /// Whether the session is currently paused.
        var isPaused: Bool

        /// Display name like “Deep work”.
        var sessionName: String

        /// Current theme id.
        var themeID: String

        /// Static string to show when paused.
        var pausedDisplayTime: String
        
        /// EXACT remaining seconds.
        /// Ensures we don't lose precision when pausing/resuming.
        var remainingSeconds: Int
        
        /// 🆕 Completion Status
        /// If true, the widget UI will show "Session Complete" / Checkmark
        var isCompleted: Bool = false
    }

    /// Total duration of the session (seconds).
    var totalDuration: TimeInterval
}
