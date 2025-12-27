import UserNotifications

// =========================================================
// MARK: - Legacy Notification Cleanup
// =========================================================
// Call this ONCE to remove old habit/stats notifications
// that are still scheduled from the previous app version.
//
// Add this to your app launch (FocusFlowApp.swift init or AppDelegate)
// then remove it after a few releases.

enum LegacyNotificationCleanup {
    
    /// Call this once on app launch to remove old scheduled notifications
    static func purgeAllLegacyNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            // Find all legacy identifiers
            var legacyIds: [String] = []
            
            for request in requests {
                let id = request.identifier.lowercased()
                
                // Old habit-related notifications
                if id.contains("habit") {
                    legacyIds.append(request.identifier)
                    continue
                }
                
                // Old stats-related notifications
                if id.contains("stat") {
                    legacyIds.append(request.identifier)
                    continue
                }
                
                // Old weekly summary
                if id.contains("weekly") || id.contains("summary") {
                    legacyIds.append(request.identifier)
                    continue
                }
                
                // Old streak reminders (not from new system)
                if id.contains("streak") && !id.hasPrefix("focusflow.") {
                    legacyIds.append(request.identifier)
                    continue
                }
                
                // Any notification not using our new prefix system
                // Uncomment if you want to be aggressive:
                // if !id.hasPrefix("focusflow.") {
                //     legacyIds.append(request.identifier)
                // }
            }
            
            if !legacyIds.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: legacyIds)
                print("🧹 Purged \(legacyIds.count) legacy notifications:")
                for id in legacyIds {
                    print("   - \(id)")
                }
            } else {
                print("🧹 No legacy notifications found")
            }
        }
        
        // Also clear any delivered legacy notifications
        center.getDeliveredNotifications { notifications in
            var legacyIds: [String] = []
            
            for notification in notifications {
                let id = notification.request.identifier.lowercased()
                
                if id.contains("habit") || id.contains("stat") || id.contains("weekly") || id.contains("summary") {
                    legacyIds.append(notification.request.identifier)
                }
            }
            
            if !legacyIds.isEmpty {
                center.removeDeliveredNotifications(withIdentifiers: legacyIds)
                print("🧹 Cleared \(legacyIds.count) delivered legacy notifications")
            }
        }
    }
    
    /// Debug: Print ALL pending notifications to see what's scheduled
    static func debugPrintAllPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 === ALL PENDING NOTIFICATIONS (\(requests.count)) ===")
            for request in requests.sorted(by: { $0.identifier < $1.identifier }) {
                let trigger: String
                if let cal = request.trigger as? UNCalendarNotificationTrigger {
                    trigger = "calendar: \(cal.dateComponents)"
                } else if let time = request.trigger as? UNTimeIntervalNotificationTrigger {
                    trigger = "interval: \(time.timeInterval)s"
                } else {
                    trigger = String(describing: request.trigger)
                }
                print("   • \(request.identifier)")
                print("     Title: \(request.content.title)")
                print("     Trigger: \(trigger)")
                print("")
            }
            print("📋 =========================================")
        }
    }
    
    /// Nuclear option: Cancel ALL notifications and reschedule fresh
    static func cancelAllAndReschedule() {
        let center = UNUserNotificationCenter.current()
        
        // Cancel everything
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        print("💥 Cancelled ALL notifications")
        
        // Reschedule via coordinator
        Task { @MainActor in
            await NotificationsCoordinator.shared.reconcileAll(reason: "nuclear reset")
        }
    }
}
