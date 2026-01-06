import SwiftUI

/// Main chat interface for AI assistant
struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var showPaywall = false
    @State private var showClearConfirmation = false
    @FocusState private var isInputFocused: Bool
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    var body: some View {
        Group {
            if pro.isPro {
                chatInterface
            } else {
                paywallView
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .ai)
        }
    }
    
    private var chatInterface: some View {
        chatInterfaceContent
    }
    
    private var chatInterfaceContent: some View {
        GeometryReader { geo in
            ZStack {
                // Premium animated background
                PremiumAppBackground(theme: theme, particleCount: 12)
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                if viewModel.messages.isEmpty {
                                    emptyStateView
                                        .frame(minHeight: geo.size.height - 280)
                                } else {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message, theme: theme)
                                            .id(message.id)
                                            .transition(.asymmetric(
                                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                removal: .opacity
                                            ))
                                    }
                                    
                                    if viewModel.isLoading {
                                        TypingIndicator(theme: theme)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, isLoading in
                            if isLoading, let lastMessage = viewModel.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Quick action chips - always visible
                    quickActionChips
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Input area
                    inputSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
            }
        }
        .onAppear {
            AIContextBuilder.shared.invalidateCache()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Focus AI")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        showClearConfirmation = true
                    }) {
                        Label("Clear History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Clear Chat History", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("Are you sure you want to clear all chat messages? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                // FocusFlow logo
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("Focus Ai")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Clear chat button
            if !viewModel.messages.isEmpty {
                Button(action: {
                    showClearConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 28) {
            // Premium AI icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accentPrimary.opacity(0.25),
                                theme.accentSecondary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Hey, I'm Focus AI")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your personal productivity companion.\nTap a suggestion below or ask me anything!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// Always-visible quick action chips
    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickChip(icon: "hand.wave", text: "Say Hi", theme: theme) {
                    sendQuickMessage("Hi!")
                }
                
                QuickChip(icon: "list.bullet", text: "My Tasks", theme: theme) {
                    sendQuickMessage("What are my tasks?")
                }
                
                QuickChip(icon: "chart.bar", text: "Today's Stats", theme: theme) {
                    sendQuickMessage("How am I doing today?")
                }
                
                QuickChip(icon: "cup.and.saucer", text: "Need Break", theme: theme) {
                    sendQuickMessage("I need a break")
                }
                
                QuickChip(icon: "calendar", text: "Plan Day", theme: theme) {
                    sendQuickMessage("Help me plan my day")
                }
                
                QuickChip(icon: "star", text: "Motivate Me", theme: theme) {
                    sendQuickMessage("Motivate me!")
                }
                
                QuickChip(icon: "doc.text", text: "Week Report", theme: theme) {
                    sendQuickMessage("Show my weekly report")
                }
                
                QuickChip(icon: "play.fill", text: "Start Focus", theme: theme) {
                    sendQuickMessage("Start a 25 minute focus session")
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func sendQuickMessage(_ message: String) {
        guard !viewModel.isLoading else { return }
        Haptics.impact(.light)
        viewModel.inputText = message
        viewModel.sendMessage()
    }
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            // Text field container
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accentPrimary.opacity(0.70))
                
                TextField("Ask me anything...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .lineLimit(1...4)
                    .submitLabel(.done)
                    .onSubmit {
                        if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.sendMessage()
                        }
                    }
                
                Spacer(minLength: 0)
                
                // Send button
                Button(action: {
                    Haptics.impact(.light)
                    viewModel.sendMessage()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                                    ? LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [theme.accentPrimary, theme.accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 36, height: 36)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var paywallView: some View {
        ZStack {
            PremiumAppBackground(theme: theme)
            
            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accentPrimary.opacity(0.3),
                                    theme.accentPrimary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 50)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 20) {
                    Text("Focus AI")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Unlock AI-powered assistance to help you stay focused and productive.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                
                Button(action: {
                    Haptics.impact(.medium)
                    showPaywall = true
                }) {
                    HStack {
                        Text("Upgrade to Pro")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: theme.accentPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 60)
        }
    }
}

// MARK: - Supporting Views

/// Premium quick action chip
struct QuickChip: View {
    let icon: String
    let text: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentPrimary.opacity(0.3),
                                theme.accentSecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.accentPrimary.opacity(0.5),
                                        theme.accentSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Scale button style for premium feel
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct QuickSuggestionButton: View {
    let text: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
}

struct CapabilityRow: View {
    let icon: String
    let text: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentPrimary.opacity(0.2),
                                theme.accentSecondary.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

/// Message bubble component with premium design
struct MessageBubble: View {
    let message: AIMessage
    let theme: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.sender == .user {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 10) {
                // Message text with better formatting
                Text(formatMessageText(message.text))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                message.sender == .user
                                    ? LinearGradient(
                                        colors: [theme.accentPrimary, theme.accentSecondary.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        message.sender == .user
                                            ? Color.clear
                                            : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: message.sender == .user ? theme.accentPrimary.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
                
                // Show action buttons if present
                if let actions = message.actions, !actions.isEmpty {
                    if let firstAction = actions.first {
                        ActionButton(action: firstAction, theme: theme)
                    }
                } else if let action = message.action {
                    ActionButton(action: action, theme: theme)
                }
            }
            
            if message.sender == .user {
                // User avatar (optional - can remove if too cluttered)
            }
            
            if message.sender == .assistant {
                Spacer(minLength: 40)
            }
        }
    }
    
    /// Format message text for better display
    private func formatMessageText(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        // Basic formatting - can enhance later
        return result
    }
}

/// Action button for AI-suggested actions
/// Actions are auto-executed, so button shows "Done" state and can't be re-tapped
struct ActionButton: View {
    let action: AIAction
    let theme: AppTheme
    @State private var wasExecuted = true // Actions are auto-executed by ViewModel
    @State private var isExecuting = false
    
    var body: some View {
        Button(action: {
            guard !wasExecuted && !isExecuting else { return }
            isExecuting = true
            Haptics.impact(.light)
            Task {
                do {
                    try await AIActionHandler.shared.execute(action)
                    wasExecuted = true
                } catch {
                    print("[ActionButton] Failed to execute action: \(error)")
                }
                isExecuting = false
            }
        }) {
            HStack(spacing: 8) {
                if isExecuting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: wasExecuted ? "checkmark.circle.fill" : actionIcon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(wasExecuted ? "Done" : actionTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white.opacity(wasExecuted ? 0.7 : 1.0))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(wasExecuted ? Color.white.opacity(0.15) : theme.accentPrimary)
            )
        }
        .disabled(wasExecuted || isExecuting)
    }
    
    private var actionIcon: String {
        switch action {
        case .createTask:
            return "checkmark.circle.fill"
        case .updateTask:
            return "pencil.circle.fill"
        case .deleteTask:
            return "trash.circle.fill"
        case .toggleTaskCompletion:
            return "checkmark.square.fill"
        case .listFutureTasks:
            return "list.bullet"
        case .setPreset:
            return "slider.horizontal.3"
        case .createPreset:
            return "plus.circle.fill"
        case .updatePreset:
            return "pencil.circle.fill"
        case .deletePreset:
            return "trash.circle.fill"
        case .startFocus:
            return "play.circle.fill"
        case .updateSetting:
            return "gearshape.fill"
        case .getStats:
            return "chart.bar.fill"
        case .analyzeSessions:
            return "chart.bar.fill"
        case .generateDailyPlan:
            return "calendar.badge.clock"
        case .suggestBreak:
            return "cup.and.saucer.fill"
        case .motivate:
            return "star.fill"
        case .generateWeeklyReport:
            return "doc.text.fill"
        case .showWelcome:
            return "hand.wave.fill"
        }
    }
    
    private var actionTitle: String {
        switch action {
        case .createTask(let title, _, _):
            return "Create: \(title.prefix(20))\(title.count > 20 ? "..." : "")"
        case .updateTask:
            return "Update Task"
        case .deleteTask:
            return "Delete Task"
        case .toggleTaskCompletion:
            return "Toggle Complete"
        case .listFutureTasks:
            return "View Tasks"
        case .setPreset:
            return "Use Preset"
        case .createPreset(let name, _, _):
            return "Create: \(name)"
        case .updatePreset:
            return "Update Preset"
        case .deletePreset:
            return "Delete Preset"
        case .startFocus(let minutes, _, _):
            return "Start \(minutes)m Focus"
        case .updateSetting(let setting, _):
            return "Update: \(setting)"
        case .getStats(let period):
            return "View \(period.capitalized) Stats"
        case .analyzeSessions:
            return "View Analysis"
        case .generateDailyPlan:
            return "View Daily Plan"
        case .suggestBreak:
            return "Break Suggestion"
        case .motivate:
            return "Get Motivated"
        case .generateWeeklyReport:
            return "Weekly Report"
        case .showWelcome:
            return "Welcome"
        }
    }
}

/// Typing indicator
struct TypingIndicator: View {
    let theme: AppTheme
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animationPhase = 0
            withAnimation {
                animationPhase = 1
            }
        }
    }
}

#Preview {
    NavigationView {
        AIChatView()
            .environmentObject(ProEntitlementManager.shared)
    }
}
