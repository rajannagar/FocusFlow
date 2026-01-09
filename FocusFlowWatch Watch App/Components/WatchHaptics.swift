import Foundation
import WatchKit

/// Haptic feedback patterns for the Watch app
struct WatchHaptics {
    
    /// Called when a focus session starts
    static func sessionStarted() {
        WKInterfaceDevice.current().play(.start)
    }
    
    /// Called when a focus session completes successfully
    static func sessionCompleted() {
        // Play success twice for emphasis (like Apple's Activity rings)
        WKInterfaceDevice.current().play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }
    
    /// Called at milestones (e.g., 5 minutes remaining)
    static func milestone() {
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Called when a task is completed
    static func taskCompleted() {
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Called when user taps interactive elements
    static func tap() {
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Called for errors or warnings
    static func warning() {
        WKInterfaceDevice.current().play(.failure)
    }
    
    /// Called when Flow AI starts listening
    static func flowActivated() {
        WKInterfaceDevice.current().play(.start)
    }
    
    /// Called when break time reminder
    static func breakReminder() {
        WKInterfaceDevice.current().play(.notification)
    }
}
