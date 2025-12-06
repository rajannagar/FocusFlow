import SwiftUI
import UIKit   // for UITableViewCell appearance

// MARK: - Glass card container (local to this file)

private struct GlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @StateObject private var viewModel = HabitsViewModel()
    @ObservedObject private var appSettings = AppSettings.shared

    // State for Add Habit bottom sheet
    @State private var showingAddHabitSheet = false
    @State private var newHabitName: String = ""

    // Header icon animation
    @State private var iconPulse = false

    init() {
        // Remove default row highlight & background
        UITableViewCell.appearance().selectionStyle = .none
        UITableView.appearance().backgroundColor = .clear

        // Darker reorder handle for better visibility
        UITableView.appearance().tintColor = UIColor(white: 0.08, alpha: 1.0)
    }

    // MARK: - Derived values

    private var completedCount: Int {
        viewModel.habits.filter { $0.isDoneToday }.count
    }

    private var progress: Double {
        guard !viewModel.habits.isEmpty else { return 0 }
        return Double(completedCount) / Double(viewModel.habits.count)
    }

    private var theme: AppTheme { appSettings.selectedTheme }

    private var hasHabits: Bool {
        !viewModel.habits.isEmpty
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Blurred halos – match FocusView vibe
                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                VStack(spacing: 18) {
                    // Header – aligned like FocusView
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    // Summary card under header
                    summaryCard
                        .padding(.horizontal, 22)

                    // Section header
                    sectionHeader
                        .padding(.horizontal, 22)

                    if viewModel.habits.isEmpty {
                        emptyState
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                        Spacer(minLength: 0)
                    } else {
                        habitsList
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                    }

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        // Add Habit bottom sheet
        .sheet(isPresented: $showingAddHabitSheet) {
            addHabitSheet
        }
        .onAppear {
            iconPulse = true
        }
    }

    // MARK: - Header

    private var header: some View {
        let accentPrimary = theme.accentPrimary

        return HStack(spacing: 12) {
            // LEFT: title + subtitle
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true),
                            value: iconPulse
                        )

                    Text("Habits")
                        .font(.system(size: 20, weight: .semibold))   // match FocusView
                        .foregroundColor(.white)

                    if hasHabits {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(progress >= 1 ? accentPrimary : Color.white.opacity(0.35))
                                .frame(width: 8, height: 8)

                            Text(progress >= 1 ? "All done" : "In progress")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Text("Tiny rituals that support your focus.")
                    .font(.system(size: 14, weight: .medium))       // subtitle
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // RIGHT: Reset – same style as bell/headphones on Focus
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.resetAll()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today’s habit loop")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("Tap to complete. Long press to reorder.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if hasHabits {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .imageScale(.small)
                    Text("\(completedCount)/\(viewModel.habits.count)")
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Summary card with donut progress

    private var summaryCard: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily habits")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    if viewModel.habits.isEmpty {
                        Text("Create a few anchors that support your deep work.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("\(completedCount) of \(viewModel.habits.count) completed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))

                        Text(completedCount == 0
                             ? "Start with just one tiny win."
                             : (progress >= 1
                                ? "Beautiful. You’ve closed your loop for today."
                                : "Keep going — stack one more small action."))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        newHabitName = ""
                        showingAddHabitSheet = true
                        simpleTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add habit")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.accentPrimary,
                                    theme.accentSecondary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)

                donutProgress
            }
        }
    }

    private var donutProgress: some View {
        let percentage = Int((progress * 100).rounded())

        return ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.18),
                    lineWidth: 8
                )

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            theme.accentPrimary,
                            theme.accentSecondary,
                            theme.accentPrimary
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            VStack(spacing: 2) {
                Text(viewModel.habits.isEmpty ? "--" : "\(percentage)%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("Done")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 70, height: 70)
        .padding(.leading, 4)
    }

    // MARK: - Habits list (no blur, no bottom padding)

    private var habitsList: some View {
        List {
            ForEach(viewModel.habits) { habit in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.toggle(habit)
                    }
                    simpleTap()
                } label: {
                    habitRow(habit)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
                )
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.delete(habit: habit)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .onMove(perform: viewModel.move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        // no blur, no extra padding – list scrolls right to the bottom
    }

    // MARK: - Empty state

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.accentPrimary,
                                        theme.accentSecondary
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)

                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                            .imageScale(.medium)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No habits yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Add 3–5 small habits that pair well with your Focus capsules — like “Plan tomorrow”, “Journal 3 lines”, or “Drink water”.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                HStack {
                    Spacer()
                    Button {
                        newHabitName = ""
                        showingAddHabitSheet = true
                        simpleTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.small)
                            Text("Create first habit")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.accentPrimary,
                                    theme.accentSecondary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Add Habit sheet

    private var addHabitSheet: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // top spacer so the system drag indicator has room
                Spacer()
                    .frame(height: 24)

                Text("New Habit")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Make it tiny and specific so it’s easy to succeed daily.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    TextField("e.g. Plan tomorrow", text: $newHabitName)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.16))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .tint(.white)
                        .colorScheme(.dark)
                        .padding(.horizontal)
                }

                HStack {
                    Button("Cancel") {
                        showingAddHabitSheet = false
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button("Add") {
                        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            viewModel.addHabit(name: trimmed)
                        }
                        showingAddHabitSheet = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .presentationDetents([.fraction(0.32)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Row view

    private func habitRow(_ habit: Habit) -> some View {
        let isDone = habit.isDoneToday
        let iconName = iconForHabit(name: habit.name)

        return HStack(spacing: 12) {
            // Check circle with softer glow
            ZStack {
                if isDone {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.accentPrimary,
                                    theme.accentSecondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: Color.white.opacity(0.35), radius: 5)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }

            // Icon + name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let iconName {
                        Image(systemName: iconName)
                            .imageScale(.small)
                            .foregroundColor(
                                theme.accentPrimary
                                    .opacity(isDone ? 1.0 : 0.9)
                            )
                    }

                    Text(habit.name)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .regular))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Text(isDone ? "Completed today" : "Tap to complete")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isDone ? 0.20 : 0.14),
                            Color.white.opacity(isDone ? 0.10 : 0.07)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .scaleEffect(isDone ? 0.99 : 1.0)
    }

    // MARK: - Icon helper

    private func iconForHabit(name: String) -> String? {
        let lower = name.lowercased()
        if lower.contains("read") || lower.contains("book") {
            return "book.closed"
        } else if lower.contains("journal") || lower.contains("write") {
            return "square.and.pencil"
        } else if lower.contains("workout") || lower.contains("gym") || lower.contains("run") {
            return "figure.strengthtraining.traditional"
        } else if lower.contains("water") || lower.contains("drink") {
            return "drop.fill"
        } else if lower.contains("study") || lower.contains("learn") {
            return "graduationcap"
        } else if lower.contains("meditate") || lower.contains("breath") {
            return "sparkles"
        } else if lower.contains("walk") {
            return "figure.walk"
        } else if lower.contains("email") || lower.contains("inbox") {
            return "tray.full"
        } else {
            return nil
        }
    }

    // MARK: - Haptics (now respect global setting)

    private func simpleTap() {
        Haptics.impact(.light)
    }
}

#Preview {
    HabitsView()
}
