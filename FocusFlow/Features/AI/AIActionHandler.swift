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
            
        case .toggleTaskCompletion(let taskID):
            try toggleTaskCompletion(taskID: taskID)
            
        case .listFutureTasks:
            // This is handled by generating stats in the response
            break
            
        case .setPreset(let presetID):
            try setPreset(presetID: presetID)
            
        case .createPreset(let name, let durationSeconds, let soundID):
            try createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
            
        case .updatePreset(let presetID, let name, let durationSeconds):
            try updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
            
        case .deletePreset(let presetID):
            try deletePreset(presetID: presetID)
            
        case .startFocus(let minutes, let presetID, let sessionName):
            try startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
            
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
    
    // MARK: - Task Actions
    
    private func createTask(title: String, reminderDate: Date?, duration: TimeInterval?) throws {
        // Validation constants
        let maxTitleLength = 200
        let maxDurationMinutes = 480 // 8 hours
        let maxFutureDays = 365 // 1 year
        
        // Validate title
        guard !title.isEmpty else {
            throw AIActionError.invalidTaskTitle
        }
        guard title.count <= maxTitleLength else {
            throw AIActionError.titleTooLong
        }
        
        // Validate duration if provided
        if let duration = duration {
            guard duration > 0 && duration <= TimeInterval(maxDurationMinutes * 60) else {
                throw AIActionError.invalidDuration
            }
        }
        
        // Validate reminder date if provided
        if let reminderDate = reminderDate {
            let maxFutureDate = Calendar.current.date(byAdding: .day, value: maxFutureDays, to: Date()) ?? Date()
            guard reminderDate <= maxFutureDate else {
                throw AIActionError.reminderDateTooFar
            }
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
    
    private func toggleTaskCompletion(taskID: UUID) throws {
        let calendar = Calendar.autoupdatingCurrent
        let today = Date()
        
        TasksStore.shared.toggleCompletion(taskID: taskID, on: today, calendar: calendar)
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
        
        #if DEBUG
        let isNowCompleted = TasksStore.shared.isCompleted(taskId: taskID, on: today, calendar: calendar)
        print("[AIActionHandler] ✅ Task completion toggled: \(taskID) - now \(isNowCompleted ? "complete" : "incomplete")")
        #endif
    }
    
    // MARK: - Preset Actions
    
    private func setPreset(presetID: UUID) throws {
        // Validate preset exists
        guard FocusPresetStore.shared.presets.contains(where: { $0.id == presetID }) else {
            throw AIActionError.presetNotFound
        }
        
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
        // Validation constants
        let maxNameLength = 50
        let minDurationSeconds = 60 // 1 minute
        let maxDurationSeconds = 28800 // 8 hours
        
        // Validate name
        guard !name.isEmpty else {
            throw AIActionError.invalidPresetName
        }
        guard name.count <= maxNameLength else {
            throw AIActionError.presetNameTooLong
        }
        
        // Validate duration
        guard durationSeconds >= minDurationSeconds && durationSeconds <= maxDurationSeconds else {
            throw AIActionError.invalidPresetDuration
        }
        
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
    
    // MARK: - Focus Actions
    
    private func startFocus(minutes: Int, presetID: UUID?, sessionName: String?) throws {
        // Validate duration
        guard minutes >= 1 && minutes <= 480 else {
            throw AIActionError.invalidFocusDuration
        }
        
        // If preset specified, apply it first
        if let presetID = presetID {
            guard FocusPresetStore.shared.presets.contains(where: { $0.id == presetID }) else {
                throw AIActionError.presetNotFound
            }
            FocusPresetStore.shared.activePresetID = presetID
        }
        
        // Send notification to start focus session
        NotificationCenter.default.post(
            name: Notification.Name("FocusFlow.startFocusFromAI"),
            object: nil,
            userInfo: [
                "minutes": minutes,
                "sessionName": sessionName ?? "",
                "presetID": presetID as Any
            ]
        )
        
        #if DEBUG
        print("[AIActionHandler] ✅ Starting focus: \(minutes) min, name: \(sessionName ?? "none"), preset: \(presetID?.uuidString ?? "none")")
        #endif
    }
    
    // MARK: - Settings Actions
    
    private func updateSetting(setting: String, value: String) throws {
        let appSettings = AppSettings.shared
        
        switch setting.lowercased() {
        case "dailygoal", "daily_goal", "goal":
            guard let minutes = Int(value), minutes >= 1 && minutes <= 1440 else {
                throw AIActionError.invalidSettingValue
            }
            ProgressStore.shared.dailyGoalMinutes = minutes
            #if DEBUG
            print("[AIActionHandler] ✅ Daily goal set to \(minutes) minutes")
            #endif
            
        case "theme":
            guard let theme = AppTheme(rawValue: value.lowercased()) else {
                throw AIActionError.invalidTheme
            }
            appSettings.profileTheme = theme
            #if DEBUG
            print("[AIActionHandler] ✅ Theme changed to \(theme.displayName)")
            #endif
            
        case "soundenabled", "sound_enabled", "sound":
            let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
            appSettings.soundEnabled = enabled
            #if DEBUG
            print("[AIActionHandler] ✅ Sound \(enabled ? "enabled" : "disabled")")
            #endif
            
        case "hapticsenabled", "haptics_enabled", "haptics":
            let enabled = value.lowercased() == "true" || value == "1" || value.lowercased() == "on"
            appSettings.hapticsEnabled = enabled
            #if DEBUG
            print("[AIActionHandler] ✅ Haptics \(enabled ? "enabled" : "disabled")")
            #endif
            
        case "focussound", "focus_sound":
            if value.lowercased() == "none" || value.isEmpty {
                appSettings.selectedFocusSound = nil
            } else if let sound = FocusSound(rawValue: value) {
                appSettings.selectedFocusSound = sound
            } else {
                throw AIActionError.invalidFocusSound
            }
            #if DEBUG
            print("[AIActionHandler] ✅ Focus sound set to \(value)")
            #endif
            
        case "displayname", "display_name", "name":
            guard !value.isEmpty && value.count <= 50 else {
                throw AIActionError.invalidSettingValue
            }
            appSettings.displayName = value
            #if DEBUG
            print("[AIActionHandler] ✅ Display name set to \(value)")
            #endif
            
        case "tagline":
            guard value.count <= 100 else {
                throw AIActionError.invalidSettingValue
            }
            appSettings.tagline = value
            #if DEBUG
            print("[AIActionHandler] ✅ Tagline set to \(value)")
            #endif
            
        default:
            throw AIActionError.unknownSetting
        }
        
        // Invalidate context cache
        AIContextBuilder.shared.invalidateCache()
    }
}

enum AIActionError: LocalizedError {
    case invalidTaskTitle
    case titleTooLong
    case invalidDuration
    case reminderDateTooFar
    case taskNotFound
    case presetNotFound
    case invalidPresetName
    case presetNameTooLong
    case invalidPresetDuration
    case invalidFocusDuration
    case invalidSettingValue
    case invalidTheme
    case invalidFocusSound
    case unknownSetting
    
    var errorDescription: String? {
        switch self {
        case .invalidTaskTitle:
            return "Task title cannot be empty"
        case .titleTooLong:
            return "Task title is too long (max 200 characters)"
        case .invalidDuration:
            return "Duration must be between 1 minute and 8 hours"
        case .reminderDateTooFar:
            return "Reminder date cannot be more than 1 year in the future"
        case .taskNotFound:
            return "Task not found"
        case .presetNotFound:
            return "Preset not found"
        case .invalidPresetName:
            return "Preset name cannot be empty"
        case .presetNameTooLong:
            return "Preset name is too long (max 50 characters)"
        case .invalidPresetDuration:
            return "Preset duration must be between 1 minute and 8 hours"
        case .invalidFocusDuration:
            return "Focus duration must be between 1 minute and 8 hours"
        case .invalidSettingValue:
            return "Invalid setting value"
        case .invalidTheme:
            return "Invalid theme name. Use: forest, neon, peach, cyber, ocean, sunrise, amber, mint, royal, slate"
        case .invalidFocusSound:
            return "Invalid focus sound"
        case .unknownSetting:
            return "Unknown setting"
        }
    }
}

