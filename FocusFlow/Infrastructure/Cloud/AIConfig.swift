import Foundation

/// Configuration for AI service via Supabase Edge Function
struct AIConfig {
    /// Supabase Edge Function URL for AI chat
    /// The Edge Function handles OpenAI API calls securely on the server
    static var apiURL: String {
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            #if DEBUG
            print("[AIConfig] ⚠️ Missing SUPABASE_URL in Info.plist")
            #endif
            return ""
        }
        return "\(supabaseURL)/functions/v1/ai-chat"
    }
    
    /// Model to use (for reference - actual model is configured in Edge Function)
    static let model = "gpt-4o"
    
    /// Maximum conversation length (to limit token usage)
    static let maxMessages = 20
    
    /// Context cache duration (short to keep data fresh)
    static let contextCacheDuration: TimeInterval = 5
    
    /// Check if AI service is configured
    /// Returns true if Supabase URL is configured (Edge Function handles API key)
    static var isConfigured: Bool {
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !supabaseURL.isEmpty else {
            return false
        }
        return true
    }
}
