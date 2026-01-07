import SwiftUI

// MARK: - Skeleton Loading (Shimmer)
// Beautiful loading placeholders that shimmer

// MARK: - FFShimmer Modifier

struct FFShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200
    let animation: Animation
    
    init(animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.2),
                            .white.opacity(0.3),
                            .white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(animation) {
                            phase = geo.size.width + 200
                        }
                    }
                }
                .mask(content)
            )
    }
}

extension View {
    /// Add shimmer loading effect
    func ffShimmer() -> some View {
        self.modifier(FFShimmerModifier())
    }
}

// MARK: - FFSkeletonCard
/// Card-shaped skeleton placeholder

struct FFSkeletonCard: View {
    var height: CGFloat = 100
    var cornerRadius: CGFloat = DS.Radius.lg
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(height: height)
            .ffShimmer()
    }
}

// MARK: - FFSkeletonRow
/// Row-shaped skeleton with avatar and text lines

struct FFSkeletonRow: View {
    var showAvatar: Bool = true
    var avatarSize: CGFloat = 44
    var lines: Int = 2
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            if showAvatar {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: avatarSize, height: avatarSize)
            }
            
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                ForEach(0..<lines, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(index == 0 ? 0.08 : 0.05))
                        .frame(width: index == 0 ? 140 : 90, height: index == 0 ? 14 : 10)
                }
            }
            
            Spacer()
        }
        .ffShimmer()
    }
}

// MARK: - FFSkeletonText
/// Text line skeleton

struct FFSkeletonText: View {
    var width: CGFloat = 120
    var height: CGFloat = 14
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: height)
            .ffShimmer()
    }
}

// MARK: - FFSkeletonCircle
/// Circular skeleton

struct FFSkeletonCircle: View {
    var size: CGFloat = 44
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: size, height: size)
            .ffShimmer()
    }
}

// MARK: - FFSkeletonList
/// Multiple skeleton rows

struct FFSkeletonList: View {
    var count: Int = 5
    var showAvatar: Bool = true
    
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            ForEach(0..<count, id: \.self) { _ in
                FFSkeletonRow(showAvatar: showAvatar)
            }
        }
    }
}

// MARK: - FFSkeletonGrid
/// Grid of skeleton cards

struct FFSkeletonGrid: View {
    var columns: Int = 2
    var count: Int = 4
    var cardHeight: CGFloat = 100
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.md), count: columns),
            spacing: DS.Spacing.md
        ) {
            ForEach(0..<count, id: \.self) { _ in
                FFSkeletonCard(height: cardHeight)
            }
        }
    }
}

// MARK: - FFLoadingView
/// Full-screen loading with animated orb

struct FFLoadingView: View {
    var message: String? = nil
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var isAnimating = false
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            // Animated orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(currentTheme.accentPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                
                // Inner orb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                currentTheme.accentPrimary,
                                currentTheme.accentSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            if let message {
                Text(message)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - FFSpinner
/// Simple spinning loader

struct FFSpinner: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 3
    var color: Color = .white
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - FFProgressBar
/// Animated progress bar

struct FFProgressBar: View {
    let progress: Double // 0 to 1
    var height: CGFloat = 8
    var cornerRadius: CGFloat = DS.Radius.full
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                
                // Fill
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                currentTheme.accentPrimary,
                                currentTheme.accentSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(DS.Animation.smooth, value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - FFContentLoader
/// Loading wrapper that shows skeleton while loading

struct FFContentLoader<Content: View, Skeleton: View>: View {
    let isLoading: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let skeleton: () -> Skeleton
    
    var body: some View {
        if isLoading {
            skeleton()
                .transition(.opacity)
        } else {
            content()
                .transition(.opacity)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: DS.Spacing.xxl) {
                Text("Skeleton Examples")
                    .font(.ffTitle)
                    .foregroundColor(.white)
                
                FFSkeletonCard(height: 80)
                
                FFSkeletonList(count: 3)
                
                FFSkeletonGrid(count: 4, cardHeight: 80)
                
                FFDivider()
                
                Text("Loading States")
                    .font(.ffHeadline)
                    .foregroundColor(.white)
                
                HStack(spacing: DS.Spacing.xl) {
                    FFSpinner()
                    FFSpinner(size: 32, color: .green)
                    FFSpinner(size: 40, lineWidth: 4, color: .orange)
                }
                
                FFProgressBar(progress: 0.65)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            .padding(DS.Spacing.xl)
        }
    }
}
