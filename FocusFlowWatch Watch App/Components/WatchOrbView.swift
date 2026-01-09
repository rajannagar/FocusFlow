import SwiftUI

struct WatchOrbView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var isPulsing = false
    @State private var isLongPressing = false
    
    // Theme colors
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    private let orbGradientInner = Color(red: 0.08, green: 0.18, blue: 0.14)
    private let orbGradientOuter = Color(red: 0.04, green: 0.09, blue: 0.07)
    
    private var formattedTime: String {
        let minutes = dataManager.remainingSeconds / 60
        let seconds = dataManager.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            
            ZStack {
                // Outer glow
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .blur(radius: 20)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                
                // Orb background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [orbGradientInner, orbGradientOuter],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.5), accentColor.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Progress ring (when running)
                if dataManager.sessionPhase == .running {
                    Circle()
                        .trim(from: 0, to: dataManager.progress)
                        .stroke(
                            accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(4)
                }
                
                // Time display
                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: size * 0.28, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    if !dataManager.currentSessionName.isEmpty {
                        Text(dataManager.currentSessionName)
                            .font(.system(size: size * 0.10, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .onTapGesture {
                // Toggle timer
                dataManager.toggleSession()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Activate Flow AI
                // TODO: Implement Flow AI activation
                print("Flow AI activated")
            } onPressingChanged: { pressing in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isLongPressing = pressing
                }
            }
            .scaleEffect(isLongPressing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLongPressing)
            .onAppear {
                startPulseAnimation()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

#Preview {
    WatchOrbView()
        .frame(width: 120, height: 120)
        .environmentObject(WatchDataManager.shared)
}
