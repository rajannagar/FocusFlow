import SwiftUI
import Combine

// MARK: - Flow Proactive Engine

/// Intelligent nudge system that learns from user behavior
/// and provides proactive suggestions at optimal times

@MainActor
final class FlowProactiveEngine: ObservableObject {
    static let shared = FlowProactiveEngine()
    
    // MARK: - State
    
    @Published private(set) var isAnalyzing = false
    @Published private(set) var lastInsight: ProactiveInsight?
    @Published private(set) var pendingNudges: [ProactiveNudge] = []
    
    // MARK: - Dependencies
    
    private let context = FlowContext.shared
    private let hintManager = FlowHintManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    private let analysisInterval: TimeInterval = 300 // 5 minutes
    private let maxNudgesPerDay = 10
    private var nudgesShownToday = 0
    private var lastAnalysisDate: Date?
    
    // MARK: - User Behavior Tracking
    
    private var sessionHistory: [SessionRecord] = []
    private var appUsagePatterns: [String: UsagePattern] = [:]
    private var lastActiveTime: Date = Date()
    
    // MARK: - Initialization
    
    private init() {
        loadHistory()
        setupObservers()
        scheduleAnalysis()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Track tab changes via pending tab navigation
        FlowNavigationCoordinator.shared.$pendingTab
            .compactMap { $0 }
            .sink { [weak self] tab in
                self?.recordTabVisit(tab)
            }
            .store(in: &cancellables)
        
        // Track focus session completions
        NotificationCenter.default.publisher(for: .focusSessionCompleted)
            .sink { [weak self] notification in
                if let duration = notification.userInfo?["duration"] as? Int {
                    self?.recordFocusSession(duration: duration)
                }
            }
            .store(in: &cancellables)
        
        // Reset daily counter at midnight
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                self?.nudgesShownToday = 0
            }
            .store(in: &cancellables)
    }
    
    private func scheduleAnalysis() {
        Timer.publish(every: analysisInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeAndNudge()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Behavior Recording
    
    private func recordTabVisit(_ tab: AppTab) {
        let tabName = String(describing: tab)
        var pattern = appUsagePatterns[tabName] ?? UsagePattern(identifier: tabName)
        pattern.recordVisit()
        appUsagePatterns[tabName] = pattern
        lastActiveTime = Date()
    }
    
    private func recordFocusSession(duration: Int) {
        let record = SessionRecord(
            duration: duration,
            timestamp: Date(),
            hour: Calendar.current.component(.hour, from: Date()),
            dayOfWeek: Calendar.current.component(.weekday, from: Date())
        )
        sessionHistory.append(record)
        
        // Keep last 100 sessions
        if sessionHistory.count > 100 {
            sessionHistory = Array(sessionHistory.suffix(100))
        }
        
        saveHistory()
        analyzeCompletionPatterns()
    }
    
    // MARK: - Analysis
    
    func analyzeAndNudge() {
        guard canShowNudge() else { return }
        
        isAnalyzing = true
        
        Task { @MainActor in
            defer { isAnalyzing = false }
            
            // Gather insights
            let insights = gatherInsights()
            
            // Generate appropriate nudge
            if let nudge = selectBestNudge(from: insights) {
                deliverNudge(nudge)
            }
            
            lastAnalysisDate = Date()
        }
    }
    
    private func gatherInsights() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Time-based insights
        insights.append(contentsOf: analyzeTimePatterns())
        
        // Progress-based insights
        insights.append(contentsOf: analyzeProgress())
        
        // Task-based insights
        insights.append(contentsOf: analyzeTasks())
        
        // Streak-based insights
        insights.append(contentsOf: analyzeStreaks())
        
        return insights.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func analyzeTimePatterns() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let currentDay = calendar.component(.weekday, from: Date())
        
        // Check if this is user's productive time
        let sessionsAtThisHour = sessionHistory.filter { $0.hour == currentHour }
        let avgProductivity = sessionsAtThisHour.isEmpty ? 0 : 
            Double(sessionsAtThisHour.reduce(0) { $0 + $1.duration }) / Double(sessionsAtThisHour.count)
        
        if avgProductivity > 30 && !FocusSessionHelper.isRunning {
            insights.append(ProactiveInsight(
                type: .optimalTime,
                message: "This is your productive hour",
                suggestedAction: .startFocus,
                relevanceScore: min(avgProductivity / 60, 1.0),
                data: ["avgMinutes": avgProductivity]
            ))
        }
        
        // Check for same-day patterns
        let sessionsOnThisDay = sessionHistory.filter { $0.dayOfWeek == currentDay }
        if sessionsOnThisDay.count >= 5 {
            let avgStartHour = sessionsOnThisDay.map { $0.hour }.reduce(0, +) / sessionsOnThisDay.count
            if currentHour == avgStartHour && !FocusSessionHelper.isRunning {
                insights.append(ProactiveInsight(
                    type: .habitReminder,
                    message: "You usually start focusing around now",
                    suggestedAction: .startFocus,
                    relevanceScore: 0.7,
                    data: [:]
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeProgress() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        let progress = ProgressStore.shared
        let todayMinutes = Int(progress.totalToday / 60)
        let goal = progress.dailyGoalMinutes
        let percentComplete = Double(todayMinutes) / Double(max(goal, 1))
        
        // Close to goal
        if percentComplete >= 0.7 && percentComplete < 1.0 {
            let remaining = goal - todayMinutes
            insights.append(ProactiveInsight(
                type: .goalProgress,
                message: "\(remaining) minutes to daily goal",
                suggestedAction: .startFocus,
                relevanceScore: percentComplete,
                data: ["remaining": remaining]
            ))
        }
        
        // Goal achieved
        if percentComplete >= 1.0 && percentComplete < 1.1 {
            insights.append(ProactiveInsight(
                type: .celebration,
                message: "Daily goal achieved!",
                suggestedAction: .celebrate,
                relevanceScore: 0.9,
                data: [:]
            ))
        }
        
        // Behind schedule (afternoon, less than 50%)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 14 && percentComplete < 0.5 {
            insights.append(ProactiveInsight(
                type: .behindSchedule,
                message: "Afternoon focus boost?",
                suggestedAction: .startFocus,
                relevanceScore: 0.6,
                data: [:]
            ))
        }
        
        return insights
    }
    
    private func analyzeTasks() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        let tasks = TasksStore.shared.tasks
        let calendar = Calendar.current
        let today = Date()
        
        // Overdue tasks
        let overdueTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return reminder < today && !TasksStore.shared.isCompleted(taskId: task.id, on: today)
        }
        
        if !overdueTasks.isEmpty {
            insights.append(ProactiveInsight(
                type: .overdueTasks,
                message: "\(overdueTasks.count) task(s) overdue",
                suggestedAction: .showTasks,
                relevanceScore: 0.8,
                data: ["count": overdueTasks.count]
            ))
        }
        
        // Tasks due today
        let todayTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return calendar.isDateInToday(reminder) && !TasksStore.shared.isCompleted(taskId: task.id, on: today)
        }
        
        if todayTasks.count >= 3 {
            insights.append(ProactiveInsight(
                type: .busyDay,
                message: "\(todayTasks.count) tasks due today",
                suggestedAction: .prioritize,
                relevanceScore: 0.7,
                data: ["count": todayTasks.count]
            ))
        }
        
        return insights
    }
    
    private func analyzeStreaks() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        let streak = ProgressStore.shared.lifetimeBestStreak
        
        // Streak at risk
        if streak > 0 {
            let progress = ProgressStore.shared
            let todayMinutes = Int(progress.totalToday / 60)
            let goal = progress.dailyGoalMinutes
            
            if todayMinutes < goal {
                let hour = Calendar.current.component(.hour, from: Date())
                if hour >= 20 { // After 8 PM
                    insights.append(ProactiveInsight(
                        type: .streakAtRisk,
                        message: "\(streak)-day streak at risk!",
                        suggestedAction: .startFocus,
                        relevanceScore: 0.95,
                        data: ["streak": streak, "remaining": goal - todayMinutes]
                    ))
                }
            }
        }
        
        // Milestone approaching
        let milestones = [7, 14, 30, 60, 90, 100, 365]
        if let nextMilestone = milestones.first(where: { $0 > streak }) {
            if nextMilestone - streak <= 2 {
                insights.append(ProactiveInsight(
                    type: .streakMilestone,
                    message: "\(nextMilestone - streak) days to \(nextMilestone)-day milestone!",
                    suggestedAction: .motivate,
                    relevanceScore: 0.6,
                    data: ["current": streak, "target": nextMilestone]
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeCompletionPatterns() {
        guard sessionHistory.count >= 5 else { return }
        
        // Find peak productivity hours
        var hourlyTotals: [Int: Int] = [:]
        for session in sessionHistory {
            hourlyTotals[session.hour, default: 0] += session.duration
        }
        
        let sortedHours = hourlyTotals.sorted { $0.value > $1.value }
        let peakHours = sortedHours.prefix(3).map { $0.key }
        
        // Update memory through FlowMemoryManager
        FlowMemoryManager.shared.updateMemory { memory in
            memory.peakProductivityHours = peakHours
        }
        
        // Calculate preferred duration
        let avgDuration = sessionHistory.reduce(0) { $0 + $1.duration } / sessionHistory.count
        FlowMemoryManager.shared.updateMemory { memory in
            memory.preferredFocusDuration = avgDuration
        }
    }
    
    // MARK: - Nudge Delivery
    
    private func selectBestNudge(from insights: [ProactiveInsight]) -> ProactiveNudge? {
        guard let topInsight = insights.first else { return nil }
        
        lastInsight = topInsight
        
        return createNudge(from: topInsight)
    }
    
    private func createNudge(from insight: ProactiveInsight) -> ProactiveNudge {
        switch insight.type {
        case .optimalTime:
            let avgMinutes = insight.data["avgMinutes"] as? Double ?? 25
            return ProactiveNudge(
                hint: FlowHint(
                    type: .suggestion,
                    title: "Your productive hour",
                    message: "You typically focus for \(Int(avgMinutes)) minutes around now. Ready to start?",
                    primaryAction: HintAction(
                        label: "Start Session",
                        action: nil,
                        systemAction: .startFocus(minutes: Int(avgMinutes))
                    ),
                    secondaryAction: HintAction(
                        label: "Not now",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .habitReminder:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .suggestion,
                    title: "Habit time! 🎯",
                    message: insight.message,
                    primaryAction: HintAction(
                        label: "Let's go",
                        action: nil,
                        systemAction: .startFocus(minutes: FlowContext.shared.memory.preferredFocusDuration ?? 25)
                    ),
                    secondaryAction: HintAction(
                        label: "Skip today",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .goalProgress:
            let remaining = insight.data["remaining"] as? Int ?? 25
            return ProactiveNudge(
                hint: FlowHint(
                    type: .motivation,
                    title: "Almost there! 💪",
                    message: "Just \(remaining) minutes to hit your daily goal!",
                    primaryAction: HintAction(
                        label: "Finish it",
                        action: nil,
                        systemAction: .startFocus(minutes: remaining)
                    ),
                    context: .general,
                    priority: .high
                ),
                insight: insight
            )
            
        case .celebration:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .celebration,
                    title: "Goal achieved! 🎉",
                    message: "You hit your daily focus goal. Amazing work!",
                    primaryAction: HintAction(
                        label: "View stats",
                        action: nil,
                        systemAction: .navigateToTab(.progress)
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .behindSchedule:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .tip,
                    title: "Afternoon boost?",
                    message: "A quick focus session could help you catch up on your goal.",
                    primaryAction: HintAction(
                        label: "Quick 15 min",
                        action: nil,
                        systemAction: .startFocus(minutes: 15)
                    ),
                    secondaryAction: HintAction(
                        label: "Maybe later",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .low
                ),
                insight: insight
            )
            
        case .overdueTasks:
            let count = insight.data["count"] as? Int ?? 1
            return ProactiveNudge(
                hint: FlowHint(
                    type: .reminder,
                    title: "Tasks need attention",
                    message: "You have \(count) overdue task\(count > 1 ? "s" : ""). Let's tackle them!",
                    primaryAction: HintAction(
                        label: "View tasks",
                        action: nil,
                        systemAction: .navigateToTab(.tasks)
                    ),
                    context: .general,
                    priority: .high
                ),
                insight: insight
            )
            
        case .busyDay:
            let count = insight.data["count"] as? Int ?? 3
            return ProactiveNudge(
                hint: FlowHint(
                    type: .tip,
                    title: "Busy day ahead",
                    message: "\(count) tasks due today. Want help prioritizing?",
                    primaryAction: HintAction(
                        label: "Help me prioritize",
                        action: nil,
                        systemAction: .openChat
                    ),
                    secondaryAction: HintAction(
                        label: "I've got it",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .streakAtRisk:
            let streak = insight.data["streak"] as? Int ?? 1
            let remaining = insight.data["remaining"] as? Int ?? 25
            return ProactiveNudge(
                hint: FlowHint(
                    type: .streak,
                    title: "Streak at risk! 🔥",
                    message: "Don't lose your \(streak)-day streak! \(remaining) minutes to go.",
                    primaryAction: HintAction(
                        label: "Save my streak",
                        action: nil,
                        systemAction: .startFocus(minutes: remaining)
                    ),
                    context: .general,
                    priority: .urgent
                ),
                insight: insight
            )
            
        case .streakMilestone:
            let current = insight.data["current"] as? Int ?? 0
            let target = insight.data["target"] as? Int ?? 7
            return ProactiveNudge(
                hint: FlowHint(
                    type: .streak,
                    title: "Milestone ahead! 🏆",
                    message: "Just \(target - current) days until your \(target)-day milestone!",
                    primaryAction: HintAction(
                        label: "Keep going",
                        action: nil,
                        systemAction: .startFocus(minutes: 25)
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
        }
    }
    
    private func deliverNudge(_ nudge: ProactiveNudge) {
        nudgesShownToday += 1
        hintManager.showHint(nudge.hint)
    }
    
    private func canShowNudge() -> Bool {
        // Check daily limit
        guard nudgesShownToday < maxNudgesPerDay else { return false }
        
        // Don't nudge during active focus
        guard !FocusSessionHelper.isRunning else { return false }
        
        // Don't nudge too frequently
        if let lastAnalysis = lastAnalysisDate {
            let elapsed = Date().timeIntervalSince(lastAnalysis)
            guard elapsed >= analysisInterval else { return false }
        }
        
        return true
    }
    
    // MARK: - Persistence
    
    private let historyKey = "proactive_engine_history"
    
    private func saveHistory() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(sessionHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            return
        }
        sessionHistory = history
    }
}

// MARK: - Supporting Types

struct SessionRecord: Codable {
    let duration: Int
    let timestamp: Date
    let hour: Int
    let dayOfWeek: Int
}

struct UsagePattern {
    let identifier: String
    var visitCount: Int = 0
    var lastVisit: Date = Date()
    var avgDuration: TimeInterval = 0
    
    mutating func recordVisit() {
        visitCount += 1
        lastVisit = Date()
    }
}

struct ProactiveInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let suggestedAction: SuggestedAction
    let relevanceScore: Double
    let data: [String: Any]
    
    enum InsightType {
        case optimalTime
        case habitReminder
        case goalProgress
        case celebration
        case behindSchedule
        case overdueTasks
        case busyDay
        case streakAtRisk
        case streakMilestone
    }
    
    enum SuggestedAction {
        case startFocus
        case showTasks
        case celebrate
        case prioritize
        case motivate
    }
}

struct ProactiveNudge {
    let hint: FlowHint
    let insight: ProactiveInsight
}

// MARK: - Notification Names

extension Notification.Name {
    static let focusSessionCompleted = Notification.Name("focusSessionCompleted")
}
