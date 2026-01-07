import SwiftUI
import Combine

// MARK: - Flow Performance Optimization

/// Performance optimization utilities for Flow AI
/// Includes caching, debouncing, and efficient context building

// MARK: - Focus Session Helper

/// Helper to check focus session state from UserDefaults
struct FocusSessionHelper {
    private static let defaults = UserDefaults.standard
    private static let isActiveKey = "FocusFlow.focusSession.isActive"
    private static let isPausedKey = "FocusFlow.focusSession.isPaused"
    private static let plannedSecondsKey = "FocusFlow.focusSession.plannedSeconds"
    private static let pausedRemainingKey = "FocusFlow.focusSession.pausedRemaining"
    
    static var isRunning: Bool {
        defaults.bool(forKey: isActiveKey) && !defaults.bool(forKey: isPausedKey)
    }
    
    static var isActive: Bool {
        defaults.bool(forKey: isActiveKey)
    }
    
    static var isPaused: Bool {
        defaults.bool(forKey: isPausedKey)
    }
    
    static var remainingMinutes: Int {
        let seconds = defaults.integer(forKey: pausedRemainingKey)
        return max(0, seconds / 60)
    }
}

// MARK: - Context Cache

/// Caches expensive context computations
@MainActor
final class FlowContextCache {
    static let shared = FlowContextCache()
    
    // MARK: - Cache Storage
    
    private var taskContextCache: CachedValue<String>?
    private var progressContextCache: CachedValue<String>?
    private var presetContextCache: CachedValue<String>?
    private var memoryContextCache: CachedValue<String>?
    private var fullContextCache: CachedValue<String>?
    
    // Cache settings
    private let taskCacheTTL: TimeInterval = 30 // 30 seconds
    private let progressCacheTTL: TimeInterval = 60 // 1 minute
    private let presetCacheTTL: TimeInterval = 120 // 2 minutes
    private let memoryCacheTTL: TimeInterval = 180 // 3 minutes
    private let fullContextTTL: TimeInterval = 15 // 15 seconds
    
    // MARK: - Cache Accessors
    
    /// Get cached task context or rebuild
    func getTaskContext() -> String {
        if let cached = taskContextCache, !cached.isExpired {
            return cached.value
        }
        
        let context = buildTaskContext()
        taskContextCache = CachedValue(value: context, ttl: taskCacheTTL)
        return context
    }
    
    /// Get cached progress context or rebuild
    func getProgressContext() -> String {
        if let cached = progressContextCache, !cached.isExpired {
            return cached.value
        }
        
        let context = buildProgressContext()
        progressContextCache = CachedValue(value: context, ttl: progressCacheTTL)
        return context
    }
    
    /// Get cached preset context or rebuild
    func getPresetContext() -> String {
        if let cached = presetContextCache, !cached.isExpired {
            return cached.value
        }
        
        let context = buildPresetContext()
        presetContextCache = CachedValue(value: context, ttl: presetCacheTTL)
        return context
    }
    
    /// Get cached memory context or rebuild
    func getMemoryContext() -> String {
        if let cached = memoryContextCache, !cached.isExpired {
            return cached.value
        }
        
        let context = FlowMemoryManager.shared.buildMemoryContext()
        memoryContextCache = CachedValue(value: context, ttl: memoryCacheTTL)
        return context
    }
    
    /// Get full cached context for AI
    func getFullContext() -> String {
        if let cached = fullContextCache, !cached.isExpired {
            return cached.value
        }
        
        let context = buildFullContext()
        fullContextCache = CachedValue(value: context, ttl: fullContextTTL)
        return context
    }
    
    // MARK: - Cache Invalidation
    
    /// Invalidate task cache when tasks change
    func invalidateTaskCache() {
        taskContextCache = nil
        fullContextCache = nil
    }
    
    /// Invalidate progress cache when progress changes
    func invalidateProgressCache() {
        progressContextCache = nil
        fullContextCache = nil
    }
    
    /// Invalidate preset cache when presets change
    func invalidatePresetCache() {
        presetContextCache = nil
        fullContextCache = nil
    }
    
    /// Invalidate all caches
    func invalidateAll() {
        taskContextCache = nil
        progressContextCache = nil
        presetContextCache = nil
        memoryContextCache = nil
        fullContextCache = nil
    }
    
    // MARK: - Context Builders
    
    private func buildTaskContext() -> String {
        let tasks = TasksStore.shared.tasks
        guard !tasks.isEmpty else {
            return "Tasks: No tasks created yet"
        }
        
        let today = Date()
        let incompleteTasks = tasks.filter { 
            !TasksStore.shared.isCompleted(taskId: $0.id, on: today) 
        }
        let completedToday = tasks.filter { task in
            TasksStore.shared.isCompleted(taskId: task.id, on: today)
        }.count
        
        var context = "Tasks Overview: \(tasks.count) total, \(incompleteTasks.count) pending, \(completedToday) completed today"
        
        // Add top 5 pending tasks
        if !incompleteTasks.isEmpty {
            context += "\n\nPending Tasks:"
            for task in incompleteTasks.prefix(5) {
                let dueInfo = task.reminderDate.map { " (due: \(formatDate($0)))" } ?? ""
                context += "\n- \(task.title) (\(task.durationMinutes)min)\(dueInfo)"
            }
        }
        
        return context
    }
    
    private func buildProgressContext() -> String {
        let progress = ProgressStore.shared
        let todayMinutes = Int(progress.totalToday / 60)
        let goal = progress.dailyGoalMinutes
        let streak = progress.lifetimeBestStreak
        let sessions = progress.sessions.filter {
            Calendar.current.isDateInToday($0.date)
        }
        
        var context = """
        Progress:
        - Today: \(todayMinutes)/\(goal) minutes (\(goal > 0 ? Int(Double(todayMinutes)/Double(goal)*100) : 0)%)
        - Streak: \(streak) days
        - Sessions today: \(sessions.count)
        """
        
        // Week summary
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekMinutes = Int(progress.sessions.filter {
            $0.date >= weekStart
        }.reduce(0) { $0 + $1.duration } / 60)
        
        context += "\n- This week: \(weekMinutes) minutes"
        
        return context
    }
    
    private func buildPresetContext() -> String {
        let presets = FocusPresetStore.shared.presets
        let activeID = FocusPresetStore.shared.activePresetID
        
        guard !presets.isEmpty else {
            return "Presets: Using default settings"
        }
        
        var context = "Available Presets:"
        for preset in presets {
            let active = preset.id == activeID ? " (active)" : ""
            let focusMinutes = preset.durationSeconds / 60
            context += "\n- \(preset.name): \(focusMinutes)min focus\(active)"
        }
        
        return context
    }
    
    private func buildFullContext() -> String {
        var parts: [String] = []
        
        parts.append(getTaskContext())
        parts.append(getProgressContext())
        parts.append(getPresetContext())
        parts.append(getMemoryContext())
        
        // Add current focus state
        if FocusSessionHelper.isRunning {
            parts.append("Current Focus: Active session, \(FocusSessionHelper.remainingMinutes) minutes remaining")
        } else {
            parts.append("Current Focus: No active session")
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Cached Value

struct CachedValue<T> {
    let value: T
    let timestamp: Date
    let ttl: TimeInterval
    
    init(value: T, ttl: TimeInterval) {
        self.value = value
        self.timestamp = Date()
        self.ttl = ttl
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

// MARK: - Debouncer

/// Debounces rapid function calls
final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    func cancel() {
        workItem?.cancel()
    }
}

// MARK: - Throttler

/// Throttles function calls to max rate
final class Throttler {
    private var lastExecution: Date?
    private let interval: TimeInterval
    private let queue: DispatchQueue
    
    init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    func throttle(action: @escaping () -> Void) {
        let now = Date()
        
        if let last = lastExecution {
            let elapsed = now.timeIntervalSince(last)
            if elapsed < interval {
                // Schedule for later
                queue.asyncAfter(deadline: .now() + (interval - elapsed)) { [weak self] in
                    self?.lastExecution = Date()
                    action()
                }
                return
            }
        }
        
        lastExecution = now
        action()
    }
}

// MARK: - Message Batching

/// Batches message updates for smooth UI
@MainActor
final class FlowMessageBatcher: ObservableObject {
    @Published private(set) var visibleMessages: [FlowMessage] = []
    
    private var pendingMessages: [FlowMessage] = []
    private let batchInterval: TimeInterval = 0.1
    private var batchTimer: Timer?
    
    func addMessage(_ message: FlowMessage) {
        pendingMessages.append(message)
        scheduleBatch()
    }
    
    func addMessages(_ messages: [FlowMessage]) {
        pendingMessages.append(contentsOf: messages)
        scheduleBatch()
    }
    
    func clearMessages() {
        pendingMessages.removeAll()
        visibleMessages.removeAll()
        batchTimer?.invalidate()
    }
    
    private func scheduleBatch() {
        guard batchTimer == nil else { return }
        
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { [weak self] _ in
            self?.processBatch()
        }
    }
    
    private func processBatch() {
        batchTimer = nil
        
        guard !pendingMessages.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            visibleMessages.append(contentsOf: pendingMessages)
        }
        pendingMessages.removeAll()
    }
}

// MARK: - Lazy Context Builder

/// Builds context lazily and efficiently
struct LazyContextBuilder {
    
    /// Build minimal context for quick queries
    static func buildMinimalContext() -> String {
        let progress = ProgressStore.shared
        let todayMinutes = Int(progress.totalToday / 60)
        let today = Date()
        let pendingCount = TasksStore.shared.tasks.filter { 
            !TasksStore.shared.isCompleted(taskId: $0.id, on: today) 
        }.count
        
        return """
        Quick Context:
        - Focus today: \(todayMinutes)/\(progress.dailyGoalMinutes) min
        - Streak: \(progress.lifetimeBestStreak) days
        - Tasks pending: \(pendingCount)
        - Focus active: \(FocusSessionHelper.isRunning ? "Yes" : "No")
        """
    }
    
    /// Build context for specific action types
    static func buildContextForAction(_ actionType: FlowActionCategory) -> String {
        switch actionType {
        case .focusControl:
            return buildFocusContext()
        case .taskManagement:
            return buildTaskContextDetailed()
        case .presetManagement:
            return buildPresetContextDetailed()
        case .progressQuery:
            return buildProgressContextDetailed()
        case .navigation, .settings, .motivation:
            return buildMinimalContext()
        }
    }
    
    private static func buildFocusContext() -> String {
        let presets = FocusPresetStore.shared.presets
        
        var context = "Focus State:\n"
        
        if FocusSessionHelper.isRunning {
            context += "- Active session: \(FocusSessionHelper.remainingMinutes) min remaining\n"
            context += "- Can pause/stop/extend session\n"
        } else {
            context += "- No active session\n"
            context += "- Ready to start focus\n"
        }
        
        context += "\nAvailable presets:\n"
        for preset in presets.prefix(5) {
            let focusMinutes = preset.durationSeconds / 60
            context += "- \(preset.name): \(focusMinutes) min\n"
        }
        
        return context
    }
    
    private static func buildTaskContextDetailed() -> String {
        let tasks = TasksStore.shared.tasks
        let calendar = Calendar.current
        let todayDate = Date()
        
        var context = "Tasks Detail:\n"
        context += "Total: \(tasks.count)\n"
        
        // Group by status
        let pending = tasks.filter { 
            !TasksStore.shared.isCompleted(taskId: $0.id, on: todayDate) 
        }
        let dueToday = pending.filter { $0.reminderDate.map { calendar.isDateInToday($0) } ?? false }
        let overdue = pending.filter { task in
            guard let reminder = task.reminderDate else { return false }
            return reminder < Date()
        }
        
        context += "- Pending: \(pending.count)\n"
        context += "- Due today: \(dueToday.count)\n"
        context += "- Overdue: \(overdue.count)\n\n"
        
        if !pending.isEmpty {
            context += "Top pending:\n"
            for task in pending.prefix(8) {
                context += "- [\(task.id.uuidString.prefix(8))]: \(task.title)"
                if let due = task.reminderDate {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .short
                    context += " (due \(formatter.localizedString(for: due, relativeTo: Date())))"
                }
                context += "\n"
            }
        }
        
        return context
    }
    
    private static func buildPresetContextDetailed() -> String {
        let presets = FocusPresetStore.shared.presets
        let activeID = FocusPresetStore.shared.activePresetID
        
        var context = "Presets Detail:\n"
        
        for preset in presets {
            let isActive = preset.id == activeID
            let focusMinutes = preset.durationSeconds / 60
            context += "- \(preset.name)\(isActive ? " [ACTIVE]" : "")\n"
            context += "  Focus: \(focusMinutes)min\n"
        }
        
        return context
    }
    
    private static func buildProgressContextDetailed() -> String {
        let progress = ProgressStore.shared
        let calendar = Calendar.current
        let todayMinutes = Int(progress.totalToday / 60)
        
        var context = "Progress Detail:\n"
        context += "- Today: \(todayMinutes)/\(progress.dailyGoalMinutes) min\n"
        context += "- Streak: \(progress.lifetimeBestStreak) days\n"
        
        // Week data
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let weekSessions = progress.sessions.filter { $0.date >= weekStart }
        let weekMinutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        context += "- This week: \(weekMinutes) min across \(weekSessions.count) sessions\n"
        
        // Average session
        if !progress.sessions.isEmpty {
            let avgDuration = Int(progress.sessions.reduce(0) { $0 + $1.duration } / TimeInterval(progress.sessions.count) / 60)
            context += "- Avg session: \(avgDuration) min\n"
        }
        
        return context
    }
}

// MARK: - Action Category

enum FlowActionCategory {
    case focusControl
    case taskManagement
    case presetManagement
    case progressQuery
    case navigation
    case settings
    case motivation
}

// MARK: - Memory Pool

/// Reusable object pool for performance
final class ObjectPool<T> {
    private var available: [T] = []
    private let factory: () -> T
    private let reset: (T) -> Void
    
    init(initialSize: Int = 5, factory: @escaping () -> T, reset: @escaping (T) -> Void) {
        self.factory = factory
        self.reset = reset
        
        // Pre-populate pool
        for _ in 0..<initialSize {
            available.append(factory())
        }
    }
    
    func acquire() -> T {
        if let object = available.popLast() {
            return object
        }
        return factory()
    }
    
    func release(_ object: T) {
        reset(object)
        available.append(object)
    }
}

// MARK: - Cache Observers

extension FlowContextCache {
    
    /// Set up observers to invalidate cache when data changes
    func setupCacheInvalidation() {
        // Observe task changes
        NotificationCenter.default.addObserver(
            forName: .tasksDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.invalidateTaskCache()
        }
        
        // Observe progress changes
        NotificationCenter.default.addObserver(
            forName: .progressDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.invalidateProgressCache()
        }
        
        // Observe preset changes
        NotificationCenter.default.addObserver(
            forName: .presetsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.invalidatePresetCache()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let tasksDidChange = Notification.Name("tasksDidChange")
    static let progressDidChange = Notification.Name("progressDidChange")
    static let presetsDidChange = Notification.Name("presetsDidChange")
}
