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

        var mainGradient: LinearGradient {
            LinearGradient(
                colors: [top, bottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        var borderGradient: LinearGradient {
            LinearGradient(
                colors: [accent.opacity(0.3), accent.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        var textShadow: Color { accent.opacity(0.5) }
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
            LockScreenMasterpiece(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedMasterpiece(context: context)
                }
            } compactLeading: {
                CompactTimer(context: context)
            } compactTrailing: {
                CompactVisual(context: context)
            } minimal: {
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
    let now = Date()

    // ✅ Derive completion even if the app never set isCompleted (e.g. app killed)
    let derivedCompleted = context.state.isCompleted || (!isPaused && now >= context.state.endDate)

    return Group {
        if derivedCompleted {
            Text("Session complete")
        } else if isPaused {
            Text(context.state.pausedDisplayTime)
        } else {
            // ✅ Countdown that never counts up after end
            Text(timerInterval: now...context.state.endDate, countsDown: true)
        }
    }
    .font(font)
    .monospacedDigit()
    .foregroundStyle(color)
    .opacity(isPaused && dimIfPaused ? 0.6 : 1.0)
}

// MARK: - 4. Lock Screen View
@available(iOSApplicationExtension 18.0, *)
struct LockScreenMasterpiece: View {
    let context: ActivityViewContext<FocusSessionAttributes>

    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isPaused = context.state.isPaused
        let now = Date()
        let derivedCompleted = context.state.isCompleted || (!isPaused && now >= context.state.endDate)

        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: derivedCompleted ? "checkmark.circle.fill" : (isPaused ? "pause.circle.fill" : "record.circle"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: !isPaused && !derivedCompleted)

                    Text(derivedCompleted ? "SESSION COMPLETE" : "FOCUS SESSION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(theme.accent.opacity(0.9))
                }

                if derivedCompleted {
                    Text("\(context.state.sessionName) - Completed")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .foregroundStyle(.white)
                        .shadow(color: theme.textShadow, radius: 10)
                } else {
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

            ZStack {
                Circle()
                    .strokeBorder(theme.accent.opacity(isPaused || derivedCompleted ? 0.45 : 0.7), lineWidth: 2)
                    .background(Circle().fill(theme.accent.opacity(0.12)))
                    .frame(width: 40, height: 40)

                Image(systemName: derivedCompleted ? "checkmark" : (isPaused ? "pause.fill" : "play.fill"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(DesignSystem.contentPadding)
        .background(Color.clear)
    }
}

// MARK: - 5. Expanded View
@available(iOSApplicationExtension 18.0, *)
struct ExpandedMasterpiece: View {
    let context: ActivityViewContext<FocusSessionAttributes>

    var body: some View {
        let theme = DesignSystem.colors(for: context.state.themeID)
        let isPaused = context.state.isPaused
        let now = Date()
        let derivedCompleted = context.state.isCompleted || (!isPaused && now >= context.state.endDate)

        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.96))

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(theme.accent.opacity(0.16))
                    Circle().stroke(theme.accent.opacity(0.5), lineWidth: 1)
                    Image(systemName: derivedCompleted ? "checkmark" : "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(derivedCompleted ? "Session Complete" : "Focus Session")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    if derivedCompleted {
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

                ZStack {
                    Circle().fill(.white).frame(width: 48, height: 48)
                    Circle().stroke(theme.accent.opacity(0.3), lineWidth: 2).frame(width: 52, height: 52)

                    Image(systemName: derivedCompleted ? "checkmark" : (isPaused ? "pause.fill" : "play.fill"))
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
        let isPaused = context.state.isPaused
        let now = Date()
        let derivedCompleted = context.state.isCompleted || (!isPaused && now >= context.state.endDate)

        if derivedCompleted {
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
        Circle()
            .fill(theme.accent)
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
        let isPaused = context.state.isPaused
        let now = Date()
        let derivedCompleted = context.state.isCompleted || (!isPaused && now >= context.state.endDate)

        if derivedCompleted {
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
