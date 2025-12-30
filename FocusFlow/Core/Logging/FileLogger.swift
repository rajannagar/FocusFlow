import Foundation
import os.log

/// Simple file-based logger for debugging
final class FileLogger {
    static let shared = FileLogger()
    
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.focusflow.filelogger", qos: .utility)
    private let maxLogSize: Int = 1024 * 1024 // 1MB max
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logFileURL = documentsPath.appendingPathComponent("focusflow_debug.log")
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }
    
    func log(_ message: String, level: String = "INFO") {
        queue.async { [weak self] in
            guard let self else { return }
            
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let logLine = "[\(timestamp)] [\(level)] \(message)\n"
            
            // Check file size and rotate if needed
            if let attributes = try? FileManager.default.attributesOfItem(atPath: self.logFileURL.path),
               let fileSize = attributes[.size] as? Int,
               fileSize > self.maxLogSize {
                self.rotateLog()
            }
            
            // Append to file
            if let data = logLine.data(using: .utf8),
               let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.synchronizeFile() // ✅ Flush immediately
                fileHandle.closeFile()
            } else {
                // Fallback: write directly with immediate flush
                if let fileHandle = FileHandle(forWritingAtPath: self.logFileURL.path) {
                    fileHandle.seekToEndOfFile()
                    if let data = logLine.data(using: .utf8) {
                        fileHandle.write(data)
                        fileHandle.synchronizeFile()
                    }
                    fileHandle.closeFile()
                } else {
                    // Last resort: read, append, write
                    var existing = (try? String(contentsOf: self.logFileURL, encoding: .utf8)) ?? ""
                    existing += logLine
                    try? existing.write(to: self.logFileURL, atomically: true, encoding: .utf8)
                }
            }
            
            // Also print to console for Xcode
            print(logLine.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    private func rotateLog() {
        let oldLogURL = logFileURL.appendingPathExtension("old")
        try? FileManager.default.removeItem(at: oldLogURL)
        try? FileManager.default.moveItem(at: logFileURL, to: oldLogURL)
        FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
    }
    
    /// Get the log file path (for sharing/debugging)
    var logFilePath: String {
        logFileURL.path
    }
    
    /// Clear the log file
    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            try? "".write(to: self.logFileURL, atomically: true, encoding: .utf8)
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// Convenience functions
func logSound(_ message: String) {
    FileLogger.shared.log("🔊🔇 [Sound] \(message)", level: "SOUND")
}

func logTimer(_ message: String) {
    FileLogger.shared.log("⏱️ [Timer] \(message)", level: "TIMER")
}

func logDebug(_ message: String) {
    FileLogger.shared.log(message, level: "DEBUG")
}

