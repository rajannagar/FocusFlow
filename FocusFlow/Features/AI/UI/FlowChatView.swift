import SwiftUI

// MARK: - Flow Chat View

/// Ultra-premium ChatGPT-level chat interface for Flow AI
struct FlowChatView: View {
    @StateObject private var viewModel = FlowChatViewModel()
    @StateObject private var voiceManager = FlowVoiceInputManager.shared
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var showPaywall = false
    @State private var showClearConfirmation = false
    @State private var showInfoSheet = false
    @State private var showVoiceInput = false
    @State private var animateGradient = false
    @FocusState private var isInputFocused: Bool
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    var body: some View {
        Group {
            if pro.isPro {
                chatInterface
            } else {
                paywallPrompt
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .ai)
        }
        .sheet(isPresented: $showInfoSheet) {
            FlowInfoSheet(theme: theme)
        }
        .sheet(isPresented: $showVoiceInput) {
            voiceInputSheet
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
                .presentationCornerRadius(32)
        }
    }
    
    // MARK: - Voice Input Sheet
    
    @State private var voicePulseAnimation = false
    
    private var voiceInputSheet: some View {
        ZStack {
            // Premium themed background with rounded corners
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            theme.accentPrimary.opacity(0.15),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Subtle radial glow behind mic
            RadialGradient(
                colors: [
                    theme.accentPrimary.opacity(voiceManager.isListening ? 0.3 : 0.1),
                    theme.accentSecondary.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .offset(y: 20)
            
            VStack(spacing: 20) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                // Header
                HStack {
                    HStack(spacing: 10) {
                        // Animated listening indicator
                        if voiceManager.isListening {
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(theme.accentPrimary)
                                        .frame(width: 3, height: voicePulseAnimation ? 16 : 8)
                                        .animation(
                                            .easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.15),
                                            value: voicePulseAnimation
                                        )
                                }
                            }
                        }
                        
                        Text(voiceManager.isListening ? "Listening..." : "Voice Input")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        Haptics.impact(.light)
                        Task {
                            await voiceManager.stopListening()
                            voiceManager.clearTranscription()
                        }
                        showVoiceInput = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .padding(.horizontal, 4)
                
                Spacer()
                
                // Voice visualization
                ZStack {
                    // Outer animated pulse rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.accentPrimary.opacity(0.4 - Double(index) * 0.12),
                                        theme.accentSecondary.opacity(0.2 - Double(index) * 0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: voiceManager.isListening ? 2 : 1
                            )
                            .frame(width: 100 + CGFloat(index * 35), height: 100 + CGFloat(index * 35))
                            .scaleEffect(voiceManager.isListening ? 1 + CGFloat(voiceManager.audioLevel) * 0.4 : 1)
                            .opacity(voiceManager.isListening ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.15), value: voiceManager.audioLevel)
                    }
                    
                    // Glow effect when listening
                    if voiceManager.isListening {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        theme.accentPrimary.opacity(0.4),
                                        theme.accentSecondary.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                    }
                    
                    // Center microphone button
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: voiceManager.isListening 
                                        ? [theme.accentPrimary, theme.accentSecondary]
                                        : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: voiceManager.isListening ? theme.accentPrimary.opacity(0.5) : .clear, radius: 20)
                        
                        // Inner glow
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(voiceManager.isListening ? 0.4 : 0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 88, height: 88)
                        
                        Image(systemName: voiceManager.isListening ? "waveform" : "mic.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundColor(.white)
                            .symbolEffect(.variableColor.iterative, isActive: voiceManager.isListening)
                    }
                    .scaleEffect(voiceManager.isListening ? 1.0 : 0.95)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: voiceManager.isListening)
                    .onTapGesture {
                        Haptics.impact(.medium)
                        Task {
                            if voiceManager.isListening {
                                await voiceManager.stopListening()
                            } else {
                                await voiceManager.startListening()
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                Spacer()
                
                // Transcribed text area
                VStack(spacing: 12) {
                    if !voiceManager.transcribedText.isEmpty {
                        Text(voiceManager.transcribedText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: voiceManager.transcribedText)
                    } else {
                        Text(voiceManager.isListening ? "Speak now..." : "Tap the mic to start")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.vertical, 20)
                    }
                }
                .frame(minHeight: 80)
                
                // Error message
                if let error = voiceManager.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(error.localizedDescription)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(20)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button {
                        Haptics.impact(.light)
                        Task {
                            await voiceManager.stopListening()
                            voiceManager.clearTranscription()
                        }
                        showVoiceInput = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Send button
                    if !voiceManager.transcribedText.isEmpty {
                        Button {
                            Haptics.impact(.medium)
                            let text = voiceManager.transcribedText
                            Task {
                                await voiceManager.stopListening()
                                voiceManager.clearTranscription()
                            }
                            showVoiceInput = false
                            // Send to AI
                            viewModel.inputText = text
                            viewModel.sendMessage()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Send")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: theme.accentPrimary.opacity(0.4), radius: 10, y: 4)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: voiceManager.transcribedText.isEmpty)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.xl)
        }
        .onAppear {
            voicePulseAnimation = true
            // Auto-start listening with slight delay for sheet animation
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
                await voiceManager.startListening()
            }
        }
        .onDisappear {
            voicePulseAnimation = false
            Task {
                await voiceManager.stopListening()
            }
        }
    }
    
    // MARK: - Chat Interface
    
    private var chatInterface: some View {
        GeometryReader { geo in
            ZStack {
                // Premium background
                PremiumAppBackground(theme: theme, particleCount: 15)
                
                VStack(spacing: 0) {
                    // Header
                    flowHeaderSection
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.top, DS.Spacing.sm)
                        .padding(.bottom, DS.Spacing.xxs)
                    
                    // Messages area
                    messagesScrollView(geometry: geo)
                    
                    // Quick suggestions (contextual)
                    if viewModel.messages.isEmpty || viewModel.messages.count <= 2 {
                        suggestionChipsSection
                            .padding(.top, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if !viewModel.quickActions.isEmpty && !viewModel.isLoading {
                        quickActionsSection
                            .padding(.top, 8)
                    }
                    
                    // Input area
                    inputSection
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.md)
                        .padding(.bottom, DS.Spacing.xxs)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Start Fresh?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Chat", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.clearHistory()
                }
            }
        } message: {
            Text("This will clear your conversation. Flow will still remember your preferences.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
            if viewModel.messages.last?.state == .failed {
                Button("Retry") { viewModel.retryLastMessage() }
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
    
    // MARK: - Flow Header Section
    
    private var flowHeaderSection: some View {
        HStack(spacing: 12) {
            // Logo + Title
            HStack(spacing: 10) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("Flow")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Clear button
            Button {
                if !viewModel.messages.isEmpty {
                    showClearConfirmation = true
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.messages.isEmpty ? .white.opacity(0.3) : .white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(viewModel.messages.isEmpty ? 0.03 : 0.06))
                    .clipShape(Circle())
            }
            .disabled(viewModel.messages.isEmpty)
            
            // Info button
            Button {
                Haptics.impact(.light)
                showInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private func messagesScrollView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    // Status card at top
                    if let statusCard = viewModel.statusCard {
                        FlowStatusCard(data: statusCard, theme: theme)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    // Empty state
                    if viewModel.messages.isEmpty {
                        emptyStateView
                            .frame(minHeight: geometry.size.height - 400)
                    } else {
                        // Messages
                        ForEach(viewModel.messages) { message in
                            FlowMessageBubble(message: message, theme: theme)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                        
                        // Typing indicator
                        if viewModel.isLoading && !viewModel.isStreaming {
                            FlowTypingIndicator(theme: theme)
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 28) {
            // Animated AI Icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentPrimary.opacity(0.3 - Double(i) * 0.1), theme.accentSecondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(90 + i * 30), height: CGFloat(90 + i * 30))
                        .scaleEffect(animateGradient ? 1.1 : 1.0)
                        .opacity(animateGradient ? 0.6 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                            value: animateGradient
                        )
                }
                
                // Center circle
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
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateGradient ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateGradient
                    )
            }
            .onAppear {
                animateGradient = true
            }
            
            VStack(spacing: 10) {
                Text(greetingText)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("I'm your AI productivity companion")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Example prompts
            VStack(spacing: 12) {
                Text("Try asking:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)
                
                VStack(spacing: 10) {
                    ForEach(examplePrompts, id: \.self) { prompt in
                        ExamplePromptButton(prompt: prompt, theme: theme) {
                            viewModel.inputText = prompt
                            viewModel.sendMessage()
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let rawName = AppSettings.shared.displayName
        let name = rawName.isEmpty ? "there" : (rawName.components(separatedBy: " ").first ?? "there")
        
        if hour < 12 {
            return "Good morning, \(name)!"
        } else if hour < 17 {
            return "Good afternoon, \(name)!"
        } else {
            return "Good evening, \(name)!"
        }
    }
    
    private var examplePrompts: [String] {
        [
            "Plan my day",
            "Start a 25 min focus session",
            "What are my tasks for today?"
        ]
    }
    
    // MARK: - Suggestion Chips
    
    private var suggestionChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(contextualSuggestions) { suggestion in
                    FlowSuggestionChip(suggestion: suggestion, theme: theme) {
                        Haptics.impact(.light)
                        viewModel.inputText = suggestion.prompt
                        viewModel.sendMessage()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var contextualSuggestions: [FlowSuggestion] {
        let hour = Calendar.current.component(.hour, from: Date())
        let todayMinutes = viewModel.statusCard?.focusedMinutes ?? 0
        let goalMinutes = viewModel.statusCard?.goalMinutes ?? 60
        let tasksCount = viewModel.statusCard?.tasksCount ?? 0
        
        var suggestions: [FlowSuggestion] = []
        
        // Time-based primary suggestion
        if hour >= 5 && hour < 12 {
            suggestions.append(FlowSuggestion(id: "morning", icon: "sun.max.fill", label: "Plan my day", prompt: "Help me plan my day"))
        } else if hour >= 12 && hour < 14 {
            suggestions.append(FlowSuggestion(id: "midday", icon: "cup.and.saucer.fill", label: "Lunch break?", prompt: "Should I take a lunch break?"))
        } else if hour >= 17 {
            suggestions.append(FlowSuggestion(id: "evening", icon: "moon.stars.fill", label: "Day review", prompt: "How was my productivity today?"))
        }
        
        // Progress-based
        if todayMinutes == 0 {
            suggestions.append(FlowSuggestion(id: "start", icon: "play.fill", label: "Start focus", prompt: "Start a 25 minute focus session"))
        } else if todayMinutes < goalMinutes {
            suggestions.append(FlowSuggestion(id: "progress", icon: "chart.line.uptrend.xyaxis", label: "My progress", prompt: "How am I doing on my daily goal?"))
        } else {
            suggestions.append(FlowSuggestion(id: "celebrate", icon: "star.fill", label: "Goal reached! 🎉", prompt: "I reached my daily goal!"))
        }
        
        // Tasks-based
        if tasksCount > 0 {
            suggestions.append(FlowSuggestion(id: "tasks", icon: "checklist", label: "\(tasksCount) tasks", prompt: "What are my tasks for today?"))
        } else {
            suggestions.append(FlowSuggestion(id: "add", icon: "plus.circle.fill", label: "Add task", prompt: "Help me add a new task"))
        }
        
        // Always offer these
        suggestions.append(FlowSuggestion(id: "presets", icon: "slider.horizontal.3", label: "My presets", prompt: "Show me my focus presets"))
        suggestions.append(FlowSuggestion(id: "motivate", icon: "flame.fill", label: "Motivate me", prompt: "Give me some motivation!"))
        
        return Array(suggestions.prefix(5))
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.quickActions) { action in
                    FlowQuickActionChip(action: action, theme: theme) {
                        viewModel.sendQuickAction(action)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            // Voice button (left side, only shows when input is empty)
            if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                Button {
                    Haptics.impact(.medium)
                    showVoiceInput = true
                    Task {
                        await voiceManager.startListening()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Text input
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accentPrimary.opacity(0.7))
                
                TextField("Ask Flow anything...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.sendMessage()
                        }
                    }
                
                Spacer(minLength: 0)
                
                // Send button
                Button(action: {
                    Haptics.impact(.light)
                    if viewModel.isStreaming {
                        viewModel.cancelStreaming()
                    } else {
                        viewModel.sendMessage()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(sendButtonGradient)
                            .frame(width: 36, height: 36)
                        
                        if viewModel.isLoading {
                            if viewModel.isStreaming {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isStreaming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.accentPrimary.opacity(isInputFocused ? 0.5 : 0.15), theme.accentSecondary.opacity(isInputFocused ? 0.3 : 0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.inputText.isEmpty)
    }
    
    private var sendButtonGradient: LinearGradient {
        let isEmpty = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isDisabled = isEmpty && !viewModel.isStreaming
        
        return LinearGradient(
            colors: isDisabled
                ? [Color.white.opacity(0.15), Color.white.opacity(0.1)]
                : [theme.accentPrimary, theme.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Paywall Prompt
    
    private var paywallPrompt: some View {
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
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 70, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 16) {
                    Text("Meet Flow")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your AI-powered productivity companion.\nUnlock unlimited access with Pro.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Button(action: {
                    Haptics.impact(.medium)
                    showPaywall = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Upgrade to Pro")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DS.Radius.sm)
                    .shadow(color: theme.accentPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 60)
        }
    }
}

// MARK: - Flow Info Sheet

struct FlowInfoSheet: View {
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        theme.accentPrimary.opacity(0.1),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle radial glow
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(0.15),
                        theme.accentSecondary.opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 88, height: 88)
                                
                                Image("Focusflow_Logo")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            
                            Text("What can Flow do?")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Flow is your AI productivity assistant that can control your entire app with simple commands.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Capabilities
                        VStack(spacing: 20) {
                            FlowCapabilitySection(
                                title: "Focus Sessions",
                                icon: "timer",
                                theme: theme,
                                examples: [
                                    "\"Start a 25 minute focus session\"",
                                    "\"Pause my session\"",
                                    "\"Add 10 more minutes\"",
                                    "\"Start my Deep Work preset\""
                                ]
                            )
                            
                            FlowCapabilitySection(
                                title: "Task Management",
                                icon: "checklist",
                                theme: theme,
                                examples: [
                                    "\"Add a task: call mom at 5pm\"",
                                    "\"Create a daily task for gym at 9am\"",
                                    "\"Mark 'Morning Focus' as done\"",
                                    "\"What are my tasks for today?\""
                                ]
                            )
                            
                            FlowCapabilitySection(
                                title: "Presets & Settings",
                                icon: "slider.horizontal.3",
                                theme: theme,
                                examples: [
                                    "\"Create a 45 min preset called Deep Work\"",
                                    "\"Change my theme to forest\"",
                                    "\"Set my daily goal to 2 hours\"",
                                    "\"Open settings\""
                                ]
                            )
                            
                            FlowCapabilitySection(
                                title: "Progress & Analytics",
                                icon: "chart.bar.fill",
                                theme: theme,
                                examples: [
                                    "\"How am I doing today?\"",
                                    "\"Show my weekly report\"",
                                    "\"What's my current streak?\"",
                                    "\"Analyze my productivity\""
                                ]
                            )
                            
                            FlowCapabilitySection(
                                title: "Planning & Motivation",
                                icon: "lightbulb.fill",
                                theme: theme,
                                examples: [
                                    "\"Plan my day\"",
                                    "\"When should I take a break?\"",
                                    "\"Motivate me!\"",
                                    "\"What should I focus on next?\""
                                ]
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Pro tip
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Pro Tip")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Flow understands natural language. Just describe what you want and Flow will figure out the best way to help you!")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.accentPrimary)
                }
            }
        }
    }
}

struct FlowCapabilitySection: View {
    let title: String
    let icon: String
    let theme: AppTheme
    let examples: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                }
            }
            .padding(.leading, 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(Color.white.opacity(DS.Glass.thin))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(Color.white.opacity(DS.Glass.regular), lineWidth: 1)
                )
        )
    }
}

// MARK: - Example Prompt Button

struct ExamplePromptButton: View {
    let prompt: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\"" + prompt + "\"")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .italic()
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(Color.white.opacity(DS.Glass.subtle))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(Color.white.opacity(DS.Glass.borderMedium), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(FlowScaleButtonStyle())
    }
}

// MARK: - Suggestion Chip

struct FlowSuggestion: Identifiable {
    let id: String
    let icon: String
    let label: String
    let prompt: String
}

struct FlowSuggestionChip: View {
    let suggestion: FlowSuggestion
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(suggestion.label)
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
                                theme.accentPrimary.opacity(0.2),
                                theme.accentSecondary.opacity(0.12)
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
                                        theme.accentPrimary.opacity(0.4),
                                        theme.accentSecondary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(FlowChipButtonStyle())
    }
}

// MARK: - Flow Status Card

struct FlowStatusCard: View {
    let data: StatusCardData
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(data.percentage) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(data.percentage)%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(data.percentage, 100)) / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var statusText: String {
        if data.tasksCount > 0 {
            return "📋 \(data.tasksCount) task\(data.tasksCount == 1 ? "" : "s") today"
        } else {
            return "✨ No tasks scheduled"
        }
    }
    
    private var subText: String {
        "\(data.focusedMinutes) min focused • Goal: \(data.goalMinutes) min"
    }
}

// MARK: - Flow Message Bubble

struct FlowMessageBubble: View {
    let message: FlowMessage
    let theme: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.sender == .user {
                Spacer(minLength: 50)
            } else {
                // Flow avatar
                flowAvatar
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 8) {
                // Message content
                messageContent
                
                // Actions (if any and completed)
                if let actions = message.actions, !actions.isEmpty, message.state == .complete {
                    FlowActionButtons(actions: actions, theme: theme)
                }
            }
            
            if message.sender == .user {
                // No avatar for user
            } else {
                Spacer(minLength: 40)
            }
        }
    }
    
    private var flowAvatar: some View {
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var messageContent: some View {
        Text(message.content)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.white)
            .lineSpacing(4)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .overlay(streamingOverlay)
    }
    
    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
            .fill(
                message.sender == .user
                    ? LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(DS.Glass.thick), Color.white.opacity(DS.Glass.subtle)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(
                        message.sender == .user ? Color.clear : Color.white.opacity(DS.Glass.regular),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: message.sender == .user ? theme.accentPrimary.opacity(0.15) : Color.clear,
                radius: 8, x: 0, y: 4
            )
    }
    
    @ViewBuilder
    private var streamingOverlay: some View {
        if message.state == .streaming {
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [theme.accentPrimary.opacity(0.5), theme.accentSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - Flow Action Buttons

struct FlowActionButtons: View {
    let actions: [FlowAction]
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(actions.prefix(2).enumerated()), id: \.offset) { _, action in
                FlowActionButton(action: action, theme: theme)
            }
        }
    }
}

struct FlowActionButton: View {
    let action: FlowAction
    let theme: AppTheme
    
    @State private var wasExecuted = true
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: wasExecuted ? "checkmark.circle.fill" : action.icon)
                .font(.system(size: 12, weight: .semibold))
            
            Text(wasExecuted ? "Done" : action.displayTitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(.white.opacity(wasExecuted ? 0.6 : 0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(wasExecuted ? Color.white.opacity(0.1) : theme.accentPrimary.opacity(0.8))
        )
    }
}

// MARK: - Flow Quick Action Chip

struct FlowQuickActionChip: View {
    let action: QuickAction
    let theme: AppTheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(action.label)
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
                                theme.accentPrimary.opacity(0.25),
                                theme.accentSecondary.opacity(0.15)
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
                                        theme.accentPrimary.opacity(0.4),
                                        theme.accentSecondary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(FlowChipButtonStyle())
    }
}

struct FlowChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Flow Typing Indicator

struct FlowTypingIndicator: View {
    let theme: AppTheme
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Dots
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.7)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        FlowChatView()
            .environmentObject(ProEntitlementManager.shared)
    }
    .preferredColorScheme(.dark)
}
