import SwiftUI

struct WatchProfileView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var showSettings = false
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    private var xpProgress: Double {
        guard dataManager.xpToNextLevel > 0 else { return 0 }
        let currentLevelXP = dataManager.xp - xpForLevel(dataManager.level)
        return Double(currentLevelXP) / Double(dataManager.xpToNextLevel)
    }
    
    private func xpForLevel(_ level: Int) -> Int {
        // Simple XP curve: level * 100
        return (level - 1) * 100
    }
    
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Pro badge
                        if dataManager.isPro {
                            HStack {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(accentColor)
                                    .cornerRadius(4)
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 10))
                                    .foregroundColor(accentColor)
                            }
                        }
                        
                        // Level display
                        Text("Level \(dataManager.level)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // XP Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                            
                            Circle()
                                .trim(from: 0, to: xpProgress)
                                .stroke(
                                    accentColor,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Image(systemName: "bolt.fill")
                                    .font(.title3)
                                    .foregroundColor(accentColor)
                                Text("\(dataManager.xp)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("XP")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(width: 80, height: 80)
                        
                        // XP to next level
                        Text("\(dataManager.xpToNextLevel - (dataManager.xp - xpForLevel(dataManager.level))) to level \(dataManager.level + 1)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Recent badges
                        if !dataManager.recentBadges.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Badges")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                HStack(spacing: 8) {
                                    ForEach(dataManager.recentBadges.prefix(5), id: \.self) { badge in
                                        Text(badge)
                                            .font(.title3)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                        
                        // View all badges button
                        NavigationLink(destination: WatchBadgesView()) {
                            Text("View All Badges")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                WatchSettingsView()
            }
        }
    }
}

#Preview {
    WatchProfileView()
        .environmentObject(WatchDataManager.shared)
}
