import SwiftUI

// MARK: - FFIconButton
/// Standardized icon button used in headers and actions

struct FFIconButton: View {
    let icon: String
    var size: CGFloat = DS.IconButton.md
    var iconSize: CGFloat = 16
    var backgroundColor: Color = .white.opacity(DS.Glass.regular)
    var foregroundColor: Color = .white.opacity(0.8)
    var borderColor: Color = .white.opacity(DS.Glass.borderSubtle)
    var showBorder: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            DS.Haptic.tap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .overlay {
                    if showBorder {
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - FFPrimaryButton
/// Primary action button with gradient background

struct FFPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var height: CGFloat = 54
    var cornerRadius: CGFloat = DS.Radius.md
    var theme: AppTheme? = nil
    let action: () -> Void
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            DS.Haptic.confirm()
            action()
        }) {
            HStack(spacing: DS.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: DS.Font.callout, weight: .semibold))
                    }
                    Text(title)
                        .font(.ffButton)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(FFGlowPressButtonStyle(glowColor: currentTheme.accentPrimary))
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - FFSecondaryButton
/// Secondary button (ghost/outline style)

struct FFSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 48
    var cornerRadius: CGFloat = DS.Radius.md
    var backgroundOpacity: Double = DS.Glass.regular
    var borderOpacity: Double = DS.Glass.borderMedium
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            DS.Haptic.tap()
            action()
        }) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: DS.Font.body, weight: .medium))
                }
                Text(title)
                    .font(.system(size: DS.Font.body, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(backgroundOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - FFTextButton
/// Text-only button for links and tertiary actions

struct FFTextButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .white.opacity(0.7)
    var fontSize: CGFloat = DS.Font.body
    var underline: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            DS.Haptic.soft()
            action()
        }) {
            HStack(spacing: DS.Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize - 1, weight: .medium))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .semibold))
                    .if(underline) { $0.underline() }
            }
            .foregroundColor(color)
        }
        .buttonStyle(FFPressButtonStyle(scale: DS.PressScale.subtle))
    }
}

// MARK: - FFPillButton
/// Small pill-shaped button for inline actions

struct FFPillButton: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    var theme: AppTheme? = nil
    let action: () -> Void
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        Button(action: {
            DS.Haptic.selection()
            action()
        }) {
            HStack(spacing: DS.Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: DS.Font.caption, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: DS.Font.footnote, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [currentTheme.accentPrimary, currentTheme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(DS.Glass.thin)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.white.opacity(0.3)
                            : Color.white.opacity(DS.Glass.borderSubtle),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(FFPressButtonStyle())
    }
}

// MARK: - FFFloatingActionButton
/// Floating action button (FAB)

struct FFFloatingActionButton: View {
    let icon: String
    var size: CGFloat = DS.IconButton.xl
    var theme: AppTheme? = nil
    let action: () -> Void
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        Button(action: {
            DS.Haptic.confirm()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [currentTheme.accentPrimary, currentTheme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(FFGlowPressButtonStyle(scale: DS.PressScale.deep, glowColor: currentTheme.accentPrimary))
    }
}

// MARK: - Button Press Style

struct FFPressButtonStyle: ButtonStyle {
    var scale: CGFloat = DS.PressScale.normal
    var enableGlow: Bool = false
    var glowColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(DS.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - Glowing Press Style (for accent buttons)

struct FFGlowPressButtonStyle: ButtonStyle {
    var scale: CGFloat = DS.PressScale.normal
    var glowColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .shadow(
                color: configuration.isPressed ? glowColor.opacity(0.5) : glowColor.opacity(0.25),
                radius: configuration.isPressed ? 16 : 8,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(DS.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - Bouncy Press Style (for playful interactions)

struct FFBouncyPressButtonStyle: ButtonStyle {
    var scale: CGFloat = DS.PressScale.bouncy
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(DS.Animation.bounce, value: configuration.isPressed)
    }
}

// MARK: - Card Press Style (for tappable cards)

struct FFCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.05 : 0))
            )
            .animation(DS.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: DS.Spacing.xl) {
            HStack(spacing: DS.Spacing.md) {
                FFIconButton(icon: "gear") {}
                FFIconButton(icon: "bell") {}
                FFIconButton(icon: "xmark", size: DS.IconButton.sm, iconSize: 14) {}
            }
            
            FFPrimaryButton(title: "Start Focus", icon: "play.fill") {}
            
            FFSecondaryButton(title: "View History", icon: "clock") {}
            
            HStack(spacing: DS.Spacing.sm) {
                FFPillButton(title: "25 min", isSelected: true) {}
                FFPillButton(title: "45 min") {}
                FFPillButton(title: "60 min") {}
            }
            
            FFTextButton(title: "Forgot Password?", underline: true) {}
            
            Spacer()
            
            HStack {
                Spacer()
                FFFloatingActionButton(icon: "plus") {}
            }
            .padding(.trailing, DS.Spacing.xl)
        }
        .padding(DS.Spacing.xl)
    }
}
