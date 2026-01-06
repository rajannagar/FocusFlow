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
                let (response, actions) = try await aiService.sendMessage(
                    userMessage: text,
                    conversationHistory: messages,
                    context: context
                )
                
                // Create assistant message with batch actions
                let assistantMessage = AIMessage(
                    text: response,
                    sender: .assistant,
                    action: actions.first, // Keep backward compatibility
                    actions: !actions.isEmpty ? actions : nil
                )
                messageStore.addMessage(assistantMessage)
                
                // Execute actions sequentially if present
                if !actions.isEmpty {
                    #if DEBUG
                    print("[AIChatViewModel] Executing \(actions.count) action(s)")
                    #endif
                    do {
                        // Execute actions in sequence
                        for (index, action) in actions.enumerated() {
                            #if DEBUG
                            print("[AIChatViewModel] Executing action \(index + 1)/\(actions.count): \(action)")
                            #endif
                            try await actionHandler.execute(action)
                        }
                        
                        // Invalidate context cache after all actions
                        contextBuilder.invalidateCache()
                        
                        #if DEBUG
                        print("[AIChatViewModel] ✅ All \(actions.count) action(s) executed successfully")
                        #endif
                        
                    } catch {
                        // Log error but don't fail the message
                        print("[AIChatViewModel] ❌ Failed to execute action: \(error)")
                        // Add error message to chat
                        let errorMsg = AIMessage(
                            text: "I encountered an error while executing the task: \(error.localizedDescription). Please try again.",
                            sender: .assistant
                        )
                        messageStore.addMessage(errorMsg)
                    }
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
                
                // Only set errorMessage for critical errors that need alert
                // For most errors, just show in chat
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
        let errorDesc = error.localizedDescription.lowercased()
        
        // Network/connectivity issues
        if errorDesc.contains("network") || errorDesc.contains("internet") || errorDesc.contains("offline") ||
           errorDesc.contains("connection") || errorDesc.contains("timed out") {
            return "I'm having trouble connecting right now. Please check your internet connection and try again. 📶"
        }
        
        // Auth issues - should be rare with retry logic
        if errorDesc.contains("unauthorized") || errorDesc.contains("invalid jwt") || errorDesc.contains("401") {
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
        
        // OpenAI specific errors
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

