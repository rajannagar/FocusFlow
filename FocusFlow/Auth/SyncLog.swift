import Foundation

enum SyncModelTag: String {
    case habits = "HABITS"
    case stats  = "STATS"
    case other  = "OTHER"
}

enum SyncModeTag: String {
    case guest = "GUEST"
    case auth  = "AUTH"
    case off   = "OFF"
}

/// Small, consistent logger for all sync engines.
struct SyncLog {
    static var enabled: Bool = true

    static func info(_ model: SyncModelTag, _ message: String) {
        guard enabled else { return }
        print(prefix(model) + message)
    }

    static func error(_ model: SyncModelTag, _ message: String) {
        guard enabled else { return }
        print(prefix(model) + "❌ " + message)
    }

    private static func prefix(_ model: SyncModelTag) -> String {
        // Example:
        // SYNC[HABITS] 2025-12-16T18:35:12Z ...
        let ts = ISO8601DateFormatter().string(from: Date())
        return "SYNC[\(model.rawValue)] \(ts) "
    }
}
