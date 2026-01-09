import SwiftUI

struct WatchSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: WatchDataManager
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    // Theme
                    NavigationLink(destination: ThemeSettingsView()) {
                        SettingsRow(icon: "paintbrush.fill", title: "Theme", iconColor: .purple)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    // Haptics
                    NavigationLink(destination: HapticsSettingsView()) {
                        SettingsRow(icon: "waveform", title: "Haptics", iconColor: .orange)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    // Sync
                    NavigationLink(destination: SyncSettingsView()) {
                        SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Sync", iconColor: .blue)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    // About
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About", iconColor: .gray)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Theme Settings
struct ThemeSettingsView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            List {
                Button(action: {
                    dataManager.syncThemeWithiPhone = true
                }) {
                    HStack {
                        Text("Sync with iPhone")
                            .foregroundColor(.white)
                        Spacer()
                        if dataManager.syncThemeWithiPhone {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Theme")
    }
}

// MARK: - Haptics Settings
struct HapticsSettingsView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            List {
                Toggle(isOn: $dataManager.hapticsEnabled) {
                    Text("Haptic Feedback")
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.1))
                
                Toggle(isOn: $dataManager.hapticOnComplete) {
                    Text("Session Complete")
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.1))
                
                Toggle(isOn: $dataManager.hapticOnMilestone) {
                    Text("Milestones")
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Haptics")
    }
}

// MARK: - Sync Settings
struct SyncSettingsView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Connection status
                    HStack {
                        Image(systemName: connectivityManager.isReachable ? "iphone" : "iphone.slash")
                            .foregroundColor(connectivityManager.isReachable ? accentColor : .red)
                        Text(connectivityManager.isReachable ? "Connected" : "Not Connected")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Last synced
                    if let lastSync = connectivityManager.lastSyncDate {
                        Text("Last synced: \(lastSync, style: .relative) ago")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Sync button
                    Button(action: {
                        connectivityManager.requestSync()
                    }) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(accentColor)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .navigationTitle("Sync")
    }
}

// MARK: - About View
struct AboutView: View {
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor)
                    
                    Text("FocusFlow")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    Text("Made with 💚 in Canada")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    WatchSettingsView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchConnectivityManager.shared)
}
