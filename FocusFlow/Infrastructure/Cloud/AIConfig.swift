import Foundation

/// Configuration for AI service
struct AIConfig {
    /// OpenAI API endpoint
    static let apiURL = "https://api.openai.com/v1/chat/completions"
    
    /// Model to use
    /// Try these models in order of preference (check which ones your API key has access to):
    static let model = "gpt-4o-mini" // Cost-effective, supports function calling, best compatibility
    // Alternative models to try if gpt-4o-mini doesn't work:
    // - "gpt-4o" (most capable, but requires higher tier API access)
    // - "gpt-4-turbo" (if you have access)
    // - "gpt-3.5-turbo" (older model, may not have access)
    
    /// Maximum conversation length (to limit costs)
    static let maxMessages = 20
    
    /// Context cache duration (5 minutes)
    static let contextCacheDuration: TimeInterval = 300
    
    /// API key - should be stored securely (e.g., in environment variables or secure storage)
    /// For production, this should be retrieved from a secure backend service
    static var apiKey: String {
        // First, try environment variable (for development/testing)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // For production, you should:
        // 1. Store the key in Keychain or secure storage
        // 2. Or better yet, route API calls through your backend server
        // This prevents the key from being exposed in the app binary
        
        return ""
    }
    
    /// Check if API key is configured
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

