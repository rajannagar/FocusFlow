import Foundation
import WatchConnectivity
import Combine

/// iPhone-side manager for Watch communication
/// TODO: Wire up to your existing ViewModels (FocusTimerViewModel, ProgressStore, etc.)
final class iPhoneWatchConnectivityManager: NSObject, ObservableObject {
    static let shared = iPhoneWatchConnectivityManager()
    
    @MainActor @Published var isWatchAppInstalled: Bool = false
    @MainActor @Published var isReachable: Bool = false
    @MainActor @Published var isPaired: Bool = false
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Full Sync to Watch
    
    /// Call this to sync all data to Watch
    /// TODO: Integrate with your actual data sources
    @MainActor
    func sendFullSync() {
        guard let session = session, session.activationState == .activated else { return }
        
        // Get Pro status from your entitlement manager
        let isPro = ProEntitlementManager.shared.isPro
        
        // Build payload with available data
        var payload: [String: Any] = [
            "type": "fullSync",
            "isPro": isPro,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Add session state from your FocusTimerViewModel
        // payload["sessionPhase"] = "idle" // idle, running, paused, completed
        // payload["remainingSeconds"] = 0
        // payload["totalSeconds"] = 25 * 60
        // payload["sessionName"] = ""
        
        // TODO: Add progress data from your ProgressStore
        // payload["todayFocusSeconds"] = 0
        // payload["currentStreak"] = 0
        // payload["dailyGoalMinutes"] = 120
        
        // TODO: Add XP/Level data from your JourneyManager
        // payload["level"] = 1
        // payload["xp"] = 0
        // payload["xpToNextLevel"] = 100
        
        // Send via application context (latest state persists)
        do {
            try session.updateApplicationContext(payload)
        } catch {
            print("Failed to update application context: \(error)")
        }
        
        // Also send as message for immediate delivery if reachable
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("Failed to send message to Watch: \(error)")
            }
        }
    }
    
    // MARK: - Send Session State Update
    
    /// Call this whenever focus session state changes
    @MainActor
    func sendSessionStateUpdate(phase: String, remainingSeconds: Int, totalSeconds: Int, sessionName: String) {
        guard let session = session, session.activationState == .activated else { return }
        
        let payload: [String: Any] = [
            "type": "sessionStateUpdate",
            "sessionPhase": phase,
            "remainingSeconds": remainingSeconds,
            "totalSeconds": totalSeconds,
            "sessionName": sessionName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    // MARK: - Send Pro Status Update
    
    @MainActor
    func sendProStatusUpdate() {
        guard let session = session, session.activationState == .activated else { return }
        
        let payload: [String: Any] = [
            "type": "proStatusUpdate",
            "isPro": ProEntitlementManager.shared.isPro,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        try? session.updateApplicationContext(payload)
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
}

// MARK: - WCSessionDelegate

extension iPhoneWatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
            
            // Send initial sync when activated
            if activationState == .activated {
                self.sendFullSync()
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            
            // Send sync when Watch becomes reachable
            if session.isReachable {
                self.sendFullSync()
            }
        }
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isPaired = session.isPaired
        }
    }
    
    // Receive messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleWatchMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            handleWatchMessage(message)
            replyHandler(["received": true])
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleWatchMessage(userInfo)
        }
    }
    
    @MainActor
    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "sessionStateUpdate":
            // TODO: Handle session state changes from Watch
            // Update your FocusTimerViewModel accordingly
            print("Received session state update from Watch")
            
        case "sessionCompleted":
            // TODO: Log completed session
            let duration = message["duration"] as? Int ?? 0
            let sessionName = message["sessionName"] as? String ?? ""
            print("Watch completed session: \(sessionName) for \(duration) seconds")
            
        case "presetActivated":
            // TODO: Apply preset to FocusTimerViewModel
            let presetId = message["presetId"] as? String ?? ""
            print("Watch activated preset: \(presetId)")
            
        case "taskToggled":
            // TODO: Toggle task in TasksStore
            let taskId = message["taskId"] as? String ?? ""
            let isCompleted = message["isCompleted"] as? Bool ?? false
            print("Watch toggled task \(taskId) to \(isCompleted)")
            
        case "openProUpgrade":
            // Post notification to open paywall
            NotificationCenter.default.post(name: .openPaywallFromWatch, object: nil)
            
        case "requestSync":
            sendFullSync()
            
        default:
            print("Unknown message type from Watch: \(type)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openPaywallFromWatch = Notification.Name("openPaywallFromWatch")
}
