import Foundation

/// AI Service that communicates with Supabase Edge Function
/// The Edge Function handles OpenAI API calls securely on the server
@MainActor
final class AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Send a message to the AI via Supabase Edge Function
    /// - Parameters:
    ///   - userMessage: The user's message text
    ///   - conversationHistory: Previous messages in the conversation
    ///   - context: Context string with user data (tasks, presets, settings, etc.)
    /// - Returns: Tuple of (response text, array of actions to execute)
    func sendMessage(
        userMessage: String,
        conversationHistory: [AIMessage],
        context: String
    ) async throws -> (response: String, actions: [AIAction]) {
        
        guard AIConfig.isConfigured else {
            throw AIServiceError.notConfigured
        }
        
        // Get auth token from Supabase
        let authToken: String
        do {
            authToken = try await SupabaseManager.shared.currentUserToken()
        } catch {
            #if DEBUG
            print("[AIService] ❌ Failed to get auth token: \(error)")
            #endif
            throw AIServiceError.authenticationRequired
        }
        
        // Build conversation history for Edge Function
        let conversationData = conversationHistory.suffix(AIConfig.maxMessages).map { msg in
            ["sender": msg.sender.rawValue, "text": msg.text]
        }
        
        let requestBody: [String: Any] = [
            "userMessage": userMessage,
            "conversationHistory": conversationData,
            "context": context
        ]
        
        guard let url = URL(string: AIConfig.apiURL) else {
            throw AIServiceError.invalidURL
        }
        
        #if DEBUG
        print("[AIService] 📤 Sending request to Edge Function: \(url.absoluteString)")
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Supabase anon key for Edge Function auth
        if let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60 // AI responses can take time
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        #if DEBUG
        print("[AIService] 📥 Response status: \(httpResponse.statusCode)")
        if let responseStr = String(data: data, encoding: .utf8) {
            print("[AIService] 📥 Response body: \(responseStr.prefix(500))...")
        }
        #endif
        
        // Handle HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            switch httpResponse.statusCode {
            case 401:
                throw AIServiceError.authenticationRequired
            case 429:
                throw AIServiceError.rateLimited
            case 500...599:
                throw AIServiceError.serverError(message: errorMessage)
            default:
                throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        }
        
        // Parse Edge Function response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.invalidResponseFormat
        }
        
        // Check for error in response
        if let error = json["error"] as? String {
            throw AIServiceError.serverError(message: error)
        }
        
        let responseText = json["response"] as? String ?? ""
        var actions: [AIAction] = []
        
        // Parse actions array from Edge Function
        if let actionsArray = json["actions"] as? [[String: Any]] {
            for actionDict in actionsArray {
                if let action = parseActionFromEdgeFunction(actionDict) {
                    actions.append(action)
                }
            }
        }
        
        #if DEBUG
        print("[AIService] ✅ Parsed response with \(actions.count) action(s)")
        #endif
        
        return (responseText, actions)
    }
    
    // MARK: - Action Parsing
    
    /// Parse action from Edge Function response format
    /// Edge Function returns: { "type": "function_name", "params": { ... } }
    private func parseActionFromEdgeFunction(_ dict: [String: Any]) -> AIAction? {
        guard let type = dict["type"] as? String,
              let params = dict["params"] as? [String: Any] else {
            #if DEBUG
            print("[AIService] ⚠️ Invalid action format: \(dict)")
            #endif
            return nil
        }
        
        #if DEBUG
        print("[AIService] Parsing action: \(type) with params: \(params)")
        #endif
        
        switch type {
        // MARK: Task Actions
        case "create_task":
            guard let title = params["title"] as? String, !title.isEmpty else {
                #if DEBUG
                print("[AIService] ⚠️ create_task missing title")
                #endif
                return nil
            }
            let reminderDate = (params["reminderDate"] as? String).flatMap { parseDate(from: $0) }
            let duration = (params["durationMinutes"] as? Int).map { TimeInterval($0 * 60) }
            return .createTask(title: title, reminderDate: reminderDate, duration: duration)
            
        case "update_task":
            guard let taskIDStr = params["taskID"] as? String,
                  let taskID = UUID(uuidString: taskIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ update_task missing/invalid taskID")
                #endif
                return nil
            }
            let title = params["title"] as? String
            let reminderDate = (params["reminderDate"] as? String).flatMap { parseDate(from: $0) }
            let duration = (params["durationMinutes"] as? Int).map { TimeInterval($0 * 60) }
            return .updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case "delete_task":
            guard let taskIDStr = params["taskID"] as? String,
                  let taskID = UUID(uuidString: taskIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ delete_task missing/invalid taskID")
                #endif
                return nil
            }
            return .deleteTask(taskID: taskID)
            
        case "toggle_task_completion":
            guard let taskIDStr = params["taskID"] as? String,
                  let taskID = UUID(uuidString: taskIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ toggle_task_completion missing/invalid taskID")
                #endif
                return nil
            }
            return .toggleTaskCompletion(taskID: taskID)
            
        case "list_future_tasks":
            return .listFutureTasks
            
        // MARK: Preset Actions
        case "set_preset":
            guard let presetIDStr = params["presetID"] as? String,
                  let presetID = UUID(uuidString: presetIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ set_preset missing/invalid presetID")
                #endif
                return nil
            }
            return .setPreset(presetID: presetID)
            
        case "create_preset":
            guard let name = params["name"] as? String, !name.isEmpty,
                  let durationSeconds = params["durationSeconds"] as? Int else {
                #if DEBUG
                print("[AIService] ⚠️ create_preset missing name or durationSeconds")
                #endif
                return nil
            }
            let soundID = params["soundID"] as? String ?? "none"
            return .createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case "update_preset":
            guard let presetIDStr = params["presetID"] as? String,
                  let presetID = UUID(uuidString: presetIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ update_preset missing/invalid presetID")
                #endif
                return nil
            }
            let name = params["name"] as? String
            let durationSeconds = params["durationSeconds"] as? Int
            return .updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case "delete_preset":
            guard let presetIDStr = params["presetID"] as? String,
                  let presetID = UUID(uuidString: presetIDStr) else {
                #if DEBUG
                print("[AIService] ⚠️ delete_preset missing/invalid presetID")
                #endif
                return nil
            }
            return .deletePreset(presetID: presetID)
            
        // MARK: Focus Actions
        case "start_focus":
            guard let minutes = params["minutes"] as? Int, minutes > 0 else {
                #if DEBUG
                print("[AIService] ⚠️ start_focus missing/invalid minutes")
                #endif
                return nil
            }
            let presetID = (params["presetID"] as? String).flatMap { UUID(uuidString: $0) }
            let sessionName = params["sessionName"] as? String
            return .startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
        // MARK: Settings Actions
        case "update_setting":
            guard let setting = params["setting"] as? String, !setting.isEmpty,
                  let value = params["value"] as? String else {
                #if DEBUG
                print("[AIService] ⚠️ update_setting missing setting or value")
                #endif
                return nil
            }
            return .updateSetting(setting: setting, value: value)
            
        // MARK: Stats Actions
        case "get_stats":
            guard let period = params["period"] as? String, !period.isEmpty else {
                #if DEBUG
                print("[AIService] ⚠️ get_stats missing period")
                #endif
                return nil
            }
            return .getStats(period: period)
            
        case "analyze_sessions":
            return .analyzeSessions
            
        // MARK: Smart Planning Actions
        case "generate_daily_plan":
            return .generateDailyPlan
            
        case "suggest_break":
            return .suggestBreak
            
        case "motivate":
            return .motivate
            
        // MARK: Advanced Analytics Actions
        case "generate_weekly_report":
            return .generateWeeklyReport
            
        case "show_welcome":
            return .showWelcome
            
        default:
            #if DEBUG
            print("[AIService] ⚠️ Unknown action type: \(type)")
            #endif
            return nil
        }
    }
    
    // MARK: - Date Parsing
    
    /// Parse ISO 8601 date string from AI response
    /// Handles multiple formats:
    /// - Full ISO 8601 with timezone: 2026-01-06T19:00:00Z
    /// - ISO 8601 without timezone: 2026-01-06T19:00:00
    /// - With fractional seconds: 2026-01-06T19:00:00.000Z
    private func parseDate(from dateString: String) -> Date? {
        // Try ISO 8601 with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // Try ISO 8601 standard
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // Try without timezone (local time from AI)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = localFormatter.date(from: dateString) {
            return date
        }
        
        // Try with timezone offset
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = localFormatter.date(from: dateString) {
            return date
        }
        
        #if DEBUG
        print("[AIService] ⚠️ Failed to parse date: \(dateString)")
        #endif
        return nil
    }
}

// MARK: - Error Types

enum AIServiceError: LocalizedError {
    case notConfigured
    case authenticationRequired
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case rateLimited
    case serverError(message: String)
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service is not configured. Please check your Supabase configuration."
        case .authenticationRequired:
            return "Please sign in to use Focus AI."
        case .invalidURL:
            return "Invalid API URL configuration."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidResponseFormat:
            return "Unable to parse server response."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let message):
            #if DEBUG
            return "Server error: \(message)"
            #else
            return "Server error. Please try again later."
            #endif
        case .apiError(let statusCode, let message):
            #if DEBUG
            return "API error (\(statusCode)): \(message)"
            #else
            return "Something went wrong. Please try again."
            #endif
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
