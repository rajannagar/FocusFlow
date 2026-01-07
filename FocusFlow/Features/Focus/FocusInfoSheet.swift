import SwiftUI

// =========================================================
// MARK: - Focus Info Sheet (Premium themed)
// =========================================================

struct FocusInfoSheet: View {
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false

    private var details: [(String, String)] {
        [
            ("Start • Pause • Resume",
             "Tap Start to begin. Tap again to pause. Tap Resume to continue anytime."),

            ("When sessions get recorded",
             "Completed sessions are always recorded.\n\nIf you end early, we record it only if you focused for at least 1 minute AND you hit either 5 minutes OR 40% of the planned session — whichever happens first."),

            ("Lock screen & background",
             "The timer keeps running while your screen is locked. If it finishes while you're away, it will still record the session."),

            ("Music & sounds",
             "Tap the headphones icon next to your intention to pick a focus sound or connect your preferred music app."),

            ("Vibe / ambience",
             "Tap Vibe to change the background atmosphere and intensity. This is purely visual and helps you get into the zone."),

            ("Presets",
             "Presets help you jump into modes fast. Switching presets resets the current timer setup.")
        ]
    }

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, particleCount: 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }
                        .buttonStyle(FFPressButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(theme.accentPrimary.opacity(0.20))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                                .scaleEffect(appearAnimation ? 1.18 : 0.82)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.accentPrimary.opacity(0.30),
                                            theme.accentSecondary.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)

                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(theme.accentPrimary)
                                .scaleEffect(appearAnimation ? 1.0 : 0.6)
                        }
                        .padding(.top, 18)

                        Text("How Focus Works")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 18)

                        Text("A quick guide to the timer, controls, and recording rules.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 18)
                    }
                    .padding(.bottom, 26)

                    VStack(spacing: 12) {
                        ForEach(Array(details.enumerated()), id: \.offset) { index, item in
                            FocusInfoDetailCard(
                                title: item.0,
                                text: item.1,
                                iconColor: theme.accentPrimary,
                                index: index
                            )
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 24)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.82)
                                    .delay(Double(index) * 0.06 + 0.22),
                                value: appearAnimation
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: theme.accentPrimary.opacity(0.35), radius: 16, y: 8)
                    }
                    .buttonStyle(FFPressButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                    .opacity(appearAnimation ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                appearAnimation = true
            }
        }
        .colorScheme(.dark)
    }
}

private struct FocusInfoDetailCard: View {
    let title: String
    let text: String
    let iconColor: Color
    let index: Int

    private var cardIcon: String {
        let icons = ["1.circle.fill", "2.circle.fill", "3.circle.fill", "4.circle.fill", "5.circle.fill", "6.circle.fill"]
        return icons[index % icons.count]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: cardIcon)
                .font(.system(size: 24))
                .foregroundColor(iconColor.opacity(0.85))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
