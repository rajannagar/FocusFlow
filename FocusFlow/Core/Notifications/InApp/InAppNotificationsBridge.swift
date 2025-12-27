import Foundation
import Combine

// =========================================================
// MARK: - InAppNotificationsBridge
// =========================================================
// Bridges AppSyncManager events to NotificationCenterManager.
//
// NOTE: In-app notifications are ALWAYS recorded regardless of
// NotificationPreferences. The in-app feed serves as an activity
// log / history of accomplishments. Users can clear them manually.
//
// Push notifications (system banners) respect preferences.
// In-app notifications (feed) do NOT - they always record.

@MainActor
final class InAppNotificationsBridge: ObservableObject {
    static let shared = InAppNotificationsBridge()
    
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenterManager.shared
    private let calendar = Calendar.autoupdatingCurrent
    
    /// Key to track last recap date shown
    private let lastRecapDateKey = "ff_lastDailyRecapDate"
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Session completed
        // userInfo: ["duration": TimeInterval, "sessionName": String]
        NotificationCenter.default.publisher(for: AppSyncManager.sessionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSessionCompleted(notification)
            }
            .store(in: &cancellables)
        
        // Task completed
        // userInfo: ["taskId": UUID, "taskTitle": String, "date": Date]
        NotificationCenter.default.publisher(for: AppSyncManager.taskCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleTaskCompleted(notification)
            }
            .store(in: &cancellables)
        
        // Streak updated
        // userInfo: ["previousStreak": Int, "currentStreak": Int]
        NotificationCenter.default.publisher(for: AppSyncManager.streakUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleStreakUpdated(notification)
            }
            .store(in: &cancellables)
        
        // Level up
        // userInfo: ["info": LevelUpInfo]
        NotificationCenter.default.publisher(for: AppSyncManager.levelUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleLevelUp(notification)
            }
            .store(in: &cancellables)
        
        // Badge unlocked
        // userInfo: (not currently posted by AppSyncManager, but we listen anyway)
        NotificationCenter.default.publisher(for: AppSyncManager.badgeUnlocked)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleBadgeUnlocked(notification)
            }
            .store(in: &cancellables)
        
        print("📬 InAppNotificationsBridge: observers setup (always-on mode)")
    }
    
    // MARK: - Daily Recap (called on app launch)
    
    /// Call this on app launch to generate yesterday's recap if not already shown today.
    /// This adds a personalized summary to the in-app notification feed.
    func generateDailyRecapIfNeeded() {
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already generated today's recap
        if let lastRecapDate = UserDefaults.standard.object(forKey: lastRecapDateKey) as? Date {
            let lastRecapDay = calendar.startOfDay(for: lastRecapDate)
            if lastRecapDay == today {
                print("📬 Daily recap already generated today")
                return
            }
        }
        
        // Get yesterday's date
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        
        // Find yesterday's summary from JourneyManager
        let journeyManager = JourneyManager.shared
        journeyManager.refresh() // Ensure data is fresh
        
        guard let yesterdaySummary = journeyManager.summaries.first(where: {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        }) else {
            print("📬 No data for yesterday, skipping recap")
            // Still mark as generated so we don't keep checking
            UserDefaults.standard.set(today, forKey: lastRecapDateKey)
            return
        }
        
        // Generate personalized recap notification
        let (title, body) = generateRecapContent(from: yesterdaySummary)
        
        notificationCenter.add(
            kind: .dailyRecap,
            title: title,
            body: body
        )
        
        // Mark as generated
        UserDefaults.standard.set(today, forKey: lastRecapDateKey)
        
        print("📬 Daily recap generated for yesterday")
    }
    
    /// Generate personalized recap content based on yesterday's summary
    private func generateRecapContent(from summary: DailySummary) -> (title: String, body: String) {
        // No activity yesterday
        if !summary.hasActivity {
            return (
                "Ready for Today? 🌅",
                "Yesterday was a rest day. Start fresh today!"
            )
        }
        
        // Build stats string
        var stats: [String] = []
        
        if summary.totalFocusMinutes > 0 {
            stats.append("\(summary.formattedFocusTime) focused")
        }
        
        if summary.sessionCount > 0 {
            let sessionText = summary.sessionCount == 1 ? "1 session" : "\(summary.sessionCount) sessions"
            stats.append(sessionText)
        }
        
        if summary.tasksCompleted > 0 {
            let taskText = summary.tasksCompleted == 1 ? "1 task" : "\(summary.tasksCompleted) tasks"
            stats.append(taskText)
        }
        
        let statsString = stats.joined(separator: " · ")
        
        // Choose title based on performance
        let title: String
        let extraInfo: String
        
        if summary.goalHit && summary.tasksCompleted >= summary.tasksTotal && summary.tasksTotal > 0 {
            title = "Amazing Day Yesterday! 🏆"
            extraInfo = "Goal crushed + all tasks done!"
        } else if summary.goalHit {
            title = "Goal Achieved Yesterday! 🎯"
            extraInfo = "You hit your daily goal!"
        } else if summary.streakCount >= 7 {
            title = "Yesterday's Recap 🔥"
            extraInfo = "\(summary.streakCount) day streak!"
        } else if summary.xpEarnedToday >= 50 {
            title = "Productive Day! ⭐️"
            extraInfo = "+\(summary.xpEarnedToday) XP earned"
        } else {
            title = "Yesterday's Recap 📊"
            extraInfo = "Every session counts!"
        }
        
        let body = statsString.isEmpty ? extraInfo : "\(statsString). \(extraInfo)"
        
        return (title, body)
    }
    
    // MARK: - Event Handlers
    // All handlers write to in-app feed unconditionally
    
    private func handleSessionCompleted(_ notification: Notification) {
        // Extract session info - matches AppSyncManager.sessionDidComplete userInfo
        let sessionName = notification.userInfo?["sessionName"] as? String ?? "Focus session"
        let duration = notification.userInfo?["duration"] as? TimeInterval ?? 0
        
        let durationText = duration > 0 ? formatDuration(duration) : ""
        let body = durationText.isEmpty
            ? "You completed \"\(sessionName)\"."
            : "You completed \"\(sessionName)\" (\(durationText))."
        
        notificationCenter.add(
            kind: .sessionCompleted,
            title: "Session Complete ✨",
            body: body
        )
        
        print("📬 InAppNotificationsBridge: session completed → feed")
    }
    
    private func handleTaskCompleted(_ notification: Notification) {
        // Extract task info - matches AppSyncManager.taskDidComplete userInfo
        let taskTitle = notification.userInfo?["taskTitle"] as? String ?? "Task"
        
        notificationCenter.add(
            kind: .taskCompleted,
            title: "Task Complete ✓",
            body: "You completed \"\(taskTitle)\"."
        )
        
        print("📬 InAppNotificationsBridge: task completed → feed")
    }
    
    private func handleStreakUpdated(_ notification: Notification) {
        // Extract streak info - matches AppSyncManager.checkStreakUpdate userInfo
        let currentStreak = notification.userInfo?["currentStreak"] as? Int ?? 0
        let previousStreak = notification.userInfo?["previousStreak"] as? Int ?? 0
        
        // Only notify when streak increases and hits a milestone
        guard currentStreak > previousStreak else { return }
        guard shouldNotifyStreak(currentStreak) else { return }
        
        let emoji = streakEmoji(for: currentStreak)
        
        notificationCenter.add(
            kind: .streak,
            title: "\(currentStreak) Day Streak! \(emoji)",
            body: "You're on fire! Keep the momentum going."
        )
        
        print("📬 InAppNotificationsBridge: streak milestone → feed (\(currentStreak) days)")
    }
    
    private func handleLevelUp(_ notification: Notification) {
        // Extract level info - matches AppSyncManager.checkForLevelUp userInfo
        if let info = notification.userInfo?["info"] as? LevelUpInfo {
            notificationCenter.add(
                kind: .levelUp,
                title: "Level Up! ⬆️",
                body: "You've reached Level \(info.newLevel) - \(info.newTitle)!"
            )
        } else {
            notificationCenter.add(
                kind: .levelUp,
                title: "Level Up! ⬆️",
                body: "Congratulations, you leveled up!"
            )
        }
        
        print("📬 InAppNotificationsBridge: level up → feed")
    }
    
    private func handleBadgeUnlocked(_ notification: Notification) {
        let badgeName = notification.userInfo?["badgeName"] as? String ?? "Achievement"
        
        notificationCenter.add(
            kind: .badgeUnlocked,
            title: "Badge Unlocked! 🏅",
            body: "You earned the \"\(badgeName)\" badge."
        )
        
        print("📬 InAppNotificationsBridge: badge unlocked → feed")
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    private func shouldNotifyStreak(_ streak: Int) -> Bool {
        // Notify on these milestone streaks
        let milestones = [3, 7, 14, 21, 30, 50, 60, 90, 100, 150, 200, 365]
        return milestones.contains(streak)
    }
    
    private func streakEmoji(for streak: Int) -> String {
        switch streak {
        case 3...6: return "🔥"
        case 7...13: return "🔥🔥"
        case 14...29: return "⚡️"
        case 30...59: return "💪"
        case 60...99: return "🏆"
        case 100...199: return "👑"
        case 200...364: return "🌟"
        case 365...: return "🎖️"
        default: return "✨"
        }
    }
}

// Note: All notification names already exist in AppSyncManager:
// - AppSyncManager.sessionCompleted
// - AppSyncManager.taskCompleted
// - AppSyncManager.streakUpdated
// - AppSyncManager.goalUpdated
// - AppSyncManager.levelUp
// - AppSyncManager.badgeUnlocked
// - AppSyncManager.xpUpdated
// - AppSyncManager.themeChanged
// - AppSyncManager.forceRefresh
