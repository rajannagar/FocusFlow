import Foundation

/// OpenAI API client with comprehensive function calling
@MainActor
final class AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Build all available functions for OpenAI function calling
    private func buildFunctions() -> [[String: Any]] {
        return [
            // ═══════════════════════════════════════════════════════════════
            // TASK FUNCTIONS
            // ═══════════════════════════════════════════════════════════════
            [
                "name": "create_task",
                "description": "Create a new task. Use when user asks to create, add, make, or schedule a task. ALWAYS include reminderDate if user mentions ANY time (7pm, tomorrow, etc). Be proactive - if user says 'I need to study' or 'remind me to call mom', create a task.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "Task title/name. Be concise but clear."
                        ],
                        "reminderDate": [
                            "type": "string",
                            "description": "REQUIRED if user mentions ANY time. Format: YYYY-MM-DDTHH:MM:SS (local time). Examples: '7pm' = 'YYYY-MM-DDT19:00:00', 'tomorrow 2pm' = 'YYYY-MM-DDT14:00:00'. Use TODAY's date for 'today/tonight/this evening'. Use TOMORROW's date for 'tomorrow'."
                        ],
                        "durationMinutes": [
                            "type": "integer",
                            "description": "Estimated duration in minutes. Only include if user specifies duration."
                        ]
                    ],
                    "required": ["title"]
                ]
            ],
            [
                "name": "update_task",
                "description": "Update an existing task. Use task ID from context. Only include fields user wants to change.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "taskID": ["type": "string", "description": "UUID of task from context"],
                        "title": ["type": "string", "description": "New title (only if changing)"],
                        "reminderDate": ["type": "string", "description": "New reminder in YYYY-MM-DDTHH:MM:SS format"],
                        "durationMinutes": ["type": "integer", "description": "New duration in minutes"]
                    ],
                    "required": ["taskID"]
                ]
            ],
            [
                "name": "delete_task",
                "description": "Delete a task. Use when user asks to delete, remove, or cancel a task.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "taskID": ["type": "string", "description": "UUID of task to delete from context"]
                    ],
                    "required": ["taskID"]
                ]
            ],
            [
                "name": "toggle_task_completion",
                "description": "Mark a task as complete or incomplete. Use when user says 'done', 'complete', 'finished', 'mark as done', etc.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "taskID": ["type": "string", "description": "UUID of task to toggle"]
                    ],
                    "required": ["taskID"]
                ]
            ],
            [
                "name": "list_future_tasks",
                "description": "List upcoming tasks. Use when user asks 'what tasks do I have?', 'show my tasks', 'upcoming tasks'.",
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ],
            
            // ═══════════════════════════════════════════════════════════════
            // PRESET FUNCTIONS
            // ═══════════════════════════════════════════════════════════════
            [
                "name": "set_preset",
                "description": "Set/activate a focus preset. Use when user asks to 'use', 'set', 'switch to', or 'activate' a preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of preset from context"]
                    ],
                    "required": ["presetID"]
                ]
            ],
            [
                "name": "create_preset",
                "description": "Create a new focus preset. Use when user asks to create or add a preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string", "description": "Preset name"],
                        "durationSeconds": ["type": "integer", "description": "Duration in SECONDS (e.g., 25 min = 1500, 50 min = 3000)"],
                        "soundID": ["type": "string", "description": "Sound ID: angelsbymyside, fireplace, floatinggarden, hearty, light-rain-ambient, longnight, sound-ambience, underwater, yesterday, or 'none'"]
                    ],
                    "required": ["name", "durationSeconds"]
                ]
            ],
            [
                "name": "update_preset",
                "description": "Update an existing preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of preset from context"],
                        "name": ["type": "string", "description": "New name (only if changing)"],
                        "durationSeconds": ["type": "integer", "description": "New duration in SECONDS"]
                    ],
                    "required": ["presetID"]
                ]
            ],
            [
                "name": "delete_preset",
                "description": "Delete a preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of preset to delete"]
                    ],
                    "required": ["presetID"]
                ]
            ],
            
            // ═══════════════════════════════════════════════════════════════
            // FOCUS FUNCTIONS
            // ═══════════════════════════════════════════════════════════════
            [
                "name": "start_focus",
                "description": "Start a focus session. Use when user says 'start focus', 'let's focus', 'begin session', 'start timer', 'focus for X minutes'.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "minutes": [
                            "type": "integer",
                            "description": "Focus duration in minutes (1-480). Default to 25 if not specified."
                        ],
                        "presetID": [
                            "type": "string",
                            "description": "Optional preset ID to use"
                        ],
                        "sessionName": [
                            "type": "string",
                            "description": "Optional name for the session (e.g., 'Deep work on project')"
                        ]
                    ],
                    "required": ["minutes"]
                ]
            ],
            
            // ═══════════════════════════════════════════════════════════════
            // SETTINGS FUNCTIONS
            // ═══════════════════════════════════════════════════════════════
            [
                "name": "update_setting",
                "description": "Update app settings. Use when user asks to change goal, theme, sounds, haptics, name, etc.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "setting": [
                            "type": "string",
                            "description": "Setting name: 'dailyGoal' (minutes), 'theme' (forest/neon/peach/cyber/ocean/sunrise/amber/mint/royal/slate), 'soundEnabled' (true/false), 'hapticsEnabled' (true/false), 'focusSound' (sound ID or 'none'), 'displayName', 'tagline'"
                        ],
                        "value": [
                            "type": "string",
                            "description": "New value for the setting"
                        ]
                    ],
                    "required": ["setting", "value"]
                ]
            ],
            
            // ═══════════════════════════════════════════════════════════════
            // STATS FUNCTIONS
            // ═══════════════════════════════════════════════════════════════
            [
                "name": "get_stats",
                "description": "Get productivity statistics. Use when user asks for stats, progress, summary, overview, 'how am I doing?', 'my progress'.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "period": [
                            "type": "string",
                            "description": "Time period: 'today', 'week', 'month', 'alltime'"
                        ]
                    ],
                    "required": ["period"]
                ]
            ],
            [
                "name": "analyze_sessions",
                "description": "Provide productivity analysis and insights. Use when user asks 'analyze my productivity', 'give me insights', 'how can I improve?'.",
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ]
        ]
    }
    
    /// Send a message to the AI and get a response
    func sendMessage(
        userMessage: String,
        conversationHistory: [AIMessage],
        context: String
    ) async throws -> (response: String, action: AIAction?) {
        // Get auth token from Supabase
        guard let authToken = try? await SupabaseManager.shared.currentUserToken() else {
            throw AIServiceError.unauthorized
        }
        
        // Build conversation history for backend
        let historyArray = conversationHistory.map { msg in
            [
                "sender": msg.sender == .user ? "user" : "assistant",
                "text": msg.text
            ]
        }
        
        // Prepare backend request
        let requestBody: [String: Any] = [
            "userMessage": userMessage,
            "conversationHistory": historyArray,
            "context": context
        ]
        
        // Call backend function (Supabase Edge Function)
        guard let url = URL(string: "https://grcelvuzlayxrrokojpg.supabase.co/functions/v1/ai-chat") else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request to backend
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse backend response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.invalidResponseFormat
        }
        
        // Extract response text and action from backend
        let responseText = json["response"] as? String ?? ""
        let action: AIAction? = nil
        
        // Check if there's an action to execute
        if let actionData = json["action"] as? [String: Any],
           let actionType = actionData["type"] as? String,
           let params = actionData["params"] as? [String: Any] {
            
            #if DEBUG
            print("[AIService] Action from backend: \(actionType)")
            print("[AIService] Parameters: \(params)")
            #endif
            
            // Handle the action based on type
            let (parsedAction, actionResponse) = handleFunctionCall(name: actionType, arguments: params)
            
            if let parsedAction = parsedAction {
                return (actionResponse, parsedAction)
            }
        }
        
        // Return text response
        return (responseText.trimmingCharacters(in: .whitespacesAndNewlines), nil)
    }
    
    // MARK: - Function Call Handler
    
    private func handleFunctionCall(name: String, arguments: [String: Any]) -> (AIAction?, String) {
        switch name {
        // ═══════════════════════════════════════════════════════════════
        // TASK HANDLERS
        // ═══════════════════════════════════════════════════════════════
        case "create_task":
            if let action = parseCreateTaskAction(from: arguments) {
                let title = arguments["title"] as? String ?? "task"
                var response = "✓ Created task: \"\(title)\""
                
                if let reminderStr = arguments["reminderDate"] as? String,
                   let date = parseDate(from: reminderStr) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    response += " with reminder at \(formatter.string(from: date))"
                }
                
                if let duration = arguments["durationMinutes"] as? Int, duration > 0 {
                    response += " (\(duration) min)"
                }
                
                return (action, response)
            }
            return (nil, "I couldn't create that task. Please try again with a title.")
            
        case "update_task":
            if let action = parseUpdateTaskAction(from: arguments) {
                return (action, "✓ Task updated successfully.")
            }
            return (nil, "I couldn't find that task to update.")
            
        case "delete_task":
            if let action = parseDeleteTaskAction(from: arguments) {
                return (action, "✓ Task deleted.")
            }
            return (nil, "I couldn't find that task to delete.")
            
        case "toggle_task_completion":
            if let action = parseToggleTaskAction(from: arguments) {
                return (action, "✓ Task completion toggled.")
            }
            return (nil, "I couldn't find that task.")
            
        case "list_future_tasks":
            return (.listFutureTasks, "Here are your upcoming tasks:")
            
        // ═══════════════════════════════════════════════════════════════
        // PRESET HANDLERS
        // ═══════════════════════════════════════════════════════════════
        case "set_preset":
            if let action = parseSetPresetAction(from: arguments) {
                // Find preset name for response
                if let presetIDStr = arguments["presetID"] as? String,
                   let presetID = UUID(uuidString: presetIDStr),
                   let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) {
                    return (action, "✓ Preset '\(preset.name)' activated. Ready to focus!")
                }
                return (action, "✓ Preset activated.")
            }
            return (nil, "I couldn't find that preset. Check the available presets above.")
            
        case "create_preset":
            if let action = parseCreatePresetAction(from: arguments) {
                let name = arguments["name"] as? String ?? "preset"
                let minutes = (arguments["durationSeconds"] as? Int ?? 1500) / 60
                return (action, "✓ Created preset '\(name)' (\(minutes) min)")
            }
            return (nil, "I couldn't create that preset. Please specify a name and duration.")
            
        case "update_preset":
            if let action = parseUpdatePresetAction(from: arguments) {
                return (action, "✓ Preset updated.")
            }
            return (nil, "I couldn't find that preset to update.")
            
        case "delete_preset":
            if let action = parseDeletePresetAction(from: arguments) {
                return (action, "✓ Preset deleted.")
            }
            return (nil, "I couldn't find that preset to delete.")
            
        // ═══════════════════════════════════════════════════════════════
        // FOCUS HANDLERS
        // ═══════════════════════════════════════════════════════════════
        case "start_focus":
            if let action = parseStartFocusAction(from: arguments) {
                let minutes = arguments["minutes"] as? Int ?? 25
                var response = "🎯 Starting \(minutes)-minute focus session"
                if let name = arguments["sessionName"] as? String, !name.isEmpty {
                    response += ": \"\(name)\""
                }
                response += ". Let's go!"
                return (action, response)
            }
            return (nil, "I couldn't start the focus session. Please specify duration.")
            
        // ═══════════════════════════════════════════════════════════════
        // SETTINGS HANDLERS
        // ═══════════════════════════════════════════════════════════════
        case "update_setting":
            if let action = parseUpdateSettingAction(from: arguments) {
                let setting = arguments["setting"] as? String ?? ""
                let value = arguments["value"] as? String ?? ""
                
                switch setting.lowercased() {
                case "dailygoal", "daily_goal", "goal":
                    return (action, "✓ Daily goal set to \(value) minutes.")
                case "theme":
                    return (action, "✓ Theme changed to \(value). Looks great!")
                case "soundenabled", "sound":
                    let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
                    return (action, "✓ Sound \(enabled ? "enabled" : "disabled").")
                case "hapticsenabled", "haptics":
                    let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
                    return (action, "✓ Haptics \(enabled ? "enabled" : "disabled").")
                case "focussound", "focus_sound":
                    return (action, "✓ Focus sound set to \(value).")
                case "displayname", "name":
                    return (action, "✓ Name changed to \(value).")
                default:
                    return (action, "✓ Setting updated.")
                }
            }
            return (nil, "I couldn't update that setting. Check the available options.")
            
        // ═══════════════════════════════════════════════════════════════
        // STATS HANDLERS
        // ═══════════════════════════════════════════════════════════════
        case "get_stats":
            if let action = parseGetStatsAction(from: arguments) {
                let period = arguments["period"] as? String ?? "today"
                return (action, "Here's your \(period) summary:")
            }
            return (.getStats(period: "today"), "Here's your summary:")
            
        case "analyze_sessions":
            return (.analyzeSessions, "Let me analyze your productivity patterns...")
            
        default:
            return (nil, "I'll help you with that.")
        }
    }
    
    // MARK: - Action Parsers
    
    /// Parse create_task function call arguments into AIAction
    private func parseCreateTaskAction(from arguments: [String: Any]) -> AIAction? {
        guard let title = arguments["title"] as? String, !title.isEmpty else {
            print("[AIService] Failed to parse task: missing title")
            return nil
        }
        
        var reminderDate: Date? = nil
        if let reminderString = arguments["reminderDate"] as? String {
            reminderDate = parseDate(from: reminderString)
            #if DEBUG
            if reminderDate != nil {
                print("[AIService] Parsed reminder date: \(reminderDate!)")
            } else {
                print("[AIService] Failed to parse reminder date: \(reminderString)")
            }
            #endif
        }
        
        var duration: TimeInterval? = nil
        if let durationMinutes = arguments["durationMinutes"] as? Int, durationMinutes > 0 {
            duration = TimeInterval(durationMinutes * 60)
        }
        
        return .createTask(title: title, reminderDate: reminderDate, duration: duration)
    }
    
    private func parseUpdateTaskAction(from arguments: [String: Any]) -> AIAction? {
        guard let taskIDString = arguments["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else {
            return nil
        }
        
        let title = arguments["title"] as? String
        var reminderDate: Date? = nil
        if let reminderString = arguments["reminderDate"] as? String {
            reminderDate = parseDate(from: reminderString)
        }
        var duration: TimeInterval? = nil
        if let durationMinutes = arguments["durationMinutes"] as? Int, durationMinutes > 0 {
            duration = TimeInterval(durationMinutes * 60)
        }
        
        return .updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
    }
    
    private func parseDeleteTaskAction(from arguments: [String: Any]) -> AIAction? {
        guard let taskIDString = arguments["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else {
            return nil
        }
        return .deleteTask(taskID: taskID)
    }
    
    private func parseToggleTaskAction(from arguments: [String: Any]) -> AIAction? {
        guard let taskIDString = arguments["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else {
            return nil
        }
        return .toggleTaskCompletion(taskID: taskID)
    }
    
    private func parseSetPresetAction(from arguments: [String: Any]) -> AIAction? {
        guard let presetIDString = arguments["presetID"] as? String,
              let presetID = UUID(uuidString: presetIDString) else {
            return nil
        }
        return .setPreset(presetID: presetID)
    }
    
    private func parseCreatePresetAction(from arguments: [String: Any]) -> AIAction? {
        guard let name = arguments["name"] as? String,
              let durationSeconds = arguments["durationSeconds"] as? Int else {
            return nil
        }
        let soundID = arguments["soundID"] as? String ?? "none"
        return .createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
    }
    
    private func parseUpdatePresetAction(from arguments: [String: Any]) -> AIAction? {
        guard let presetIDString = arguments["presetID"] as? String,
              let presetID = UUID(uuidString: presetIDString) else {
            return nil
        }
        let name = arguments["name"] as? String
        let durationSeconds = arguments["durationSeconds"] as? Int
        return .updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
    }
    
    private func parseDeletePresetAction(from arguments: [String: Any]) -> AIAction? {
        guard let presetIDString = arguments["presetID"] as? String,
              let presetID = UUID(uuidString: presetIDString) else {
            return nil
        }
        return .deletePreset(presetID: presetID)
    }
    
    private func parseStartFocusAction(from arguments: [String: Any]) -> AIAction? {
        guard let minutes = arguments["minutes"] as? Int, minutes > 0 else {
            return nil
        }
        
        var presetID: UUID? = nil
        if let presetIDString = arguments["presetID"] as? String {
            presetID = UUID(uuidString: presetIDString)
        }
        
        let sessionName = arguments["sessionName"] as? String
        
        return .startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
    }
    
    private func parseUpdateSettingAction(from arguments: [String: Any]) -> AIAction? {
        guard let setting = arguments["setting"] as? String,
              let value = arguments["value"] as? String else {
            return nil
        }
        return .updateSetting(setting: setting, value: value)
    }
    
    private func parseGetStatsAction(from arguments: [String: Any]) -> AIAction? {
        guard let period = arguments["period"] as? String else {
            return nil
        }
        return .getStats(period: period)
    }
    
    // MARK: - Date Parsing
    
    private func parseDate(from dateString: String) -> Date? {
        // Try ISO8601 with timezone first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: dateString)
        
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }
        
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            date = isoFormatter.date(from: dateString)
        }
        
        // Try local time format (YYYY-MM-DDTHH:MM:SS without timezone)
        if date == nil {
            let localFormatter = DateFormatter()
            localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            localFormatter.timeZone = TimeZone.current
            localFormatter.locale = Locale(identifier: "en_US_POSIX")
            date = localFormatter.date(from: dateString)
        }
        
        // Try simpler formats
        if date == nil {
            let simpleFormatter = DateFormatter()
            simpleFormatter.timeZone = TimeZone.current
            simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            let formats = [
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd"
            ]
            
            for format in formats {
                simpleFormatter.dateFormat = format
                if let parsed = simpleFormatter.date(from: dateString) {
                    date = parsed
                    break
                }
            }
        }
        
        return date
    }
}

enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case unauthorized
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "API key is not configured."
        case .unauthorized:
            return "Unauthorized. Please ensure you're logged in."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidResponseFormat:
            return "Response format is invalid"
        case .apiError(let statusCode, let message):
            // Provide user-friendly error messages
            if message.contains("model_not_found") || message.contains("does not have access to model") {
                return "The AI model is not available. Please contact support."
            }
            if statusCode == 403 {
                return "Access denied. Please check your permissions."
            }
            if statusCode == 429 {
                return "Rate limit exceeded. Please try again in a moment."
            }
            if statusCode == 401 {
                return "Invalid API key. Please check your OPENAI_API_KEY environment variable."
            }
            return "API error (\(statusCode)). Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

