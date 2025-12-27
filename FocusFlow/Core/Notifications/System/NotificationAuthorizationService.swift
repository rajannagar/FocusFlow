import Foundation
import Combine
import UserNotifications

// =========================================================
// MARK: - NotificationAuthorizationService
// =========================================================
// Handles iOS notification permission state.
// Does NOT prompt automatically - only when user explicitly enables a feature.

@MainActor
final class NotificationAuthorizationService: ObservableObject {
    static let shared = NotificationAuthorizationService()
    
    @Published private(set) var status: UNAuthorizationStatus = .notDetermined
    
    private init() {}
    
    // MARK: - Public API
    
    /// Silently refresh current authorization status (no prompt)
    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.status = settings.authorizationStatus
    }
    
    /// Request permission - call only when user explicitly enables a notification feature
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
            return granted
        } catch {
            print("🔔 Authorization request failed: \(error)")
            await refreshStatus()
            return false
        }
    }
    
    // MARK: - Convenience
    
    var isAuthorized: Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }
    
    var isDenied: Bool {
        status == .denied
    }
    
    var shouldShowSettingsPrompt: Bool {
        status == .denied
    }
}
