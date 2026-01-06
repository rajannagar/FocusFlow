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
                let (response, action) = try await aiService.sendMessage(
                    userMessage: text,
                    conversationHistory: messages,
                    context: context
                )
                
                // Create assistant message
                let assistantMessage = AIMessage(
                    text: response,
                    sender: .assistant,
                    action: action
                )
                messageStore.addMessage(assistantMessage)
                
                // Execute action if present
                if let action = action {
                    #if DEBUG
                    print("[AIChatViewModel] Executing action: \(action)")
                    #endif
                    do {
                        try await actionHandler.execute(action)
                        
                        // Invalidate context cache after action
                        contextBuilder.invalidateCache()
                        
                        #if DEBUG
                        print("[AIChatViewModel] ✅ Action executed successfully")
                        #endif
                        
                        // Add success confirmation message for task creation
                        if case .createTask(let title, _, _) = action {
                            let successMsg = AIMessage(
                                text: "✅ Task '\(title)' has been created! You can see it in the Tasks tab.",
                                sender: .assistant
                            )
                            messageStore.addMessage(successMsg)
                        } else if case .updateTask = action {
                            let successMsg = AIMessage(
                                text: "✅ Task has been updated successfully!",
                                sender: .assistant
                            )
                            messageStore.addMessage(successMsg)
                        } else if case .deleteTask = action {
                            let successMsg = AIMessage(
                                text: "✅ Task has been deleted successfully!",
                                sender: .assistant
                            )
                            messageStore.addMessage(successMsg)
                        }
                    } catch {
                        // Log error but don't fail the message
                        print("[AIChatViewModel] ❌ Failed to execute action: \(error)")
                        // Add error message to chat
                        let errorMsg = AIMessage(
                            text: "I encountered an error while creating the task: \(error.localizedDescription). Please try again.",
                            sender: .assistant
                        )
                        messageStore.addMessage(errorMsg)
                    }
                } else {
                    #if DEBUG
                    print("[AIChatViewModel] No action to execute")
                    #endif
                }
                
                isLoading = false
            } catch {
                isLoading = false
                let errorDesc = error.localizedDescription
                errorMessage = errorDesc
                
                // Add user-friendly error message to chat
                var userFriendlyError = "Sorry, I encountered an error."
                if errorDesc.contains("model is not available") {
                    userFriendlyError = "⚠️ The AI model is not available. Please check your OpenAI API key has access to the model in your account settings (platform.openai.com)."
                } else if errorDesc.contains("Access denied") || errorDesc.contains("403") {
                    userFriendlyError = "⚠️ Access denied. Please check your OpenAI API key permissions."
                } else if errorDesc.contains("Rate limit") || errorDesc.contains("429") {
                    userFriendlyError = "⚠️ Rate limit exceeded. Please try again in a moment."
                } else if errorDesc.contains("Invalid API key") || errorDesc.contains("401") {
                    userFriendlyError = "⚠️ Invalid API key. Please check your OPENAI_API_KEY environment variable in Xcode."
                } else {
                    userFriendlyError = "⚠️ \(errorDesc)"
                }
                
                let errorMsg = AIMessage(
                    text: userFriendlyError,
                    sender: .assistant
                )
                messageStore.addMessage(errorMsg)
            }
        }
    }
    
    /// Clear chat history
    func clearHistory() {
        messageStore.clearHistory()
    }
}

