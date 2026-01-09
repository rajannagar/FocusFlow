import Foundation
import Combine

/// Central data manager for the Watch app
/// Receives data from iPhone and manages local state
@MainActor
final class WatchDataManager: ObservableObject {
    static let shared = WatchDataManager()
    
    // MARK: - Pro Status
    @Published var isPro: Bool = false
    
    // MARK: - Session State
    @Published var sessionPhase: SessionPhase = .idle
    @Published var totalSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var currentSessionName: String = ""
    
    enum SessionPhase: String, Codable {
        case idle
        case running
        case paused
        case completed
    }
    
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }
    
    // MARK: - Progress Data
    @Published var todayFocusSeconds: TimeInterval = 0
    @Published var dailyGoalMinutes: Int = 120
    @Published var currentStreak: Int = 0
    @Published var todaySessionCount: Int = 0
    @Published var lifetimeSessions: Int = 0
    
    // MARK: - XP & Level
    @Published var level: Int = 1
    @Published var xp: Int = 0
    @Published var xpToNextLevel: Int = 100
    
    // MARK: - Badges
    @Published var recentBadges: [String] = []
    @Published var allBadges: [String] = []
    
    // MARK: - Presets
    @Published var presets: [WatchPreset] = []
    
    // MARK: - Tasks
    @Published var tasks: [WatchTask] = []
    
    // MARK: - Settings
    @Published var syncThemeWithiPhone: Bool = true
    @Published var selectedTheme: String = "forest"
    @Published var hapticsEnabled: Bool = true
    @Published var hapticOnComplete: Bool = true
    @Published var hapticOnMilestone: Bool = true
    
    // MARK: - Timer
    private var timer: Timer?
    private var sessionEndDate: Date?
    
    private init() {
        loadFromAppGroup()
        
        // Add sample data for development
        #if DEBUG
        loadSampleData()
        #endif
    }
    
    // MARK: - App Group Data Loading
    
    private func loadFromAppGroup() {
        guard let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow") else { return }
        
        isPro = defaults.bool(forKey: "widget.isPro")
        todayFocusSeconds = defaults.double(forKey: "widget.todayFocusSeconds")
        dailyGoalMinutes = defaults.integer(forKey: "widget.dailyGoalMinutes")
        currentStreak = defaults.integer(forKey: "widget.currentStreak")
        selectedTheme = defaults.string(forKey: "widget.selectedTheme") ?? "forest"
    }
    
    // MARK: - Session Control
    
    func toggleSession() {
        switch sessionPhase {
        case .idle:
            startSession()
        case .running:
            pauseSession()
        case .paused:
            resumeSession()
        case .completed:
            resetSession()
        }
    }
    
    func startSession() {
        sessionPhase = .running
        sessionEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startTimer()
        
        // Notify iPhone
        WatchConnectivityManager.shared.sendSessionStateUpdate(
            phase: .running,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            sessionName: currentSessionName
        )
        
        // Haptic feedback
        if hapticsEnabled {
            WatchHaptics.sessionStarted()
        }
    }
    
    func pauseSession() {
        sessionPhase = .paused
        stopTimer()
        
        // Calculate remaining time
        if let endDate = sessionEndDate {
            remainingSeconds = max(0, Int(endDate.timeIntervalSince(Date())))
        }
        
        // Notify iPhone
        WatchConnectivityManager.shared.sendSessionStateUpdate(
            phase: .paused,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            sessionName: currentSessionName
        )
    }
    
    func resumeSession() {
        sessionPhase = .running
        sessionEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startTimer()
        
        // Notify iPhone
        WatchConnectivityManager.shared.sendSessionStateUpdate(
            phase: .running,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            sessionName: currentSessionName
        )
    }
    
    func resetSession() {
        sessionPhase = .idle
        remainingSeconds = totalSeconds
        sessionEndDate = nil
        stopTimer()
    }
    
    func endSession() {
        sessionPhase = .completed
        stopTimer()
        
        // Notify iPhone of completion
        WatchConnectivityManager.shared.sendSessionCompleted(
            duration: totalSeconds - remainingSeconds,
            sessionName: currentSessionName
        )
        
        // Haptic feedback
        if hapticsEnabled && hapticOnComplete {
            WatchHaptics.sessionCompleted()
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timerTick() {
        guard let endDate = sessionEndDate else { return }
        
        let remaining = Int(endDate.timeIntervalSince(Date()))
        
        if remaining <= 0 {
            remainingSeconds = 0
            endSession()
        } else {
            remainingSeconds = remaining
            
            // Milestone haptic (5 minutes remaining)
            if hapticsEnabled && hapticOnMilestone && remaining == 300 {
                WatchHaptics.milestone()
            }
        }
    }
    
    // MARK: - Preset Activation
    
    func activatePreset(_ preset: WatchPreset) {
        totalSeconds = preset.durationMinutes * 60
        remainingSeconds = totalSeconds
        currentSessionName = preset.name
        sessionPhase = .idle
        
        // Notify iPhone
        WatchConnectivityManager.shared.sendPresetActivated(presetId: preset.id)
    }
    
    // MARK: - Task Management
    
    func toggleTaskCompletion(_ taskId: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].isCompleted.toggle()
            
            // Notify iPhone
            WatchConnectivityManager.shared.sendTaskToggled(taskId: taskId, isCompleted: tasks[index].isCompleted)
            
            // Haptic feedback
            if hapticsEnabled {
                WatchHaptics.taskCompleted()
            }
        }
    }
    
    // MARK: - Update from iPhone
    
    func updateFromiPhone(_ payload: [String: Any]) {
        if let pro = payload["isPro"] as? Bool {
            isPro = pro
        }
        
        if let phase = payload["sessionPhase"] as? String,
           let sessionPhase = SessionPhase(rawValue: phase) {
            self.sessionPhase = sessionPhase
        }
        
        if let remaining = payload["remainingSeconds"] as? Int {
            remainingSeconds = remaining
        }
        
        if let total = payload["totalSeconds"] as? Int {
            totalSeconds = total
        }
        
        if let name = payload["sessionName"] as? String {
            currentSessionName = name
        }
        
        if let focus = payload["todayFocusSeconds"] as? Double {
            todayFocusSeconds = focus
        }
        
        if let streak = payload["currentStreak"] as? Int {
            currentStreak = streak
        }
        
        if let lvl = payload["level"] as? Int {
            level = lvl
        }
        
        if let xpVal = payload["xp"] as? Int {
            xp = xpVal
        }
        
        // Handle session state changes
        if sessionPhase == .running && timer == nil {
            if let endDateTimestamp = payload["sessionEndDate"] as? TimeInterval {
                sessionEndDate = Date(timeIntervalSince1970: endDateTimestamp)
                startTimer()
            }
        } else if sessionPhase != .running {
            stopTimer()
        }
    }
    
    // MARK: - Sample Data (Debug)
    
    #if DEBUG
    private func loadSampleData() {
        isPro = true
        todayFocusSeconds = 5400 // 1.5 hours
        currentStreak = 12
        todaySessionCount = 4
        lifetimeSessions = 156
        level = 24
        xp = 2450
        xpToNextLevel = 100
        
        presets = [
            WatchPreset(id: "1", name: "Deep Work", emoji: "🎯", durationMinutes: 25),
            WatchPreset(id: "2", name: "Creative", emoji: "💡", durationMinutes: 45),
            WatchPreset(id: "3", name: "Study", emoji: "📚", durationMinutes: 50),
            WatchPreset(id: "4", name: "Quick Focus", emoji: "⚡", durationMinutes: 15)
        ]
        
        tasks = [
            WatchTask(id: "1", title: "Review PR", isCompleted: false, dueDate: Date()),
            WatchTask(id: "2", title: "Write documentation", isCompleted: false, dueDate: Date().addingTimeInterval(86400)),
            WatchTask(id: "3", title: "Team meeting", isCompleted: true, dueDate: nil)
        ]
        
        recentBadges = ["🏆", "🔥", "📚", "⭐", "🎯"]
        allBadges = ["🏆", "🔥", "📚", "⭐", "🎯", "💪", "🧠", "🌟", "🚀", "💎"]
    }
    #endif
}

// MARK: - Watch Models

struct WatchPreset: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let durationMinutes: Int
}

struct WatchTask: Identifiable, Codable {
    let id: String
    let title: String
    var isCompleted: Bool
    let dueDate: Date?
}
