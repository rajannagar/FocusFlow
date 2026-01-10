import SwiftUI

// =========================================================
// MARK: - Focus Info Sheet (Premium themed)
// =========================================================

struct FocusInfoSheet: View {
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss

    private var details: [(icon: String, title: String, text: String)] {
        [
            ("play.circle.fill", "Start • Pause • Resume",
             "Tap Start to begin. Tap again to pause. Tap Resume to continue anytime."),

            ("checkmark.seal.fill", "When sessions get recorded",
             "Completed sessions are always recorded. If you end early, we record it only if you focused for at least 1 minute AND you hit either 5 minutes OR 40% of the planned session — whichever happens first."),

            ("lock.fill", "Lock screen & background",
             "The timer keeps running while your screen is locked. If it finishes while you're away, it will still record the session."),

            ("headphones", "Music & sounds",
             "Tap the headphones icon next to your intention to pick a focus sound or connect your preferred music app."),

            ("sparkles", "Vibe / ambience",
             "Tap Vibe to change the background atmosphere and intensity. This is purely visual and helps you get into the zone."),

            ("slider.horizontal.3", "Presets",
             "Presets help you jump into modes fast. Switching presets resets the current timer setup.")
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Themed gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        theme.accentPrimary.opacity(0.1),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle radial glow
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(0.15),
                        theme.accentSecondary.opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 88, height: 88)
                                
                                Image(systemName: "timer")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [theme.accentPrimary, theme.accentSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("How Focus Works")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("A quick guide to the timer, controls, and recording rules.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Detail Sections
                        VStack(spacing: 16) {
                            ForEach(Array(details.enumerated()), id: \.offset) { index, item in
                                FocusInfoSection(
                                    icon: item.icon,
                                    title: item.title,
                                    text: item.text,
                                    theme: theme
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Pro tip
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Pro Tip")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Set an intention before starting — it helps you stay accountable and creates better focus history.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.accentPrimary)
                }
            }
        }
    }
}

// MARK: - Focus Info Section

private struct FocusInfoSection: View {
    let icon: String
    let title: String
    let text: String
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
