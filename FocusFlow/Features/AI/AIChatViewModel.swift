import Foundation
import SwiftUI
import Combine

/// Manages chat state and handles message sending
@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""
    
    private let aiService = AIService.shared
    private let contextBuilder = AIContextBuilder.shared
    private let messageStore = AIMessageStore.shared
    private let actionHandler = AIActionHandler.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load messages from store
        messageStore.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.messages = messages
            }
            .store(in: &cancellables)
    }
    
    /// Send a user message
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        
        // Clear input
        inputText = ""
        errorMessage = nil
        
        // Create user message
        let userMessage = AIMessage(text: text, sender: .user)
        messageStore.addMessage(userMessage)
        
        // Show loading
        isLoading = true
        
        // Send to AI
        Task {
            do {
                let context = contextBuilder.buildContext()
                
                // AIService now returns array of actions
                let (response, actions) = try await aiService.sendMessage(
                    userMessage: text,
                    conversationHistory: messages,
                    context: context
                )
                
                // Create assistant message with actions
                let assistantMessage = AIMessage(
                    text: response,
                    sender: .assistant,
                    action: actions.first, // Keep backward compatibility for UI
                    actions: actions.isEmpty ? nil : actions
                )
                messageStore.addMessage(assistantMessage)
                
                // Execute actions sequentially if present
                if !actions.isEmpty {
                    #if DEBUG
                    print("[AIChatViewModel] Executing \(actions.count) action(s)")
                    #endif
                    
                    var failedActions: [String] = []
                    
                    // Execute actions in sequence
                    for (index, action) in actions.enumerated() {
                        #if DEBUG
                        print("[AIChatViewModel] Executing action \(index + 1)/\(actions.count): \(action)")
                        #endif
                        
                        do {
                            try await actionHandler.execute(action)
                        } catch {
                            // Log error but continue with other actions
                            print("[AIChatViewModel] ❌ Action \(index + 1) failed: \(error)")
                            failedActions.append(error.localizedDescription)
                        }
                    }
                    
                    // Invalidate context cache after all actions
                    contextBuilder.invalidateCache()
                    
                    // Report any failures
                    if !failedActions.isEmpty {
                        let errorMsg = AIMessage(
                            text: "Some actions couldn't be completed: \(failedActions.joined(separator: ", "))",
                            sender: .assistant
                        )
                        messageStore.addMessage(errorMsg)
                    }
                    
                    #if DEBUG
                    let successCount = actions.count - failedActions.count
                    print("[AIChatViewModel] ✅ \(successCount)/\(actions.count) action(s) executed successfully")
                    #endif
                    
                } else {
                    #if DEBUG
                    print("[AIChatViewModel] No actions to execute")
                    #endif
                }
                
                isLoading = false
                
            } catch {
                isLoading = false
                
                // Generate user-friendly error message
                let userFriendlyError = Self.friendlyErrorMessage(from: error)
                
                // Show error in chat
                let errorMsg = AIMessage(
                    text: userFriendlyError,
                    sender: .assistant
                )
                messageStore.addMessage(errorMsg)
                
                #if DEBUG
                print("[AIChatViewModel] ❌ Error: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    /// Convert errors to user-friendly messages
    private static func friendlyErrorMessage(from error: Error) -> String {
        // Check for specific AI service errors
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .authenticationRequired:
                return "I need you to sign in to continue. Please go to Settings and sign in. 🔐"
            case .rateLimited:
                return "I'm receiving too many requests right now. Please wait a moment and try again. ⏳"
            case .notConfigured:
                return "I'm not properly configured. Please contact support. ⚙️"
            case .serverError:
                return "I'm experiencing some technical difficulties. Please try again in a moment. 🔧"
            default:
                break
            }
        }
        
        let errorDesc = error.localizedDescription.lowercased()
        
        // Network/connectivity issues
        if errorDesc.contains("network") || errorDesc.contains("internet") || errorDesc.contains("offline") ||
           errorDesc.contains("connection") || errorDesc.contains("timed out") || errorDesc.contains("nsurlerror") {
            return "I'm having trouble connecting right now. Please check your internet connection and try again. 📶"
        }
        
        // Auth issues
        if errorDesc.contains("unauthorized") || errorDesc.contains("invalid jwt") || errorDesc.contains("401") ||
           errorDesc.contains("authentication") {
            return "I need you to sign in again to continue. Please go to Settings and sign in. 🔐"
        }
        
        // Rate limiting
        if errorDesc.contains("rate limit") || errorDesc.contains("429") || errorDesc.contains("too many") {
            return "I'm receiving too many requests right now. Please wait a moment and try again. ⏳"
        }
        
        // Server issues
        if errorDesc.contains("500") || errorDesc.contains("502") || errorDesc.contains("503") || errorDesc.contains("server") {
            return "I'm experiencing some technical difficulties. Please try again in a moment. 🔧"
        }
        
        // OpenAI specific errors (shouldn't happen with Edge Function, but just in case)
        if errorDesc.contains("openai") || errorDesc.contains("model") {
            return "I'm having trouble with my AI backend. The team has been notified. Please try again later. 🤖"
        }
        
        // Generic fallback - still friendly
        return "Something went wrong on my end. Please try again, and if the problem persists, restart the app. 💫"
    }
    
    /// Clear chat history
    func clearHistory() {
        messageStore.clearHistory()
    }
}
