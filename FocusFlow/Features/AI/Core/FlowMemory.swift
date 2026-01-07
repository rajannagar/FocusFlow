import Foundation
import Combine

// MARK: - Flow Memory System

/// Comprehensive memory system for Flow AI
/// Tracks user preferences, patterns, conversation history, and learned behaviors
/// Persists across app sessions for continuous learning and personalization
@MainActor
final class FlowMemoryManager: ObservableObject {
    static let shared = FlowMemoryManager()
    
    // MARK: - Published State
    
    @Published private(set) var memory: FlowMemory
    @Published private(set) var conversationSummaries: [ConversationSummary] = []
    @Published private(set) var learnedPatterns: LearnedPatterns
    @Published private(set) var sessionInsights: [SessionInsight] = []
    
    // MARK: - Storage Keys
    
    private let memoryKey = "flow_memory_v3"
    private let summariesKey = "flow_conversation_summaries_v2"
    private let patternsKey = "flow_learned_patterns_v2"
    private let insightsKey = "flow_session_insights"
    
    // MARK: - Initialization
    
    private init() {
        self.memory = Self.loadFromStorage(key: memoryKey) ?? FlowMemory()
        self.conversationSummaries = Self.loadFromStorage(key: summariesKey) ?? []
        self.learnedPatterns = Self.loadFromStorage(key: patternsKey) ?? LearnedPatterns()
        self.sessionInsights = Self.loadFromStorage(key: insightsKey) ?? []
        
        // Update session tracking
        recordNewSession()
    }
    
    // MARK: - Session Tracking
    
    private func recordNewSession() {
        updateMemory { memory in
            memory.lastSessionDate = Date()
            memory.totalSessions += 1
        }
    }
    
    // MARK: - Memory Updates
    
    /// Update core memory with new information
    func updateMemory(_ update: (inout FlowMemory) -> Void) {
        update(&memory)
        saveToStorage(memory, key: memoryKey)
    }
    
    /// Record a conversation summary for long-term memory
    func recordConversationSummary(
        userIntent: String,
        aiResponse: String,
        actionsExecuted: [String],
        satisfaction: ConversationSatisfaction?
    ) {
        let summary = ConversationSummary(
            date: Date(),
            userIntent: userIntent,
            aiResponseSummary: String(aiResponse.prefix(200)),
            actionsExecuted: actionsExecuted,
            satisfaction: satisfaction
        )
        
        conversationSummaries.append(summary)
        
        // Keep only last 50 summaries
        if conversationSummaries.count > 50 {
            conversationSummaries = Array(conversationSummaries.suffix(50))
        }
        
        saveToStorage(conversationSummaries, key: summariesKey)
        
        // Update conversation count
        updateMemory { $0.totalConversations += 1 }
    }
    
    /// Learn from user behavior
    func learnFromAction(action: String, context: ActionContext) {
        var patterns = learnedPatterns
        
        // Track action frequency
        patterns.actionFrequency[action, default: 0] += 1
        
        // Track time-based patterns
        let hour = Calendar.current.component(.hour, from: Date())
        patterns.hourlyActionPatterns[hour, default: [:]][action, default: 0] += 1
        
        // Track focus session patterns
        if action == "start_focus", let duration = context.duration {
            patterns.preferredFocusDurations.append(duration)
            // Keep last 20 durations
            if patterns.preferredFocusDurations.count > 20 {
                patterns.preferredFocusDurations = Array(patterns.preferredFocusDurations.suffix(20))
            }
            
            // Calculate preferred duration
            let avg = patterns.preferredFocusDurations.reduce(0, +) / patterns.preferredFocusDurations.count
            updateMemory { $0.preferredFocusDuration = avg }
        }
        
        // Track task creation patterns
        if action == "create_task", let taskType = context.taskType {
            patterns.commonTaskTypes[taskType, default: 0] += 1
        }
        
        learnedPatterns = patterns
        saveToStorage(patterns, key: patternsKey)
    }
    
    /// Record user feedback on AI response
    func recordFeedback(positive: Bool, conversationID: UUID?) {
        updateMemory { memory in
            if positive {
                memory.positiveInteractions += 1
            } else {
                memory.negativeInteractions += 1
            }
        }
        
        // Adjust motivation style based on feedback patterns
        let ratio = Double(memory.positiveInteractions) / max(1, Double(memory.positiveInteractions + memory.negativeInteractions))
        if ratio < 0.5 {
            // User may prefer different style - try being more direct
            updateMemory { $0.motivationStyle = .direct }
        } else if ratio > 0.8 {
            updateMemory { $0.motivationStyle = .encouraging }
        }
    }
    
    // MARK: - Pattern Analysis
    
    /// Get user's peak productivity hours
    func getPeakProductivityHours() -> [Int] {
        let sessions = ProgressStore.shared.sessions
        let calendar = Calendar.current
        
        var hourCounts: [Int: Int] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            hourCounts[hour, default: 0] += 1
        }
        
        // Get top 3 hours
        let sortedHours = hourCounts.sorted { $0.value > $1.value }
        let peakHours = sortedHours.prefix(3).map { $0.key }
        
        return peakHours
    }
    
    /// Get most used actions
    func getMostUsedActions(limit: Int = 5) -> [String] {
        learnedPatterns.actionFrequency
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    /// Get suggested action based on current time
    func getSuggestedActionForCurrentTime() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        
        guard let hourActions = learnedPatterns.hourlyActionPatterns[hour] else {
            return nil
        }
        
        return hourActions.max(by: { $0.value < $1.value })?.key
    }
    
    /// Check if user prefers a certain focus duration
    func getPreferredFocusDuration() -> Int? {
        guard !learnedPatterns.preferredFocusDurations.isEmpty else {
            return nil
        }
        
        let avg = learnedPatterns.preferredFocusDurations.reduce(0, +) / learnedPatterns.preferredFocusDurations.count
        return avg
    }
    
    // MARK: - Context Building
    
    /// Build memory context for AI system prompt
    func buildMemoryContext() -> String {
        var context = """
        
        === USER MEMORY ===
        Conversations so far: \(memory.totalConversations)
        Positive interactions: \(memory.positiveInteractions)
        Motivation style preference: \(memory.motivationStyle.displayName)
        """
        
        // Add preferred focus duration
        if let duration = memory.preferredFocusDuration {
            context += "\nPreferred focus duration: \(duration) minutes"
        }
        
        // Add peak hours
        let peakHours = getPeakProductivityHours()
        if !peakHours.isEmpty {
            let formatted = peakHours.map { formatHour($0) }.joined(separator: ", ")
            context += "\nPeak productivity hours: \(formatted)"
        }
        
        // Add recent goals
        if !memory.recentGoals.isEmpty {
            context += "\nRecent goals mentioned: \(memory.recentGoals.prefix(3).joined(separator: ", "))"
        }
        
        // Add recent conversation topics
        let recentTopics = conversationSummaries.suffix(5).map { $0.userIntent }
        if !recentTopics.isEmpty {
            context += "\nRecent conversation topics: \(recentTopics.joined(separator: "; "))"
        }
        
        // Add most used features
        let topActions = getMostUsedActions(limit: 3)
        if !topActions.isEmpty {
            let formatted = topActions.map { formatActionName($0) }.joined(separator: ", ")
            context += "\nMost used features: \(formatted)"
        }
        
        return context
    }
    
    // MARK: - Reset
    
    /// Clear all memory (for privacy/testing)
    func clearAllMemory() {
        memory = FlowMemory()
        conversationSummaries = []
        learnedPatterns = LearnedPatterns()
        
        UserDefaults.standard.removeObject(forKey: memoryKey)
        UserDefaults.standard.removeObject(forKey: summariesKey)
        UserDefaults.standard.removeObject(forKey: patternsKey)
    }
    
    // MARK: - Private Helpers
    
    private static func loadFromStorage<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func saveToStorage<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date).lowercased()
    }
    
    private func formatActionName(_ action: String) -> String {
        action
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Data Models

/// Core memory state
struct FlowMemory: Codable {
    var preferredFocusDuration: Int?
    var peakProductivityHours: [Int] = []
    var recentGoals: [String] = []
    var totalConversations: Int = 0
    var positiveInteractions: Int = 0
    var negativeInteractions: Int = 0
    var lastTipDate: Date?
    var lastMotivationDate: Date?
    var motivationStyle: MotivationStyle = .balanced
    var userPreferences: UserPreferences = UserPreferences()
    
    // Session tracking
    var lastSessionDate: Date?
    var totalSessions: Int = 0
    var longestStreak: Int = 0
    
    // Personalization data
    var userName: String?
    var userGoals: [String] = []
    var userChallenges: [String] = []
    var learnedFacts: [String] = []
    
    enum MotivationStyle: String, Codable {
        case encouraging
        case direct
        case balanced
        
        var displayName: String {
            switch self {
            case .encouraging: return "Encouraging & supportive"
            case .direct: return "Direct & concise"
            case .balanced: return "Balanced"
            }
        }
    }
}

/// User preferences learned over time
struct UserPreferences: Codable {
    var prefersShortResponses: Bool = true
    var likesEmojis: Bool = true
    var prefersMorningFocus: Bool?
    var prefersTaskReminders: Bool = true
    var preferredTaskDuration: Int?
}

/// Summary of a conversation for long-term memory
struct ConversationSummary: Codable, Identifiable {
    let id: UUID
    let date: Date
    let userIntent: String
    let aiResponseSummary: String
    let actionsExecuted: [String]
    let satisfaction: ConversationSatisfaction?
    
    init(
        id: UUID = UUID(),
        date: Date,
        userIntent: String,
        aiResponseSummary: String,
        actionsExecuted: [String],
        satisfaction: ConversationSatisfaction?
    ) {
        self.id = id
        self.date = date
        self.userIntent = userIntent
        self.aiResponseSummary = aiResponseSummary
        self.actionsExecuted = actionsExecuted
        self.satisfaction = satisfaction
    }
}

/// User satisfaction with conversation
enum ConversationSatisfaction: String, Codable {
    case positive
    case neutral
    case negative
}

/// Learned behavioral patterns
struct LearnedPatterns: Codable {
    var actionFrequency: [String: Int] = [:]
    var hourlyActionPatterns: [Int: [String: Int]] = [:]
    var preferredFocusDurations: [Int] = []
    var commonTaskTypes: [String: Int] = [:]
    var dayOfWeekPatterns: [Int: [String: Int]] = [:]
}

/// Context for learning from an action
struct ActionContext {
    var duration: Int?
    var taskType: String?
    var presetName: String?
    var wasSuccessful: Bool = true
}

/// Session insight for long-term pattern learning
struct SessionInsight: Codable, Identifiable {
    let id: UUID
    let date: Date
    let insightType: InsightType
    let message: String
    let data: [String: String]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        insightType: InsightType,
        message: String,
        data: [String: String] = [:]
    ) {
        self.id = id
        self.date = date
        self.insightType = insightType
        self.message = message
        self.data = data
    }
    
    enum InsightType: String, Codable {
        case productivityPattern
        case focusPreference
        case taskBehavior
        case progressMilestone
        case streakAchievement
        case learningMoment
    }
}

// MARK: - FlowMemoryManager Extensions

extension FlowMemoryManager {
    
    /// Record a session insight for future reference
    func recordInsight(_ insight: SessionInsight) {
        sessionInsights.append(insight)
        
        // Keep last 100 insights
        if sessionInsights.count > 100 {
            sessionInsights = Array(sessionInsights.suffix(100))
        }
        
        saveToStorage(sessionInsights, key: insightsKey)
    }
    
    /// Learn user's name from conversation
    func learnUserName(_ name: String) {
        guard !name.isEmpty else { return }
        updateMemory { $0.userName = name }
    }
    
    /// Learn a fact about the user
    func learnFact(_ fact: String) {
        guard !fact.isEmpty else { return }
        updateMemory { memory in
            if !memory.learnedFacts.contains(fact) {
                memory.learnedFacts.append(fact)
                // Keep last 20 facts
                if memory.learnedFacts.count > 20 {
                    memory.learnedFacts = Array(memory.learnedFacts.suffix(20))
                }
            }
        }
    }
    
    /// Learn a user goal
    func learnGoal(_ goal: String) {
        guard !goal.isEmpty else { return }
        updateMemory { memory in
            if !memory.userGoals.contains(goal) {
                memory.userGoals.append(goal)
                // Keep last 10 goals
                if memory.userGoals.count > 10 {
                    memory.userGoals = Array(memory.userGoals.suffix(10))
                }
            }
        }
    }
    
    /// Learn a user challenge
    func learnChallenge(_ challenge: String) {
        guard !challenge.isEmpty else { return }
        updateMemory { memory in
            if !memory.userChallenges.contains(challenge) {
                memory.userChallenges.append(challenge)
                // Keep last 10 challenges
                if memory.userChallenges.count > 10 {
                    memory.userChallenges = Array(memory.userChallenges.suffix(10))
                }
            }
        }
    }
    
    /// Get greeting based on relationship and time
    func getPersonalizedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        
        if hour < 12 {
            timeGreeting = "Good morning"
        } else if hour < 17 {
            timeGreeting = "Good afternoon"
        } else {
            timeGreeting = "Good evening"
        }
        
        if let name = memory.userName {
            return "\(timeGreeting), \(name)!"
        } else if memory.totalConversations > 10 {
            return "\(timeGreeting)! Great to see you back."
        } else if memory.totalConversations > 0 {
            return "\(timeGreeting)! Welcome back."
        } else {
            return "\(timeGreeting)! I'm Flow, your AI assistant."
        }
    }
    
    /// Check if user is a returning user
    var isReturningUser: Bool {
        memory.totalSessions > 1
    }
    
    /// Get days since last session
    var daysSinceLastSession: Int? {
        guard let lastSession = memory.lastSessionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastSession, to: Date()).day
    }
}
