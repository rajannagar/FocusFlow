import Foundation
import SwiftUI

/// Handles AI-initiated actions
@MainActor
final class AIActionHandler {
    static let shared = AIActionHandler()
    
    private init() {}
    
    /// Execute an AI action
    func execute(_ action: AIAction) async throws {
        switch action {
        case .createTask(let title, let reminderDate, let duration):
            try createTask(title: title, reminderDate: reminderDate, duration: duration)
            
        case .updateTask(let taskID, let title, let reminderDate, let duration):
            try updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
            
        case .deleteTask(let taskID):
            try deleteTask(taskID: taskID)
            
        case .listFutureTasks:
            // Invalidate cache to ensure we get fresh task data
            AIContextBuilder.shared.invalidateCache()
            // The actual task listing is handled in AIService.formatFutureTasksResponse()
            break
            
        case .setPreset(let presetID):
            setPreset(presetID: presetID)
            
        case .createPreset(let name, let durationSeconds, let soundID):
            try createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case .updatePreset(let presetID, let name, let durationSeconds):
            try updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case .deletePreset(let presetID):
            try deletePreset(presetID: presetID)
            
        case .updateSetting(let setting, let value):
            try updateSetting(setting: setting, value: value)
            
        case .getStats(let period):
            // Stats are generated in the AI response based on context
            break
            
        case .analyzeSessions:
            // Analysis is handled in the AI response, no action needed
            break
        }
    }
    
    private func createTask(title: String, reminderDate: Date?, duration: TimeInterval?) throws {
        guard !title.isEmpty else {
            throw AIActionError.invalidTaskTitle
        }
        
        // Validate reminder date - if it's in the past, set it to today at the same time
        var validReminderDate = reminderDate
        if let reminder = reminderDate, reminder < Date() {
            // If reminder is in the past, move it to today at the same time
            let calendar = Calendar.autoupdatingCurrent
            let now = Date()
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder)
            if let hour = reminderComponents.hour, let minute = reminderComponents.minute {
                validReminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
                #if DEBUG
                print("[AIActionHandler] ⚠️ Reminder date was in the past, adjusted to today: \(validReminderDate?.description ?? "none")")
                #endif
            } else {
                // If we can't extract time, just use today
                validReminderDate = calendar.startOfDay(for: now)
            }
        }
        
        #if DEBUG
        print("[AIActionHandler] Creating task: '\(title)'")
        print("[AIActionHandler] Reminder date: \(validReminderDate?.description ?? "none")")
        print("[AIActionHandler] Duration: \(duration != nil ? "\(Int(duration! / 60)) minutes" : "none")")
        #endif
        
        // Create task using TasksStore
        let task = FFTaskItem(
            id: UUID(),
            title: title,
            reminderDate: validReminderDate,
            durationMinutes: duration != nil ? Int(duration! / 60) : 0,
            createdAt: Date()
        )
        
        TasksStore.shared.upsert(task)
        
        // Invalidate context cache so AI sees the new task
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        print("[AIActionHandler] ✅ Task created successfully: \(task.id) - '\(title)'")
        #endif
    }
    
    private func updateTask(taskID: UUID, title: String?, reminderDate: Date?, duration: TimeInterval?) throws {
        guard let task = TasksStore.shared.tasks.first(where: { $0.id == taskID }) else {
            throw AIActionError.taskNotFound
        }
        
        var updatedTask = task
        if let title = title {
            updatedTask.title = title
        }
        if let reminderDate = reminderDate {
            updatedTask.reminderDate = reminderDate
        }
        if let duration = duration {
            updatedTask.durationMinutes = Int(duration / 60)
        }
        
        TasksStore.shared.upsert(updatedTask)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
    
    private func deleteTask(taskID: UUID) throws {
        TasksStore.shared.delete(taskID: taskID)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
    
    private func setPreset(presetID: UUID) {
        // Set the preset as active
        FocusPresetStore.shared.activePresetID = presetID
        
        // Notify FocusView to apply the preset (reuse same notification as widget)
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.applyPresetFromWidget"),
            object: nil,
            userInfo: ["presetID": presetID, "autoStart": false]
        )
    }
    
    private func createPreset(name: String, durationSeconds: Int, soundID: String) throws {
        let preset = FocusPreset(
            name: name,
            durationSeconds: durationSeconds,
            soundID: soundID,
            isSystemDefault: false
        )
        FocusPresetStore.shared.upsert(preset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
    
    private func updatePreset(presetID: UUID, name: String?, durationSeconds: Int?) throws {
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw AIActionError.presetNotFound
        }
        
        var updatedPreset = preset
        if let name = name {
            updatedPreset.name = name
        }
        if let durationSeconds = durationSeconds {
            updatedPreset.durationSeconds = durationSeconds
        }
        
        FocusPresetStore.shared.upsert(updatedPreset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
    
    private func deletePreset(presetID: UUID) throws {
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            throw AIActionError.presetNotFound
        }
        FocusPresetStore.shared.delete(preset)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
    
    private func updateSetting(setting: String, value: String) throws {
        let appSettings = AppSettings.shared
        
        switch setting {
        case "dailyGoal":
            guard let minutes = Int(value) else {
                throw AIActionError.invalidSettingValue
            }
            ProgressStore.shared.dailyGoalMinutes = minutes
            
        case "theme":
            guard let theme = AppTheme(rawValue: value.lowercased()) else {
                throw AIActionError.invalidSettingValue
            }
            appSettings.profileTheme = theme
            
        case "soundEnabled":
            let enabled = value.lowercased() == "true" || value == "1"
            appSettings.soundEnabled = enabled
            
        case "hapticsEnabled":
            let enabled = value.lowercased() == "true" || value == "1"
            appSettings.hapticsEnabled = enabled
            
        default:
            throw AIActionError.unknownSetting
        }
    }
}

enum AIActionError: LocalizedError {
    case invalidTaskTitle
    case taskNotFound
    case presetNotFound
    case invalidSettingValue
    case unknownSetting
    
    var errorDescription: String? {
        switch self {
        case .invalidTaskTitle:
            return "Task title cannot be empty"
        case .taskNotFound:
            return "Task not found"
        case .presetNotFound:
            return "Preset not found"
        case .invalidSettingValue:
            return "Invalid setting value"
        case .unknownSetting:
            return "Unknown setting"
        }
    }
}

