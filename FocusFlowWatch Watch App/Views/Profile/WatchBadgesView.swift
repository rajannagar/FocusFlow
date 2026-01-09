import SwiftUI

struct WatchBadgesView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if dataManager.allBadges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                    Text("No badges yet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(dataManager.allBadges, id: \.self) { badge in
                            Text(badge)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Badges")
    }
}

#Preview {
    WatchBadgesView()
        .environmentObject(WatchDataManager.shared)
}
