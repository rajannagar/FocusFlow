import SwiftUI

struct ProRequiredView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    // Theme colors (Forest theme - default)
    private let gradientTop = Color(red: 0.05, green: 0.11, blue: 0.09)
    private let gradientBottom = Color(red: 0.13, green: 0.22, blue: 0.18)
    private let accentColor = Color(red: 0.55, green: 0.90, blue: 0.70)
    
    var body: some View {
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
                    // App icon
                    Image(systemName: "target")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(accentColor)
                        .padding(.top, 8)
                    
                    Text("FocusFlow Watch")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal)
                    
                    // Pro required message
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(accentColor.opacity(0.8))
                        
                        Text("Pro Feature")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("The Watch app is available with FocusFlow Pro.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                    
                    // Learn more button
                    Button(action: {
                        connectivityManager.requestOpenProUpgrade()
                    }) {
                        HStack {
                            Image(systemName: "iphone")
                                .font(.caption)
                            Text("Learn More on iPhone")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // Already pro hint
                    Text("Already Pro? Make sure you're signed in on iPhone.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    ProRequiredView()
        .environmentObject(WatchConnectivityManager.shared)
}
