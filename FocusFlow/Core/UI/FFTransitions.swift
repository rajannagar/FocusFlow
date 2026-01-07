import SwiftUI

// MARK: - Transitions & Scroll Effects
// Smooth page transitions and scroll-based effects

// MARK: - Custom Transitions

extension AnyTransition {
    /// Slide up with opacity
    static var ffSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Slide down with opacity
    static var ffSlideDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Scale with opacity
    static var ffScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    /// Blur transition
    static var ffBlur: AnyTransition {
        .modifier(
            active: FFBlurTransitionModifier(blur: 10, opacity: 0),
            identity: FFBlurTransitionModifier(blur: 0, opacity: 1)
        )
    }
    
    /// Pop in from center
    static var ffPop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    /// Slide from leading
    static var ffSlideLeading: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    /// Slide from trailing
    static var ffSlideTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

struct FFBlurTransitionModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Scroll Offset Reader

struct FFScrollOffsetReader: View {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: FFScrollOffsetKey.self,
                    value: -geo.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
        .onPreferenceChange(FFScrollOffsetKey.self) { offset = $0 }
    }
}

struct FFScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Parallax Header

struct FFParallaxHeader<Content: View>: View {
    let height: CGFloat
    let coordinateSpace: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named(coordinateSpace)).minY
            let isScrollingUp = minY > 0
            
            content()
                .frame(
                    width: geo.size.width,
                    height: height + (isScrollingUp ? minY : 0)
                )
                .offset(y: isScrollingUp ? -minY : 0)
                .clipped()
        }
        .frame(height: height)
    }
}

// MARK: - Blur Header on Scroll

struct FFBlurHeaderOnScroll: ViewModifier {
    let threshold: CGFloat
    @Binding var scrollOffset: CGFloat
    
    private var progress: CGFloat {
        min(max(0, scrollOffset / threshold), 1)
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(progress)
            }
    }
}

extension View {
    func ffBlurOnScroll(threshold: CGFloat = 100, offset: Binding<CGFloat>) -> some View {
        self.modifier(FFBlurHeaderOnScroll(threshold: threshold, scrollOffset: offset))
    }
}

// MARK: - Sticky Header

struct FFStickyHeader<Content: View>: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    @Binding var scrollOffset: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content // progress 0-1
    
    private var progress: CGFloat {
        let range = maxHeight - minHeight
        return min(max(0, scrollOffset / range), 1)
    }
    
    private var currentHeight: CGFloat {
        maxHeight - (progress * (maxHeight - minHeight))
    }
    
    var body: some View {
        content(progress)
            .frame(height: currentHeight)
    }
}

// MARK: - Fade on Scroll

struct FFFadeOnScroll: ViewModifier {
    let threshold: CGFloat
    @Binding var scrollOffset: CGFloat
    let fadeIn: Bool
    
    private var opacity: Double {
        let progress = min(max(0, scrollOffset / threshold), 1)
        return fadeIn ? progress : 1 - progress
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
    }
}

extension View {
    /// Fade in as user scrolls down
    func ffFadeInOnScroll(threshold: CGFloat = 100, offset: Binding<CGFloat>) -> some View {
        self.modifier(FFFadeOnScroll(threshold: threshold, scrollOffset: offset, fadeIn: true))
    }
    
    /// Fade out as user scrolls down
    func ffFadeOutOnScroll(threshold: CGFloat = 100, offset: Binding<CGFloat>) -> some View {
        self.modifier(FFFadeOnScroll(threshold: threshold, scrollOffset: offset, fadeIn: false))
    }
}

// MARK: - Scale on Scroll

struct FFScaleOnScroll: ViewModifier {
    let threshold: CGFloat
    let minScale: CGFloat
    @Binding var scrollOffset: CGFloat
    
    private var scale: CGFloat {
        let progress = min(max(0, scrollOffset / threshold), 1)
        return 1 - (progress * (1 - minScale))
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
    }
}

extension View {
    /// Scale down as user scrolls
    func ffScaleOnScroll(threshold: CGFloat = 100, minScale: CGFloat = 0.8, offset: Binding<CGFloat>) -> some View {
        self.modifier(FFScaleOnScroll(threshold: threshold, minScale: minScale, scrollOffset: offset))
    }
}

// MARK: - Matched Geometry Namespace Environment

struct FFNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var ffNamespace: Namespace.ID? {
        get { self[FFNamespaceKey.self] }
        set { self[FFNamespaceKey.self] = newValue }
    }
}

// MARK: - Page Transition Wrapper

struct FFPageTransition<Content: View>: View {
    let content: () -> Content
    
    @State private var isVisible = false
    
    var body: some View {
        content()
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(DS.Animation.smooth) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extension for Scroll Tracking

extension View {
    /// Wraps view in a ScrollView with offset tracking
    func ffScrollView(
        offset: Binding<CGFloat>,
        coordinateSpace: String = "scroll",
        showsIndicators: Bool = false
    ) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            FFScrollOffsetReader(coordinateSpace: coordinateSpace, offset: offset)
            self
        }
        .coordinateSpace(name: coordinateSpace)
    }
}

// MARK: - Refresh Control

struct FFRefreshControl: View {
    let isRefreshing: Bool
    let progress: CGFloat
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var rotation: Double = 0
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
            
            // Progress
            Circle()
                .trim(from: 0, to: isRefreshing ? 0.8 : progress)
                .stroke(
                    LinearGradient(
                        colors: [currentTheme.accentPrimary, currentTheme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(isRefreshing ? rotation : -90))
        }
        .frame(width: 28, height: 28)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = -90
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var scrollOffset: CGFloat = 0
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sticky header
                    HStack {
                        Text("Header")
                            .font(.ffTitle)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.vertical, DS.Spacing.md)
                    .ffBlurOnScroll(offset: $scrollOffset)
                    
                    // Scrolling content
                    ScrollView {
                        FFScrollOffsetReader(coordinateSpace: "scroll", offset: $scrollOffset)
                        
                        VStack(spacing: DS.Spacing.md) {
                            // Fades out on scroll
                            Text("Welcome!")
                                .font(.ffHeadline)
                                .foregroundColor(.white)
                                .ffFadeOutOnScroll(offset: $scrollOffset)
                            
                            ForEach(0..<20, id: \.self) { index in
                                FFLiquidGlassCard {
                                    Text("Card \(index + 1)")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .ffStaggeredAppear(index: index)
                            }
                        }
                        .padding(DS.Spacing.xl)
                    }
                    .coordinateSpace(name: "scroll")
                }
            }
        }
    }
    
    return PreviewWrapper()
}
