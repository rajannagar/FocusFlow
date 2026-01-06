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
        // No need to check for API key anymore - it's on the backend!
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
                                        .frame(minHeight: geo.size.height - 200)
                                } else {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message, theme: theme)
                                            .id(message.id)
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
                    
                    // Input area
                    inputSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Focus Ai")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your intelligent productivity companion")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 12) {
                    CapabilityRow(icon: "checkmark.circle.fill", text: "Create and manage tasks", theme: theme)
                    CapabilityRow(icon: "slider.horizontal.3", text: "Set and customize presets", theme: theme)
                    CapabilityRow(icon: "chart.bar.fill", text: "Analyze your productivity", theme: theme)
                    CapabilityRow(icon: "gearshape.fill", text: "Change app settings", theme: theme)
                    CapabilityRow(icon: "calendar", text: "View stats and insights", theme: theme)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
    
    private var apiKeySetupView: some View {
        ZStack {
            PremiumAppBackground(theme: theme)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.orange.opacity(0.3),
                                        Color.orange.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 220, height: 220)
                            .blur(radius: 50)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 80, weight: .ultraLight))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 24) {
                        Text("API Key Required")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("To use Focus AI, configure your OpenAI API key in Xcode.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        FFGlassCard(cornerRadius: 20, padding: 20) {
                            VStack(alignment: .leading, spacing: 20) {
                                PremiumSectionHeader(title: "SETUP INSTRUCTIONS")
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    InstructionRow(number: "1", text: "Get an API key from platform.openai.com/api-keys", theme: theme)
                                    InstructionRow(number: "2", text: "In Xcode, go to Product → Scheme → Edit Scheme", theme: theme)
                                    InstructionRow(number: "3", text: "Select 'Run' → 'Arguments' tab", theme: theme)
                                    InstructionRow(number: "4", text: "Add environment variable: OPENAI_API_KEY = your_key_here", theme: theme)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Supporting Views

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

struct InstructionRow: View {
    let number: String
    let text: String
    let theme: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentPrimary.opacity(0.25),
                                theme.accentSecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

/// Message bubble component with clean iMessage-style design
struct MessageBubble: View {
    let message: AIMessage
    let theme: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.sender == .user {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 10) {
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                message.sender == .user
                                    ? theme.accentPrimary
                                    : Color.white.opacity(0.08)
                            )
                    )
                
                if let action = message.action {
                    ActionButton(action: action, theme: theme)
                }
            }
            
            if message.sender == .assistant {
                Spacer(minLength: 50)
            }
        }
    }
}

/// Action button for AI-suggested actions
struct ActionButton: View {
    let action: AIAction
    let theme: AppTheme
    
    var body: some View {
        Button(action: {
            Haptics.impact(.light)
            Task {
                do {
                    try await AIActionHandler.shared.execute(action)
                } catch {
                    print("[ActionButton] Failed to execute action: \(error)")
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: actionIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(actionTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accentPrimary)
            )
        }
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
        }
    }
    
    private var actionTitle: String {
        switch action {
        case .createTask(let title, _, _):
            return "Create: \(title)"
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
            return "View \(period) Stats"
        case .analyzeSessions:
            return "View Analysis"
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
