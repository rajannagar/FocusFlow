import Foundation
import Combine

// MARK: - Navigation Destination

enum NotificationDestination: String {
    case journey
    case profile
    case progress
    case focus
    case tasks
}

final class NotificationCenterManager: ObservableObject {
    static let shared = NotificationCenterManager()

    @Published private(set) var notifications: [FocusNotification] = []
    
    // MARK: - Navigation Event
    
    /// Posted when user taps a notification that should navigate somewhere
    static let navigateToDestination = Notification.Name("NotificationCenterManager.navigateToDestination")

    private let storageKey = "focusflow.notifications"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    // MARK: - Public API

    func add(
        kind: FocusNotification.Kind,
        title: String,
        body: String,
        date: Date = Date()
    ) {
        let new = FocusNotification(
            kind: kind,
            title: title,
            body: body,
            date: date,
            isRead: false
        )

        notifications.insert(new, at: 0) // newest at top
        trimIfNeeded()
        persist()
    }

    func markAllAsRead() {
        notifications = notifications.map { n in
            var mutable = n
            mutable.isRead = true
            return mutable
        }
        persist()
    }

    func markAsRead(_ notification: FocusNotification) {
        guard let index = notifications.firstIndex(of: notification) else { return }
        notifications[index].isRead = true
        persist()
    }

    /// Explicitly mark as unread (used for swipe right)
    func markAsUnread(_ notification: FocusNotification) {
        guard let index = notifications.firstIndex(of: notification) else { return }
        notifications[index].isRead = false
        persist()
    }

    /// Delete a single notification (swipe left)
    func delete(_ notification: FocusNotification) {
        guard let index = notifications.firstIndex(of: notification) else { return }
        notifications.remove(at: index)
        persist()
    }

    /// Remove all notifications (header "Clear all")
    func clearAll() {
        notifications.removeAll()
        persist()
    }
    
    // MARK: - Navigation
    
    /// Returns the destination for a notification kind, or nil if not navigable
    func destination(for kind: FocusNotification.Kind) -> NotificationDestination? {
        switch kind {
        case .dailyRecap:       return .journey
        case .streak:           return .journey
        case .levelUp:          return .profile
        case .badgeUnlocked:    return .profile
        case .goalUpdated:      return .progress
        case .sessionCompleted: return nil  // Usually already on Focus
        case .taskCompleted:    return nil  // Just confirmation
        case .general:          return nil
        }
    }
    
    /// Call this when user taps a notification to navigate
    func handleTap(on notification: FocusNotification) {
        // Mark as read
        markAsRead(notification)
        
        // Get destination
        guard let destination = destination(for: notification.kind) else { return }
        
        // Post navigation event (after small delay to let sheet dismiss)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(
                name: Self.navigateToDestination,
                object: nil,
                userInfo: ["destination": destination]
            )
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try decoder.decode([FocusNotification].self, from: data)
            notifications = decoded.sorted(by: { $0.date > $1.date })
        } catch {
            print("⚠️ Failed to decode notifications: \(error)")
            notifications = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ Failed to encode notifications: \(error)")
        }
    }

    private func trimIfNeeded(maxCount: Int = 100) {
        if notifications.count > maxCount {
            notifications = Array(notifications.prefix(maxCount))
        }
    }
}
