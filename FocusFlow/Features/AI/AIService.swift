import Foundation

/// OpenAI API client with context
@MainActor
final class AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Build all available functions for OpenAI
    private func buildFunctions() -> [[String: Any]] {
        return [
            // Task functions
            [
                "name": "create_task",
                "description": "Create a new task. Use when user asks to create, add, or make a task. ALWAYS include reminderDate if user mentions ANY time (e.g., '7pm', '7 PM', 'tonight at 7', 'at 7pm', '7:00 PM', etc.).",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": ["type": "string", "description": "Task title/name"],
                        "reminderDate": ["type": "string", "description": "ISO 8601 date string with timezone (e.g., '2026-01-05T19:00:00Z' for 7pm today). REQUIRED if user mentions ANY time (7pm, 7 PM, 7:00 PM, tonight at 7, at 7pm, etc.). Use TODAY's date if user says 'today', 'tonight', 'this evening'. Use TOMORROW's date if user says 'tomorrow'. Format: YYYY-MM-DDTHH:MM:SSZ where HH is 24-hour format (19 = 7pm, 14 = 2pm)."],
                        "durationMinutes": ["type": "integer", "description": "Duration in minutes. Only include if user explicitly specified a duration for the task."]
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
                        "taskID": ["type": "string", "description": "UUID of the task to update (from context)"],
                        "title": ["type": "string", "description": "New title (only if user wants to change it)"],
                        "reminderDate": ["type": "string", "description": "New reminder date in ISO 8601 format (only if changing)"],
                        "durationMinutes": ["type": "integer", "description": "New duration in minutes (only if changing)"]
                    ],
                    "required": ["taskID"]
                ]
            ],
            [
                "name": "delete_task",
                "description": "Delete a task. Use when user asks to delete, remove, or cancel a task. If user says 'delete all [keyword] tasks' or 'delete all tasks with [keyword]', find all matching tasks from context and delete them one by one (you may need to call this function multiple times).",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "taskID": ["type": "string", "description": "UUID of the task to delete (from context). Find the task ID by matching the task title from the context above."]
                    ],
                    "required": ["taskID"]
                ]
            ],
            [
                "name": "list_future_tasks",
                "description": "List all tasks with future reminders. Use when user asks 'what tasks do I have?', 'show my tasks', 'upcoming tasks', etc.",
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ],
            // Preset functions
            [
                "name": "set_preset",
                "description": "Set a preset as active. Use when user asks to use, set, or switch to a preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of the preset (from context)"]
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
                        "durationSeconds": ["type": "integer", "description": "Duration in seconds"],
                        "soundID": ["type": "string", "description": "Sound ID (default: 'none' if not specified)"]
                    ],
                    "required": ["name", "durationSeconds"]
                ]
            ],
            [
                "name": "update_preset",
                "description": "Update an existing preset. Use preset ID from context.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of the preset (from context)"],
                        "name": ["type": "string", "description": "New name (only if changing)"],
                        "durationSeconds": ["type": "integer", "description": "New duration in seconds (only if changing)"]
                    ],
                    "required": ["presetID"]
                ]
            ],
            [
                "name": "delete_preset",
                "description": "Delete a preset. Use when user asks to delete or remove a preset.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "presetID": ["type": "string", "description": "UUID of the preset (from context)"]
                    ],
                    "required": ["presetID"]
                ]
            ],
            // Settings functions
            [
                "name": "update_setting",
                "description": "Update app settings. Use when user asks to change daily goal, theme, sound, haptics, etc.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "setting": ["type": "string", "description": "Setting name: 'dailyGoal' (value in minutes), 'theme' (theme name), 'soundEnabled' ('true'/'false'), 'hapticsEnabled' ('true'/'false')"],
                        "value": ["type": "string", "description": "New value for the setting"]
                    ],
                    "required": ["setting", "value"]
                ]
            ],
            // Stats function
            [
                "name": "get_stats",
                "description": "Get statistics and overview. Use when user asks for stats, overview, summary, or progress for a time period.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "period": ["type": "string", "description": "Time period: 'today', 'week', '7days', 'month', '30days'"]
                    ],
                    "required": ["period"]
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
        guard AIConfig.isConfigured else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        // Build messages array for OpenAI API
        var messages: [[String: Any]] = []
        
        // Add system message with context
        messages.append([
            "role": "system",
            "content": context
        ])
        
        // Add conversation history (limit to maxMessages)
        let recentHistory = conversationHistory.suffix(AIConfig.maxMessages)
        for msg in recentHistory {
            messages.append([
                "role": msg.sender == .user ? "user" : "assistant",
                "content": msg.text
            ])
        }
        
        // Add current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        // Define functions for OpenAI function calling
        let functions: [[String: Any]] = buildFunctions()
        
        // Prepare request
        var requestBody: [String: Any] = [
            "model": AIConfig.model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500,
            "functions": functions,
            "function_call": "auto"
        ]
        
        guard let url = URL(string: AIConfig.apiURL) else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw AIServiceError.invalidResponseFormat
        }
        
        // Check if AI wants to call a function
        if let functionCall = message["function_call"] as? [String: Any],
           let functionName = functionCall["name"] as? String {
            
            // Parse function arguments - can be a string (JSON) or already a dictionary
            var arguments: [String: Any] = [:]
            
            if let argumentsString = functionCall["arguments"] as? String {
                // Arguments are a JSON string - parse them
                if let argumentsData = argumentsString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] {
                    arguments = parsed
                }
            } else if let argumentsDict = functionCall["arguments"] as? [String: Any] {
                // Arguments are already a dictionary
                arguments = argumentsDict
            }
            
            #if DEBUG
            print("[AIService] Function call detected: \(functionName)")
            print("[AIService] Arguments: \(arguments)")
            #endif
            
            // Handle function calls
            let action: AIAction?
            var responseMessage: String
            
            switch functionName {
            case "create_task":
                action = parseCreateTaskAction(from: arguments)
                if let title = arguments["title"] as? String {
                    responseMessage = "I've created the task: \(title)"
                    if let reminderDateStr = arguments["reminderDate"] as? String,
                       let reminderDate = parseDate(from: reminderDateStr) {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .none
                        formatter.timeStyle = .short
                        let timeStr = formatter.string(from: reminderDate)
                        responseMessage += " with a reminder at \(timeStr)"
                    }
                    if let durationMinutes = arguments["durationMinutes"] as? Int, durationMinutes > 0 {
                        responseMessage += " (duration: \(durationMinutes) minutes)"
                    }
                    responseMessage += "."
                } else {
                    responseMessage = "I'll create that task for you."
                }
                
            case "update_task":
                action = parseUpdateTaskAction(from: arguments)
                responseMessage = "I've updated the task."
                
            case "delete_task":
                action = parseDeleteTaskAction(from: arguments)
                responseMessage = "I've deleted the task."
                
            case "list_future_tasks":
                action = .listFutureTasks
                // Actually fetch and format the tasks
                responseMessage = formatFutureTasksResponse()
                
            case "set_preset":
                action = parseSetPresetAction(from: arguments)
                responseMessage = "I've set that preset as active."
                
            case "create_preset":
                action = parseCreatePresetAction(from: arguments)
                if let name = arguments["name"] as? String {
                    responseMessage = "I've created the preset: \(name)"
                } else {
                    responseMessage = "I've created the preset."
                }
                
            case "update_preset":
                action = parseUpdatePresetAction(from: arguments)
                responseMessage = "I've updated the preset."
                
            case "delete_preset":
                action = parseDeletePresetAction(from: arguments)
                responseMessage = "I've deleted the preset."
                
            case "update_setting":
                action = parseUpdateSettingAction(from: arguments)
                responseMessage = "I've updated that setting."
                
            case "get_stats":
                action = parseGetStatsAction(from: arguments)
                responseMessage = "Here are your statistics:"
                
            default:
                action = nil
                responseMessage = "I'll help you with that."
            }
            
            if let action = action {
                return (responseMessage, action)
            }
        }
        
        // Regular text response
        let content = message["content"] as? String ?? ""
        let action = parseAction(from: content)
        
        return (content.trimmingCharacters(in: .whitespacesAndNewlines), action)
    }
    
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
            #if DEBUG
            print("[AIService] Parsed duration: \(durationMinutes) minutes")
            #endif
        }
        
        #if DEBUG
        print("[AIService] Creating task: '\(title)' with reminder: \(reminderDate?.description ?? "none"), duration: \(duration?.description ?? "none")")
        #endif
        
        return .createTask(title: title, reminderDate: reminderDate, duration: duration)
    }
    
    /// Parse action from AI response text (fallback for when function calling isn't used)
    private func parseAction(from response: String) -> AIAction? {
        // This is a fallback parser for when the AI responds with text instead of function calling
        // Try to extract task information from the conversation context
        
        // Look for task creation hints in the response
        let lowercased = response.lowercased()
        if lowercased.contains("create") && (lowercased.contains("task") || lowercased.contains("dinner") || lowercased.contains("meeting")) {
            // Try to extract task title from common patterns
            // This is a simple fallback - function calling is preferred
            return nil
        }
        
        return nil
    }
    
    // MARK: - Action Parsers
    
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
    
    private func parseDate(from dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            date = formatter.date(from: dateString)
        }
        
        return date
    }
    
    /// Formats future tasks into a readable response message
    private func formatFutureTasksResponse() -> String {
        let allTasks = TasksStore.shared.tasks
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        
        // Filter tasks with future reminders
        let futureTasks = allTasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return reminder > now
        }
        
        // Sort by reminder date (earliest first)
        let sortedTasks = futureTasks.sorted { task1, task2 in
            let date1 = task1.reminderDate ?? Date.distantFuture
            let date2 = task2.reminderDate ?? Date.distantFuture
            return date1 < date2
        }
        
        if sortedTasks.isEmpty {
            return "You don't have any upcoming tasks with reminders. All your tasks are either completed or don't have reminder dates set."
        }
        
        var response = "Here are your upcoming tasks:\n\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for (index, task) in sortedTasks.enumerated() {
            response += "\(index + 1). **\(task.title)**"
            
            if let reminder = task.reminderDate {
                let reminderStr = dateFormatter.string(from: reminder)
                response += "\n   📅 \(reminderStr)"
            }
            
            if task.durationMinutes > 0 {
                response += "\n   ⏱️ \(task.durationMinutes) minutes"
            }
            
            if index < sortedTasks.count - 1 {
                response += "\n"
            }
        }
        
        return response
    }
}

enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key is not configured. Please set OPENAI_API_KEY environment variable."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidResponseFormat:
            return "Response format is invalid"
        case .apiError(let statusCode, let message):
            // Provide user-friendly error messages
            if message.contains("model_not_found") || message.contains("does not have access to model") {
                return "The AI model is not available with your API key. Please enable access to the model in your OpenAI account settings (platform.openai.com), or try a different model."
            }
            if statusCode == 403 {
                return "Access denied. Please check your OpenAI API key permissions."
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

