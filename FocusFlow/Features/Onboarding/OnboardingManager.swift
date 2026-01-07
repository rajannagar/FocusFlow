//
//  OnboardingManager.swift
//  FocusFlow
//
//  Manages onboarding state and user preferences during onboarding.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Onboarding Intent

enum OnboardingIntent: String, Codable, CaseIterable, Identifiable {
    case deepFocus = "Deep Focus"
    case smartTasks = "Smart Tasks"
    case aiPlanning = "AI Planning"
    case ambientStudy = "Ambient Study"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .deepFocus: return "target"
        case .smartTasks: return "checklist"
        case .aiPlanning: return "sparkles"
        case .ambientStudy: return "music.note.list"
        }
    }
    
    var description: String {
        switch self {
        case .deepFocus: return "Long sessions, zero distractions"
        case .smartTasks: return "Organize, prioritize, accomplish"
        case .aiPlanning: return "Let AI orchestrate your day"
        case .ambientStudy: return "Soundscapes for concentration"
        }
    }
    
    /// Returns suggested defaults based on the selected intent
    func suggestedDefaults() -> (goalMinutes: Int, sound: FocusSound?, ambiance: AmbientMode?) {
        switch self {
        case .deepFocus:
            return (90, .lightRainAmbient, .forest)
        case .smartTasks:
            return (45, .soundAmbience, .minimal)
        case .aiPlanning:
            return (60, .fireplace, .aurora)
        case .ambientStudy:
            return (60, .hearty, .stars)
        }
    }
}

// MARK: - Notification Style

enum NotificationStyle: String, Codable, CaseIterable, Identifiable {
    case gentle = "Gentle reminders"
    case balanced = "Keep me on track"
    case silent = "Silent mode"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gentle: return "bell"
        case .balanced: return "bolt"
        case .silent: return "bell.slash"
        }
    }
    
    var description: String {
        switch self {
        case .gentle: return "Focus start times only"
        case .balanced: return "Focus + tasks + streaks"
        case .silent: return "No notifications"
        }
    }
}

// MARK: - Onboarding Data

struct OnboardingData {
    // Basic personalization
    var displayName: String = ""
    var dailyGoalMinutes: Int = 60
    var selectedTheme: AppTheme = .forest
    var remindersEnabled: Bool = true
    
    // NEW: Intent-based customization
    var selectedIntent: OnboardingIntent? = nil
    var notificationStyle: NotificationStyle = .balanced
    var firstPriorityTask: String = ""
    
    // NEW: Notification preferences
    var notificationWindowStart: Int = 9  // 9 AM
    var notificationWindowEnd: Int = 21   // 9 PM
}

// MARK: - Onboarding Manager

@MainActor
final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "ff_hasCompletedOnboarding"
        static let onboardingVersion = "ff_onboardingVersion"
    }
    
    /// Current onboarding version - increment to show onboarding again for major updates
    private let currentOnboardingVersion = 3  // Bumped for simplified overview-first onboarding
    
    // MARK: - Published State
    
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentPage: Int = 0
    @Published var onboardingData = OnboardingData()
    
    // MARK: - Constants
    
    let totalPages = 5  // Intro, Tour, Quick Prefs, Notifications, Finish
    
    // MARK: - Goal Options
    
    let goalOptions: [Int] = [15, 30, 45, 60, 90, 120]
    
    // MARK: - Init
    
    private init() {
        loadOnboardingState()
    }
    
    // MARK: - State Management
    
    private func loadOnboardingState() {
        let defaults = UserDefaults.standard
        
        // Check if onboarding was completed
        let completed = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        let savedVersion = defaults.integer(forKey: Keys.onboardingVersion)
        
        // Show onboarding if never completed OR if we have a new version
        if completed && savedVersion >= currentOnboardingVersion {
            hasCompletedOnboarding = true
        } else {
            hasCompletedOnboarding = false
        }
        
        // Load default theme from AppSettings if available
        onboardingData.selectedTheme = AppSettings.shared.selectedTheme
    }
    
    // MARK: - Navigation
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
            Haptics.impact(.light)
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage -= 1
            }
            Haptics.impact(.light)
        }
    }
    
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage = page
        }
        Haptics.impact(.light)
    }
    
    // MARK: - Theme Selection
    
    func selectTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.5)) {
            onboardingData.selectedTheme = theme
        }
        Haptics.impact(.medium)
    }
    
    // MARK: - Goal Selection
    
    func selectGoal(_ minutes: Int) {
        onboardingData.dailyGoalMinutes = minutes
        Haptics.impact(.light)
    }

    // MARK: - Reminders

    func setRemindersEnabled(_ isEnabled: Bool) {
        onboardingData.remindersEnabled = isEnabled
        Haptics.impact(.light)
    }
    
    // MARK: - Intent Selection
    
    func selectIntent(_ intent: OnboardingIntent) {
        withAnimation(.easeInOut(duration: 0.3)) {
            onboardingData.selectedIntent = intent
        }
        
        // Apply suggested defaults based on intent
        let defaults = intent.suggestedDefaults()
        onboardingData.dailyGoalMinutes = defaults.goalMinutes
        
        Haptics.impact(.medium)
        
        #if DEBUG
        print("[OnboardingManager] Selected intent: \(intent.rawValue)")
        print("  - Suggested goal: \(defaults.goalMinutes) min")
        #endif
    }
    
    // MARK: - Notification Style Selection
    
    func setNotificationStyle(_ style: NotificationStyle) {
        onboardingData.notificationStyle = style
        Haptics.impact(.light)
        
        #if DEBUG
        print("[OnboardingManager] Notification style: \(style.rawValue)")
        #endif
    }
    
    // MARK: - First Task
    
    func setFirstTask(_ task: String) {
        onboardingData.firstPriorityTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Completion
    
    func completeOnboarding() {
        // Save user preferences to AppSettings
        let settings = AppSettings.shared
        
        // 1. Save basic personalization
        let trimmedName = onboardingData.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            settings.displayName = trimmedName
        }
        
        // Save theme
        settings.selectedTheme = onboardingData.selectedTheme
        settings.profileTheme = onboardingData.selectedTheme
        
        // Save daily goal
        settings.dailyGoalMinutes = onboardingData.dailyGoalMinutes
        
        // 2. Apply intent-based seeds
        if let intent = onboardingData.selectedIntent {
            seedIntentDefaults(intent)
        }
        
        // 3. Create first task if provided
        if !onboardingData.firstPriorityTask.isEmpty {
            createFirstTask()
        }
        
        // 4. Apply notification preferences
        applyNotificationStyle()
        
        // Mark onboarding as completed
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.set(currentOnboardingVersion, forKey: Keys.onboardingVersion)
        
        // Update state
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        
        Haptics.notification(.success)
        
        #if DEBUG
        print("[OnboardingManager] Onboarding completed!")
        print("  - Name: \(trimmedName.isEmpty ? "(default)" : trimmedName)")
        print("  - Theme: \(onboardingData.selectedTheme.displayName)")
        print("  - Goal: \(onboardingData.dailyGoalMinutes) minutes")
        print("  - Intent: \(onboardingData.selectedIntent?.rawValue ?? "none")")
        print("  - Notification style: \(onboardingData.notificationStyle.rawValue)")
        #endif
    }
    
    // MARK: - Intent-Based Seeding
    
    private func seedIntentDefaults(_ intent: OnboardingIntent) {
        let defaults = intent.suggestedDefaults()
        
        #if DEBUG
        print("[OnboardingManager] Seeding defaults for \(intent.rawValue)")
        #endif
        
        // Seed default sound
        if let sound = defaults.sound {
            // Just ensure sound is enabled, the user can select sound later
            AppSettings.shared.soundEnabled = true
        }
        
        // Seed default ambiance (stored in AppSettings or UserDefaults if needed)
        // Note: Currently AmbientMode is handled per-session, but we could add a default preference
        
        // Intent-specific actions
        switch intent {
        case .deepFocus:
            // User prefers long, uninterrupted sessions
            // Could seed a 90-min "Deep Work" preset (already exists as default)
            break
            
        case .smartTasks:
            // User is task-focused - create sample tasks to demonstrate
            createSampleTasks()
            
        case .aiPlanning:
            // User wants AI assistance - could show AI welcome tip on first launch
            // This can be handled in the main app with a flag
            UserDefaults.standard.set(true, forKey: "ff_showAIWelcomeTip")
            
        case .ambientStudy:
            // User wants soundscape variety - ensure sound is enabled
            AppSettings.shared.soundEnabled = true
        }
    }
    
    private func createSampleTasks() {
        // Create 2 sample tasks to demonstrate task management
        let tasksStore = TasksStore.shared
        
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        // Sample task 1: Review priorities (reminder today)
        let task1 = FFTaskItem(
            title: "Review today's priorities",
            reminderDate: today,
            durationMinutes: 15
        )
        tasksStore.upsert(task1)
        
        // Sample task 2: Plan tomorrow (reminder tomorrow)
        let task2 = FFTaskItem(
            title: "Plan tomorrow's focus time",
            reminderDate: tomorrow,
            durationMinutes: 10
        )
        tasksStore.upsert(task2)
        
        #if DEBUG
        print("[OnboardingManager] Created 2 sample tasks")
        #endif
    }
    
    private func createFirstTask() {
        let tasksStore = TasksStore.shared
        
        // Create the user's first priority task with reminder in 2 days
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        
        let firstTask = FFTaskItem(
            title: onboardingData.firstPriorityTask,
            reminderDate: twoDaysFromNow
        )
        tasksStore.upsert(firstTask)
        
        #if DEBUG
        print("[OnboardingManager] Created first priority task: \(onboardingData.firstPriorityTask)")
        #endif
    }
    
    private func applyNotificationStyle() {
        NotificationPreferencesStore.shared.update { prefs in
            let enable = onboardingData.remindersEnabled
            prefs.masterEnabled = enable
            prefs.sessionCompletionEnabled = enable
            prefs.dailyReminderEnabled = enable
            prefs.dailyReminderHour = 9
            prefs.dailyReminderMinute = 0
            prefs.taskRemindersEnabled = enable
            prefs.dailyRecapEnabled = enable
            prefs.dailyNudgesEnabled = false
        }
        
        #if DEBUG
        print("[OnboardingManager] Applied notification prefs (enabled: \(onboardingData.remindersEnabled))")
        #endif
    }
    
    func skipOnboarding() {
        // Mark as completed without saving preferences
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.set(currentOnboardingVersion, forKey: Keys.onboardingVersion)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        
        Haptics.impact(.light)
        
        #if DEBUG
        print("[OnboardingManager] Onboarding skipped")
        #endif
    }
    
    // MARK: - Reset (for testing)
    
    #if DEBUG
    func resetOnboarding() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.onboardingVersion)
        
        hasCompletedOnboarding = false
        currentPage = 0
        onboardingData = OnboardingData()
        
        print("[OnboardingManager] Onboarding reset for testing")
    }
    #endif
}
