import Foundation

/// Flow AI Configuration
/// Central configuration for the Flow AI assistant
enum FlowConfig {
    
    // MARK: - API Configuration
    
    /// Supabase Edge Function URL for AI chat
    static var apiURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            #if DEBUG
            print("[FlowConfig] ⚠️ SUPABASE_URL not found in Info.plist")
            #endif
            return ""
        }
        return "\(url)/functions/v1/ai-chat"
    }
    
    /// Check if API is properly configured
    static var isConfigured: Bool {
        !apiURL.isEmpty
    }
    
    // MARK: - Conversation Limits
    
    /// Maximum messages to include in conversation history
    static let maxConversationHistory = 30
    
    /// Maximum characters for context sent to API
    static let maxContextCharacters = 24000
    
    /// Context cache duration in seconds
    static let contextCacheDuration: TimeInterval = 30
    
    // MARK: - Rate Limiting
    
    /// Maximum messages per minute for free users
    static let freeUserMessagesPerMinute = 5
    
    /// Maximum messages per day for free users
    static let freeUserMessagesPerDay = 25
    
    /// Cooldown period after hitting rate limit (seconds)
    static let rateLimitCooldown: TimeInterval = 60
    
    // MARK: - Streaming Configuration
    
    /// Enable streaming responses (disabled for now - use non-streaming for stability)
    static let streamingEnabled = false
    
    /// Timeout for streaming responses (seconds)
    static let streamTimeout: TimeInterval = 90
    
    /// Request timeout (seconds)
    static let requestTimeout: TimeInterval = 60
    
    // MARK: - Memory Configuration
    
    /// Enable AI memory (learns user preferences)
    static let memoryEnabled = true
    
    /// Days to keep memory data
    static let memoryRetentionDays = 30
    
    /// Maximum stored insights
    static let maxStoredInsights = 50
    
    // MARK: - UI Configuration
    
    /// Delay before showing typing indicator (seconds)
    static let typingIndicatorDelay: TimeInterval = 0.3
    
    /// Animation duration for message appearance
    static let messageAnimationDuration: TimeInterval = 0.25
    
    /// Haptic feedback enabled
    static let hapticsEnabled = true
    
    // MARK: - Feature Flags
    
    /// Voice input enabled
    static let voiceInputEnabled = true
    
    /// Proactive suggestions enabled
    static let proactiveSuggestionsEnabled = true
    
    /// Show smart status card at top of chat
    static let showStatusCard = true
    
    /// Enable quick action chips
    static let quickActionsEnabled = true
    
    // MARK: - Model Configuration
    
    /// OpenAI model to use (configured in Edge Function)
    static let modelName = "gpt-4o"
    
    /// Temperature for responses (0.0 - 1.0)
    static let temperature = 0.7
    
    // MARK: - Debug
    
    #if DEBUG
    static let debugLogging = true
    #else
    static let debugLogging = false
    #endif
}

// MARK: - Flow Error Types

enum FlowError: LocalizedError {
    case notConfigured
    case authenticationRequired
    case rateLimited(retryAfter: TimeInterval)
    case networkError(underlying: Error)
    case serverError(message: String)
    case invalidResponse
    case streamingError(message: String)
    case actionFailed(action: String, reason: String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Flow AI is not configured. Please check your settings."
        case .authenticationRequired:
            return "Please sign in to use Flow AI."
        case .rateLimited(let retryAfter):
            return "Too many requests. Please wait \(Int(retryAfter)) seconds."
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Received an invalid response. Please try again."
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .actionFailed(let action, let reason):
            return "Failed to execute \(action): \(reason)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .streamingError:
            return true
        case .rateLimited:
            return true
        default:
            return false
        }
    }
}
