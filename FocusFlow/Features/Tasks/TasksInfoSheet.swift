import SwiftUI

// =========================================================
// MARK: - Tasks Info Sheet (Premium themed)
// =========================================================

struct TasksInfoSheet: View {
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss

    private var details: [(icon: String, title: String, text: String)] {
        [
            ("checkmark.circle.fill",
             "Complete Tasks",
             "Tap the circle next to any task to mark it complete. Completed tasks move to the bottom of your list."),

            ("clock.fill",
             "Duration & Focus",
             "Set a duration for your task. Tasks with duration can be converted to focus presets — tap the timer icon when editing."),

            ("bell.fill",
             "Reminders",
             "Set a reminder time and we'll notify you before your task is due. Great for time-sensitive items."),

            ("repeat",
             "Recurring Tasks",
             "Make tasks repeat daily, weekly, or on specific days. Perfect for habits and routines you want to build."),

            ("calendar",
             "Date Navigation",
             "Swipe through dates at the top, or tap the calendar icon to jump to any date. Plan ahead or review past days."),

            ("trash.fill",
             "Delete Tasks",
             "Swipe left on a task to delete. For recurring tasks, choose to delete just one occurrence or the entire series.")
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
                                
                                Image(systemName: "checklist")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [theme.accentPrimary, theme.accentSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("How Tasks Work")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Plan your day with tasks, set reminders, and track your progress.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Detail Sections
                        VStack(spacing: 16) {
                            ForEach(Array(details.enumerated()), id: \.offset) { index, item in
                                TasksInfoSection(
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
                            
                            Text("Set reminders for time-sensitive tasks and use recurring tasks for daily habits to stay on track.")
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

// MARK: - Tasks Info Section

private struct TasksInfoSection: View {
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

