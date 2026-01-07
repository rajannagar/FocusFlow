import Foundation
import SwiftUI
import Combine

// MARK: - Flow Chat View Model

/// Manages chat state, message handling, and AI interactions
@MainActor
final class FlowChatViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var messages: [FlowMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var errorMessage: String?
    
    /// Current status for the header card
    @Published var statusCard: StatusCardData?
    
    /// Contextual quick actions
    @Published var quickActions: [QuickAction] = []
    
    // MARK: - Dependencies
    
    private let service = FlowService.shared
    private let context = FlowContext.shared
    private let messageStore = FlowMessageStore.shared
    private let actionHandler = FlowActionHandler.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var streamingMessageID: UUID?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadMessages()
        updateStatusCard()
        updateQuickActions()
    }
    
    // MARK: - Public Methods
    
    /// Send a message to Flow AI
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        
        // Clear input and error
        inputText = ""
        errorMessage = nil
        
        // Create and add user message
        let userMessage = FlowMessage.user(text)
        addMessage(userMessage)
        
        // Mark as sent
        updateMessageState(id: userMessage.id, state: .complete)
        
        // Show loading
        isLoading = true
        
        // Send to AI
        Task {
            await processMessage(text)
        }
    }
    
    /// Send a quick action message
    func sendQuickAction(_ action: QuickAction) {
        guard !isLoading else { return }
        
        Haptics.impact(.light)
        inputText = action.prompt
        sendMessage()
    }
    
    /// Clear chat history
    func clearHistory() {
        messages.removeAll()
        messageStore.clearHistory()
        Haptics.impact(.medium)
        
        // Show welcome after clearing
        Task {
            await showWelcome()
        }
    }
    
    /// Retry failed message
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.sender == .user }) else { return }
        
        // Remove failed AI message if any
        if let lastMessage = messages.last, lastMessage.state == .failed {
            messages.removeLast()
        }
        
        isLoading = true
        Task {
            await processMessage(lastUserMessage.content)
        }
    }
    
    /// Cancel streaming response
    func cancelStreaming() {
        guard isStreaming, let streamingID = streamingMessageID else { return }
        
        updateMessageState(id: streamingID, state: .cancelled)
        isStreaming = false
        isLoading = false
        streamingMessageID = nil
    }
    
    /// Refresh status card and quick actions
    func refresh() {
        updateStatusCard()
        updateQuickActions()
        context.invalidateCache()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to message store
        messageStore.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] storedMessages in
                // Only update if not currently modifying
                if self?.isStreaming != true {
                    self?.messages = storedMessages
                }
            }
            .store(in: &cancellables)
        
        // Setup action handler callback for stats follow-ups
        actionHandler.statsFollowUp = { [weak self] message in
            self?.addSystemFollowUp(message)
        }
        
        // Listen for data changes to refresh status
        ProgressStore.shared.$sessions
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusCard() }
            .store(in: &cancellables)
        
        TasksStore.shared.$tasks
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusCard()
                self?.updateQuickActions()
            }
            .store(in: &cancellables)
    }
    
    private func loadMessages() {
        messages = messageStore.messages
        
        // Show welcome if no messages
        if messages.isEmpty {
            Task {
                await showWelcome()
            }
        }
    }
    
    private func processMessage(_ text: String) async {
        do {
            let contextString = context.buildContext()
            let conversationHistory = messageStore.getRecentMessages(limit: FlowConfig.maxConversationHistory)
            
            if FlowConfig.streamingEnabled {
                await processStreamingMessage(text, context: contextString, history: conversationHistory)
            } else {
                await processNonStreamingMessage(text, context: contextString, history: conversationHistory)
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
        isStreaming = false
        streamingMessageID = nil
    }
    
    private func processStreamingMessage(_ text: String, context: String, history: [FlowMessage]) async {
        // Create placeholder message for streaming
        let placeholderMessage = FlowMessage.flow("", streaming: true)
        addMessage(placeholderMessage)
        streamingMessageID = placeholderMessage.id
        isStreaming = true
        
        do {
            try await service.streamMessage(
                userMessage: text,
                conversationHistory: history,
                context: context,
                onChunk: { [weak self] chunk in
                    guard let self = self, let messageID = self.streamingMessageID else { return }
                    self.appendToMessage(id: messageID, content: chunk)
                },
                onComplete: { [weak self] response in
                    guard let self = self, let messageID = self.streamingMessageID else { return }
                    
                    // Mark complete with actions
                    self.completeMessage(id: messageID, actions: response.actions)
                    
                    // Execute actions
                    Task {
                        await self.executeActions(response.actions)
                    }
                }
            )
        } catch {
            // Mark streaming message as failed
            if let messageID = streamingMessageID {
                updateMessageState(id: messageID, state: .failed)
            }
            handleError(error)
        }
    }
    
    private func processNonStreamingMessage(_ text: String, context: String, history: [FlowMessage]) async {
        #if DEBUG
        print("[FlowChatViewModel] Sending non-streaming message: '\(text.prefix(50))...'")
        print("[FlowChatViewModel] Context length: \(context.count) chars")
        print("[FlowChatViewModel] History count: \(history.count) messages")
        #endif
        
        do {
            let response = try await service.sendMessage(
                userMessage: text,
                conversationHistory: history,
                context: context
            )
            
            #if DEBUG
            print("[FlowChatViewModel] ✅ Got response: '\(response.content.prefix(100))...'")
            print("[FlowChatViewModel] Actions: \(response.actions.count)")
            #endif
            
            // Only add AI message if there's content
            // (Actions like motivate/getStats will add their own follow-up message)
            let hasContent = !response.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            if hasContent {
                var aiMessage = FlowMessage.flow(response.content)
                aiMessage.actions = response.actions
                addMessage(aiMessage)
            }
            
            // Execute actions (they will add follow-up messages via statsFollowUp callback)
            await executeActions(response.actions)
            
        } catch {
            #if DEBUG
            print("[FlowChatViewModel] ❌ Error: \(error)")
            #endif
            handleError(error)
        }
    }
    
    private func executeActions(_ actions: [FlowAction]) async {
        guard !actions.isEmpty else { return }
        
        #if DEBUG
        print("[FlowChatViewModel] Executing \(actions.count) action(s)")
        #endif
        
        let errors = await actionHandler.executeAll(actions)
        
        if !errors.isEmpty {
            let errorMessage = "Some actions couldn't be completed:\n" + errors.joined(separator: "\n")
            addSystemFollowUp(errorMessage)
        }
        
        // Refresh context
        context.invalidateCache()
        updateStatusCard()
        updateQuickActions()
    }
    
    private func showWelcome() async {
        let userName = AppSettings.shared.displayName ?? "there"
        let firstName = userName.components(separatedBy: " ").first ?? userName
        let calendar = Calendar.autoupdatingCurrent
        let hour = calendar.component(.hour, from: Date())
        
        let greeting: String
        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 17 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
        
        let welcomeText = "\(greeting), \(firstName)! 👋\n\nI'm Flow, your productivity companion. I can help you:\n\n• Start focus sessions\n• Manage your tasks\n• Track your progress\n• Plan your day\n\nJust ask me anything!"
        
        let welcomeMessage = FlowMessage.flow(welcomeText)
        addMessage(welcomeMessage)
    }
    
    private func addSystemFollowUp(_ text: String) {
        #if DEBUG
        print("[FlowChatViewModel] 📝 Adding follow-up: '\(text.prefix(100))...'")
        #endif
        
        // Add as a system-style flow message (no actions)
        let message = FlowMessage(content: text, sender: .flow)
        
        // Add to messages (this will trigger UI update)
        messages.append(message)
        
        #if DEBUG
        print("[FlowChatViewModel] 📝 Messages count now: \(messages.count)")
        #endif
    }
    
    // MARK: - Message Management
    
    private func addMessage(_ message: FlowMessage) {
        messages.append(message)
        messageStore.addMessage(message)
    }
    
    private func updateMessageState(id: UUID, state: FlowMessage.MessageState) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].state = state
        messageStore.updateMessage(messages[index])
    }
    
    private func appendToMessage(id: UUID, content: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].appendContent(content)
    }
    
    private func completeMessage(id: UUID, actions: [FlowAction]) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].markComplete(with: actions.isEmpty ? nil : actions)
        messageStore.updateMessage(messages[index])
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        #if DEBUG
        print("[FlowChatViewModel] Error: \(error)")
        #endif
        
        if let flowError = error as? FlowError {
            errorMessage = flowError.localizedDescription
            
            // Add failed message indicator
            if flowError.isRetryable {
                let failedMessage = FlowMessage(
                    content: "Something went wrong. Tap to retry.",
                    sender: .flow,
                    state: .failed
                )
                messages.append(failedMessage)
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        Haptics.notification(.error)
    }
    
    // MARK: - Status Card
    
    private func updateStatusCard() {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        
        // Today's progress
        let todaySessions = ProgressStore.shared.sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = ProgressStore.shared.dailyGoalMinutes
        let percentage = goalMinutes > 0 ? min(100, (todayMinutes * 100) / goalMinutes) : 0
        
        // Today's tasks
        let todayTasks = TasksStore.shared.tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return calendar.isDateInToday(reminder)
        }
        
        statusCard = StatusCardData(
            focusedMinutes: todayMinutes,
            goalMinutes: goalMinutes,
            percentage: percentage,
            tasksCount: todayTasks.count,
            sessionsCount: todaySessions.count
        )
    }
    
    // MARK: - Quick Actions
    
    private func updateQuickActions() {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        var actions: [QuickAction] = []
        
        // Context-aware suggestions
        let todaySessions = ProgressStore.shared.sessions.filter { calendar.isDateInToday($0.date) }
        let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        let goalMinutes = ProgressStore.shared.dailyGoalMinutes
        
        // Primary action based on context
        if todayMinutes == 0 {
            // No sessions today - encourage starting
            actions.append(QuickAction(id: "start", label: "Start Focus", icon: "play.fill", prompt: "Start a 25 minute focus session"))
        } else if todayMinutes < goalMinutes {
            // In progress
            let remaining = goalMinutes - todayMinutes
            let suggestedTime = min(remaining, 25)
            actions.append(QuickAction(id: "continue", label: "Continue", icon: "play.fill", prompt: "Start a \(suggestedTime) minute focus session"))
        } else {
            // Goal met
            actions.append(QuickAction(id: "celebrate", label: "How'd I do?", icon: "star.fill", prompt: "How am I doing today?"))
        }
        
        // Tasks
        let todayTasks = TasksStore.shared.tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return calendar.isDateInToday(reminder)
        }
        
        if !todayTasks.isEmpty {
            actions.append(QuickAction(id: "tasks", label: "Today's Tasks", icon: "checklist", prompt: "What are my tasks for today?"))
        } else {
            actions.append(QuickAction(id: "add_task", label: "Add Task", icon: "plus.circle", prompt: "Help me add a new task"))
        }
        
        // Time-based suggestions
        if hour >= 9 && hour <= 11 {
            actions.append(QuickAction(id: "plan", label: "Plan Day", icon: "calendar", prompt: "Help me plan my day"))
        } else if hour >= 12 && hour <= 14 {
            actions.append(QuickAction(id: "break", label: "Break Time?", icon: "cup.and.saucer", prompt: "Should I take a break?"))
        } else if hour >= 17 {
            actions.append(QuickAction(id: "review", label: "Day Review", icon: "chart.bar", prompt: "How was my day?"))
        }
        
        // Always include motivation option
        if !actions.contains(where: { $0.id == "motivate" }) && actions.count < 4 {
            actions.append(QuickAction(id: "motivate", label: "Motivate Me", icon: "flame", prompt: "Motivate me!"))
        }
        
        quickActions = Array(actions.prefix(4))
    }
}

// MARK: - Supporting Types

struct StatusCardData {
    let focusedMinutes: Int
    let goalMinutes: Int
    let percentage: Int
    let tasksCount: Int
    let sessionsCount: Int
}

struct QuickAction: Identifiable {
    let id: String
    let label: String
    let icon: String
    let prompt: String
}

// Note: Haptics enum is defined in Core/Utilities/Haptics.swift
