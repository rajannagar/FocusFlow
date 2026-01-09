//
//  NotificationPermissionHelper.swift
//  FocusFlow
//
//  Centralized helper for prompting notification permissions
//  when users perform actions that require notifications.
//

import SwiftUI
import Combine
import UserNotifications

/// Context for why we're requesting notification permission
enum NotificationPermissionContext {
    case focusSession
    case taskReminder
    case dailyReminder
    case streakProtection
    
    var title: String {
        switch self {
        case .focusSession:
            return "Enable Session Alerts"
        case .taskReminder:
            return "Enable Task Reminders"
        case .dailyReminder:
            return "Enable Daily Reminders"
        case .streakProtection:
            return "Enable Streak Alerts"
        }
    }
    
    var message: String {
        switch self {
        case .focusSession:
            return "Get notified when your focus sessions end, even if the app is in the background."
        case .taskReminder:
            return "Receive reminders for your tasks so you never miss a deadline."
        case .dailyReminder:
            return "Get gentle nudges to maintain your focus habit."
        case .streakProtection:
            return "We'll remind you before your streak is at risk."
        }
    }
    
    var icon: String {
        switch self {
        case .focusSession: return "timer"
        case .taskReminder: return "checklist"
        case .dailyReminder: return "bell.badge"
        case .streakProtection: return "flame.fill"
        }
    }
}

/// Result of a permission check
enum NotificationPermissionResult {
    case authorized      // Already authorized, proceed
    case granted         // Just granted via system prompt
    case denied          // Denied, user chose not to enable
    case openedSettings  // User went to settings
}

/// Centralized helper for notification permission prompts
@MainActor
final class NotificationPermissionHelper: ObservableObject {
    static let shared = NotificationPermissionHelper()
    
    @Published var showingPermissionAlert = false
    @Published var currentContext: NotificationPermissionContext = .focusSession
    
    private var pendingCompletion: ((NotificationPermissionResult) -> Void)?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check and prompt for notification permission if needed.
    /// Returns immediately if already authorized.
    /// Shows system prompt if not determined.
    /// Shows custom alert if denied (directing to Settings).
    func ensurePermission(
        for context: NotificationPermissionContext,
        completion: @escaping (NotificationPermissionResult) -> Void
    ) {
        Task {
            let result = await ensurePermissionAsync(for: context)
            completion(result)
        }
    }
    
    /// Async version of ensurePermission
    func ensurePermissionAsync(for context: NotificationPermissionContext) async -> NotificationPermissionResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            // Already authorized
            return .authorized
            
        case .notDetermined:
            // Show system prompt
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    Haptics.notification(.success)
                    return .granted
                } else {
                    return .denied
                }
            } catch {
                print("🔔 Permission request failed: \(error)")
                return .denied
            }
            
        case .denied:
            // Show custom alert directing to Settings
            return await withCheckedContinuation { continuation in
                self.currentContext = context
                self.pendingCompletion = { result in
                    continuation.resume(returning: result)
                }
                self.showingPermissionAlert = true
            }
            
        @unknown default:
            return .denied
        }
    }
    
    /// Quick check without prompting
    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Alert Actions
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        showingPermissionAlert = false
        pendingCompletion?(.openedSettings)
        pendingCompletion = nil
    }
    
    func dismissAlert() {
        showingPermissionAlert = false
        pendingCompletion?(.denied)
        pendingCompletion = nil
    }
}

// MARK: - SwiftUI Alert View Modifier

struct NotificationPermissionAlertModifier: ViewModifier {
    @ObservedObject var helper = NotificationPermissionHelper.shared
    
    func body(content: Content) -> some View {
        content
            .alert(helper.currentContext.title, isPresented: $helper.showingPermissionAlert) {
                Button("Go to Settings") {
                    helper.openSettings()
                }
                Button("Not Now", role: .cancel) {
                    helper.dismissAlert()
                }
            } message: {
                Text(helper.currentContext.message)
            }
    }
}

extension View {
    /// Attach this to your root view to enable notification permission alerts
    func notificationPermissionAlert() -> some View {
        modifier(NotificationPermissionAlertModifier())
    }
}
