import SwiftUI
import Combine
import UserNotifications

// MARK: - Flow Proactive Engine

/// Intelligent nudge system that learns from user behavior
/// and provides proactive suggestions at optimal times
/// Phase 5 Enhanced: AI-powered personalized nudges with push notifications

@MainActor
final class FlowProactiveEngine: ObservableObject {
    static let shared = FlowProactiveEngine()
    
    // MARK: - State
    
    @Published private(set) var isAnalyzing = false
    @Published private(set) var lastInsight: ProactiveInsight?
    @Published private(set) var pendingNudges: [ProactiveNudge] = []
    @Published private(set) var latestAINudge: AIGeneratedNudge?
    
    // MARK: - Dependencies
    
    private let context = FlowContext.shared
    private let hintManager = FlowHintManager.shared
    private let service = FlowService.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    private let analysisInterval: TimeInterval = 300 // 5 minutes
    private let maxNudgesPerDay = 10
    private let aiNudgeCooldown: TimeInterval = 1800 // 30 minutes between AI nudges
    private var nudgesShownToday = 0
    private var lastAnalysisDate: Date?
    private var lastAINudgeDate: Date?
    
    // MARK: - User Behavior Tracking
    
    private var sessionHistory: [SessionRecord] = []
    private var appUsagePatterns: [String: UsagePattern] = [:]
    private var lastActiveTime: Date = Date()
    
    // MARK: - Initialization
    
    private init() {
        loadHistory()
        setupObservers()
        scheduleAnalysis()
        scheduleBackgroundNudgeCheck()
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
            
            // Get top insight
            guard let topInsight = insights.first else {
                lastAnalysisDate = Date()
                return
            }
            
            // Check if app is in foreground or background
            let isAppActive = UIApplication.shared.applicationState == .active
            
            // For high-priority insights (urgent/high), try AI-generated nudge
            if topInsight.relevanceScore >= 0.8 {
                // Try to generate AI nudge for high-priority insights
                if let aiNudge = await generateAINudge(for: topInsight) {
                    if isAppActive {
                        // Send to in-app chat
                        sendNudgeToChat(aiNudge)
                    } else {
                        // Send push notification for background
                        sendPushNotification(for: topInsight, message: aiNudge.message)
                    }
                } else {
                    // Fallback to hint system (in-app only)
                    if isAppActive {
                        let nudge = createNudge(from: topInsight)
                        deliverNudge(nudge)
                    } else {
                        // Send basic push notification
                        sendPushNotification(for: topInsight, message: topInsight.message)
                    }
                }
            } else {
                // Regular insights use hint system (in-app only)
                if isAppActive {
                    let nudge = createNudge(from: topInsight)
                    deliverNudge(nudge)
                }
                // Lower priority insights don't trigger push notifications
            }
            
            lastInsight = topInsight
            lastAnalysisDate = Date()
        }
    }
    
    /// Force trigger analysis (for testing or manual invocation)
    func forceAnalyze() {
        isAnalyzing = true
        
        Task { @MainActor in
            defer { isAnalyzing = false }
            
            let insights = gatherInsights()
            
            if let topInsight = insights.first {
                lastInsight = topInsight
                
                // Always try AI nudge when forced
                if let aiNudge = await generateAINudge(for: topInsight) {
                    sendNudgeToChat(aiNudge)
                } else {
                    let nudge = createNudge(from: topInsight)
                    deliverNudge(nudge)
                }
            }
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
        
        // Behavioral insights (new)
        insights.append(contentsOf: analyzeBehavior())
        
        // Achievement milestones (new)
        insights.append(contentsOf: analyzeAchievements())
        
        // Time-of-day contextual (new)
        insights.append(contentsOf: analyzeTimeOfDay())
        
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
    
    // MARK: - Behavioral Analysis (Phase 5)
    
    private func analyzeBehavior() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Check for unusual inactivity
        let hoursSinceLastSession = calculateHoursSinceLastSession()
        let avgGapBetweenSessions = calculateAverageSessionGap()
        
        // If inactive for significantly longer than usual
        if hoursSinceLastSession > max(avgGapBetweenSessions * 2, 24) {
            insights.append(ProactiveInsight(
                type: .unusualInactivity,
                message: "Haven't seen you in a while",
                suggestedAction: .startFocus,
                relevanceScore: 0.5,
                data: ["hoursSince": hoursSinceLastSession]
            ))
        }
        
        // Check for potential burnout (too many sessions recently)
        let sessionsLast3Days = sessionHistory.filter { session in
            Calendar.current.isDate(session.timestamp, equalTo: Date(), toGranularity: .day) ||
            Calendar.current.isDate(session.timestamp, equalTo: Date().addingTimeInterval(-86400), toGranularity: .day) ||
            Calendar.current.isDate(session.timestamp, equalTo: Date().addingTimeInterval(-172800), toGranularity: .day)
        }
        
        let totalMinutesLast3Days = sessionsLast3Days.reduce(0) { $0 + $1.duration }
        let avgMinutesPerDay = totalMinutesLast3Days / 3
        let goal = ProgressStore.shared.dailyGoalMinutes
        
        // Burnout indicator: >150% of goal for 3 consecutive days
        if avgMinutesPerDay > Int(Double(goal) * 1.5) && sessionsLast3Days.count >= 6 {
            insights.append(ProactiveInsight(
                type: .potentialBurnout,
                message: "You've been crushing it! Maybe take a longer break?",
                suggestedAction: .takeBreak,
                relevanceScore: 0.7,
                data: ["avgMinutes": avgMinutesPerDay, "sessionsCount": sessionsLast3Days.count]
            ))
        }
        
        // Consistent progress (hit goal 5+ days in a row)
        let progress = ProgressStore.shared
        let currentStreak = progress.lifetimeBestStreak  // Use best streak as proxy
        if currentStreak >= 5 && currentStreak % 5 == 0 {
            insights.append(ProactiveInsight(
                type: .consistentProgress,
                message: "\(currentStreak) days of hitting your goal!",
                suggestedAction: .celebrate,
                relevanceScore: 0.75,
                data: ["streak": currentStreak]
            ))
        }
        
        return insights
    }
    
    private func calculateHoursSinceLastSession() -> Int {
        guard let lastSession = sessionHistory.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return 999 // Very high if no sessions
        }
        return Int(Date().timeIntervalSince(lastSession.timestamp) / 3600)
    }
    
    private func calculateAverageSessionGap() -> Int {
        guard sessionHistory.count >= 2 else { return 24 }
        
        let sortedSessions = sessionHistory.sorted { $0.timestamp < $1.timestamp }
        var totalGap: TimeInterval = 0
        
        for i in 1..<sortedSessions.count {
            totalGap += sortedSessions[i].timestamp.timeIntervalSince(sortedSessions[i-1].timestamp)
        }
        
        let avgGap = totalGap / Double(sortedSessions.count - 1)
        return Int(avgGap / 3600)
    }
    
    // MARK: - Achievement Analysis (Phase 5)
    
    private func analyzeAchievements() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        let progress = ProgressStore.shared
        
        // Total focus hours milestones
        let allTimeTotal = progress.sessions.reduce(0) { $0 + $1.duration }
        let totalHours = Int(allTimeTotal / 3600)
        let hourMilestones = [10, 25, 50, 100, 250, 500, 1000]
        
        for milestone in hourMilestones {
            // Check if just crossed milestone (within last session)
            let previousHours = totalHours - (sessionHistory.last?.duration ?? 0) / 60
            if totalHours >= milestone && previousHours < milestone {
                insights.append(ProactiveInsight(
                    type: .focusHoursMilestone,
                    message: "You've reached \(milestone) total focus hours! 🎉",
                    suggestedAction: .celebrate,
                    relevanceScore: 0.9,
                    data: ["hours": milestone]
                ))
                break
            }
        }
        
        // Total sessions count milestones
        let totalSessions = progress.sessions.count
        let sessionMilestones = [10, 50, 100, 250, 500, 1000]
        
        for milestone in sessionMilestones {
            if totalSessions == milestone {
                insights.append(ProactiveInsight(
                    type: .sessionsCountMilestone,
                    message: "\(milestone) focus sessions completed! 🏆",
                    suggestedAction: .celebrate,
                    relevanceScore: 0.85,
                    data: ["sessions": milestone]
                ))
                break
            }
        }
        
        // New personal best today
        let todayMinutes = Int(progress.totalToday / 60)
        // Calculate historical best day from sessions
        let calendar = Calendar.current
        var dailyTotals: [Date: Int] = [:]
        for session in progress.sessions {
            let day = calendar.startOfDay(for: session.date)
            dailyTotals[day, default: 0] += Int(session.duration / 60)
        }
        let previousBestDay = dailyTotals.values.max() ?? 0
        
        // Check if today beats the previous best (excluding today)
        let todayStart = calendar.startOfDay(for: Date())
        let bestExcludingToday = dailyTotals.filter { $0.key < todayStart }.values.max() ?? 0
        
        if todayMinutes > bestExcludingToday && bestExcludingToday > 0 {
            insights.append(ProactiveInsight(
                type: .newPersonalBest,
                message: "New personal best! \(todayMinutes) minutes today 🎯",
                suggestedAction: .celebrate,
                relevanceScore: 0.95,
                data: ["minutes": todayMinutes, "previous": bestExcludingToday]
            ))
        }
        
        return insights
    }
    
    // MARK: - Time of Day Analysis (Phase 5)
    
    private func analyzeTimeOfDay() -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let progress = ProgressStore.shared
        let todayMinutes = Int(progress.totalToday / 60)
        let goal = progress.dailyGoalMinutes
        
        // Morning welcome (7-9 AM, first check of day)
        if hour >= 7 && hour <= 9 && todayMinutes == 0 {
            let pendingTasks = TasksStore.shared.tasks.filter { task in
                guard let reminder = task.reminderDate else { return false }
                return calendar.isDateInToday(reminder) && !TasksStore.shared.isCompleted(taskId: task.id, on: Date())
            }.count
            
            insights.append(ProactiveInsight(
                type: .morningWelcome,
                message: pendingTasks > 0 ? "Good morning! \(pendingTasks) tasks await" : "Good morning! Ready to focus?",
                suggestedAction: .planDay,
                relevanceScore: 0.6,
                data: ["tasks": pendingTasks]
            ))
        }
        
        // End of day summary (after 8 PM, if goal was hit)
        if hour >= 20 && hour <= 22 && todayMinutes >= goal {
            insights.append(ProactiveInsight(
                type: .endOfDaySummary,
                message: "Great day! \(todayMinutes) minutes focused 🌟",
                suggestedAction: .reviewProgress,
                relevanceScore: 0.65,
                data: ["minutes": todayMinutes, "goalPercent": (todayMinutes * 100) / goal]
            ))
        }
        
        // Weekly review (Sunday evening)
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 1 && hour >= 18 && hour <= 21 { // Sunday evening
            insights.append(ProactiveInsight(
                type: .weeklyReview,
                message: "Ready for your weekly review?",
                suggestedAction: .reviewProgress,
                relevanceScore: 0.55,
                data: [:]
            ))
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
        
        // MARK: - New Phase 5 Cases
            
        case .taskDueSoon:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .reminder,
                    title: "Task due soon ⏰",
                    message: insight.message,
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
            
        case .unusualInactivity:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .suggestion,
                    title: "Hey there 👋",
                    message: "Haven't seen you in a while. Everything okay? Here when you're ready.",
                    primaryAction: HintAction(
                        label: "Quick session",
                        action: nil,
                        systemAction: .startFocus(minutes: 15)
                    ),
                    secondaryAction: HintAction(
                        label: "Not today",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .low
                ),
                insight: insight
            )
            
        case .potentialBurnout:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .tip,
                    title: "Rest is productive too 💙",
                    message: "You've been crushing it lately! Consider a longer break today.",
                    primaryAction: HintAction(
                        label: "Got it",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .consistentProgress:
            let streak = insight.data["streak"] as? Int ?? 5
            return ProactiveNudge(
                hint: FlowHint(
                    type: .celebration,
                    title: "Consistency champion! 🏆",
                    message: "\(streak) days of hitting your goal. You're building real momentum!",
                    primaryAction: HintAction(
                        label: "View progress",
                        action: nil,
                        systemAction: .navigateToTab(.progress)
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .newPersonalBest:
            let minutes = insight.data["minutes"] as? Int ?? 0
            return ProactiveNudge(
                hint: FlowHint(
                    type: .celebration,
                    title: "New personal best! 🎯",
                    message: "\(minutes) minutes today - that's your record!",
                    primaryAction: HintAction(
                        label: "Celebrate",
                        action: nil,
                        systemAction: .navigateToTab(.progress)
                    ),
                    context: .general,
                    priority: .high
                ),
                insight: insight
            )
            
        case .focusHoursMilestone:
            let hours = insight.data["hours"] as? Int ?? 0
            return ProactiveNudge(
                hint: FlowHint(
                    type: .celebration,
                    title: "\(hours) hours milestone! 🎉",
                    message: "You've reached \(hours) total focus hours. Incredible dedication!",
                    primaryAction: HintAction(
                        label: "View stats",
                        action: nil,
                        systemAction: .navigateToTab(.progress)
                    ),
                    context: .general,
                    priority: .high
                ),
                insight: insight
            )
            
        case .sessionsCountMilestone:
            let sessions = insight.data["sessions"] as? Int ?? 0
            return ProactiveNudge(
                hint: FlowHint(
                    type: .celebration,
                    title: "\(sessions) sessions! 🏅",
                    message: "You've completed \(sessions) focus sessions. Keep building!",
                    primaryAction: HintAction(
                        label: "Nice!",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .weeklyGoalStreak:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .streak,
                    title: "Weekly streak! 🔥",
                    message: insight.message,
                    primaryAction: HintAction(
                        label: "Keep it up",
                        action: nil,
                        systemAction: .startFocus(minutes: 25)
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .morningWelcome:
            let tasks = insight.data["tasks"] as? Int ?? 0
            return ProactiveNudge(
                hint: FlowHint(
                    type: .suggestion,
                    title: "Good morning! ☀️",
                    message: tasks > 0 ? "\(tasks) tasks await. Ready to plan your day?" : "Fresh day, fresh start. What will you focus on?",
                    primaryAction: HintAction(
                        label: tasks > 0 ? "Plan my day" : "Start focusing",
                        action: nil,
                        systemAction: tasks > 0 ? .openChat : .startFocus(minutes: 25)
                    ),
                    secondaryAction: HintAction(
                        label: "Later",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .normal
                ),
                insight: insight
            )
            
        case .endOfDaySummary:
            let minutes = insight.data["minutes"] as? Int ?? 0
            return ProactiveNudge(
                hint: FlowHint(
                    type: .insight,
                    title: "Day complete! 🌟",
                    message: "You focused for \(minutes) minutes today. Great work!",
                    primaryAction: HintAction(
                        label: "View summary",
                        action: nil,
                        systemAction: .navigateToTab(.progress)
                    ),
                    context: .general,
                    priority: .low
                ),
                insight: insight
            )
            
        case .weeklyReview:
            return ProactiveNudge(
                hint: FlowHint(
                    type: .insight,
                    title: "Weekly review 📊",
                    message: "Sunday evening - perfect time to review your week!",
                    primaryAction: HintAction(
                        label: "Show my week",
                        action: nil,
                        systemAction: .openChat
                    ),
                    secondaryAction: HintAction(
                        label: "Skip",
                        action: nil,
                        systemAction: .dismiss
                    ),
                    context: .general,
                    priority: .low
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
        // Performance-based
        case optimalTime
        case habitReminder
        case goalProgress
        case celebration
        case behindSchedule
        
        // Task-based
        case overdueTasks
        case busyDay
        case taskDueSoon
        
        // Streak-based
        case streakAtRisk
        case streakMilestone
        case newPersonalBest
        
        // Behavioral
        case unusualInactivity
        case potentialBurnout
        case consistentProgress
        
        // Achievement
        case focusHoursMilestone
        case sessionsCountMilestone
        case weeklyGoalStreak
        
        // Contextual
        case morningWelcome
        case endOfDaySummary
        case weeklyReview
    }
    
    enum SuggestedAction {
        case startFocus
        case showTasks
        case celebrate
        case prioritize
        case motivate
        case takeBreak
        case reviewProgress
        case planDay
    }
}

struct ProactiveNudge {
    let hint: FlowHint
    let insight: ProactiveInsight
}

// MARK: - AI Generated Nudge (Phase 5)

/// A nudge generated by the AI backend with personalized messaging
struct AIGeneratedNudge: Identifiable {
    let id = UUID()
    let message: String
    let suggestedAction: FlowAction?
    let actionLabel: String?
    let priority: HintPriority
    let trigger: ProactiveInsight.InsightType
    let timestamp: Date
    
    init(
        message: String,
        suggestedAction: FlowAction? = nil,
        actionLabel: String? = nil,
        priority: HintPriority = .normal,
        trigger: ProactiveInsight.InsightType
    ) {
        self.message = message
        self.suggestedAction = suggestedAction
        self.actionLabel = actionLabel
        self.priority = priority
        self.trigger = trigger
        self.timestamp = Date()
    }
}

// MARK: - Proactive Engine AI Extension

extension FlowProactiveEngine {
    
    /// Generate a personalized AI nudge based on current context
    /// This calls the backend to get a contextually relevant message
    func generateAINudge(for insight: ProactiveInsight) async -> AIGeneratedNudge? {
        // Check cooldown
        if let lastDate = lastAINudgeDate {
            let elapsed = Date().timeIntervalSince(lastDate)
            guard elapsed >= aiNudgeCooldown else {
                print("[ProactiveEngine] AI nudge cooldown active, skipping")
                return nil
            }
        }
        
        // Build context for the AI
        let contextString = context.buildContext()
        let nudgePrompt = buildNudgePrompt(for: insight)
        
        do {
            let response = try await service.sendMessage(
                userMessage: nudgePrompt,
                conversationHistory: [],
                context: contextString
            )
            
            // Parse the response
            let nudge = AIGeneratedNudge(
                message: response.content,
                suggestedAction: response.actions.first,
                actionLabel: suggestedActionLabel(for: insight.suggestedAction),
                priority: mapPriority(from: insight.relevanceScore),
                trigger: insight.type
            )
            
            lastAINudgeDate = Date()
            latestAINudge = nudge
            
            return nudge
            
        } catch {
            print("[ProactiveEngine] Failed to generate AI nudge: \(error)")
            return nil
        }
    }
    
    private func buildNudgePrompt(for insight: ProactiveInsight) -> String {
        switch insight.type {
        case .streakAtRisk:
            let streak = insight.data["streak"] as? Int ?? 0
            let remaining = insight.data["remaining"] as? Int ?? 25
            return "Generate a SHORT (1-2 sentences max) motivational nudge. The user's \(streak)-day streak is at risk - they need \(remaining) more minutes today. Be urgent but encouraging. Don't be preachy."
            
        case .goalProgress:
            let remaining = insight.data["remaining"] as? Int ?? 25
            return "Generate a SHORT (1-2 sentences max) encouraging nudge. User is close to their daily goal - just \(remaining) minutes left! Make them feel good about their progress."
            
        case .celebration:
            return "Generate a SHORT (1-2 sentences max) celebration message. User just hit their daily focus goal! Be genuinely excited but not over-the-top."
            
        case .unusualInactivity:
            let hours = insight.data["hoursSince"] as? Int ?? 24
            return "Generate a SHORT (1-2 sentences max) gentle check-in. User hasn't focused in \(hours)+ hours which is unusual for them. Be caring, not guilt-tripping."
            
        case .potentialBurnout:
            return "Generate a SHORT (1-2 sentences max) caring nudge. User has been working intensely for several days. Suggest taking a break without being preachy."
            
        case .newPersonalBest:
            let minutes = insight.data["minutes"] as? Int ?? 0
            return "Generate a SHORT (1-2 sentences max) celebration. User just hit a new personal best: \(minutes) minutes today! Make them feel accomplished."
            
        case .morningWelcome:
            let tasks = insight.data["tasks"] as? Int ?? 0
            return "Generate a SHORT (1-2 sentences max) morning greeting. \(tasks > 0 ? "User has \(tasks) tasks today." : "Fresh day ahead.") Be energizing but not annoying."
            
        case .endOfDaySummary:
            let minutes = insight.data["minutes"] as? Int ?? 0
            return "Generate a SHORT (1-2 sentences max) end-of-day wrap-up. User focused for \(minutes) minutes today. Acknowledge their effort warmly."
            
        default:
            return "Generate a SHORT (1-2 sentences max) proactive productivity nudge. Be helpful and encouraging without being preachy. Context: \(insight.message)"
        }
    }
    
    private func suggestedActionLabel(for action: ProactiveInsight.SuggestedAction) -> String {
        switch action {
        case .startFocus: return "Start Focus"
        case .showTasks: return "View Tasks"
        case .celebrate: return "Nice!"
        case .prioritize: return "Help Me"
        case .motivate: return "Let's Go"
        case .takeBreak: return "Got It"
        case .reviewProgress: return "View Stats"
        case .planDay: return "Plan My Day"
        }
    }
    
    private func mapPriority(from score: Double) -> HintPriority {
        switch score {
        case 0.9...1.0: return .urgent
        case 0.7..<0.9: return .high
        case 0.5..<0.7: return .normal
        default: return .low
        }
    }
    
    /// Send a proactive nudge directly to the chat view
    func sendNudgeToChat(_ nudge: AIGeneratedNudge) {
        NotificationCenter.default.post(
            name: .proactiveNudgeReceived,
            object: nil,
            userInfo: ["nudge": nudge]
        )
    }
    
    // MARK: - Push Notifications
    
    /// Schedule background nudge checks using local notifications
    private func scheduleBackgroundNudgeCheck() {
        // Request notification permission if needed
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("📱 FlowProactiveEngine: Push notification permission granted")
            }
        }
    }
    
    /// Send a push notification for a proactive insight
    func sendPushNotification(for insight: ProactiveInsight, message: String) {
        // Check if smart nudges are enabled globally
        guard NotificationPreferencesStore.shared.preferences.smartNudgesEnabled else {
            print("📱 Smart nudges disabled - skipping push notification")
            return
        }
        
        // Check specific preference for this insight type
        guard shouldSendPushNotification(for: insight.type) else {
            print("📱 Push notification disabled for type: \(insight.type)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: insight.type)
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "PROACTIVE_NUDGE"
        
        // Add insight data for handling when tapped
        content.userInfo = [
            "insightType": String(describing: insight.type),
            "insightId": insight.id.uuidString,
            "action": String(describing: insight.suggestedAction)
        ]
        
        // Send immediately with a slight delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "proactive-\(insight.id.uuidString)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("📱 Failed to send push notification: \(error)")
            } else {
                print("📱 Push notification sent for: \(insight.type)")
            }
        }
    }
    
    /// Check user preferences to determine if push notification should be sent
    private func shouldSendPushNotification(for insightType: ProactiveInsight.InsightType) -> Bool {
        let prefs = NotificationPreferencesStore.shared.preferences
        
        switch insightType {
        // Streak-related insights
        case .streakAtRisk, .streakMilestone, .weeklyGoalStreak:
            return prefs.streakRiskNudgesEnabled
            
        // Goal progress insights
        case .goalProgress, .behindSchedule, .optimalTime:
            return prefs.goalProgressNudgesEnabled
            
        // Inactivity insights
        case .unusualInactivity, .potentialBurnout:
            return prefs.inactivityNudgesEnabled
            
        // Achievement insights
        case .newPersonalBest, .focusHoursMilestone, .sessionsCountMilestone, .celebration, .consistentProgress:
            return prefs.achievementNudgesEnabled
            
        // General insights (follow smart nudges master toggle)
        case .morningWelcome, .endOfDaySummary, .weeklyReview, .habitReminder, .overdueTasks, .busyDay, .taskDueSoon:
            return prefs.smartNudgesEnabled
        }
    }
    
    /// Get appropriate notification title based on insight type
    private func notificationTitle(for type: ProactiveInsight.InsightType) -> String {
        switch type {
        case .optimalTime: return "⏰ Perfect Timing"
        case .habitReminder: return "💡 Habit Reminder"
        case .goalProgress: return "📊 Goal Update"
        case .celebration: return "🎉 Time to Celebrate"
        case .behindSchedule: return "⏰ Quick Check-in"
        case .overdueTasks: return "📋 Task Reminder"
        case .busyDay: return "📅 Heads Up"
        case .taskDueSoon: return "⏰ Task Due Soon"
        case .streakAtRisk: return "⚠️ Streak Alert"
        case .streakMilestone: return "🔥 Streak Milestone"
        case .newPersonalBest: return "🏆 New Record!"
        case .unusualInactivity: return "👋 Hey there"
        case .potentialBurnout: return "💆 Take Care"
        case .consistentProgress: return "⭐ Great Progress"
        case .focusHoursMilestone: return "🎯 Milestone!"
        case .sessionsCountMilestone: return "🎯 Sessions Milestone"
        case .weeklyGoalStreak: return "🔥 Weekly Streak"
        case .morningWelcome: return "☀️ Good Morning"
        case .endOfDaySummary: return "🌙 Daily Recap"
        case .weeklyReview: return "📈 Weekly Review"
        }
    }
    
    /// Schedule a smart nudge based on user patterns
    func scheduleSmartNudge(for insight: ProactiveInsight) {
        Task {
            // Generate AI-powered message
            guard let nudge = await generateAINudge(for: insight) else {
                // Fallback to basic message if AI generation fails
                sendPushNotification(for: insight, message: insight.message)
                return
            }
            
            // Send in-app nudge if app is active
            if UIApplication.shared.applicationState == .active {
                if insight.relevanceScore >= 0.8 {
                    sendNudgeToChat(nudge)
                }
            } else {
                // Send push notification if app is in background
                sendPushNotification(for: insight, message: nudge.message)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let focusSessionCompleted = Notification.Name("focusSessionCompleted")
    static let proactiveNudgeReceived = Notification.Name("proactiveNudgeReceived")
}
