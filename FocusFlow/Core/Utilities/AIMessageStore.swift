import Foundation
import Combine

/// Persists chat history per user namespace
@MainActor
final class AIMessageStore: ObservableObject {
    static let shared = AIMessageStore()
    
    @Published private(set) var messages: [AIMessage] = []
    
    private let defaults = UserDefaults.standard
    private var activeNamespace: String = "guest"
    private var cancellables = Set<AnyCancellable>()
    
    private enum Keys {
        static let base = "ff_ai_messages"
    }
    
    private func key() -> String {
        "\(Keys.base)_\(activeNamespace)"
    }
    
    private init() {
        applyAuthState(AuthManagerV2.shared.state)
        
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyAuthState(state)
            }
            .store(in: &cancellables)
    }
    
    private func applyAuthState(_ state: CloudAuthState) {
        let newNamespace: String
        switch state {
        case .signedIn(let userId):
            newNamespace = userId.uuidString
        case .guest, .unknown, .signedOut:
            newNamespace = "guest"
        }
        
        if newNamespace == activeNamespace { return }
        
        activeNamespace = newNamespace
        load()
    }
    
    /// Add a message to the chat
    func addMessage(_ message: AIMessage) {
        messages.append(message)
        save()
    }
    
    /// Clear all messages
    func clearHistory() {
        messages.removeAll()
        save()
    }
    
    /// Load messages from storage
    private func load() {
        guard let data = defaults.data(forKey: key()) else {
            messages = []
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([AIMessage].self, from: data) {
            messages = loaded
        } else {
            messages = []
        }
    }
    
    /// Save messages to storage
    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(messages) {
            defaults.set(data, forKey: key())
        }
    }
}

