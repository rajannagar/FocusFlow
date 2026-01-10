import Foundation

// MARK: - Flow Intelligence Engine

/// Analyzes user patterns, infers state, and generates intelligent insights for Flow AI
/// This transforms raw data into actionable intelligence that makes Flow responses smarter
@MainActor
final class FlowIntelligence {
    static let shared = FlowIntelligence()
    
    private let calendar = Calendar.autoupdatingCurrent
    
    // Dependencies - accessed through singletons
    private var progressStore: ProgressStore { ProgressStore.shared }
    private var tasksStore: TasksStore { TasksStore.shared }
    private var memoryManager: FlowMemoryManager { FlowMemoryManager.shared }
    
    private init() {}
    
    // MARK: - Main Analysis
    
    /// Generate complete intelligence report for AI context
    func generateIntelligenceReport() -> IntelligenceReport {
        let performance = analyzePerformance()
        let patterns = detectPatterns()
        let userState = inferUserState()
        let opportunities = detectOpportunities()
        let risks = detectRisks()
        
        return IntelligenceReport(
            performance: performance,
            patterns: patterns,
            userState: userState,
            opportunities: opportunities,
            risks: risks,
            generatedAt: Date()
        )
    }
    
    /// Build context string for AI system prompt
    func buildIntelligenceContext() -> String {
        let report = generateIntelligenceReport()
        
        var context = "\n=== INTELLIGENT INSIGHTS ===\n"
        
        // Performance Analysis
        context += "\nPERFORMANCE ANALYSIS:\n"
        context += "• Today's progress: \(report.performance.todayPercentage)%"
        if let comparison = report.performance.comparisonToAverage {
            let direction = comparison > 0 ? "above" : "below"
            context += " (\(abs(comparison))% \(direction) your average)"
        }
        context += "\n"
        
        if let trend = report.performance.trend {
            let emoji = trend == .improving ? "📈" : (trend == .declining ? "📉" : "➡️")
            context += "• Trend: \(trend.description) \(emoji)\n"
        }
        
        context += "• Momentum: \(report.performance.momentum.description)\n"
        
        // Behavioral Patterns
        if !report.patterns.peakHours.isEmpty || report.patterns.preferredDuration != nil {
            context += "\nBEHAVIORAL PATTERNS:\n"
            
            if !report.patterns.peakHours.isEmpty {
                let hours = report.patterns.peakHours.map { formatHour($0) }.joined(separator: ", ")
                context += "• Peak hours: \(hours)\n"
            }
            
            if let duration = report.patterns.preferredDuration {
                context += "• Preferred session: \(duration) min\n"
            }
            
            if let bestDay = report.patterns.bestDayOfWeek {
                context += "• Best day: \(bestDay)\n"
            }
            
            if report.patterns.isInPeakWindow {
                context += "• Currently IN peak productivity window! ⚡\n"
            }
        }
        
        // User State
        context += "\nUSER STATE:\n"
        context += "• Activity level: \(report.userState.activityLevel.description)\n"
        context += "• Likely energy: \(report.userState.estimatedEnergy.description)\n"
        context += "• Streak risk: \(report.userState.streakRisk.description)\n"
        context += "• Suggested approach: \(report.userState.suggestedTone.description)\n"
        
        // Opportunities
        if !report.opportunities.isEmpty {
            context += "\nOPPORTUNITIES:\n"
            for opp in report.opportunities.prefix(3) {
                context += "• \(opp.description)\n"
            }
        }
        
        // Risks
        if !report.risks.isEmpty {
            context += "\nRISK ALERTS:\n"
            for risk in report.risks.prefix(3) {
                context += "• ⚠️ \(risk.description)\n"
            }
        }
        
        context += "\n"
        return context
    }
    
    // MARK: - Performance Analysis
    
    func analyzePerformance() -> PerformanceInsight {
        let progress = progressStore
        let sessions = progress.sessions
        let now = Date()
        
        // Today's stats
        let todaySessions = sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let todayPercentage = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        // Calculate 7-day average
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let recentSessions = sessions.filter { $0.date >= weekAgo && !calendar.isDateInToday($0.date) }
        
        var dailyTotals: [Int] = []
        for dayOffset in 1...7 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .reduce(0) { $0 + Int($1.duration / 60) }
            dailyTotals.append(dayMinutes)
        }
        
        let averageMinutes = dailyTotals.isEmpty ? 0 : dailyTotals.reduce(0, +) / dailyTotals.count
        let comparisonToAverage = averageMinutes > 0 ? ((todayMinutes - averageMinutes) * 100) / averageMinutes : nil
        
        // Detect trend (last 3 days vs previous 3 days)
        let trend = detectTrend(from: sessions)
        
        // Determine momentum
        let momentum = determineMomentum(
            todayPercentage: todayPercentage,
            streak: calculateCurrentStreak(),
            trend: trend
        )
        
        // Days hitting goal this week
        let daysHitGoal = countDaysHittingGoal(sessions: sessions, goalMinutes: goalMinutes, inLast: 7)
        
        return PerformanceInsight(
            todayMinutes: todayMinutes,
            todayPercentage: todayPercentage,
            todaySessions: todaySessions.count,
            weekAverageMinutes: averageMinutes,
            comparisonToAverage: comparisonToAverage,
            trend: trend,
            momentum: momentum,
            daysHitGoalThisWeek: daysHitGoal,
            currentStreak: calculateCurrentStreak()
        )
    }
    
    // MARK: - Pattern Detection
    
    func detectPatterns() -> BehavioralPatterns {
        let sessions = progressStore.sessions
        let memory = memoryManager.memory
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        // Peak productivity hours (top 3)
        var hourCounts: [Int: Int] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            hourCounts[hour, default: 0] += 1
        }
        let peakHours = hourCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        // Check if currently in peak window
        let isInPeakWindow = peakHours.contains(currentHour)
        
        // Preferred session length
        let preferredDuration = memory.preferredFocusDuration ?? calculateMostCommonDuration(from: sessions)
        
        // Best day of week
        var dayOfWeekCounts: [Int: (sessions: Int, totalMinutes: Int)] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            var existing = dayOfWeekCounts[weekday] ?? (0, 0)
            existing.sessions += 1
            existing.totalMinutes += Int(session.duration / 60)
            dayOfWeekCounts[weekday] = existing
        }
        
        // Best day by average completion
        let bestDayNumber = dayOfWeekCounts.max { a, b in
            let avgA = a.value.sessions > 0 ? a.value.totalMinutes / a.value.sessions : 0
            let avgB = b.value.sessions > 0 ? b.value.totalMinutes / b.value.sessions : 0
            return avgA < avgB
        }?.key
        
        let bestDay = bestDayNumber.map { dayOfWeekName($0) }
        
        // Average sessions per day (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recentSessions = sessions.filter { $0.date >= thirtyDaysAgo }
        let averageSessionsPerDay = recentSessions.isEmpty ? 0 : Double(recentSessions.count) / 30.0
        
        // Completion rate (days where goal was hit / total days with activity)
        let goalMinutes = progressStore.dailyGoalMinutes
        let completionRate = calculateCompletionRate(sessions: sessions, goalMinutes: goalMinutes)
        
        return BehavioralPatterns(
            peakHours: peakHours,
            isInPeakWindow: isInPeakWindow,
            preferredDuration: preferredDuration,
            bestDayOfWeek: bestDay,
            averageSessionsPerDay: averageSessionsPerDay,
            completionRate: completionRate
        )
    }
    
    // MARK: - User State Inference
    
    func inferUserState() -> UserStateInference {
        let sessions = progressStore.sessions
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Activity level based on recent sessions
        let todaySessions = sessions.filter { calendar.isDateInToday($0.date) }
        let hoursSinceLastSession = calculateHoursSinceLastSession(sessions: sessions)
        
        let activityLevel: ActivityLevel
        if todaySessions.count >= 3 {
            activityLevel = .veryActive
        } else if todaySessions.count >= 1 {
            activityLevel = .active
        } else if hoursSinceLastSession != nil && hoursSinceLastSession! < 24 {
            activityLevel = .returning
        } else {
            activityLevel = .inactive
        }
        
        // Energy estimation based on time, recent activity, and patterns
        let estimatedEnergy = estimateEnergy(
            hour: hour,
            todaySessionCount: todaySessions.count,
            hoursSinceLastSession: hoursSinceLastSession
        )
        
        // Streak risk
        let streak = calculateCurrentStreak()
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = progressStore.dailyGoalMinutes
        let todayPercentage = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        let streakRisk = calculateStreakRisk(
            streak: streak,
            todayPercentage: todayPercentage,
            hour: hour
        )
        
        // Suggested interaction tone
        let suggestedTone = determineSuggestedTone(
            activityLevel: activityLevel,
            energy: estimatedEnergy,
            streakRisk: streakRisk
        )
        
        return UserStateInference(
            activityLevel: activityLevel,
            estimatedEnergy: estimatedEnergy,
            streakRisk: streakRisk,
            suggestedTone: suggestedTone,
            hoursSinceLastSession: hoursSinceLastSession
        )
    }
    
    // MARK: - Opportunity Detection
    
    func detectOpportunities() -> [Opportunity] {
        var opportunities: [Opportunity] = []
        let progress = progressStore
        let sessions = progress.sessions
        let now = Date()
        
        let todaySessions = sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = progress.dailyGoalMinutes
        let remaining = max(0, goalMinutes - todayMinutes)
        let percentage = goalMinutes > 0 ? (todayMinutes * 100) / goalMinutes : 0
        
        // Goal completion proximity
        if percentage >= 75 && percentage < 100 {
            opportunities.append(.goalWithinReach(minutesLeft: remaining))
        } else if percentage >= 50 && percentage < 75 {
            opportunities.append(.halfwayToGoal(minutesLeft: remaining))
        }
        
        // Quick win with tasks (under 15 min, not completed today)
        let today = calendar.startOfDay(for: now)
        let quickTasks = tasksStore.tasks.filter { task in
            let duration = task.durationMinutes
            guard duration > 0 && duration <= 15 else { return false }
            return !tasksStore.isCompleted(taskId: task.id, on: today, calendar: calendar)
        }
        if let quickTask = quickTasks.first {
            opportunities.append(.quickWinAvailable(taskName: quickTask.title))
        }
        
        // Streak building
        let streak = calculateCurrentStreak()
        if streak > 0 && percentage >= 100 {
            opportunities.append(.streakExtension(currentStreak: streak))
        }
        
        // Peak hour opportunity
        let patterns = detectPatterns()
        if patterns.isInPeakWindow && todaySessions.isEmpty {
            opportunities.append(.peakHourActive)
        }
        
        // Milestone approaching
        let totalMinutes = Int(sessions.reduce(0) { $0 + $1.duration } / 60)
        let milestones = [100, 500, 1000, 2500, 5000, 10000]
        for milestone in milestones {
            if totalMinutes < milestone && (milestone - totalMinutes) <= 30 {
                opportunities.append(.milestoneApproaching(milestone: milestone, minutesAway: milestone - totalMinutes))
                break
            }
        }
        
        return opportunities
    }
    
    // MARK: - Risk Detection
    
    func detectRisks() -> [RiskAlert] {
        var risks: [RiskAlert] = []
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Streak risk
        let streak = calculateCurrentStreak()
        let todayProgress = analyzePerformance()
        
        if streak >= 3 && todayProgress.todayPercentage < 50 && hour >= 18 {
            risks.append(.streakAtRisk(daysAtStake: streak))
        } else if streak >= 7 && todayProgress.todayPercentage < 75 && hour >= 20 {
            risks.append(.streakAtRisk(daysAtStake: streak))
        }
        
        // Overdue tasks
        let tasks = tasksStore.tasks
        let today = calendar.startOfDay(for: now)
        let overdueTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            let isCompleted = tasksStore.isCompleted(taskId: task.id, on: today, calendar: calendar)
            return reminder < now && !isCompleted
        }
        if let overdueTask = overdueTasks.first {
            risks.append(.taskOverdue(taskName: overdueTask.title))
        }
        
        // Unusual inactivity
        let sessions = progressStore.sessions
        if let hoursSince = calculateHoursSinceLastSession(sessions: sessions), hoursSince > 48 {
            risks.append(.unusualInactivity(hoursSince: Int(hoursSince)))
        }
        
        // Potential burnout (very high activity followed by nothing today)
        let yesterdaySessions = sessions.filter { calendar.isDateInYesterday($0.date) }
        let yesterdayMinutes = Int(yesterdaySessions.reduce(0) { $0 + $1.duration } / 60)
        if yesterdayMinutes > 180 && todayProgress.todayMinutes == 0 && hour >= 12 {
            risks.append(.potentialBurnout)
        }
        
        return risks
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentStreak() -> Int {
        let sessions = progressStore.sessions
        let now = Date()
        
        var streak = 0
        var checkDate = now
        
        let hasTodaySession = sessions.contains { calendar.isDate($0.date, inSameDayAs: now) }
        if !hasTodaySession {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return 0 }
            checkDate = yesterday
        }
        
        for _ in 0..<365 {
            let hasSession = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasSession {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func detectTrend(from sessions: [ProgressSession]) -> PerformanceTrend? {
        let now = Date()
        
        // Last 3 days total
        var recent3Days = 0
        for dayOffset in 0..<3 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .reduce(0) { $0 + Int($1.duration / 60) }
            recent3Days += dayMinutes
        }
        
        // Previous 3 days total
        var previous3Days = 0
        for dayOffset in 3..<6 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .reduce(0) { $0 + Int($1.duration / 60) }
            previous3Days += dayMinutes
        }
        
        guard previous3Days > 0 else { return nil }
        
        let changePercent = ((recent3Days - previous3Days) * 100) / previous3Days
        
        if changePercent >= 20 {
            return .improving
        } else if changePercent <= -20 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func determineMomentum(todayPercentage: Int, streak: Int, trend: PerformanceTrend?) -> Momentum {
        if streak >= 7 && todayPercentage >= 50 {
            return .strong
        } else if streak >= 3 || (trend == .improving && todayPercentage >= 25) {
            return .building
        } else if trend == .declining || (streak == 0 && todayPercentage == 0) {
            return .needsBoost
        } else {
            return .steady
        }
    }
    
    private func countDaysHittingGoal(sessions: [ProgressSession], goalMinutes: Int, inLast days: Int) -> Int {
        let now = Date()
        var count = 0
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .reduce(0) { $0 + Int($1.duration / 60) }
            if dayMinutes >= goalMinutes {
                count += 1
            }
        }
        
        return count
    }
    
    private func calculateMostCommonDuration(from sessions: [ProgressSession]) -> Int? {
        guard !sessions.isEmpty else { return nil }
        
        // Round to nearest 5 minutes
        var durationCounts: [Int: Int] = [:]
        for session in sessions {
            let minutes = Int(session.duration / 60)
            let rounded = (minutes / 5) * 5
            durationCounts[rounded, default: 0] += 1
        }
        
        return durationCounts.max { $0.value < $1.value }?.key
    }
    
    private func calculateCompletionRate(sessions: [ProgressSession], goalMinutes: Int) -> Double {
        let now = Date()
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return 0 }
        
        var daysWithActivity = 0
        var daysHitGoal = 0
        
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .reduce(0) { $0 + Int($1.duration / 60) }
            
            if dayMinutes > 0 {
                daysWithActivity += 1
                if dayMinutes >= goalMinutes {
                    daysHitGoal += 1
                }
            }
        }
        
        return daysWithActivity > 0 ? Double(daysHitGoal) / Double(daysWithActivity) : 0
    }
    
    private func calculateHoursSinceLastSession(sessions: [ProgressSession]) -> Double? {
        guard let lastSession = sessions.max(by: { $0.date < $1.date }) else { return nil }
        return Date().timeIntervalSince(lastSession.date) / 3600
    }
    
    private func estimateEnergy(hour: Int, todaySessionCount: Int, hoursSinceLastSession: Double?) -> EnergyLevel {
        // Morning energy
        if hour >= 6 && hour < 12 {
            if todaySessionCount == 0 {
                return .high // Fresh start potential
            } else {
                return .medium // Already active
            }
        }
        
        // Afternoon
        if hour >= 12 && hour < 17 {
            if todaySessionCount >= 3 {
                return .low // Likely tired
            } else {
                return .medium
            }
        }
        
        // Evening
        if hour >= 17 && hour < 21 {
            return todaySessionCount >= 2 ? .low : .medium
        }
        
        // Night
        return .low
    }
    
    private func calculateStreakRisk(streak: Int, todayPercentage: Int, hour: Int) -> StreakRisk {
        if streak == 0 {
            return .none
        }
        
        if todayPercentage >= 100 {
            return .none // Already safe
        }
        
        if hour >= 21 && todayPercentage < 50 {
            return .high
        } else if hour >= 18 && todayPercentage < 25 {
            return .high
        } else if hour >= 15 && todayPercentage == 0 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func determineSuggestedTone(activityLevel: ActivityLevel, energy: EnergyLevel, streakRisk: StreakRisk) -> SuggestedTone {
        if streakRisk == .high {
            return .urgent
        }
        
        if activityLevel == .veryActive && energy == .low {
            return .gentle // Might be pushing too hard
        }
        
        if activityLevel == .inactive {
            return .encouraging
        }
        
        if energy == .high && activityLevel == .active {
            return .energetic
        }
        
        return .supportive
    }
    
    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(period)"
    }
    
    private func dayOfWeekName(_ weekday: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekday >= 1 && weekday <= 7 ? names[weekday] : "Unknown"
    }
}

// MARK: - Data Models

struct IntelligenceReport {
    let performance: PerformanceInsight
    let patterns: BehavioralPatterns
    let userState: UserStateInference
    let opportunities: [Opportunity]
    let risks: [RiskAlert]
    let generatedAt: Date
}

struct PerformanceInsight {
    let todayMinutes: Int
    let todayPercentage: Int
    let todaySessions: Int
    let weekAverageMinutes: Int
    let comparisonToAverage: Int?
    let trend: PerformanceTrend?
    let momentum: Momentum
    let daysHitGoalThisWeek: Int
    let currentStreak: Int
}

enum PerformanceTrend {
    case improving
    case stable
    case declining
    
    var description: String {
        switch self {
        case .improving: return "Improving - activity up vs last week"
        case .stable: return "Stable - consistent activity"
        case .declining: return "Declining - activity down vs last week"
        }
    }
}

enum Momentum {
    case strong
    case building
    case steady
    case needsBoost
    
    var description: String {
        switch self {
        case .strong: return "Strong - on a roll!"
        case .building: return "Building - gaining traction"
        case .steady: return "Steady - maintaining pace"
        case .needsBoost: return "Needs boost - let's get started!"
        }
    }
}

struct BehavioralPatterns {
    let peakHours: [Int]
    let isInPeakWindow: Bool
    let preferredDuration: Int?
    let bestDayOfWeek: String?
    let averageSessionsPerDay: Double
    let completionRate: Double
}

struct UserStateInference {
    let activityLevel: ActivityLevel
    let estimatedEnergy: EnergyLevel
    let streakRisk: StreakRisk
    let suggestedTone: SuggestedTone
    let hoursSinceLastSession: Double?
}

enum ActivityLevel {
    case veryActive  // 3+ sessions today
    case active      // 1-2 sessions today
    case returning   // No sessions today but recent
    case inactive    // No recent sessions
    
    var description: String {
        switch self {
        case .veryActive: return "Very active today"
        case .active: return "Active today"
        case .returning: return "Returning (no sessions yet today)"
        case .inactive: return "Inactive"
        }
    }
}

enum EnergyLevel {
    case high
    case medium
    case low
    
    var description: String {
        switch self {
        case .high: return "High (good time to focus)"
        case .medium: return "Medium"
        case .low: return "Low (consider a break)"
        }
    }
}

enum StreakRisk {
    case none
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium - keep an eye on it"
        case .high: return "High - needs attention today!"
        }
    }
}

enum SuggestedTone {
    case energetic   // Match their high energy
    case supportive  // General encouragement
    case encouraging // Need motivation
    case gentle      // Don't push too hard
    case urgent      // Streak at risk, need action
    
    var description: String {
        switch self {
        case .energetic: return "Energetic & action-oriented"
        case .supportive: return "Supportive & collaborative"
        case .encouraging: return "Encouraging & motivating"
        case .gentle: return "Gentle & understanding"
        case .urgent: return "Urgent but supportive"
        }
    }
}

enum Opportunity {
    case goalWithinReach(minutesLeft: Int)
    case halfwayToGoal(minutesLeft: Int)
    case quickWinAvailable(taskName: String)
    case streakExtension(currentStreak: Int)
    case peakHourActive
    case milestoneApproaching(milestone: Int, minutesAway: Int)
    
    var description: String {
        switch self {
        case .goalWithinReach(let minutes):
            return "Goal within reach - just \(minutes) min left!"
        case .halfwayToGoal(let minutes):
            return "Halfway there - \(minutes) min to goal"
        case .quickWinAvailable(let taskName):
            return "Quick win: '\(taskName)' is a short task"
        case .streakExtension(let streak):
            return "Extend your \(streak)-day streak with a bonus session"
        case .peakHourActive:
            return "Peak productivity hour - great time to start!"
        case .milestoneApproaching(let milestone, let away):
            return "\(milestone) min milestone is \(away) min away!"
        }
    }
}

enum RiskAlert {
    case streakAtRisk(daysAtStake: Int)
    case taskOverdue(taskName: String)
    case unusualInactivity(hoursSince: Int)
    case potentialBurnout
    
    var description: String {
        switch self {
        case .streakAtRisk(let days):
            return "\(days)-day streak at risk - need focus time today!"
        case .taskOverdue(let name):
            return "Task '\(name)' is overdue"
        case .unusualInactivity(let hours):
            return "No activity for \(hours) hours - everything okay?"
        case .potentialBurnout:
            return "Heavy day yesterday, no activity today - take it easy if needed"
        }
    }
}
