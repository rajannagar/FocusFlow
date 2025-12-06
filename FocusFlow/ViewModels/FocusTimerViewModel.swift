import Foundation
import Combine

class FocusTimerViewModel: ObservableObject {
    // Total length of the session (in seconds)
    @Published var totalSeconds: Int
    // How many seconds are left
    @Published var remainingSeconds: Int
    // Is the timer currently running?
    @Published var isRunning: Bool = false
    // Let the UI know when a session has completed
    @Published var didCompleteSession: Bool = false

    // Internal timer object
    private var timer: Timer?
    // Wall-clock based end time
    private var endDate: Date?

    init() {
        let defaultMinutes = 25
        self.totalSeconds = defaultMinutes * 60
        self.remainingSeconds = defaultMinutes * 60
    }

    // "MM:SS"
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // 0...1 for ring
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - Double(remainingSeconds) / Double(totalSeconds)
    }

    // Change the session length (in minutes)
    func updateMinutes(_ minutes: Int) {
        let safeMinutes = max(1, minutes) // at least 1 min
        invalidateTimer()
        isRunning = false
        didCompleteSession = false
        endDate = nil
        totalSeconds = safeMinutes * 60
        remainingSeconds = totalSeconds
    }

    // Start (or restart) a focus session
    func start() {
        if isRunning { return }

        // If we’re at 0, treat this as a new run of the same length
        if remainingSeconds <= 0 {
            remainingSeconds = totalSeconds
            didCompleteSession = false
        }

        guard totalSeconds > 0 else { return }

        isRunning = true
        didCompleteSession = false

        // Compute target end time based on *current* remaining seconds
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        invalidateTimer()

        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }

            guard let endDate = self.endDate else {
                self.isRunning = false
                t.invalidate()
                return
            }

            // Use wall clock; ceil so we don't visually skip a second
            let secondsLeft = max(0, Int(ceil(endDate.timeIntervalSinceNow)))

            if secondsLeft != self.remainingSeconds {
                self.remainingSeconds = secondsLeft
            }

            if secondsLeft <= 0 {
                self.isRunning = false
                self.didCompleteSession = true
                self.endDate = nil
                t.invalidate()
            }
        }

        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    // Pause without resetting the time
    func stop() {
        // Snap remainingSeconds to the exact wall-clock value at pause
        if let endDate = endDate {
            let secondsLeft = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
            remainingSeconds = secondsLeft
        }

        isRunning = false
        endDate = nil
        invalidateTimer()
    }

    // Full reset
    func reset() {
        invalidateTimer()
        isRunning = false
        didCompleteSession = false
        endDate = nil
        remainingSeconds = totalSeconds
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        invalidateTimer()
    }
}
