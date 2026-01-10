import Foundation
import Combine

// MARK: - Flow User Profile
// Enhanced user profile for Phase 7: Advanced Memory & Learning
// Tracks behavioral patterns, preferences, and learns from interactions

/// Comprehensive user profile for personalized AI interactions
struct FlowUserProfile: Codable {
    
    // MARK: - Identity & Persona
    
    /// Productivity persona inferred from behavior patterns
    var productivityPersona: ProductivityPersona = .unknown
    
    /// How the user prefers to be motivated
    var motivationStyle: MotivationStyle = .balanced
    
    /// How enthusiastic celebrations should be
    var celebrationPreference: CelebrationLevel = .moderate
    
    // MARK: - Behavioral DNA
    
    /// Hours when user is most productive (0-23)
    var peakHours: [Int] = []
    
    /// User's typical session length in minutes
    var preferredSessionLength: Int = 25
    
    /// Categories of tasks user commonly creates
    var commonTaskCategories: [String: Int] = [:]
    
    /// Average sessions per day over last 30 days
    var averageSessionsPerDay: Double = 0
    
    /// Percentage of goals completed
    var goalCompletionRate: Double = 0
    
    // MARK: - Interaction Preferences
    
    /// Whether user prefers short or detailed responses
    var responseStyle: ResponseStyle = .concise
    
    /// How often to send proactive nudges
    var nudgeFrequency: NudgeFrequency = .moderate
    
    /// Whether AI should auto-execute or ask first
    var actionBias: ActionBias = .suggest
    
    // MARK: - Learning History
    
    /// Motivation phrases that got positive engagement
    var effectiveMotivations: [MotivationRecord] = []
    
    /// Approaches that didn't resonate (user ignored or negative feedback)
    var ineffectiveApproaches: [String] = []
    
    /// Features used and frequency
    var featureUsage: [String: Int] = [:]
    
    /// Successful patterns (time + action combinations that worked)
    var successPatterns: [SuccessPattern] = []
    
    // MARK: - Timestamps
    
    var lastUpdated: Date = Date()
    var profileVersion: Int = 1
}

// MARK: - Productivity Persona

enum ProductivityPersona: String, Codable, CaseIterable {
    case morningWarrior = "Morning Warrior"
    case nightOwl = "Night Owl"
    case sprintWorker = "Sprint Worker"
    case marathonRunner = "Marathon Runner"
    case flexibleAdapter = "Flexible Adapter"
    case unknown = "Unknown"
    
    var description: String {
        switch self {
        case .morningWarrior:
            return "Most productive in early hours, front-loads important work"
        case .nightOwl:
            return "Peak performance in evening/night hours"
        case .sprintWorker:
            return "Prefers short, intense bursts of focus"
        case .marathonRunner:
            return "Thrives in longer, sustained focus sessions"
        case .flexibleAdapter:
            return "Productive across various times and session lengths"
        case .unknown:
            return "Still learning your patterns"
        }
    }
    
    var emoji: String {
        switch self {
        case .morningWarrior: return "🌅"
        case .nightOwl: return "🦉"
        case .sprintWorker: return "⚡"
        case .marathonRunner: return "🏃"
        case .flexibleAdapter: return "🔄"
        case .unknown: return "🔍"
        }
    }
    
    /// Suggested session length based on persona
    var suggestedSessionLength: Int {
        switch self {
        case .sprintWorker: return 15
        case .marathonRunner: return 45
        default: return 25
        }
    }
}

// MARK: - Motivation Style

enum MotivationStyle: String, Codable, CaseIterable {
    case encouraging = "Encouraging"
    case direct = "Direct"
    case gentle = "Gentle"
    case balanced = "Balanced"
    case dataFocused = "Data-Focused"
    
    var description: String {
        switch self {
        case .encouraging:
            return "Lots of positive reinforcement and celebration"
        case .direct:
            return "Straightforward, no-nonsense communication"
        case .gentle:
            return "Soft encouragement, never pushy"
        case .balanced:
            return "Mix of encouragement and directness"
        case .dataFocused:
            return "Focus on stats and progress metrics"
        }
    }
}

// MARK: - Celebration Level

enum CelebrationLevel: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case moderate = "Moderate"
    case enthusiastic = "Enthusiastic"
    
    var description: String {
        switch self {
        case .minimal:
            return "Simple acknowledgment, no fanfare"
        case .moderate:
            return "Appropriate celebration for achievements"
        case .enthusiastic:
            return "Big celebrations with emojis and excitement"
        }
    }
    
    var emojiCount: Int {
        switch self {
        case .minimal: return 0
        case .moderate: return 1
        case .enthusiastic: return 2
        }
    }
}

// MARK: - Response Style

enum ResponseStyle: String, Codable, CaseIterable {
    case concise = "Concise"
    case detailed = "Detailed"
    
    var description: String {
        switch self {
        case .concise:
            return "Short, to-the-point responses"
        case .detailed:
            return "More context and explanation"
        }
    }
    
    var maxWords: Int {
        switch self {
        case .concise: return 30
        case .detailed: return 75
        }
    }
}

// MARK: - Nudge Frequency

enum NudgeFrequency: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case moderate = "Moderate"
    case frequent = "Frequent"
    
    var description: String {
        switch self {
        case .minimal:
            return "Only important reminders"
        case .moderate:
            return "Balanced nudges throughout the day"
        case .frequent:
            return "Regular check-ins and suggestions"
        }
    }
    
    var maxNudgesPerDay: Int {
        switch self {
        case .minimal: return 2
        case .moderate: return 5
        case .frequent: return 10
        }
    }
}

// MARK: - Action Bias

enum ActionBias: String, Codable, CaseIterable {
    case auto = "Auto"
    case suggest = "Suggest"
    case ask = "Ask"
    
    var description: String {
        switch self {
        case .auto:
            return "Execute actions automatically when clear"
        case .suggest:
            return "Suggest actions, execute on confirmation"
        case .ask:
            return "Always ask before taking action"
        }
    }
}

// MARK: - Supporting Types

/// Record of a motivation that worked
struct MotivationRecord: Codable, Identifiable {
    let id: UUID
    let phrase: String
    let context: String
    let engagementType: EngagementType
    let date: Date
    
    init(phrase: String, context: String, engagementType: EngagementType) {
        self.id = UUID()
        self.phrase = phrase
        self.context = context
        self.engagementType = engagementType
        self.date = Date()
    }
    
    enum EngagementType: String, Codable {
        case startedSession = "Started a session after"
        case completedGoal = "Completed goal after"
        case positiveFeedback = "Received positive feedback"
        case continuedConversation = "Continued conversation"
    }
}

/// Pattern that led to success
struct SuccessPattern: Codable, Identifiable {
    let id: UUID
    let hourOfDay: Int
    let dayOfWeek: Int
    let action: String
    let outcome: String
    let count: Int
    let lastOccurred: Date
    
    init(hourOfDay: Int, dayOfWeek: Int, action: String, outcome: String, count: Int = 1) {
        self.id = UUID()
        self.hourOfDay = hourOfDay
        self.dayOfWeek = dayOfWeek
        self.action = action
        self.outcome = outcome
        self.count = count
        self.lastOccurred = Date()
    }
}

// MARK: - Profile Manager

@MainActor
final class FlowUserProfileManager: ObservableObject {
    static let shared = FlowUserProfileManager()
    
    @Published private(set) var profile: FlowUserProfile
    
    private let storageKey = "flow_user_profile_v1"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode(FlowUserProfile.self, from: data) {
            self.profile = loaded
        } else {
            self.profile = FlowUserProfile()
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(_ update: (inout FlowUserProfile) -> Void) {
        update(&profile)
        profile.lastUpdated = Date()
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // MARK: - Persona Detection
    
    /// Analyze patterns and infer productivity persona
    func inferPersona(from sessions: [ProgressSession]) {
        guard sessions.count >= 10 else { return } // Need enough data
        
        let calendar = Calendar.current
        
        // Analyze time patterns
        var hourCounts: [Int: Int] = [:]
        var durationSum: Int = 0
        
        for session in sessions.suffix(50) { // Last 50 sessions
            let hour = calendar.component(.hour, from: session.date)
            hourCounts[hour, default: 0] += 1
            durationSum += Int(session.duration / 60)
        }
        
        let avgDuration = sessions.isEmpty ? 25 : durationSum / sessions.count
        
        // Determine peak hours
        let sortedHours = hourCounts.sorted { $0.value > $1.value }
        let topHours = sortedHours.prefix(3).map { $0.key }
        
        updateProfile { $0.peakHours = topHours }
        updateProfile { $0.preferredSessionLength = avgDuration }
        
        // Infer persona
        let persona: ProductivityPersona
        
        // Morning (5-11) vs Evening (18-23) preference
        let morningCount = hourCounts.filter { (5...11).contains($0.key) }.values.reduce(0, +)
        let eveningCount = hourCounts.filter { (18...23).contains($0.key) }.values.reduce(0, +)
        
        if morningCount > eveningCount * 2 {
            persona = .morningWarrior
        } else if eveningCount > morningCount * 2 {
            persona = .nightOwl
        } else if avgDuration <= 20 {
            persona = .sprintWorker
        } else if avgDuration >= 40 {
            persona = .marathonRunner
        } else {
            persona = .flexibleAdapter
        }
        
        updateProfile { $0.productivityPersona = persona }
    }
    
    // MARK: - Learning from Interactions
    
    /// Record that a motivation phrase led to engagement
    func recordEffectiveMotivation(_ phrase: String, context: String, engagementType: MotivationRecord.EngagementType) {
        let record = MotivationRecord(phrase: phrase, context: context, engagementType: engagementType)
        
        updateProfile { profile in
            profile.effectiveMotivations.append(record)
            // Keep last 30 effective motivations
            if profile.effectiveMotivations.count > 30 {
                profile.effectiveMotivations = Array(profile.effectiveMotivations.suffix(30))
            }
        }
    }
    
    /// Record an approach that didn't work
    func recordIneffectiveApproach(_ approach: String) {
        updateProfile { profile in
            if !profile.ineffectiveApproaches.contains(approach) {
                profile.ineffectiveApproaches.append(approach)
                // Keep last 20
                if profile.ineffectiveApproaches.count > 20 {
                    profile.ineffectiveApproaches = Array(profile.ineffectiveApproaches.suffix(20))
                }
            }
        }
    }
    
    /// Track feature usage
    func trackFeatureUsage(_ feature: String) {
        updateProfile { profile in
            profile.featureUsage[feature, default: 0] += 1
        }
    }
    
    /// Record a successful pattern
    func recordSuccessPattern(action: String, outcome: String) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())
        
        updateProfile { profile in
            // Check if pattern exists
            if let index = profile.successPatterns.firstIndex(where: {
                $0.hourOfDay == hour && $0.dayOfWeek == weekday && $0.action == action
            }) {
                // Update existing pattern
                var pattern = profile.successPatterns[index]
                pattern = SuccessPattern(
                    hourOfDay: hour,
                    dayOfWeek: weekday,
                    action: action,
                    outcome: outcome,
                    count: profile.successPatterns[index].count + 1
                )
                profile.successPatterns[index] = pattern
            } else {
                // Add new pattern
                let pattern = SuccessPattern(
                    hourOfDay: hour,
                    dayOfWeek: weekday,
                    action: action,
                    outcome: outcome
                )
                profile.successPatterns.append(pattern)
                
                // Keep top 50 patterns
                if profile.successPatterns.count > 50 {
                    profile.successPatterns.sort { $0.count > $1.count }
                    profile.successPatterns = Array(profile.successPatterns.prefix(50))
                }
            }
        }
    }
    
    // MARK: - Context Building
    
    /// Build profile context for AI system prompt
    func buildProfileContext() -> String {
        var context = "\n=== USER PROFILE ===\n"
        
        // Persona
        if profile.productivityPersona != .unknown {
            context += "Productivity type: \(profile.productivityPersona.emoji) \(profile.productivityPersona.rawValue)\n"
            context += "  → \(profile.productivityPersona.description)\n"
        }
        
        // Preferences
        context += "Response preference: \(profile.responseStyle.rawValue) (\(profile.responseStyle.description))\n"
        context += "Motivation style: \(profile.motivationStyle.rawValue)\n"
        context += "Celebration level: \(profile.celebrationPreference.rawValue)\n"
        
        // Peak hours
        if !profile.peakHours.isEmpty {
            let hours = profile.peakHours.map { formatHour($0) }.joined(separator: ", ")
            context += "Peak hours: \(hours)\n"
        }
        
        // Preferred session length
        if profile.preferredSessionLength > 0 {
            context += "Preferred session: \(profile.preferredSessionLength) min\n"
        }
        
        // Effective motivations
        if !profile.effectiveMotivations.isEmpty {
            let recent = profile.effectiveMotivations.suffix(3).map { $0.phrase }
            context += "Motivations that work: \(recent.joined(separator: "; "))\n"
        }
        
        // Things to avoid
        if !profile.ineffectiveApproaches.isEmpty {
            context += "Avoid: \(profile.ineffectiveApproaches.prefix(3).joined(separator: ", "))\n"
        }
        
        // Success patterns
        let topPatterns = profile.successPatterns.sorted { $0.count > $1.count }.prefix(3)
        if !topPatterns.isEmpty {
            context += "Success patterns:\n"
            for pattern in topPatterns {
                context += "  • \(formatHour(pattern.hourOfDay)) \(formatWeekday(pattern.dayOfWeek)): \(pattern.action) → \(pattern.outcome) (×\(pattern.count))\n"
            }
        }
        
        return context
    }
    
    // MARK: - Helpers
    
    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(period)"
    }
    
    private func formatWeekday(_ weekday: Int) -> String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekday >= 1 && weekday <= 7 ? days[weekday] : ""
    }
    
    // MARK: - Reset
    
    func resetProfile() {
        profile = FlowUserProfile()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
