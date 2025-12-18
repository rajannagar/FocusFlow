import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 1. Design System & Theme Integration
@available(iOSApplicationExtension 18.0, *)
fileprivate struct DesignSystem {
    // Layout Constants
    static let contentPadding: CGFloat = 22
    
    struct ThemeColors {
        let top: Color
        let bottom: Color
        let accent: Color
        
        // Creates the background gradient using your app's specific colors
        var mainGradient: LinearGradient {
            LinearGradient(
                colors: [top, bottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // A subtle border matching the theme
        var borderGradient: LinearGradient {
            LinearGradient(
                colors: [accent.opacity(0.3), accent.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        // A subtle glow for the timer text
        var textShadow: Color {
            accent.opacity(0.5)
        }
    }

    static func colors(for themeID: String) -> ThemeColors {
        switch themeID {
        case "forest":
            return ThemeColors(top: Color(red: 0.05, green: 0.11, blue: 0.09), bottom: Color(red: 0.13, green: 0.22, blue: 0.18), accent: Color(red: 0.55, green: 0.90, blue: 0.70))
        case "neon":
            return ThemeColors(top: Color(red: 0.02, green: 0.05, blue: 0.12), bottom: Color(red: 0.13, green: 0.02, blue: 0.24), accent: Color(red: 0.25, green: 0.95, blue: 0.85))
        case "peach":
            return ThemeColors(top: Color(red: 0.16, green: 0.08, blue: 0.11), bottom: Color(red: 0.31, green: 0.15, blue: 0.18), accent: Color(red: 1.00, green: 0.72, blue: 0.63))
        case "cyber":
            return ThemeColors(top: Color(red: 0.06, green: 0.04, blue: 0.18), bottom: Color(red: 0.18, green: 0.09, blue: 0.32), accent: Color(red: 0.80, green: 0.60, blue: 1.00))
        case "ocean":
            return ThemeColors(top: Color(red: 0.02, green: 0.08, blue: 0.15), bottom: Color(red: 0.03, green: 0.27, blue: 0.32), accent: Color(red: 0.48, green: 0.84, blue: 1.00))
        case "sunrise":
            return ThemeColors(top: Color(red: 0.10, green: 0.06, blue: 0.20), bottom: Color(red: 0.33, green: 0.17, blue: 0.24), accent: Color(red: 1.00, green: 0.62, blue: 0.63))
        case "amber":
            return ThemeColors(top: Color(red: 0.10, green: 0.06, blue: 0.04), bottom: Color(red: 0.30, green: 0.18, blue: 0.10), accent: Color(red: 1.00, green: 0.78, blue: 0.45))
        case "mint":
            return ThemeColors(top: Color(red: 0.02, green: 0.10, blue: 0.09), bottom: Color(red: 0.08, green: 0.30, blue: 0.26), accent: Color(red: 0.60, green: 0.96, blue: 0.78))
        case "royal":
            return ThemeColors(top: Color(red: 0.05, green: 0.05, blue: 0.16), bottom: Color(red: 0.11, green: 0.17, blue: 0.32), accent: Color(red: 0.65, green: 0.72, blue: 1.00))
        case "slate":
            return ThemeColors(top: Color(red: 0.06, green: 0.07, blue: 0.11), bottom: Color(red: 0.16, green: 0.18, blue: 0.24), accent: Color(red: 0.75, green: 0.82, blue: 0.96))
        default:
            return ThemeColors(top: Color(red: 0.05, green: 0.11, blue: 0.09), bottom: Color(red: 0.13, green: 0.22, blue: 0.18), accent: Color(red: 0.55, green: 0.90, blue: 0.70))
        }
    }
}


// MARK: - 2. Widget Entry Point
@available(iOSApplicationExtension 18.0, *)
struct FocusSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            // Lock screen / banner
            LockScreenMasterpiece(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long-press)
                DynamicIslandExpandedRegion(.center) {
                    ExpandedMasterpiece(context: context)
                }
            } compactLeading: {
                // Compact leading pill
                CompactTimer(context: context)
            } compactTrailing: {
                // Compact trailing pill
                CompactVisual(context: context)
            } minimal: {
                // Minimal pill (when competing with other activities)
                MinimalMasterpiece(context: context)
            }
        }
    }
}


// MARK: - 3. Shared time helper

@available(iOSApplicationExtension 18.0, *)
fileprivate func timeText(
    for context: ActivityViewContext<FocusSessionAttributes>,
    font: Font,
    color: Color,
    dimIfPaused: Bool = true
) -> some View {
    let isPaused = context.state.isPaused
    
    return Group {
        if isPaused {
            // Static string while paused
            Text(context.state.pausedDisplayTime)
        } else {
            // Live countdown while running
            Text(context.state.endDate, style: .timer)
        }
    }
    .font(font)
    .monospacedDigit()
    .foregroundStyle(color)
    .opacity(isPaused && dimIfPaused ? 0.6 : 1.0)
}


// MARK: - 4. Lock Screen View (Updated text logic)

@available(iOSApplicationExtension 18.0, *)
struct LockScreenMasterpiece: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    
    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isPaused = context.state.isPaused
        let isCompleted = context.state.isCompleted
        
        HStack(alignment: .center, spacing: 0) {
            // LEFT: labels + timer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Switch icon based on state
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : (isPaused ? "pause.circle.fill" : "record.circle"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: !isPaused && !isCompleted)
                    
                    Text(isCompleted ? "SESSION COMPLETE" : "FOCUS SESSION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(theme.accent.opacity(0.9))
                }
                
                if isCompleted {
                    // ✅ FIXED: Show Intention Name + Completed
                    // Reduced size to 28 and added minimumScaleFactor to fit long names
                    Text("\(context.state.sessionName) - Completed")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.5) // Shrinks down if name is too long
                        .lineLimit(2)
                        .foregroundStyle(.white)
                        .shadow(color: theme.textShadow, radius: 10)
                } else {
                    // Normal Timer
                    timeText(
                        for: context,
                        font: .system(size: 44, weight: .light, design: .rounded),
                        color: .white
                    )
                    .shadow(
                        color: theme.textShadow.opacity(isPaused ? 0.0 : 0.7),
                        radius: isPaused ? 0 : 10,
                        x: 0, y: 0
                    )
                }
            }
            
            Spacer()
            
            // RIGHT: state indicator glyph (no tap)
            ZStack {
                Circle()
                    .strokeBorder(theme.accent.opacity(isPaused || isCompleted ? 0.45 : 0.7), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(theme.accent.opacity(0.12))
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: isCompleted ? "checkmark" : (isPaused ? "pause.fill" : "play.fill"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(DesignSystem.contentPadding)
        .background(Color.clear)
    }
}


// MARK: - 5. Expanded View (Updated for Completion)

@available(iOSApplicationExtension 18.0, *)
struct ExpandedMasterpiece: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    
    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isPaused = context.state.isPaused
        let isCompleted = context.state.isCompleted
        
        ZStack {
            // Black capsule
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.96))
            
            HStack(spacing: 14) {
                // LEFT: theme orb
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.16))
                    Circle()
                        .stroke(theme.accent.opacity(0.5), lineWidth: 1)
                    Image(systemName: isCompleted ? "checkmark" : "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .frame(width: 32, height: 32)
                
                // CENTER: text stack
                VStack(alignment: .leading, spacing: 2) {
                    Text(isCompleted ? "Session Complete" : "Focus Session")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    
                    if isCompleted {
                        // ✅ Show session name on island when done
                        Text(context.state.sessionName)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text("Completed")
                            .font(.caption2)
                            .foregroundStyle(theme.accent)
                    } else {
                        timeText(
                            for: context,
                            font: .system(size: 22, weight: .semibold, design: .rounded),
                            color: .white
                        )
                        
                        Text(isPaused ? "Paused" : "In progress")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                
                Spacer()
                
                // RIGHT: status orb
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .stroke(theme.accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: isCompleted ? "checkmark" : (isPaused ? "pause.fill" : "play.fill"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - 6. Compact Views

@available(iOSApplicationExtension 18.0, *)
struct CompactTimer: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    
    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isCompleted = context.state.isCompleted
        
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.accent)
                .padding(.leading, 4)
        } else {
            timeText(
                for: context,
                font: .system(size: 13, weight: .semibold, design: .rounded),
                color: theme.accent
            )
            .frame(maxWidth: 48, alignment: .leading)
            .padding(.leading, 4)
        }
    }
}

@available(iOSApplicationExtension 18.0, *)
struct CompactVisual: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    
    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isCompleted = context.state.isCompleted
        
        Circle()
            .fill(isCompleted ? theme.accent : theme.accent)
            .frame(width: 8, height: 8)
            .shadow(color: theme.accent.opacity(0.8), radius: 4)
            .padding(.trailing, 4)
    }
}


// MARK: - 7. Minimal View

@available(iOSApplicationExtension 18.0, *)
struct MinimalMasterpiece: View {
    let context: ActivityViewContext<FocusSessionAttributes>
    
    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isCompleted = context.state.isCompleted
        
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.accent)
        } else {
            timeText(
                for: context,
                font: .system(size: 9, weight: .heavy, design: .rounded),
                color: theme.accent
            )
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
    }
}
