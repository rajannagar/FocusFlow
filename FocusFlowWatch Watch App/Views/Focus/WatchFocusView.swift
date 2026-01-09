import SwiftUI

struct WatchFocusView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    // Theme colors
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top controls row
                    HStack {
                        // Duration button
                        Button(action: {
                            // TODO: Show duration picker
                        }) {
                            Image(systemName: "timer")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Music button
                        Button(action: {
                            // TODO: Toggle music
                        }) {
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    Spacer()
                    
                    // The Orb - Center piece
                    WatchOrbView()
                        .frame(width: min(geo.size.width * 0.7, 120), height: min(geo.size.width * 0.7, 120))
                    
                    Spacer()
                    
                    // Bottom controls row
                    HStack {
                        // Reset button
                        Button(action: {
                            // TODO: Reset timer
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Ambiance button
                        Button(action: {
                            // TODO: Toggle ambiance
                        }) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }
        }
    }
}

#Preview {
    WatchFocusView()
        .environmentObject(WatchDataManager.shared)
}
