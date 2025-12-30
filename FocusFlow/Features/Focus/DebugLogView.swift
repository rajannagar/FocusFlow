import SwiftUI

#if DEBUG
struct DebugLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logContent: String = "Loading..."
    @State private var logPath: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Path info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log File Path:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(logPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    HStack {
                        Button("Copy Path") {
                            UIPasteboard.general.string = logPath
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Refresh") {
                            loadLogs()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear Logs") {
                            FileLogger.shared.clear()
                            loadLogs()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
                
                Divider()
                
                // Log content
                ScrollView {
                    Text(logContent)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadLogs()
            }
        }
    }
    
    private func loadLogs() {
        logPath = FileLogger.shared.logFilePath
        
        if let content = try? String(contentsOfFile: logPath, encoding: .utf8) {
            // Show last 500 lines
            let lines = content.components(separatedBy: .newlines)
            let lastLines = lines.suffix(500).joined(separator: "\n")
            logContent = lastLines.isEmpty ? "Log file is empty" : lastLines
        } else {
            logContent = "Could not read log file"
        }
    }
}
#endif

