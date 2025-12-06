import SwiftUI

// MARK: - Glass card container

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
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Session grouping model

private struct SessionGroup: Identifiable {
    let id = UUID()
    let title: String
    let sessions: [FocusSession]
}

// MARK: - Alerts

private enum StatsAlertKind {
    case clearDay
    case clearHistory
}

private struct StatsAlert: Identifiable {
    let id = UUID()
    let kind: StatsAlertKind
}

// MARK: - Main Stats View

struct StatsView: View {
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var showingGoalSheet = false

    /// 0 = this week, 1 = last week, etc.
    @State private var weekOffset: Int = 0

    // header icon animation
    @State private var iconPulse = false

    // hero ring animation
    @State private var todayProgressAnimated: Double = 0
    @State private var todayValuePulse: Bool = false

    // selected day for drill-down (nil = today)
    @State private var selectedDay: Date? = nil

    // alerts
    @State private var activeAlert: StatsAlert?

    private let calendar = Calendar.current

    // MARK: - Formatters

    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let weekLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    // MARK: - Weekly helpers

    private func weekInterval(for offset: Int) -> DateInterval? {
        let baseDate = calendar.date(
            byAdding: .weekOfYear,
            value: -offset,
            to: Date()
        ) ?? Date()

        return calendar.dateInterval(of: .weekOfYear, for: baseDate)
    }

    private func statsForWeek(offset: Int) -> [DailyFocusStat] {
        guard let interval = weekInterval(for: offset) else { return [] }

        var result: [DailyFocusStat] = []
        for dayIndex in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayIndex, to: interval.start),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            let total = stats.sessions
                .filter { $0.date >= dayStart && $0.date < nextDay }
                .reduce(0) { $0 + $1.duration }

            result.append(DailyFocusStat(date: dayStart, totalDuration: total))
        }

        return result
    }

    private var currentWeekStats: [DailyFocusStat] {
        statsForWeek(offset: weekOffset)
    }

    private var currentWeekLabel: String {
        guard let interval = weekInterval(for: weekOffset) else { return "This week" }

        let start = Self.weekLabelFormatter.string(from: interval.start)
        let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        let end = Self.weekLabelFormatter.string(from: endDate)

        if weekOffset == 0 {
            return "This week • \(start) – \(end)"
        } else {
            return "\(start) – \(end)"
        }
    }

    /// Weekly insight
    private var weeklyInsightText: String {
        let totals = currentWeekStats.map { $0.totalDuration }
        let weekTotal = totals.reduce(0, +)

        guard weekTotal > 0 else {
            return "No focused time logged this week yet."
        }

        // best day this week
        let bestStat = currentWeekStats.max { $0.totalDuration < $1.totalDuration }
        let bestDay = bestStat.map { shortWeekday(for: $0.date) } ?? "—"

        // compare vs previous week
        let previousTotals = statsForWeek(offset: weekOffset + 1).map { $0.totalDuration }
        let previousTotal = previousTotals.reduce(0, +)

        var comparison = ""
        if previousTotal > 0 {
            let diff = (weekTotal - previousTotal) / previousTotal
            let percent = Int(abs(diff) * 100)

            if percent >= 10 {
                if diff > 0 {
                    comparison = "up \(percent)% vs last week."
                } else {
                    comparison = "down \(percent)% vs last week."
                }
            } else {
                comparison = "about the same as last week."
            }
        }

        return "You’ve focused for \(weekTotal.asReadableDuration) so far, mostly on \(bestDay), \(comparison)"
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Grouped sessions helper (for Recent sessions list)

    private var groupedSessions: [SessionGroup] {
        let sorted = stats.sessions.sorted { $0.date > $1.date }
        guard !sorted.isEmpty else { return [] }

        var groups: [String: [FocusSession]] = [:]

        for session in sorted {
            let dayStart = calendar.startOfDay(for: session.date)

            let title: String
            if calendar.isDateInToday(dayStart) {
                title = "Today"
            } else if calendar.isDateInYesterday(dayStart) {
                title = "Yesterday"
            } else {
                title = Self.dayLabelFormatter.string(from: dayStart)
            }

            groups[title, default: []].append(session)
        }

        // Order: Today, Yesterday, then dates descending
        var result: [SessionGroup] = []

        if let today = groups["Today"] {
            result.append(SessionGroup(title: "Today", sessions: today))
        }
        if let yesterday = groups["Yesterday"] {
            result.append(SessionGroup(title: "Yesterday", sessions: yesterday))
        }

        let otherKeys = groups.keys
            .filter { $0 != "Today" && $0 != "Yesterday" }
            .sorted { lhs, rhs in
                guard let leftDate = Self.dayLabelFormatter.date(from: lhs),
                      let rightDate = Self.dayLabelFormatter.date(from: rhs) else { return lhs > rhs }
                return leftDate > rightDate
            }

        for key in otherKeys {
            if let sessions = groups[key] {
                result.append(SessionGroup(title: key, sessions: sessions))
            }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = appSettings.selectedTheme
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

                // Soft halo blobs – match Focus & Habits
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Header
                        header
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        if stats.sessions.isEmpty {
                            emptyState
                                .padding(.horizontal, 22)
                                .padding(.top, 4)
                        } else {
                            dayHeroCard
                                .padding(.horizontal, 22)

                            weeklyCard
                                .padding(.horizontal, 22)

                            dayBreakdownCard
                                .padding(.horizontal, 22)

                            streaksCard
                                .padding(.horizontal, 22)

                            sessionsCardGrouped
                                .padding(.horizontal, 22)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert.kind {
            case .clearDay:
                return Alert(
                    title: Text("Clear this day?"),
                    message: Text("This removes all focus sessions for the selected day from your stats. This can’t be undone."),
                    primaryButton: .destructive(Text("Clear day")) {
                        simpleTap()
                        let day = selectedDay ?? calendar.startOfDay(for: Date())
                        let toDelete = sessions(on: day)
                        toDelete.forEach { stats.deleteSession($0) }
                        if sessions(on: day).isEmpty {
                            selectedDay = nil
                        }
                    },
                    secondaryButton: .cancel()
                )

            case .clearHistory:
                return Alert(
                    title: Text("Delete all recent sessions?"),
                    message: Text("This removes all recorded sessions from your stats and streaks. This can’t be undone."),
                    primaryButton: .destructive(Text("Delete all")) {
                        simpleTap()
                        stats.clearAll()
                        selectedDay = nil
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalSheet(goalMinutes: $stats.dailyGoalMinutes)
        }
        .onAppear {
            iconPulse = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // LEFT: Title + subtitle (match Focus / Habits)
            VStack(alignment: .leading, spacing: 4) {
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

                    Text("Stats")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Your focus story, in motion.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // RIGHT: Goal + Clear-day – icon squares like other tabs
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    showingGoalSheet = true
                } label: {
                    Image(systemName: "target")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                if !stats.sessions.isEmpty {
                    Button {
                        simpleTap()
                        activeAlert = StatsAlert(kind: .clearDay)
                    } label: {
                        Image(systemName: "trash")
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))

                Text("No focus sessions yet")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Start a focus timer to see your stats here.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Day hero card (animated, dynamic, driven by selectedDay)

    private var dayHeroCard: some View {
        let day = selectedDay ?? calendar.startOfDay(for: Date())
        let daySessions = sessions(on: day)
        let totalDuration = daySessions.reduce(0) { $0 + $1.duration }

        let goalMinutes = stats.dailyGoalMinutes
        let goalSeconds = TimeInterval(goalMinutes * 60)
        let targetProgress = goalSeconds > 0 ? min(totalDuration / goalSeconds, 1.0) : 0.0

        // minutes as whole number for display
        let totalMinutesInt = Int(round(totalDuration / 60))
        let digits = String(max(totalMinutesInt, 0)).count

        let numberFontSize: CGFloat
        switch digits {
        case 0...2:
            numberFontSize = 36
        case 3:
            numberFontSize = 30
        default:
            numberFontSize = 26
        }

        let isToday = calendar.isDateInToday(day)
        let titleText = isToday ? "Today" : shortWeekday(for: day)

        return GlassCard {
            HStack(spacing: 20) {
                ZStack {
                    // soft glow behind
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    appSettings.selectedTheme.accentPrimary.opacity(0.8),
                                    appSettings.selectedTheme.accentSecondary.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .blur(radius: 18)
                        .opacity(0.9)

                    // background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 16)

                    // animated progress ring
                    Circle()
                        .trim(from: 0, to: todayProgressAnimated)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    appSettings.selectedTheme.accentPrimary,
                                    appSettings.selectedTheme.accentSecondary,
                                    appSettings.selectedTheme.accentPrimary
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    // inner numbers – number + unit so it never truncates
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(totalMinutesInt)")
                                .font(.system(size: numberFontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(todayValuePulse ? 1.05 : 1.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: todayValuePulse)

                            Text("min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        Text(goalMinutes > 0 ? "of \(goalMinutes) min goal" : "No daily goal set")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))

                        if goalMinutes > 0 {
                            Text("\(Int(targetProgress * 100))% of goal")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text(daySessions.isEmpty
                                 ? "No focus logged this day."
                                 : "\(daySessions.count) session\(daySessions.count == 1 ? "" : "s")")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: isToday ? "sun.max.fill" : "calendar")
                            .imageScale(.medium)
                        Text(titleText)
                            .font(.headline)
                    }
                    .foregroundColor(.white.opacity(0.9))

                    if totalDuration == 0 {
                        Text(isToday
                             ? "No focus yet — start a session to light up your day."
                             : "No focused time logged on this day.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(isToday
                             ? "Nice. You’ve already logged \(totalDuration.asReadableDuration) of focused time."
                             : "You focused for \(totalDuration.asReadableDuration) on this day.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            todayProgressAnimated = 0
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                todayProgressAnimated = targetProgress
            }
        }
        .onChange(of: targetProgress) { _, newValue in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                todayProgressAnimated = newValue
            }
            todayValuePulse.toggle()
        }
        .onChange(of: selectedDay) { _, _ in
            let goalSeconds = TimeInterval(stats.dailyGoalMinutes * 60)
            let newTarget = goalSeconds > 0 ? min(totalDuration / goalSeconds, 1.0) : 0.0
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                todayProgressAnimated = newTarget
            }
            todayValuePulse.toggle()
        }
    }

    // MARK: - Weekly card (tappable bars)

    private var weeklyCard: some View {
        let goalSeconds = TimeInterval(stats.dailyGoalMinutes * 60)
        let totals = currentWeekStats.map { $0.totalDuration }
        let weekTotal = totals.reduce(0, +)
        let goalDays = goalSeconds > 0 ? totals.filter { $0 >= goalSeconds }.count : 0
        let maxBase = max(goalSeconds, totals.max() ?? 0, 60) // at least 1 min
        let barHeight: CGFloat = 90

        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header + week navigation
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .imageScale(.medium)
                            .foregroundColor(appSettings.selectedTheme.accentPrimary)
                        Text("Week overview")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Button {
                            weekOffset += 1
                            simpleTap()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }

                        Button {
                            weekOffset = max(weekOffset - 1, 0)
                            simpleTap()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(Color.white.opacity(weekOffset == 0 ? 0.04 : 0.10))
                                .clipShape(Circle())
                        }
                        .disabled(weekOffset == 0)
                    }
                }

                Text(currentWeekLabel)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))

                // Insight line
                Text(weeklyInsightText)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                // Summary chips
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .imageScale(.small)
                        Text("Goal days \(goalDays)/7")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.09))
                    .clipShape(Capsule())

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .imageScale(.small)
                        Text(weekTotal.asReadableDuration)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.09))
                    .clipShape(Capsule())
                }

                // Bars (tappable)
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(currentWeekStats) { stat in
                        let dayDate = calendar.startOfDay(for: stat.date)

                        let isSelected: Bool = {
                            if let selectedDay {
                                return calendar.isDate(selectedDay, inSameDayAs: dayDate)
                            } else {
                                return weekOffset == 0 && calendar.isDateInToday(dayDate)
                            }
                        }()

                        Button {
                            simpleTap()
                            selectedDay = dayDate
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    // Track
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(Color.white.opacity(0.10))
                                        .frame(width: 18, height: barHeight)

                                    // Fill
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    appSettings.selectedTheme.accentPrimary,
                                                    appSettings.selectedTheme.accentSecondary
                                                ]),
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(
                                            width: 18,
                                            height: heightForBar(
                                                duration: stat.totalDuration,
                                                maxBase: maxBase,
                                                barHeight: barHeight
                                            )
                                        )
                                        .opacity(stat.totalDuration > 0 ? 1.0 : 0.0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.85),
                                            value: stat.totalDuration
                                        )

                                    // Goal badge at top if goal reached
                                    if goalSeconds > 0 && stat.totalDuration >= goalSeconds {
                                        VStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color.green.opacity(0.95))
                                                .offset(y: -4)
                                            Spacer()
                                        }
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(
                                            Color.white.opacity(isSelected ? 0.9 : 0.0),
                                            lineWidth: isSelected ? 1.5 : 0
                                        )
                                )

                                // Day label
                                Text(shortWeekday(for: stat.date))
                                    .font(.caption2)
                                    .foregroundColor(
                                        isSelected
                                        ? appSettings.selectedTheme.accentPrimary
                                        : .white.opacity(0.7)
                                    )

                                // Minutes for that day
                                Text(stat.totalDuration.asReadableDuration)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: weekOffset)
        }
    }

    private func heightForBar(duration: TimeInterval,
                              maxBase: TimeInterval,
                              barHeight: CGFloat) -> CGFloat {
        guard maxBase > 0 else { return 0 }
        guard duration > 0 else { return 0 }
        let ratio = duration / maxBase
        return max(CGFloat(ratio) * barHeight, 4)
    }

    private func shortWeekday(for date: Date) -> String {
        Self.weekdayFormatter.string(from: date)
    }

    // MARK: - Day breakdown (sessions + avg)

    private var dayBreakdownCard: some View {
        let day = selectedDay ?? calendar.startOfDay(for: Date())
        let daySessions = sessions(on: day)
        let totalDuration = daySessions.reduce(0) { $0 + $1.duration }
        let avgSeconds = daySessions.isEmpty ? 0 : totalDuration / Double(daySessions.count)
        let avgMinutesInt = Int(round(avgSeconds / 60))

        let label = dayDisplayLabel(for: day)

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day breakdown")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Text(label)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()
                }

                HStack(spacing: 24) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 30, height: 30)
                            Image(systemName: "clock.badge.checkmark")
                                .imageScale(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(daySessions.count)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text(daySessions.count == 1 ? "session" : "sessions")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 30, height: 30)
                            Image(systemName: "gauge")
                                .imageScale(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(avgMinutesInt == 0 ? "—" : "\(avgMinutesInt)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text("min avg")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
    }

    private func dayDisplayLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return Self.dayLabelFormatter.string(from: date)
        }
    }

    // MARK: - Streaks card

    private var streaksCard: some View {
        GlassCard {
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.40))
                        .imageScale(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current streak")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                        Text("\(streaks.current) \(streaks.current == 1 ? "day" : "days")")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.45))
                        .imageScale(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best streak")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                        Text("\(streaks.best) \(streaks.best == 1 ? "day" : "days")")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var streaks: (current: Int, best: Int) {
        let daysWithFocus: Set<Date> = Set(
            stats.sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty {
            return (0, 0)
        }

        // current streak
        var current = 0
        var cursor = calendar.startOfDay(for: Date())
        while daysWithFocus.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // best streak
        let sorted = daysWithFocus.sorted()
        var best = 1
        var temp = 1

        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: -1, to: sorted[i]),
               calendar.isDate(prev, inSameDayAs: sorted[i - 1]) {
                temp += 1
            } else {
                best = max(best, temp)
                temp = 1
            }
        }
        best = max(best, temp)

        return (current, best)
    }

    // MARK: - Recent sessions card (List + swipe, tight group spacing)

    private var sessionsCardGrouped: some View {
        let groups = groupedSessions

        // Estimate height so the List gets real space instead of collapsing to 0
        let rowCount = groups.reduce(0) { $0 + $1.sessions.count }
        let estimatedHeight = max(CGFloat(rowCount) * 68 + CGFloat(groups.count) * 16, 120)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack {
                    Label {
                        Text("Recent sessions")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .imageScale(.medium)
                    }
                    .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    if !groups.isEmpty {
                        Button {
                            simpleTap()
                            activeAlert = StatsAlert(kind: .clearHistory)
                        } label: {
                            Image(systemName: "trash")
                                .imageScale(.small)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.white.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if groups.isEmpty {
                    Text("No recent sessions to show.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    List {
                        ForEach(groups) { group in
                            // Compact header row instead of a Section header
                            Text(group.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    EdgeInsets(top: 10, leading: 0, bottom: 2, trailing: 0)
                                )

                            ForEach(group.sessions) { session in
                                let quality = qualityTag(for: session.duration)

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.sessionName ?? "Focus Session")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)

                                        Text(timeFormatter.string(from: session.date))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }

                                    Spacer()

                                    Text(session.duration.asReadableDuration)
                                        .font(.subheadline)
                                        .foregroundColor(appSettings.selectedTheme.accentPrimary)

                                    if let quality {
                                        Text(quality.label)
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(quality.color.opacity(0.16))
                                            .foregroundColor(quality.color.opacity(0.95))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
                                )
                                .contentShape(Rectangle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        simpleTap()
                                        // Hard delete so stats & streaks stay in sync
                                        stats.deleteSession(session)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)              // outer ScrollView scrolls
                    .frame(height: estimatedHeight)     // shows all rows, no big empty gaps
                }
            }
        }
    }

    // MARK: - Quality tag helper

    private func qualityTag(for duration: TimeInterval) -> (label: String, color: Color)? {
        let minutes = duration / 60.0

        switch minutes {
        case 0..<10:
            return nil                    // too short, no badge
        case 10..<20:
            return ("Quick focus", Color(red: 0.60, green: 0.85, blue: 1.0))
        case 20..<35:
            return ("Good session", Color(red: 0.40, green: 0.90, blue: 0.70))
        default:
            return ("Deep focus", Color(red: 0.95, green: 0.75, blue: 0.30))
        }
    }

    // MARK: - Helpers

    private func sessions(on date: Date) -> [FocusSession] {
        stats.sessions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Haptics (now respect global setting)

    private func simpleTap() {
        Haptics.impact(.light)
    }
}

// MARK: - Goal editing sheet

private struct GoalSheet: View {
    @Binding var goalMinutes: Int
    @ObservedObject private var appSettings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: appSettings.selectedTheme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 24)

                Text("Daily Focus Goal")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("How many minutes do you want to focus each day?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text("\(goalMinutes) min")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)

                    Slider(
                        value: Binding(
                            get: { Double(goalMinutes) },
                            set: { goalMinutes = Int($0) }
                        ),
                        in: 15...240,
                        step: 5
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 16)
            }
            .padding()
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    StatsView()
}
