import SwiftUI
import Combine

// MARK: - Flow Spotlight

/// A floating quick-access bubble that provides instant AI interaction from any screen
/// Expands into a compact chat input with smart suggestions

// MARK: - Spotlight State

enum SpotlightState: Equatable {
    case collapsed      // Small floating bubble
    case expanded       // Full input with suggestions
    case processing     // Waiting for AI response
    case showingResult  // Displaying quick response
}

// MARK: - Spotlight View Model

@MainActor
final class FlowSpotlightViewModel: ObservableObject {
    static let shared = FlowSpotlightViewModel()
    
    // MARK: - Published State
    
    @Published var state: SpotlightState = .collapsed
    @Published var inputText = ""
    @Published var quickResponse: String?
    @Published var quickActions: [SpotlightQuickAction] = []
    @Published var isVisible = true
    @Published var dragOffset: CGSize = .zero
    @Published var position: SpotlightPosition = .bottomRight
    
    // MARK: - Services
    
    private let flowService = FlowService.shared
    private let actionHandler = FlowActionHandler.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        loadQuickActions()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Periodically check focus state and collapse if needed
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if FocusSessionHelper.isRunning {
                    self?.collapse()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadQuickActions() {
        // Context-aware quick actions
        updateQuickActions()
    }
    
    // MARK: - Quick Actions
    
    func updateQuickActions() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        var actions: [SpotlightQuickAction] = []
        
        // Time-based suggestions
        if hour >= 6 && hour < 12 {
            actions.append(SpotlightQuickAction(
                icon: "sun.max.fill",
                title: "Plan my morning",
                prompt: "Help me plan a productive morning"
            ))
        } else if hour >= 12 && hour < 17 {
            actions.append(SpotlightQuickAction(
                icon: "bolt.fill",
                title: "Quick focus",
                prompt: "Start a 25 minute focus session"
            ))
        } else {
            actions.append(SpotlightQuickAction(
                icon: "moon.fill",
                title: "Wrap up my day",
                prompt: "How did my day go? Show me a summary"
            ))
        }
        
        // Always available
        actions.append(SpotlightQuickAction(
            icon: "plus.circle.fill",
            title: "Add task",
            prompt: "Add a new task"
        ))
        
        actions.append(SpotlightQuickAction(
            icon: "chart.bar.fill",
            title: "My progress",
            prompt: "Show me my progress this week"
        ))
        
        quickActions = actions
    }
    
    // MARK: - Actions
    
    func expand() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state = .expanded
        }
        Haptics.impact(.medium)
        updateQuickActions()
    }
    
    func collapse() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            state = .collapsed
            inputText = ""
            quickResponse = nil
        }
        Haptics.impact(.light)
    }
    
    func submit() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let query = inputText
        inputText = ""
        
        withAnimation {
            state = .processing
        }
        
        Haptics.impact(.medium)
        
        Task {
            await processQuery(query)
        }
    }
    
    func selectQuickAction(_ action: SpotlightQuickAction) {
        inputText = action.prompt
        submit()
    }
    
    // MARK: - Query Processing
    
    private func processQuery(_ query: String) async {
        do {
            // Build minimal context for quick responses
            let context = LazyContextBuilder.buildMinimalContext()
            
            // Get response from AI (empty history for quick queries)
            let response = try await flowService.sendMessage(
                userMessage: query,
                conversationHistory: [],
                context: context
            )
            
            await MainActor.run {
                // Execute any actions
                for action in response.actions {
                    Task {
                        _ = try? await actionHandler.execute(action)
                    }
                }
                
                // Show quick response
                withAnimation(.spring(response: 0.3)) {
                    quickResponse = response.content
                    state = .showingResult
                }
                
                // Auto-collapse after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                    if self?.state == .showingResult {
                        self?.collapse()
                    }
                }
            }
        } catch {
            await MainActor.run {
                quickResponse = "Sorry, couldn't process that. Try again?"
                state = .showingResult
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.collapse()
                }
            }
        }
    }
    
    // MARK: - Positioning
    
    func updatePosition(to position: SpotlightPosition) {
        withAnimation(.spring(response: 0.3)) {
            self.position = position
        }
        dragOffset = .zero
    }
    
    func handleDragEnd(translation: CGSize, screenSize: CGSize) {
        let centerX = screenSize.width / 2
        let currentX = position.offset(for: screenSize).width + translation.width
        
        // Snap to nearest edge
        if currentX < centerX {
            position = position.isTop ? .topLeft : .bottomLeft
        } else {
            position = position.isTop ? .topRight : .bottomRight
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
        }
        
        Haptics.impact(.light)
    }
}

// MARK: - Spotlight Position

enum SpotlightPosition {
    case topLeft, topRight, bottomLeft, bottomRight
    
    var isTop: Bool {
        self == .topLeft || self == .topRight
    }
    
    func offset(for screenSize: CGSize) -> CGSize {
        let padding: CGFloat = 16
        let bubbleSize: CGFloat = 56
        
        switch self {
        case .topLeft:
            return CGSize(width: padding + bubbleSize / 2, height: 100)
        case .topRight:
            return CGSize(width: screenSize.width - padding - bubbleSize / 2, height: 100)
        case .bottomLeft:
            return CGSize(width: padding + bubbleSize / 2, height: screenSize.height - 150)
        case .bottomRight:
            return CGSize(width: screenSize.width - padding - bubbleSize / 2, height: screenSize.height - 150)
        }
    }
}

// MARK: - Quick Action Model

struct SpotlightQuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let prompt: String
}

// MARK: - Spotlight View

struct FlowSpotlightView: View {
    @StateObject private var viewModel = FlowSpotlightViewModel.shared
    @ObservedObject private var entitlementManager = ProEntitlementManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    let theme: AppTheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dimming when expanded
                if viewModel.state != .collapsed {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.collapse()
                        }
                        .transition(.opacity)
                }
                
                // Main spotlight content
                spotlightContent
                    .position(spotlightPosition(for: geometry.size))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.state)
    }
    
    private func spotlightPosition(for screenSize: CGSize) -> CGPoint {
        let baseOffset = viewModel.position.offset(for: screenSize)
        
        if viewModel.state == .collapsed {
            return CGPoint(
                x: baseOffset.width + viewModel.dragOffset.width,
                y: baseOffset.height + viewModel.dragOffset.height
            )
        } else {
            // Center when expanded
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
    }
    
    @ViewBuilder
    private var spotlightContent: some View {
        switch viewModel.state {
        case .collapsed:
            collapsedBubble
        case .expanded:
            expandedPanel
        case .processing:
            processingPanel
        case .showingResult:
            resultPanel
        }
    }
    
    // MARK: - Collapsed Bubble
    
    private var collapsedBubble: some View {
        Button {
            // Check if Pro or has spotlight access
            if entitlementManager.isPro {
                viewModel.expand()
            } else {
                // Show paywall
                FlowNavigationCoordinator.shared.showPaywall(context: .ai)
            }
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accentPrimary.opacity(0.3),
                                theme.accentPrimary.opacity(0)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)
                
                // Main bubble
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentPrimary,
                                theme.accentSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 4)
                
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(SpotlightBubbleButtonStyle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.dragOffset = value.translation
                }
                .onEnded { value in
                    viewModel.handleDragEnd(
                        translation: value.translation,
                        screenSize: UIScreen.main.bounds.size
                    )
                }
        )
    }
    
    // MARK: - Expanded Panel
    
    private var expandedPanel: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Flow")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    viewModel.collapse()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Input field
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $viewModel.inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.submit()
                    }
                
                Button {
                    viewModel.submit()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: viewModel.inputText.isEmpty
                                    ? [Color.white.opacity(0.3), Color.white.opacity(0.3)]
                                    : [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(25)
            
            // Quick actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.quickActions) { action in
                        quickActionChip(action)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
    }
    
    private func quickActionChip(_ action: SpotlightQuickAction) -> some View {
        Button {
            viewModel.selectQuickAction(action)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 12))
                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Processing Panel
    
    private var processingPanel: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(theme.accentPrimary.opacity(0.3))
                .frame(width: 60, height: 60)
                .flowPulseGlow(color: theme.accentPrimary)
            
            Text("Thinking...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.3), radius: 20)
    }
    
    // MARK: - Result Panel
    
    private var resultPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Flow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    viewModel.collapse()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text(viewModel.quickResponse ?? "Done!")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20)
        .onTapGesture {
            viewModel.collapse()
        }
    }
}

// MARK: - Button Style

struct SpotlightBubbleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Spotlight Overlay Modifier

struct SpotlightOverlayModifier: ViewModifier {
    let theme: AppTheme
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isEnabled {
                FlowSpotlightView(theme: theme)
            }
        }
    }
}

extension View {
    func flowSpotlight(theme: AppTheme, isEnabled: Bool = true) -> some View {
        modifier(SpotlightOverlayModifier(theme: theme, isEnabled: isEnabled))
    }
}
