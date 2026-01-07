import Foundation

// MARK: - Flow Service

/// Handles communication with the AI backend (Supabase Edge Function)
/// Supports streaming responses for real-time feel
@MainActor
final class FlowService {
    static let shared = FlowService()
    
    private init() {}
    
    // MARK: - Types
    
    struct FlowResponse {
        let content: String
        let actions: [FlowAction]
        let metadata: ResponseMetadata?
    }
    
    struct ResponseMetadata {
        let tokensUsed: Int?
        let responseTime: TimeInterval
        let modelUsed: String?
    }
    
    // MARK: - Send Message (Non-Streaming)
    
    /// Send a message and get a complete response
    func sendMessage(
        userMessage: String,
        conversationHistory: [FlowMessage],
        context: String
    ) async throws -> FlowResponse {
        guard FlowConfig.isConfigured else {
            #if DEBUG
            print("[FlowService] ❌ Not configured - missing SUPABASE_URL")
            #endif
            throw FlowError.notConfigured
        }
        
        #if DEBUG
        print("[FlowService] 🚀 Sending message to: \(FlowConfig.apiURL)")
        #endif
        
        let startTime = Date()
        
        // Get auth token
        let authToken: String
        do {
            authToken = try await SupabaseManager.shared.currentUserToken()
            #if DEBUG
            print("[FlowService] ✅ Got auth token (length: \(authToken.count))")
            #endif
        } catch {
            #if DEBUG
            print("[FlowService] ❌ Auth token error: \(error)")
            #endif
            throw FlowError.authenticationRequired
        }
        
        // Build request
        let requestBody = buildRequestBody(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            context: context,
            stream: false
        )
        
        let request = try buildURLRequest(authToken: authToken, body: requestBody)
        
        #if DEBUG
        print("[FlowService] 📤 Making request...")
        #endif
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        print("[FlowService] 📥 Got response, data size: \(data.count) bytes")
        if let str = String(data: data, encoding: .utf8) {
            print("[FlowService] Response preview: \(str.prefix(500))")
        }
        #endif
        
        // Handle response
        try validateResponse(response)
        
        let responseTime = Date().timeIntervalSince(startTime)
        
        #if DEBUG
        print("[FlowService] ✅ Response time: \(responseTime)s")
        #endif
        
        return try parseResponse(data: data, responseTime: responseTime)
    }
    
    // MARK: - Send Message (Streaming)
    
    /// Send a message and stream the response
    func streamMessage(
        userMessage: String,
        conversationHistory: [FlowMessage],
        context: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (FlowResponse) -> Void
    ) async throws {
        guard FlowConfig.isConfigured else {
            throw FlowError.notConfigured
        }
        
        let startTime = Date()
        
        // Get auth token
        let authToken: String
        do {
            authToken = try await SupabaseManager.shared.currentUserToken()
        } catch {
            throw FlowError.authenticationRequired
        }
        
        // Build request with streaming enabled
        let requestBody = buildRequestBody(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            context: context,
            stream: true
        )
        
        var request = try buildURLRequest(authToken: authToken, body: requestBody)
        request.timeoutInterval = FlowConfig.streamTimeout
        
        // Use URLSession for streaming
        let (bytes, urlResponse) = try await URLSession.shared.bytes(for: request)
        
        try validateResponse(urlResponse)
        
        var fullContent = ""
        var actions: [FlowAction] = []
        
        // Process stream
        for try await line in bytes.lines {
            // SSE format: "data: {...}"
            guard line.hasPrefix("data: ") else { continue }
            
            let jsonString = String(line.dropFirst(6))
            
            // Check for [DONE] signal
            if jsonString == "[DONE]" {
                break
            }
            
            // Parse chunk
            if let data = jsonString.data(using: .utf8),
               let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                
                if let content = chunk.content {
                    fullContent += content
                    onChunk(content)
                }
                
                if let chunkActions = chunk.actions {
                    actions = chunkActions
                }
            }
        }
        
        let responseTime = Date().timeIntervalSince(startTime)
        
        let response = FlowResponse(
            content: fullContent,
            actions: actions,
            metadata: ResponseMetadata(
                tokensUsed: nil,
                responseTime: responseTime,
                modelUsed: FlowConfig.modelName
            )
        )
        
        onComplete(response)
    }
    
    // MARK: - Private Methods
    
    private func buildRequestBody(
        userMessage: String,
        conversationHistory: [FlowMessage],
        context: String,
        stream: Bool
    ) -> [String: Any] {
        // Convert conversation history
        let history = conversationHistory
            .filter { $0.sender != .system }
            .suffix(FlowConfig.maxConversationHistory)
            .map { msg -> [String: String] in
                ["sender": msg.sender == .user ? "user" : "assistant", "text": msg.content]
            }
        
        // Trim context if needed
        let safeContext = context.count > FlowConfig.maxContextCharacters
            ? String(context.suffix(FlowConfig.maxContextCharacters))
            : context
        
        return [
            "userMessage": userMessage,
            "conversationHistory": history,
            "context": safeContext,
            "stream": stream
        ]
    }
    
    private func buildURLRequest(authToken: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: FlowConfig.apiURL) else {
            throw FlowError.notConfigured
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Supabase anon key
        if let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = FlowConfig.requestTimeout
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlowError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw FlowError.authenticationRequired
        case 429:
            throw FlowError.rateLimited(retryAfter: FlowConfig.rateLimitCooldown)
        case 500...599:
            throw FlowError.serverError(message: "Server error (\(httpResponse.statusCode))")
        default:
            throw FlowError.serverError(message: "HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func parseResponse(data: Data, responseTime: TimeInterval) throws -> FlowResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FlowError.invalidResponse
        }
        
        // Check for error
        if let error = json["error"] as? String {
            throw FlowError.serverError(message: error)
        }
        
        let content = json["response"] as? String ?? ""
        var actions: [FlowAction] = []
        
        // Parse actions
        if let actionsArray = json["actions"] as? [[String: Any]] {
            for actionDict in actionsArray {
                if let action = parseAction(actionDict) {
                    actions.append(action)
                }
            }
        }
        
        return FlowResponse(
            content: content,
            actions: actions,
            metadata: ResponseMetadata(
                tokensUsed: json["tokensUsed"] as? Int,
                responseTime: responseTime,
                modelUsed: json["model"] as? String ?? FlowConfig.modelName
            )
        )
    }
    
    private func parseAction(_ dict: [String: Any]) -> FlowAction? {
        guard let type = dict["type"] as? String,
              let params = dict["params"] as? [String: Any] else {
            #if DEBUG
            print("[FlowService] Invalid action format: \(dict)")
            #endif
            return nil
        }
        
        do {
            // Convert back to JSON and decode using FlowAction's Codable
            var actionData: [String: Any] = ["type": type]
            for (key, value) in params {
                actionData[key] = value
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: actionData)
            let action = try JSONDecoder().decode(FlowAction.self, from: jsonData)
            return action
        } catch {
            #if DEBUG
            print("[FlowService] Failed to parse action '\(type)': \(error)")
            #endif
            
            // Fallback: parse manually for common actions
            return parseActionManually(type: type, params: params)
        }
    }
    
    /// Manual fallback parser for common actions
    private func parseActionManually(type: String, params: [String: Any]) -> FlowAction? {
        switch type {
        // ═══════════════════════════════════════════════════════════════════
        // TASK ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "create_task":
            guard let title = params["title"] as? String else { return nil }
            let reminderDate = parseDate(params["reminderDate"])
            let duration = (params["durationMinutes"] as? Double).map { $0 * 60 }
            let repeatRule = (params["repeatRule"] as? String).flatMap { FFTaskRepeatRule(rawValue: $0) }
            return .createTask(title: title, reminderDate: reminderDate, duration: duration, repeatRule: repeatRule)
            
        case "update_task":
            // Try by UUID first, then by title
            var taskID: UUID?
            if let taskIDString = params["taskID"] as? String {
                taskID = UUID(uuidString: taskIDString)
            }
            if taskID == nil, let taskTitle = params["taskTitle"] as? String {
                taskID = TasksStore.shared.tasks.first(where: { $0.title.lowercased().contains(taskTitle.lowercased()) })?.id
            }
            guard let finalTaskID = taskID else { return nil }
            let title = params["title"] as? String
            let reminderDate = parseDate(params["reminderDate"])
            let duration = (params["durationMinutes"] as? Double).map { $0 * 60 }
            return .updateTask(taskID: finalTaskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case "delete_task":
            // Try by UUID first, then by title
            var taskID: UUID?
            if let taskIDString = params["taskID"] as? String {
                taskID = UUID(uuidString: taskIDString)
            }
            if taskID == nil, let taskTitle = params["taskTitle"] as? String {
                taskID = TasksStore.shared.tasks.first(where: { $0.title.lowercased().contains(taskTitle.lowercased()) })?.id
            }
            guard let finalTaskID = taskID else { return nil }
            return .deleteTask(taskID: finalTaskID)
            
        case "toggle_task_completion":
            // Try by UUID first, then by title
            var taskID: UUID?
            if let taskIDString = params["taskID"] as? String {
                taskID = UUID(uuidString: taskIDString)
            }
            if taskID == nil, let taskTitle = params["taskTitle"] as? String {
                taskID = TasksStore.shared.tasks.first(where: { $0.title.lowercased().contains(taskTitle.lowercased()) })?.id
            }
            guard let finalTaskID = taskID else { return nil }
            return .toggleTaskCompletion(taskID: finalTaskID)
            
        case "list_future_tasks":
            return .listFutureTasks
            
        case "list_tasks":
            guard let periodString = params["period"] as? String,
                  let period = TaskPeriod(rawValue: periodString) else { return nil }
            return .listTasks(period: period)
            
        // ═══════════════════════════════════════════════════════════════════
        // PRESET ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "set_preset":
            guard let presetIDString = params["presetID"] as? String,
                  let presetID = UUID(uuidString: presetIDString) else { return nil }
            return .setPreset(presetID: presetID)
            
        case "create_preset":
            guard let name = params["name"] as? String,
                  let durationSeconds = params["durationSeconds"] as? Int else { return nil }
            let soundID = params["soundID"] as? String
            return .createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case "update_preset":
            // Try by UUID first, then by name (with fuzzy matching)
            var presetID: UUID?
            if let presetIDString = params["presetID"] as? String {
                presetID = UUID(uuidString: presetIDString)
            }
            if presetID == nil, let presetName = params["presetName"] as? String {
                let searchTerm = presetName.lowercased()
                // Exact match first
                presetID = FocusPresetStore.shared.presets.first(where: { $0.name.lowercased() == searchTerm })?.id
                // Contains match (handles emoji suffixes)
                if presetID == nil {
                    presetID = FocusPresetStore.shared.presets.first(where: { 
                        $0.name.lowercased().contains(searchTerm) || searchTerm.contains($0.name.lowercased())
                    })?.id
                }
            }
            guard let finalPresetID = presetID else { return nil }
            let newName = params["newName"] as? String ?? params["name"] as? String
            let durationSeconds = params["durationSeconds"] as? Int
            return .updatePreset(presetID: finalPresetID, name: newName, durationSeconds: durationSeconds)
            
        case "delete_preset":
            // Try by UUID first, then by name (with fuzzy matching)
            var presetID: UUID?
            if let presetIDString = params["presetID"] as? String {
                presetID = UUID(uuidString: presetIDString)
            }
            if presetID == nil, let presetName = params["presetName"] as? String {
                let searchTerm = presetName.lowercased()
                // Exact match first
                presetID = FocusPresetStore.shared.presets.first(where: { $0.name.lowercased() == searchTerm })?.id
                // Contains match (handles emoji suffixes)
                if presetID == nil {
                    presetID = FocusPresetStore.shared.presets.first(where: { 
                        $0.name.lowercased().contains(searchTerm) || searchTerm.contains($0.name.lowercased())
                    })?.id
                }
            }
            guard let finalPresetID = presetID else { return nil }
            return .deletePreset(presetID: finalPresetID)
            
        // ═══════════════════════════════════════════════════════════════════
        // FOCUS ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "start_focus":
            guard let minutes = params["minutes"] as? Int else { return nil }
            // Try by UUID first, then by name
            var presetID: UUID?
            if let presetIDString = params["presetID"] as? String {
                presetID = UUID(uuidString: presetIDString)
                #if DEBUG
                print("[FlowService] start_focus - presetID from string: \(presetID?.uuidString ?? "nil")")
                #endif
            }
            if presetID == nil, let presetName = params["presetName"] as? String {
                #if DEBUG
                print("[FlowService] start_focus - looking up presetName: '\(presetName)'")
                print("[FlowService] Available presets: \(FocusPresetStore.shared.presets.map { $0.name })")
                #endif
                // Smart matching: try exact match first, then contains, then starts-with
                let searchTerm = presetName.lowercased()
                presetID = FocusPresetStore.shared.presets.first(where: { 
                    $0.name.lowercased() == searchTerm 
                })?.id
                // If no exact match, try if preset name contains the search term (handles emoji suffixes)
                if presetID == nil {
                    presetID = FocusPresetStore.shared.presets.first(where: { 
                        $0.name.lowercased().contains(searchTerm) || searchTerm.contains($0.name.lowercased())
                    })?.id
                }
                // If still no match, try starts-with
                if presetID == nil {
                    presetID = FocusPresetStore.shared.presets.first(where: { 
                        $0.name.lowercased().hasPrefix(searchTerm) || searchTerm.hasPrefix($0.name.lowercased())
                    })?.id
                }
                #if DEBUG
                print("[FlowService] start_focus - found presetID: \(presetID?.uuidString ?? "nil")")
                #endif
            }
            let sessionName = params["sessionName"] as? String
            #if DEBUG
            print("[FlowService] start_focus - final presetID: \(presetID?.uuidString ?? "nil"), minutes: \(minutes)")
            #endif
            return .startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
        case "pause_focus":
            return .pauseFocus
            
        case "resume_focus":
            return .resumeFocus
            
        case "end_focus", "end_focus_early":
            return .endFocusEarly
            
        case "extend_focus":
            guard let minutes = params["minutes"] as? Int else { return nil }
            return .extendFocus(additionalMinutes: minutes)
            
        case "set_focus_intention":
            guard let text = params["text"] as? String else { return nil }
            return .setFocusIntention(text: text)
            
        case "start_focus_on_task":
            guard let taskIDString = params["taskID"] as? String,
                  let taskID = UUID(uuidString: taskIDString) else { return nil }
            let minutes = params["minutes"] as? Int
            return .startFocusOnTask(taskID: taskID, minutes: minutes)
            
        // ═══════════════════════════════════════════════════════════════════
        // NAVIGATION ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "navigate_to_tab":
            guard let tabString = params["tab"] as? String,
                  let tab = AppTabDestination(rawValue: tabString) else { return nil }
            return .navigateToTab(tab: tab)
            
        case "navigate":
            guard let destination = params["destination"] as? String else { return nil }
            switch destination {
            case "focus": return .navigateToTab(tab: .focus)
            case "tasks": return .navigateToTab(tab: .tasks)
            case "progress": return .navigateToTab(tab: .progress)
            case "profile": return .navigateToTab(tab: .profile)
            case "flow": return .navigateToTab(tab: .flow)
            case "settings": return .openSettings
            case "presets": return .openPresetManager
            case "notifications": return .openNotificationCenter
            case "journey": return .navigateToTab(tab: .progress) // Journey is part of progress
            default: return nil
            }
            
        case "open_settings":
            return .openSettings
            
        case "open_preset_manager":
            return .openPresetManager
            
        case "open_notification_center":
            return .openNotificationCenter
            
        case "show_paywall":
            let contextString = params["context"] as? String ?? "general"
            let context = PaywallTrigger(rawValue: contextString) ?? .general
            return .showPaywall(context: context)
            
        case "go_back":
            return .goBack
            
        // ═══════════════════════════════════════════════════════════════════
        // SETTINGS ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "update_setting":
            guard let settingString = params["setting"] as? String,
                  let setting = SettingKey(rawValue: settingString),
                  let value = params["value"] as? String else { return nil }
            return .updateSetting(setting: setting, value: value)
            
        case "toggle_do_not_disturb":
            let enabled = params["enabled"] as? Bool ?? true
            return .toggleDoNotDisturb(enabled: enabled)
            
        case "update_daily_goal":
            guard let minutes = params["minutes"] as? Int else { return nil }
            return .updateDailyGoal(minutes: minutes)
            
        case "change_theme":
            guard let themeName = params["themeName"] as? String else { return nil }
            return .changeTheme(themeName: themeName)
            
        // ═══════════════════════════════════════════════════════════════════
        // STATS & ANALYTICS ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "get_stats":
            guard let periodString = params["period"] as? String,
                  let period = StatsPeriod(rawValue: periodString) else { return nil }
            return .getStats(period: period)
            
        case "analyze_sessions":
            return .analyzeSessions
            
        case "compare_weeks":
            return .compareWeeks
            
        case "generate_weekly_report":
            return .generateWeeklyReport
            
        case "identify_patterns":
            return .identifyPatterns
            
        // ═══════════════════════════════════════════════════════════════════
        // SMART/AI ACTIONS
        // ═══════════════════════════════════════════════════════════════════
        case "generate_daily_plan":
            return .generateDailyPlan
            
        case "suggest_optimal_focus_time":
            return .suggestOptimalFocusTime
            
        case "suggest_break":
            return .suggestBreak
            
        case "motivate":
            return .motivate
            
        case "show_welcome":
            return .showWelcome
            
        case "celebrate_achievement":
            let typeString = params["type"] as? String ?? "dailyGoal"
            let type = AchievementType(rawValue: typeString) ?? .dailyGoal
            return .celebrateAchievement(type: type)
            
        case "provide_tip":
            return .provideTip
            
        default:
            #if DEBUG
            print("[FlowService] Unknown action type: \(type)")
            #endif
            return nil
        }
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try simple format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return simpleFormatter.date(from: dateString)
    }
}

// MARK: - Stream Chunk

private struct StreamChunk: Decodable {
    let content: String?
    let actions: [FlowAction]?
    let done: Bool?
}
