import SwiftUI
import Combine

// MARK: - Flow Hint System

/// Contextual AI hints that appear throughout the app
/// Smart, non-intrusive suggestions based on user behavior and context

// MARK: - Hint Type

enum FlowHintType: String, CaseIterable {
    case suggestion      // "You usually focus around this time"
    case reminder        // "Task X is due in 2 hours"
    case celebration     // "You hit your daily goal!"
    case tip            // "Pro tip: Try the Pomodoro technique"
    case streak         // "Keep your 7-day streak alive!"
    case motivation     // "You're doing great, keep going!"
    case insight        // "You're 40% more productive in mornings"
    
    var icon: String {
        switch self {
        case .suggestion: return "lightbulb.fill"
        case .reminder: return "bell.fill"
        case .celebration: return "party.popper.fill"
        case .tip: return "star.fill"
        case .streak: return "flame.fill"
        case .motivation: return "heart.fill"
        case .insight: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .suggestion: return .blue
        case .reminder: return .orange
        case .celebration: return .yellow
        case .tip: return .purple
        case .streak: return .red
        case .motivation: return .pink
        case .insight: return .green
        }
    }
}

// MARK: - Hint Model

struct FlowHint: Identifiable, Equatable {
    let id: UUID
    let type: FlowHintType
    let title: String
    let message: String
    let primaryAction: HintAction?
    let secondaryAction: HintAction?
    let context: HintContext
    let priority: HintPriority
    let expiresAt: Date?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: FlowHintType,
        title: String,
        message: String,
        primaryAction: HintAction? = nil,
        secondaryAction: HintAction? = nil,
        context: HintContext = .general,
        priority: HintPriority = .normal,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.context = context
        self.priority = priority
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }
    
    static func == (lhs: FlowHint, rhs: FlowHint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hint Action

struct HintAction: Equatable {
    let label: String
    let action: FlowAction?
    let systemAction: SystemAction?
    
    enum SystemAction: Equatable {
        case dismiss
        case openChat
        case startFocus(minutes: Int)
        case showTask(id: UUID)
        case navigateToTab(AppTab)
        
        static func == (lhs: SystemAction, rhs: SystemAction) -> Bool {
            switch (lhs, rhs) {
            case (.dismiss, .dismiss): return true
            case (.openChat, .openChat): return true
            case (.startFocus(let m1), .startFocus(let m2)): return m1 == m2
            case (.showTask(let id1), .showTask(let id2)): return id1 == id2
            case (.navigateToTab(let t1), .navigateToTab(let t2)): return t1 == t2
            default: return false
            }
        }
    }
    
    static func == (lhs: HintAction, rhs: HintAction) -> Bool {
        lhs.label == rhs.label
    }
}

// MARK: - Hint Context

enum HintContext: String {
    case general
    case focusTab
    case tasksTab
    case progressTab
    case profileTab
    case flowTab
    case onboarding
}

// MARK: - Hint Priority

enum HintPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    static func < (lhs: HintPriority, rhs: HintPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Hint Manager

@MainActor
final class FlowHintManager: ObservableObject {
    static let shared = FlowHintManager()
    
    // MARK: - Published State
    
    @Published private(set) var currentHint: FlowHint?
    @Published private(set) var hintQueue: [FlowHint] = []
    @Published var isHintDismissed = false
    @Published var lastDismissedHintType: FlowHintType?
    
    // MARK: - Configuration
    
    private let maxHintsPerHour = 3
    private let cooldownBetweenHints: TimeInterval = 120 // 2 minutes
    
    // MARK: - State
    
    private var hintsShownThisHour: Int = 0
    private var lastHintShownAt: Date?
    private var dismissedHintIDs: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()
    
    // User preferences
    private let hintsEnabledKey = "flow_hints_enabled"
    private let dismissedTypesKey = "flow_dismissed_hint_types"
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        resetHourlyCounter()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Reset hourly counter each hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.resetHourlyCounter()
            }
            .store(in: &cancellables)
        
        // Check for expired hints
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredHints()
            }
            .store(in: &cancellables)
    }
    
    private func resetHourlyCounter() {
        hintsShownThisHour = 0
    }
    
    private func cleanupExpiredHints() {
        let now = Date()
        hintQueue.removeAll { hint in
            if let expiresAt = hint.expiresAt, expiresAt < now {
                return true
            }
            return false
        }
        
        // Check if current hint expired
        if let current = currentHint,
           let expiresAt = current.expiresAt,
           expiresAt < now {
            dismissCurrentHint()
        }
    }
    
    // MARK: - Hint Management
    
    /// Show a hint to the user
    func showHint(_ hint: FlowHint) {
        // Check if hints are enabled
        guard UserDefaults.standard.bool(forKey: hintsEnabledKey) != false else { return }
        
        // Check rate limit
        guard canShowHint() else {
            // Add to queue for later
            queueHint(hint)
            return
        }
        
        // Check if hint type was dismissed recently
        if let lastDismissed = lastDismissedHintType,
           lastDismissed == hint.type {
            return
        }
        
        // Show the hint
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentHint = hint
            isHintDismissed = false
        }
        
        hintsShownThisHour += 1
        lastHintShownAt = Date()
        
        Haptics.impact(.light)
    }
    
    /// Queue a hint for later
    private func queueHint(_ hint: FlowHint) {
        // Don't queue duplicates
        guard !hintQueue.contains(where: { $0.id == hint.id }) else { return }
        
        // Insert based on priority
        if let index = hintQueue.firstIndex(where: { $0.priority < hint.priority }) {
            hintQueue.insert(hint, at: index)
        } else {
            hintQueue.append(hint)
        }
        
        // Limit queue size
        if hintQueue.count > 10 {
            hintQueue = Array(hintQueue.prefix(10))
        }
    }
    
    /// Dismiss the current hint
    func dismissCurrentHint() {
        guard let current = currentHint else { return }
        
        withAnimation(.easeOut(duration: 0.25)) {
            isHintDismissed = true
        }
        
        dismissedHintIDs.insert(current.id)
        lastDismissedHintType = current.type
        
        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentHint = nil
            self?.showNextQueuedHint()
        }
        
        Haptics.impact(.light)
    }
    
    /// Show next hint from queue
    private func showNextQueuedHint() {
        guard !hintQueue.isEmpty, canShowHint() else { return }
        
        // Wait for cooldown
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownBetweenHints) { [weak self] in
            guard let self = self,
                  let nextHint = self.hintQueue.first else { return }
            
            self.hintQueue.removeFirst()
            self.showHint(nextHint)
        }
    }
    
    /// Execute hint action
    func executeAction(_ action: HintAction) {
        if let systemAction = action.systemAction {
            executeSystemAction(systemAction)
        } else if let flowAction = action.action {
            Task {
                _ = try? await FlowActionHandler.shared.execute(flowAction)
            }
        }
        
        dismissCurrentHint()
    }
    
    private func executeSystemAction(_ action: HintAction.SystemAction) {
        switch action {
        case .dismiss:
            break // Just dismiss
        case .openChat:
            FlowNavigationCoordinator.shared.navigateTo(tab: .flow)
        case .startFocus(let minutes):
            FlowActionHandler.shared.focusControlRequest = FlowActionHandler.FocusControlRequest(
                action: .start(minutes: minutes, presetID: nil, sessionName: nil)
            )
            FlowNavigationCoordinator.shared.navigateTo(tab: .focus)
        case .showTask(_):
            FlowNavigationCoordinator.shared.navigateTo(tab: .tasks)
            // Could add task-specific navigation here
        case .navigateToTab(let tab):
            FlowNavigationCoordinator.shared.navigateTo(tab: tab)
        }
    }
    
    // MARK: - Rate Limiting
    
    private func canShowHint() -> Bool {
        // Check hourly limit
        guard hintsShownThisHour < maxHintsPerHour else { return false }
        
        // Check cooldown
        if let lastShown = lastHintShownAt {
            let elapsed = Date().timeIntervalSince(lastShown)
            guard elapsed >= cooldownBetweenHints else { return false }
        }
        
        // Don't show if one is already visible
        guard currentHint == nil else { return false }
        
        return true
    }
    
    // MARK: - Settings
    
    var hintsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: hintsEnabledKey) != false }
        set { UserDefaults.standard.set(newValue, forKey: hintsEnabledKey) }
    }
    
    func disableHintType(_ type: FlowHintType) {
        var dismissedTypes = UserDefaults.standard.stringArray(forKey: dismissedTypesKey) ?? []
        if !dismissedTypes.contains(type.rawValue) {
            dismissedTypes.append(type.rawValue)
            UserDefaults.standard.set(dismissedTypes, forKey: dismissedTypesKey)
        }
    }
    
    func isHintTypeEnabled(_ type: FlowHintType) -> Bool {
        let dismissedTypes = UserDefaults.standard.stringArray(forKey: dismissedTypesKey) ?? []
        return !dismissedTypes.contains(type.rawValue)
    }
}

// MARK: - Hint View

struct FlowHintView: View {
    let hint: FlowHint
    let theme: AppTheme
    let onDismiss: () -> Void
    let onAction: (HintAction) -> Void
    
    @State private var isAppearing = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(hint.type.accentColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: hint.type.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(hint.type.accentColor)
                }
                
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Flow")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(hint.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                }
            }
            
            // Message
            Text(hint.message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
            
            // Actions
            if hint.primaryAction != nil || hint.secondaryAction != nil {
                HStack(spacing: 10) {
                    if let secondary = hint.secondaryAction {
                        Button {
                            onAction(secondary)
                        } label: {
                            Text(secondary.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    
                    if let primary = hint.primaryAction {
                        Button {
                            onAction(primary)
                        } label: {
                            Text(primary.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.accentPrimary, theme.accentSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    hint.type.accentColor.opacity(0.4),
                                    hint.type.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .offset(y: dragOffset)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.9)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height * 0.5
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Hint Container Modifier

struct FlowHintContainerModifier: ViewModifier {
    let context: HintContext
    let theme: AppTheme
    
    @ObservedObject private var hintManager = FlowHintManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let hint = hintManager.currentHint,
               hint.context == context || hint.context == .general,
               !hintManager.isHintDismissed {
                FlowHintView(
                    hint: hint,
                    theme: theme,
                    onDismiss: {
                        hintManager.dismissCurrentHint()
                    },
                    onAction: { action in
                        hintManager.executeAction(action)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

extension View {
    func flowHints(context: HintContext, theme: AppTheme) -> some View {
        modifier(FlowHintContainerModifier(context: context, theme: theme))
    }
}

// MARK: - Hint Factory

extension FlowHintManager {
    
    /// Create contextual hints based on app state
    func generateContextualHint(for context: HintContext) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        switch context {
        case .focusTab:
            generateFocusHint(hour: hour)
        case .tasksTab:
            generateTasksHint()
        case .progressTab:
            generateProgressHint()
        default:
            break
        }
    }
    
    private func generateFocusHint(hour: Int) {
        // Check if user typically focuses at this time
        let peakHours = FlowContext.shared.memory.peakProductivityHours
        
        if peakHours.contains(hour) {
            let hint = FlowHint(
                type: .suggestion,
                title: "Perfect timing!",
                message: "You're usually most productive around this hour. Ready for a focus session?",
                primaryAction: HintAction(
                    label: "Start Focus",
                    action: nil,
                    systemAction: .startFocus(minutes: FlowContext.shared.memory.preferredFocusDuration ?? 25)
                ),
                secondaryAction: HintAction(
                    label: "Not now",
                    action: nil,
                    systemAction: .dismiss
                ),
                context: .focusTab,
                priority: .normal
            )
            showHint(hint)
        }
    }
    
    private func generateTasksHint() {
        let tasks = TasksStore.shared.tasks
        let calendar = Calendar.current
        
        // Check for tasks due soon
        let upcomingTasks = tasks.filter { task in
            guard let reminder = task.reminderDate else { return false }
            let hoursUntilDue = calendar.dateComponents([.hour], from: Date(), to: reminder).hour ?? 0
            return hoursUntilDue > 0 && hoursUntilDue <= 2
        }
        
        if let urgentTask = upcomingTasks.first {
            let hint = FlowHint(
                type: .reminder,
                title: "Coming up soon",
                message: "\"\(urgentTask.title)\" is due in less than 2 hours",
                primaryAction: HintAction(
                    label: "Focus on this",
                    action: nil,
                    systemAction: .startFocus(minutes: urgentTask.durationMinutes > 0 ? urgentTask.durationMinutes : 25)
                ),
                secondaryAction: HintAction(
                    label: "Dismiss",
                    action: nil,
                    systemAction: .dismiss
                ),
                context: .tasksTab,
                priority: .high,
                expiresAt: urgentTask.reminderDate
            )
            showHint(hint)
        }
    }
    
    private func generateProgressHint() {
        let progress = ProgressStore.shared
        let todayMinutes = Int(progress.totalToday / 60)
        let goal = progress.dailyGoalMinutes
        
        // Check if close to goal
        let percentComplete = goal > 0 ? Double(todayMinutes) / Double(goal) : 0
        
        if percentComplete >= 0.8 && percentComplete < 1.0 {
            let remaining = goal - todayMinutes
            let hint = FlowHint(
                type: .motivation,
                title: "Almost there! 💪",
                message: "Just \(remaining) more minutes to hit your daily goal. You've got this!",
                primaryAction: HintAction(
                    label: "Finish strong",
                    action: nil,
                    systemAction: .startFocus(minutes: remaining)
                ),
                secondaryAction: HintAction(
                    label: "Later",
                    action: nil,
                    systemAction: .dismiss
                ),
                context: .progressTab,
                priority: .high
            )
            showHint(hint)
        } else if percentComplete >= 1.0 {
            let hint = FlowHint(
                type: .celebration,
                title: "Goal achieved! 🎉",
                message: "You hit your daily focus goal. Amazing work today!",
                primaryAction: HintAction(
                    label: "View stats",
                    action: nil,
                    systemAction: .navigateToTab(.progress)
                ),
                context: .progressTab,
                priority: .normal
            )
            showHint(hint)
        }
    }
}
