import Foundation

/// Represents a single message in the AI chat
struct AIMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let sender: Sender
    let timestamp: Date
    var action: AIAction?
    
    enum Sender: String, Codable {
        case user
        case assistant
    }
    
    init(id: UUID = UUID(), text: String, sender: Sender, timestamp: Date = Date(), action: AIAction? = nil) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.action = action
    }
}

/// Represents an action the AI can suggest
enum AIAction: Codable, Equatable {
    // Task actions
    case createTask(title: String, reminderDate: Date?, duration: TimeInterval?)
    case updateTask(taskID: UUID, title: String?, reminderDate: Date?, duration: TimeInterval?)
    case deleteTask(taskID: UUID)
    case toggleTaskCompletion(taskID: UUID)
    case listFutureTasks
    
    // Preset actions
    case setPreset(presetID: UUID)
    case createPreset(name: String, durationSeconds: Int, soundID: String)
    case updatePreset(presetID: UUID, name: String?, durationSeconds: Int?)
    case deletePreset(presetID: UUID)
    
    // Focus actions
    case startFocus(minutes: Int, presetID: UUID?, sessionName: String?)
    
    // Settings actions
    case updateSetting(setting: String, value: String)
    
    // Stats/Analysis actions
    case getStats(period: String) // "today", "week", "month", "alltime"
    case analyzeSessions
    
    enum CodingKeys: String, CodingKey {
        case type
        case title
        case reminderDate
        case duration
        case presetID
        case taskID
        case name
        case durationSeconds
        case soundID
        case setting
        case value
        case period
        case minutes
        case sessionName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "createTask":
            let title = try container.decode(String.self, forKey: .title)
            let reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
            let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
            self = .createTask(title: title, reminderDate: reminderDate, duration: duration)
        case "updateTask":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            let title = try container.decodeIfPresent(String.self, forKey: .title)
            let reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
            let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
            self = .updateTask(taskID: taskID, title: title, reminderDate: reminderDate, duration: duration)
        case "deleteTask":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            self = .deleteTask(taskID: taskID)
        case "toggleTaskCompletion":
            let taskID = try container.decode(UUID.self, forKey: .taskID)
            self = .toggleTaskCompletion(taskID: taskID)
        case "setPreset", "suggestPreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            self = .setPreset(presetID: presetID)
        case "createPreset":
            let name = try container.decode(String.self, forKey: .name)
            let durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
            let soundID = try container.decode(String.self, forKey: .soundID)
            self = .createPreset(name: name, durationSeconds: durationSeconds, soundID: soundID)
        case "updatePreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            let name = try container.decodeIfPresent(String.self, forKey: .name)
            let durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            self = .updatePreset(presetID: presetID, name: name, durationSeconds: durationSeconds)
        case "deletePreset":
            let presetID = try container.decode(UUID.self, forKey: .presetID)
            self = .deletePreset(presetID: presetID)
        case "startFocus":
            let minutes = try container.decode(Int.self, forKey: .minutes)
            let presetID = try container.decodeIfPresent(UUID.self, forKey: .presetID)
            let sessionName = try container.decodeIfPresent(String.self, forKey: .sessionName)
            self = .startFocus(minutes: minutes, presetID: presetID, sessionName: sessionName)
        case "updateSetting":
            let setting = try container.decode(String.self, forKey: .setting)
            let value = try container.decode(String.self, forKey: .value)
            self = .updateSetting(setting: setting, value: value)
        case "getStats":
            let period = try container.decode(String.self, forKey: .period)
            self = .getStats(period: period)
        case "listFutureTasks":
            self = .listFutureTasks
        case "analyzeSessions":
            self = .analyzeSessions
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown action type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .createTask(let title, let reminderDate, let duration):
            try container.encode("createTask", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
            try container.encodeIfPresent(duration, forKey: .duration)
        case .updateTask(let taskID, let title, let reminderDate, let duration):
            try container.encode("updateTask", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
            try container.encodeIfPresent(title, forKey: .title)
            try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
            try container.encodeIfPresent(duration, forKey: .duration)
        case .deleteTask(let taskID):
            try container.encode("deleteTask", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
        case .toggleTaskCompletion(let taskID):
            try container.encode("toggleTaskCompletion", forKey: .type)
            try container.encode(taskID, forKey: .taskID)
        case .setPreset(let presetID):
            try container.encode("setPreset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
        case .createPreset(let name, let durationSeconds, let soundID):
            try container.encode("createPreset", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(durationSeconds, forKey: .durationSeconds)
            try container.encode(soundID, forKey: .soundID)
        case .updatePreset(let presetID, let name, let durationSeconds):
            try container.encode("updatePreset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        case .deletePreset(let presetID):
            try container.encode("deletePreset", forKey: .type)
            try container.encode(presetID, forKey: .presetID)
        case .startFocus(let minutes, let presetID, let sessionName):
            try container.encode("startFocus", forKey: .type)
            try container.encode(minutes, forKey: .minutes)
            try container.encodeIfPresent(presetID, forKey: .presetID)
            try container.encodeIfPresent(sessionName, forKey: .sessionName)
        case .updateSetting(let setting, let value):
            try container.encode("updateSetting", forKey: .type)
            try container.encode(setting, forKey: .setting)
            try container.encode(value, forKey: .value)
        case .getStats(let period):
            try container.encode("getStats", forKey: .type)
            try container.encode(period, forKey: .period)
        case .listFutureTasks:
            try container.encode("listFutureTasks", forKey: .type)
        case .analyzeSessions:
            try container.encode("analyzeSessions", forKey: .type)
        }
    }
}

