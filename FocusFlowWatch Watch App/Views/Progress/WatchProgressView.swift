import SwiftUI

struct WatchProgressView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    private var todayFormatted: String {
        let minutes = Int(dataManager.todayFocusSeconds / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    private var progress: Double {
        guard dataManager.dailyGoalMinutes > 0 else { return 0 }
        return min(1.0, dataManager.todayFocusSeconds / Double(dataManager.dailyGoalMinutes * 60))
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
                        // Daily progress ring
                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            
                            // Progress ring
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    accentColor,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            
                            // Center content
                            VStack(spacing: 2) {
                                Text(todayFormatted)
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("/ \(dataManager.dailyGoalMinutes)m goal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(width: 100, height: 100)
                        .padding(.top, 8)
                        
                        // Streak
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(dataManager.currentStreak) day streak")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        
                        // Quick stats
                        VStack(spacing: 8) {
                            StatRow(label: "Sessions", value: "\(dataManager.todaySessionCount)")
                            StatRow(label: "Lifetime", value: "\(dataManager.lifetimeSessions) sessions")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Today")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
    }
}

#Preview {
    WatchProgressView()
        .environmentObject(WatchDataManager.shared)
}
