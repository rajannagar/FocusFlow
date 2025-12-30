import Foundation
import AppIntents
import ActivityKit

@available(iOSApplicationExtension 18.0, *)
struct ToggleFocusPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Focus Session"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let activity = Activity<FocusSessionAttributes>.activities.first else {
            return .result()
        }

        let state = activity.content.state
        let now = Date()
        let currentlyPaused = state.isPaused

        // Calculate exact seconds based on state
        let remainingSeconds: Int
        if currentlyPaused {
            remainingSeconds = state.remainingSeconds
        } else {
            let secondsLeft = state.endDate.timeIntervalSince(now)
            remainingSeconds = max(0, Int(secondsLeft))
        }

        let newIsPaused = !currentlyPaused
        let newEndDate: Date
        
        if newIsPaused {
            // RUNNING -> PAUSED
            newEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        } else {
            // PAUSED -> RUNNING
            newEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        }

        let newPausedDisplay = Self.formatRemaining(remainingSeconds)

        let newState = FocusSessionAttributes.ContentState(
            endDate: newEndDate,
            isPaused: newIsPaused,
            sessionName: state.sessionName,
            themeID: state.themeID,
            pausedDisplayTime: newPausedDisplay,
            remainingSeconds: remainingSeconds,
            isCompleted: false // Explicitly false while toggling
        )

        let content = ActivityContent(state: newState, staleDate: nil)
        await activity.update(content)

        // Notify App via Bridge
        FocusSessionBridge.writeFromLiveActivity(
            isPaused: newIsPaused,
            remainingSeconds: remainingSeconds
        )

        return .result()
    }

    // MARK: - Helpers
    private static func formatRemaining(_ totalSeconds: Int) -> String {
        let clamped = max(0, totalSeconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
