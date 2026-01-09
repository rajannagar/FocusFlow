import SwiftUI

struct WatchLaunchView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    
    // Theme colors (Forest theme - default)
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient (matches iPhone)
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle glow effect
                Circle()
                    .fill(accentColor.opacity(0.25))
                    .blur(radius: 40)
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .opacity(glowOpacity)
                
                VStack(spacing: 8) {
                    // App icon
                    Image(systemName: "target")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.5), radius: 10)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App name
                    Text("FocusFlow")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            runAnimation()
        }
    }
    
    private func runAnimation() {
        // Glow fades in
        withAnimation(.easeOut(duration: 0.6)) {
            glowOpacity = 1.0
        }
        
        // Logo scales and fades in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }
    }
}

#Preview {
    WatchLaunchView()
}
