import Foundation
import WatchConnectivity
import Combine

/// Manages communication between Watch and iPhone
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @MainActor @Published var isReachable: Bool = false
    @MainActor @Published var lastSyncDate: Date?
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send to iPhone
    
    func sendSessionStateUpdate(phase: WatchDataManager.SessionPhase, remainingSeconds: Int, totalSeconds: Int, sessionName: String) {
        let message: [String: Any] = [
            "type": "sessionStateUpdate",
            "phase": phase.rawValue,
            "remainingSeconds": remainingSeconds,
            "totalSeconds": totalSeconds,
            "sessionName": sessionName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    func sendSessionCompleted(duration: Int, sessionName: String) {
        let message: [String: Any] = [
            "type": "sessionCompleted",
            "duration": duration,
            "sessionName": sessionName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    func sendPresetActivated(presetId: String) {
        let message: [String: Any] = [
            "type": "presetActivated",
            "presetId": presetId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    func sendTaskToggled(taskId: String, isCompleted: Bool) {
        let message: [String: Any] = [
            "type": "taskToggled",
            "taskId": taskId,
            "isCompleted": isCompleted,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    func requestOpenProUpgrade() {
        let message: [String: Any] = [
            "type": "openProUpgrade",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    func requestSync() {
        let message: [String: Any] = [
            "type": "requestSync",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(message)
    }
    
    // MARK: - Private Helpers
    
    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.isReachable else {
            // Fall back to transferUserInfo for guaranteed delivery
            session?.transferUserInfo(message)
            return
        }
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("WatchConnectivity error: \(error.localizedDescription)")
            // Fall back to transferUserInfo
            self.session?.transferUserInfo(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
        
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
    
    // Receive messages from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            handleMessage(message)
            replyHandler(["received": true])
        }
    }
    
    // Receive application context (latest state)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            handleMessage(applicationContext)
        }
    }
    
    // Receive user info (guaranteed delivery)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleMessage(userInfo)
        }
    }
    
    @MainActor
    private func handleMessage(_ message: [String: Any]) {
        lastSyncDate = Date()
        
        // Update data manager with received data
        WatchDataManager.shared.updateFromiPhone(message)
    }
}
