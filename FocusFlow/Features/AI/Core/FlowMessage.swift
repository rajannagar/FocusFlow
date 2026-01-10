import Foundation
import Combine

// MARK: - Flow Message

/// Represents a message in the Flow AI conversation
struct FlowMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let sender: Sender
    let timestamp: Date
    var state: MessageState
    var actions: [FlowAction]?
    var attachments: [MessageAttachment]?
    var metadata: MessageMetadata?
    var isProactiveNudge: Bool  // Phase 5: Mark proactive nudges for special styling
    
    // MARK: - Sender
    
    enum Sender: String, Codable {
        case user
        case flow  // AI assistant
        case system  // System messages (errors, status updates)
    }
    
    // MARK: - Message State
    
    enum MessageState: String, Codable {
        case sending     // User message being sent
        case streaming   // AI response streaming in
        case complete    // Message complete
        case failed      // Failed to send/receive
        case cancelled   // User cancelled
    }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        content: String,
        sender: Sender,
        timestamp: Date = Date(),
        state: MessageState = .complete,
        actions: [FlowAction]? = nil,
        attachments: [MessageAttachment]? = nil,
        metadata: MessageMetadata? = nil,
        isProactiveNudge: Bool = false
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.state = state
        self.actions = actions
        self.attachments = attachments
        self.metadata = metadata
        self.isProactiveNudge = isProactiveNudge
    }
    
    /// Create a user message
    static func user(_ content: String) -> FlowMessage {
        FlowMessage(content: content, sender: .user, state: .sending)
    }
    
    /// Create a Flow AI message (initially streaming)
    static func flow(_ content: String, streaming: Bool = false) -> FlowMessage {
        FlowMessage(content: content, sender: .flow, state: streaming ? .streaming : .complete)
    }
    
    /// Create a system message
    static func system(_ content: String) -> FlowMessage {
        FlowMessage(content: content, sender: .system)
    }
    
    // MARK: - Mutations
    
    /// Append content (for streaming)
    mutating func appendContent(_ text: String) {
        self = FlowMessage(
            id: id,
            content: content + text,
            sender: sender,
            timestamp: timestamp,
            state: .streaming,
            actions: actions,
            attachments: attachments,
            metadata: metadata,
            isProactiveNudge: isProactiveNudge
        )
    }
    
    /// Mark as complete
    mutating func markComplete(with actions: [FlowAction]? = nil) {
        self = FlowMessage(
            id: id,
            content: content,
            sender: sender,
            timestamp: timestamp,
            state: .complete,
            actions: actions ?? self.actions,
            attachments: attachments,
            metadata: metadata,
            isProactiveNudge: isProactiveNudge
        )
    }
    
    /// Mark as failed
    mutating func markFailed() {
        self = FlowMessage(
            id: id,
            content: content,
            sender: sender,
            timestamp: timestamp,
            state: .failed,
            actions: actions,
            attachments: attachments,
            metadata: metadata,
            isProactiveNudge: isProactiveNudge
        )
    }
}

// MARK: - Message Attachment

/// Rich content attachments for messages
struct MessageAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AttachmentType
    let data: AttachmentData
    
    enum AttachmentType: String, Codable {
        case taskPreview      // Show task card
        case presetPreview    // Show preset card
        case focusSession     // Show focus session card
        case statsCard        // Show stats summary
        case taskList         // Show list of tasks
        case progressChart    // Show progress chart
        case quickActions     // Show quick action buttons
    }
    
    init(id: UUID = UUID(), type: AttachmentType, data: AttachmentData) {
        self.id = id
        self.type = type
        self.data = data
    }
}

// MARK: - Attachment Data

/// Data payload for attachments
enum AttachmentData: Codable, Equatable {
    case task(TaskAttachment)
    case preset(PresetAttachment)
    case focus(FocusAttachment)
    case stats(StatsAttachment)
    case taskList([TaskAttachment])
    case quickActions([QuickActionAttachment])
    
    // Coding keys for polymorphic encoding
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "task":
            let data = try container.decode(TaskAttachment.self, forKey: .data)
            self = .task(data)
        case "preset":
            let data = try container.decode(PresetAttachment.self, forKey: .data)
            self = .preset(data)
        case "focus":
            let data = try container.decode(FocusAttachment.self, forKey: .data)
            self = .focus(data)
        case "stats":
            let data = try container.decode(StatsAttachment.self, forKey: .data)
            self = .stats(data)
        case "taskList":
            let data = try container.decode([TaskAttachment].self, forKey: .data)
            self = .taskList(data)
        case "quickActions":
            let data = try container.decode([QuickActionAttachment].self, forKey: .data)
            self = .quickActions(data)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown attachment type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .task(let data):
            try container.encode("task", forKey: .type)
            try container.encode(data, forKey: .data)
        case .preset(let data):
            try container.encode("preset", forKey: .type)
            try container.encode(data, forKey: .data)
        case .focus(let data):
            try container.encode("focus", forKey: .type)
            try container.encode(data, forKey: .data)
        case .stats(let data):
            try container.encode("stats", forKey: .type)
            try container.encode(data, forKey: .data)
        case .taskList(let data):
            try container.encode("taskList", forKey: .type)
            try container.encode(data, forKey: .data)
        case .quickActions(let data):
            try container.encode("quickActions", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Attachment Types

struct TaskAttachment: Codable, Equatable {
    let id: UUID
    let title: String
    let reminderDate: Date?
    let duration: TimeInterval?
    let isCompleted: Bool
}

struct PresetAttachment: Codable, Equatable {
    let id: UUID
    let name: String
    let durationSeconds: Int
    let soundID: String?
}

struct FocusAttachment: Codable, Equatable {
    let minutes: Int
    let presetName: String?
    let sessionName: String?
    let isActive: Bool
}

struct StatsAttachment: Codable, Equatable {
    let period: String
    let totalMinutes: Int
    let goalMinutes: Int
    let sessionsCount: Int
    let tasksCompleted: Int
    let streak: Int
}

struct QuickActionAttachment: Codable, Equatable {
    let id: String
    let label: String
    let icon: String
    let action: FlowAction
}

// MARK: - Message Metadata

/// Additional metadata for messages
struct MessageMetadata: Codable, Equatable {
    var responseTime: TimeInterval?    // How long the AI took to respond
    var tokensUsed: Int?               // API tokens used
    var modelUsed: String?             // Which model was used
    var wasStreamed: Bool?             // Was this a streamed response
    var executedActions: [String]?     // Actions that were executed
}

// MARK: - Flow Message Store

/// Persists chat messages locally
@MainActor
final class FlowMessageStore: ObservableObject {
    static let shared = FlowMessageStore()
    
    @Published private(set) var messages: [FlowMessage] = []
    
    private let defaults = UserDefaults.standard
    private let storageKey = "flow_messages_v1"
    private let maxStoredMessages = 100
    
    private init() {
        load()
    }
    
    // MARK: - Public Methods
    
    func addMessage(_ message: FlowMessage) {
        messages.append(message)
        trimIfNeeded()
        save()
    }
    
    func updateMessage(_ message: FlowMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            save()
        }
    }
    
    func removeMessage(id: UUID) {
        messages.removeAll { $0.id == id }
        save()
    }
    
    func clearHistory() {
        messages.removeAll()
        save()
    }
    
    func getRecentMessages(limit: Int = 20) -> [FlowMessage] {
        Array(messages.suffix(limit))
    }
    
    // MARK: - Private Methods
    
    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode([FlowMessage].self, from: data)
            messages = decoded
        } catch {
            #if DEBUG
            print("[FlowMessageStore] Failed to load messages: \(error)")
            #endif
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(messages)
            defaults.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("[FlowMessageStore] Failed to save messages: \(error)")
            #endif
        }
    }
    
    private func trimIfNeeded() {
        if messages.count > maxStoredMessages {
            messages = Array(messages.suffix(maxStoredMessages))
        }
    }
}
