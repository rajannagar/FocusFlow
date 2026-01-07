import SwiftUI

// MARK: - FFDesignSystem
// Single source of truth for all design tokens in FocusFlow

enum FFDesignSystem {
    
    // MARK: - Spacing Scale (4pt base unit)
    enum Spacing {
        /// 2pt - Micro gaps
        static let xxxs: CGFloat = 2
        /// 4pt - Icon to text
        static let xxs: CGFloat = 4
        /// 6pt - Tight grouping
        static let xs: CGFloat = 6
        /// 8pt - Related elements
        static let sm: CGFloat = 8
        /// 12pt - Section elements
        static let md: CGFloat = 12
        /// 16pt - Card padding
        static let lg: CGFloat = 16
        /// 20pt - Screen padding (STANDARD)
        static let xl: CGFloat = 20
        /// 24pt - Section gaps
        static let xxl: CGFloat = 24
        /// 32pt - Major sections
        static let xxxl: CGFloat = 32
        /// 48pt - Large gaps
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius Scale
    enum Radius {
        /// 8pt - Small badges
        static let xs: CGFloat = 8
        /// 12pt - Pills, chips
        static let sm: CGFloat = 12
        /// 16pt - Buttons, inputs
        static let md: CGFloat = 16
        /// 20pt - Cards
        static let lg: CGFloat = 20
        /// 24pt - Large cards, sheets
        static let xl: CGFloat = 24
        /// 28pt - Extra large
        static let xxl: CGFloat = 28
        /// 999pt - Capsules, circles
        static let full: CGFloat = 999
    }
    
    // MARK: - Typography Scale
    enum Font {
        /// 9pt - Tiny badges
        static let tiny: CGFloat = 9
        /// 10pt - Badges, tiny labels
        static let micro: CGFloat = 10
        /// 11pt - Section headers, hints
        static let caption: CGFloat = 11
        /// 12pt - Meta text, timestamps
        static let small: CGFloat = 12
        /// 13pt - Secondary text
        static let footnote: CGFloat = 13
        /// 15pt - Body text (STANDARD)
        static let body: CGFloat = 15
        /// 16pt - Emphasis, buttons
        static let callout: CGFloat = 16
        /// 18pt - Card titles
        static let headline: CGFloat = 18
        /// 22pt - Section titles
        static let title3: CGFloat = 22
        /// 24pt - Screen titles
        static let title: CGFloat = 24
        /// 28pt - Large titles
        static let title2: CGFloat = 28
        /// 32pt - Hero text
        static let largeTitle: CGFloat = 32
        /// 44pt - Timer displays
        static let display: CGFloat = 44
    }
    
    // MARK: - Icon Button Sizes
    enum IconButton {
        /// 28pt - Tiny inline actions
        static let xs: CGFloat = 28
        /// 32pt - Small inline actions
        static let sm: CGFloat = 32
        /// 36pt - Header buttons (STANDARD)
        static let md: CGFloat = 36
        /// 44pt - Primary actions
        static let lg: CGFloat = 44
        /// 56pt - FAB (Floating Action Button)
        static let xl: CGFloat = 56
    }
    
    // MARK: - Glass Effects
    enum Glass {
        // Background fills
        /// 0.03 - Ultra subtle backgrounds
        static let ultraThin: Double = 0.03
        /// 0.04 - Very subtle backgrounds (common pattern)
        static let veryThin: Double = 0.04
        /// 0.05 - Card backgrounds
        static let thin: Double = 0.05
        /// 0.06 - Subtle emphasis
        static let subtle: Double = 0.06
        /// 0.08 - Input backgrounds, emphasized
        static let regular: Double = 0.08
        /// 0.12 - Strong emphasis
        static let thick: Double = 0.12
        /// 0.18 - Selected states
        static let solid: Double = 0.18
        
        // Border opacities
        /// 0.06 - Subtle borders
        static let borderSubtle: Double = 0.06
        /// 0.10 - Normal borders
        static let borderMedium: Double = 0.10
        /// 0.15 - Strong borders
        static let borderStrong: Double = 0.15
        
        // Blur radii
        /// 10pt - Light blur
        static let blurLight: CGFloat = 10
        /// 20pt - Medium blur
        static let blurMedium: CGFloat = 20
        /// 40pt - Heavy blur
        static let blurHeavy: CGFloat = 40
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = ShadowStyle(opacity: 0.10, radius: 4, y: 2)
        static let medium = ShadowStyle(opacity: 0.15, radius: 12, y: 6)
        static let large = ShadowStyle(opacity: 0.20, radius: 20, y: 10)
        static let glow = ShadowStyle(opacity: 0.25, radius: 16, y: 0)
        static let float = ShadowStyle(opacity: 0.30, radius: 24, y: 12)
    }
    
    // MARK: - Animation Presets
    enum Animation {
        /// Quick response (0.3s) - buttons, toggles
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        /// Smooth transition (0.5s) - cards, panels
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.9)
        /// Bouncy effect (0.4s) - celebrations, emphasis
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        /// Slow reveal (0.7s) - page transitions
        static let slow = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.85)
        /// Micro interaction (0.2s) - instant feedback
        static let micro = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.9)
        /// Snappy response (0.25s) - selection changes
        static let snappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.85)
        /// Elastic bounce (0.5s) - playful animations
        static let elastic = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.5)
        /// Gentle settle (0.6s) - modal presentations
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.9)
    }
    
    // MARK: - Haptic Patterns
    /// Standardized haptic feedback for consistent tactile experience
    enum Haptic {
        /// Light tap - navigation, toggles, selection
        static func tap() { Haptics.impact(.light) }
        /// Medium tap - confirmations, primary actions
        static func confirm() { Haptics.impact(.medium) }
        /// Heavy tap - warnings, destructive actions
        static func heavy() { Haptics.impact(.heavy) }
        /// Soft tap - subtle feedback, hover-like
        static func soft() { Haptics.impact(.soft) }
        /// Rigid tap - firm feedback
        static func rigid() { Haptics.impact(.rigid) }
        /// Success notification
        static func success() { Haptics.notification(.success) }
        /// Warning notification  
        static func warning() { Haptics.notification(.warning) }
        /// Error notification
        static func error() { Haptics.notification(.error) }
        /// Selection changed
        static func selection() { Haptics.selection() }
    }
    
    // MARK: - Transition Presets
    /// Standard transitions for consistent enter/exit animations
    enum Transition {
        /// Fade + scale up - cards, modals
        static let scaleUp = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
        /// Fade + scale down - dismissals
        static let scaleDown = AnyTransition.opacity.combined(with: .scale(scale: 1.05))
        /// Slide from bottom + fade - sheets, toasts
        static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        /// Slide from top + fade - notifications
        static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)
        /// Slide from right + fade - push navigation
        static let slideRight = AnyTransition.move(edge: .trailing).combined(with: .opacity)
        /// Slide from left + fade - pop navigation  
        static let slideLeft = AnyTransition.move(edge: .leading).combined(with: .opacity)
        /// Blur + fade - overlays
        static let blur = AnyTransition.opacity
        /// Spring scale - celebrations
        static let pop = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    }
    
    // MARK: - Press Scale Values
    enum PressScale {
        /// Subtle press - text buttons (0.98)
        static let subtle: CGFloat = 0.98
        /// Normal press - most buttons (0.96)
        static let normal: CGFloat = 0.96
        /// Bouncy press - FABs, cards (0.94)
        static let bouncy: CGFloat = 0.94
        /// Deep press - large buttons (0.92)
        static let deep: CGFloat = 0.92
    }
    
    // MARK: - Timing
    enum Duration {
        static let instant: Double = 0.1
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 0.8
    }
}

// MARK: - Shadow Style Helper
struct ShadowStyle {
    let opacity: Double
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - Convenience Typealiases
typealias DS = FFDesignSystem
typealias Spacing = DS.Spacing
typealias Radius = DS.Radius

// MARK: - View Extensions

extension View {
    /// Apply standard screen horizontal padding
    func ffScreenPadding() -> some View {
        self.padding(.horizontal, DS.Spacing.xl)
    }
    
    /// Apply standard card padding
    func ffCardPadding() -> some View {
        self.padding(DS.Spacing.lg)
    }
    
    /// Apply shadow style
    func ffShadow(_ style: ShadowStyle, color: Color = .black) -> some View {
        self.shadow(
            color: color.opacity(style.opacity),
            radius: style.radius,
            y: style.y
        )
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply when condition is met
    @ViewBuilder
    func when<Transform: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply standard animation
    func ffAnimated(_ animation: SwiftUI.Animation = DS.Animation.quick) -> some View {
        self.animation(animation, value: UUID())
    }
    
    /// Apply transition with standard animation
    func ffTransition(_ transition: AnyTransition, animation: SwiftUI.Animation = DS.Animation.smooth) -> some View {
        self.transition(transition)
            .animation(animation, value: UUID())
    }
    
    /// Staggered appear animation for lists
    func ffStaggered(index: Int, baseDelay: Double = 0.05) -> some View {
        self.opacity(1)
            .animation(DS.Animation.smooth.delay(Double(index) * baseDelay), value: index)
    }
    
    /// Glow effect on press
    func ffGlowEffect(color: Color, isActive: Bool) -> some View {
        self.shadow(color: isActive ? color.opacity(0.4) : .clear, radius: isActive ? 12 : 0, y: 0)
            .animation(DS.Animation.micro, value: isActive)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Standard white with glass opacity
    static func glass(_ opacity: Double) -> Color {
        Color.white.opacity(opacity)
    }
}

// MARK: - Font Extensions

extension SwiftUI.Font {
    /// FocusFlow standard font
    static func ff(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular, design: SwiftUI.Font.Design = .default) -> SwiftUI.Font {
        .system(size: size, weight: weight, design: design)
    }
    
    /// Body text - 15pt medium
    static var ffBody: SwiftUI.Font {
        .system(size: DS.Font.body, weight: .medium)
    }
    
    /// Caption - 11pt bold rounded with tracking
    static var ffCaption: SwiftUI.Font {
        .system(size: DS.Font.caption, weight: .bold, design: .rounded)
    }
    
    /// Title - 24pt bold
    static var ffTitle: SwiftUI.Font {
        .system(size: DS.Font.title, weight: .bold)
    }
    
    /// Headline - 18pt semibold
    static var ffHeadline: SwiftUI.Font {
        .system(size: DS.Font.headline, weight: .semibold)
    }
    
    /// Button text - 16pt semibold
    static var ffButton: SwiftUI.Font {
        .system(size: DS.Font.callout, weight: .semibold)
    }
}
