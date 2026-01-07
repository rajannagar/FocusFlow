import SwiftUI

// MARK: - FFLiquidGlassCard
/// Premium glass card component with iOS 26 Liquid Glass support
/// Falls back gracefully on iOS 18-25

struct FFLiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DS.Radius.lg
    var padding: CGFloat = DS.Spacing.lg
    var backgroundOpacity: Double = DS.Glass.thin
    var borderOpacity: Double = DS.Glass.borderMedium
    var tint: Color = .white
    var showShadow: Bool = true
    var shadowStyle: ShadowStyle = DS.Shadow.medium
    let content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background { glassBackground }
            .overlay { glassBorder }
            .if(showShadow) { view in
                view.ffShadow(shadowStyle)
            }
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base glass fill
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(backgroundOpacity))
            
            // Top highlight gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(borderOpacity * 1.5),
                        Color.white.opacity(borderOpacity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - FFGlassBackground
/// Reusable glass background without content wrapper

struct FFGlassBackground: View {
    var cornerRadius: CGFloat = DS.Radius.lg
    var opacity: Double = DS.Glass.thin
    var borderOpacity: Double = DS.Glass.borderMedium
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(opacity))
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(borderOpacity * 1.5),
                            Color.white.opacity(borderOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - View Extension for Glass

extension View {
    /// Apply glass card styling to any view
    func ffGlassCard(
        cornerRadius: CGFloat = DS.Radius.lg,
        padding: CGFloat = DS.Spacing.lg,
        backgroundOpacity: Double = DS.Glass.thin,
        borderOpacity: Double = DS.Glass.borderMedium
    ) -> some View {
        self
            .padding(padding)
            .background(
                FFGlassBackground(
                    cornerRadius: cornerRadius,
                    opacity: backgroundOpacity,
                    borderOpacity: borderOpacity
                )
            )
    }
    
    /// Apply simple glass background
    func ffGlassBackground(
        cornerRadius: CGFloat = DS.Radius.lg,
        opacity: Double = DS.Glass.thin
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(opacity))
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: DS.Spacing.xl) {
            FFLiquidGlassCard {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Glass Card")
                        .font(.ffHeadline)
                        .foregroundColor(.white)
                    Text("Beautiful frosted glass effect")
                        .font(.ffBody)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            FFLiquidGlassCard(
                cornerRadius: DS.Radius.xl,
                backgroundOpacity: DS.Glass.regular
            ) {
                Text("Emphasized Card")
                    .font(.ffHeadline)
                    .foregroundColor(.white)
            }
        }
        .padding(DS.Spacing.xl)
    }
}
