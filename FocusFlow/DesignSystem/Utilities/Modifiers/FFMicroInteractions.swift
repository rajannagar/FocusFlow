import SwiftUI

// MARK: - Micro-interactions
// Button press effects, glow, pulse, and other subtle animations

// MARK: - FFGlowEffect
/// Adds a glow effect on tap

struct FFGlowEffect: ViewModifier {
    @State private var isGlowing = false
    let color: Color
    let cornerRadius: CGFloat
    
    init(color: Color = .white, cornerRadius: CGFloat = DS.Radius.lg) {
        self.color = color
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(isGlowing ? 0.6 : 0), lineWidth: 2)
                    .blur(radius: isGlowing ? 4 : 0)
            )
            .onTapGesture {
                withAnimation(DS.Animation.quick) {
                    isGlowing = true
                }
                withAnimation(DS.Animation.quick.delay(0.2)) {
                    isGlowing = false
                }
            }
    }
}

// MARK: - FFPulseModifier
/// Creates a subtle pulsing animation

struct FFPulseModifier: ViewModifier {
    @State private var isPulsing = false
    let scale: CGFloat
    let opacity: Double
    
    init(scale: CGFloat = 1.02, opacity: Double = 0.95) {
        self.scale = scale
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? opacity : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - FFBounceModifier
/// Bounces the view on value change

struct FFBounceModifier<V: Equatable>: ViewModifier {
    let trigger: V
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.05 : 1.0)
            .onChange(of: trigger) { _, _ in
                withAnimation(DS.Animation.bounce) {
                    isBouncing = true
                }
                withAnimation(DS.Animation.bounce.delay(0.15)) {
                    isBouncing = false
                }
            }
    }
}

// MARK: - FFShakeModifier
/// Shakes the view (for errors)

struct FFShakeModifier: ViewModifier {
    @Binding var isShaking: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? -10 : 0)
            .animation(
                isShaking
                    ? .linear(duration: 0.05).repeatCount(6, autoreverses: true)
                    : .default,
                value: isShaking
            )
            .onChange(of: isShaking) { _, newValue in
                if newValue {
                    DS.Haptic.error()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShaking = false
                    }
                }
            }
    }
}

// MARK: - FFRippleEffect
/// Creates a ripple effect from the tap point

struct FFRippleEffect: ViewModifier {
    @State private var ripples: [Ripple] = []
    let color: Color
    
    struct Ripple: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat = 0
        var opacity: Double = 0.5
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        ForEach(ripples) { ripple in
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .scaleEffect(ripple.scale)
                                .opacity(ripple.opacity)
                                .position(ripple.position)
                        }
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture { location in
                addRipple(at: location)
            }
    }
    
    private func addRipple(at position: CGPoint) {
        let ripple = Ripple(position: position)
        ripples.append(ripple)
        
        guard let index = ripples.firstIndex(where: { $0.id == ripple.id }) else { return }
        
        withAnimation(.easeOut(duration: 0.6)) {
            ripples[index].scale = 4
            ripples[index].opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

// MARK: - FFScaleOnAppear
/// Scales in the view on appear

struct FFScaleOnAppear: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(DS.Animation.bounce.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - FFSlideOnAppear
/// Slides in the view on appear

struct FFSlideOnAppear: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double
    
    private var offset: CGFloat {
        switch edge {
        case .top: return -30
        case .bottom: return 30
        case .leading: return -30
        case .trailing: return 30
        }
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading || edge == .trailing ? (isVisible ? 0 : offset) : 0,
                y: edge == .top || edge == .bottom ? (isVisible ? 0 : offset) : 0
            )
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(DS.Animation.smooth.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Add glow effect on tap
    func ffGlow(color: Color = .white, cornerRadius: CGFloat = DS.Radius.lg) -> some View {
        self.modifier(FFGlowEffect(color: color, cornerRadius: cornerRadius))
    }
    
    /// Add subtle pulse animation
    func ffPulse(scale: CGFloat = 1.02, opacity: Double = 0.95) -> some View {
        self.modifier(FFPulseModifier(scale: scale, opacity: opacity))
    }
    
    /// Bounce on value change
    func ffBounce<V: Equatable>(on trigger: V) -> some View {
        self.modifier(FFBounceModifier(trigger: trigger))
    }
    
    /// Shake effect (for errors)
    func ffShake(isShaking: Binding<Bool>) -> some View {
        self.modifier(FFShakeModifier(isShaking: isShaking))
    }
    
    /// Add ripple effect on tap
    func ffRipple(color: Color = .white.opacity(0.3)) -> some View {
        self.modifier(FFRippleEffect(color: color))
    }
    
    /// Scale in on appear
    func ffScaleOnAppear(delay: Double = 0) -> some View {
        self.modifier(FFScaleOnAppear(delay: delay))
    }
    
    /// Slide in on appear
    func ffSlideOnAppear(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(FFSlideOnAppear(edge: edge, delay: delay))
    }
    
    /// Staggered appear animation for list items
    func ffStaggeredAppear(index: Int, baseDelay: Double = 0.05) -> some View {
        self.modifier(FFScaleOnAppear(delay: Double(index) * baseDelay))
    }
}

// MARK: - FFHoverEffect (for iPadOS/Mac Catalyst)

struct FFHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .brightness(isHovered ? 0.05 : 0)
            .animation(DS.Animation.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    /// Add hover effect for iPad/Mac
    func ffHover() -> some View {
        self.modifier(FFHoverEffect())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: DS.Spacing.xl) {
            // Pulse effect
            FFLiquidGlassCard {
                Text("Pulsing Card")
                    .foregroundColor(.white)
            }
            .ffPulse()
            .padding(.horizontal, DS.Spacing.xl)
            
            // Scale on appear
            HStack(spacing: DS.Spacing.md) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .ffStaggeredAppear(index: index)
                }
            }
            
            // Glow effect
            FFPrimaryButton(title: "Tap for Glow") {}
                .padding(.horizontal, DS.Spacing.xl)
                .ffGlow(color: .green, cornerRadius: DS.Radius.md)
            
            // Ripple effect
            FFLiquidGlassCard {
                Text("Tap for Ripple")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .ffRipple()
        }
    }
}
