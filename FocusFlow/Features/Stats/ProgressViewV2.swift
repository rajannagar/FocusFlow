import SwiftUI
import UIKit

// =========================================================
// MARK: - ProgressViewV2 (Scrolls as a single page)
// =========================================================

struct ProgressViewV2: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var tasksStore = TasksStore.shared

    @State private var selectedDate: Date = Date()
    @State private var iconPulse = false

    @State private var showGoalSheet = false
    @State private var showDatePicker = false

    @State private var trendRange: FFPTrendRange = .d7

    private var theme: AppTheme { appSettings.selectedTheme }
    private var cal: Calendar { .autoupdatingCurrent }

    // MARK: - Derived metrics

    private struct TaskAgg {
        var scheduled: Int = 0
        var completed: Int = 0
        var plannedMinutes: Int = 0
        var completionRate: Double { scheduled > 0 ? Double(completed) / Double(scheduled) : 0 }
    }

    private func dayInterval(_ d: Date) -> DateInterval {
        let s = cal.startOfDay(for: d)
        let e = cal.date(byAdding: .day, value: 1, to: s) ?? s.addingTimeInterval(86400)
        return DateInterval(start: s, end: e)
    }

    private func weekInterval(_ d: Date) -> DateInterval {
        cal.dateInterval(of: .weekOfYear, for: d) ??
        DateInterval(start: cal.startOfDay(for: d), duration: 7 * 86400)
    }

    private func monthInterval(_ d: Date) -> DateInterval {
        cal.dateInterval(of: .month, for: d) ??
        DateInterval(start: cal.startOfDay(for: d), duration: 30 * 86400)
    }

    private func sessions(in interval: DateInterval) -> [FocusSession] {
        stats.sessions.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private func focusSeconds(in interval: DateInterval) -> TimeInterval {
        sessions(in: interval).reduce(0) { $0 + $1.duration }
    }

    private func avgSessionMinutes(_ list: [FocusSession]) -> Int {
        guard !list.isEmpty else { return 0 }
        let avg = list.reduce(0.0) { $0 + $1.duration } / Double(list.count)
        return max(0, Int(round(avg / 60.0)))
    }

    private func tasksAgg(in interval: DateInterval) -> TaskAgg {
        var agg = TaskAgg()

        var cursor = cal.startOfDay(for: interval.start)
        let endDay = cal.startOfDay(for: interval.end)

        while cursor < endDay {
            let visible = tasksStore.tasksVisible(on: cursor, calendar: cal)
            agg.scheduled += visible.count

            for t in visible {
                agg.plannedMinutes += max(0, t.durationMinutes)
                if tasksStore.isCompleted(taskId: t.id, on: cursor, calendar: cal) {
                    agg.completed += 1
                }
            }

            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }

        return agg
    }

    private func activeFocusDays(lastNDays n: Int) -> Int {
        guard n > 0 else { return 0 }
        let today = cal.startOfDay(for: Date())
        let set = Set(stats.sessions.filter { $0.duration > 0 }.map { cal.startOfDay(for: $0.date) })

        var count = 0
        for i in 0..<n {
            if let d = cal.date(byAdding: .day, value: -i, to: today), set.contains(d) { count += 1 }
        }
        return count
    }

    private var bestTimeOfDayLabel: String {
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -29, to: today) ?? today
        let interval = DateInterval(start: start, end: cal.date(byAdding: .day, value: 1, to: today) ?? today)

        var buckets = Array(repeating: TimeInterval(0), count: 24)
        for s in sessions(in: interval) {
            let h = cal.component(.hour, from: s.date)
            if (0..<24).contains(h) { buckets[h] += s.duration }
        }

        guard let best = buckets.enumerated().max(by: { $0.element < $1.element }),
              best.element > 0 else { return "—" }

        return hourRangeLabel(best.offset)
    }

    private func hourRangeLabel(_ startHour: Int) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.dateFormat = "h a"

        let base = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: startHour, to: base) ?? base
        let end = cal.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)

        let s = df.string(from: start)
        let e = df.string(from: end)

        let sParts = s.split(separator: " ")
        let eParts = e.split(separator: " ")
        if sParts.count == 2, eParts.count == 2, sParts[1] == eParts[1] {
            return "\(sParts[0])–\(eParts[0]) \(sParts[1])"
        }
        return "\(s)–\(e)"
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0m" }
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .abbreviated
        return f.string(from: seconds) ?? "0m"
    }

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: d)
    }

    private func dayTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return f.string(from: d)
    }

    // MARK: - Momentum

    private func momentumScore(focusSec: TimeInterval, taskRate: Double) -> Int {
        let goalSec = Double(max(1, stats.dailyGoalMinutes)) * 60.0
        let focusPart = min(1.0, focusSec / goalSec) * 70.0
        let taskPart = min(1.0, taskRate) * 30.0
        return Int(round(focusPart + taskPart))
    }

    private func momentumLabel(_ score: Int) -> String {
        switch score {
        case 90...100: return "Unstoppable"
        case 75...89:  return "High momentum"
        case 55...74:  return "Locked in"
        case 35...54:  return "Warming up"
        case 1...34:   return "Ignition needed"
        default:       return "Start your first session"
        }
    }

    // MARK: - Trend (ending at selected date)

    private func dailyMinutesSeries(endingAt date: Date, days: Int) -> [Double] {
        let anchor = cal.startOfDay(for: date)
        return (0..<days).map { i in
            let back = (days - 1) - i
            let d = cal.date(byAdding: .day, value: -back, to: anchor) ?? anchor
            return focusSeconds(in: dayInterval(d)) / 60.0
        }
    }

    private func dateForSeriesIndex(_ idx: Int, anchor: Date, days: Int) -> Date {
        let anchorDay = cal.startOfDay(for: anchor)
        let back = (days - 1) - idx
        return cal.date(byAdding: .day, value: -back, to: anchorDay) ?? anchorDay
    }

    private func weekBars(endingAt date: Date) -> [(String, Double, Date)] {
        let anchor = cal.startOfDay(for: date)
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.setLocalizedDateFormatFromTemplate("E")

        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: -(6 - i), to: anchor) ?? anchor
            let mins = focusSeconds(in: dayInterval(d)) / 60.0
            return (df.string(from: d).uppercased(), mins, d)
        }
    }

    // MARK: - Actions

    private func stepDay(_ delta: Int) {
        Haptics.impact(.light)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.92)) {
            selectedDate = cal.date(byAdding: .day, value: delta, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            let dayI = dayInterval(selectedDate)
            let weekI = weekInterval(selectedDate)
            let monthI = monthInterval(selectedDate)

            let focusDay = focusSeconds(in: dayI)
            let focusWeek = focusSeconds(in: weekI)
            let focusMonth = focusSeconds(in: monthI)

            let daySessions = sessions(in: dayI).sorted(by: { $0.date > $1.date })
            let dayTasks = tasksAgg(in: dayI)

            let goalMins = max(0, stats.dailyGoalMinutes)
            let goalSec = Double(max(1, goalMins)) * 60.0
            let orbProgress = min(1.0, focusDay / goalSec)

            let score = momentumScore(focusSec: focusDay, taskRate: dayTasks.completionRate)
            let scoreLabel = momentumLabel(score)

            let trendDays = (trendRange == .d7) ? 7 : 30
            let trendSeries = dailyMinutesSeries(endingAt: selectedDate, days: trendDays)
            let bars = weekBars(endingAt: selectedDate)

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Halos
                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.50)

                // ✅ Whole page scrolls
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        header(scoreLabel: scoreLabel)
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        dateBar
                            .padding(.horizontal, 22)

                        // HERO
                        PGlassCard {
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Momentum")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    Text(scoreLabel)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.72))

                                    Text("\(durationText(focusDay)) focused • \(daySessions.count) sessions")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.70))

                                    HStack(spacing: 10) {
                                        PStatPill(label: "Week", value: durationText(focusWeek))
                                        PStatPill(label: "Month", value: durationText(focusMonth))
                                    }
                                    .padding(.top, 2)
                                }

                                Spacer(minLength: 0)

                                FFMomentumOrb(
                                    progress: orbProgress,
                                    title: "Score",
                                    mainValue: "\(score)",
                                    subValue: cal.isDateInToday(selectedDate) ? "Today" : "Replay",
                                    accentA: accentPrimary,
                                    accentB: accentSecondary,
                                    size: 118
                                )
                            }
                        }
                        .padding(.horizontal, 22)

                        sectionHeader(dayTasks: dayTasks)
                            .padding(.horizontal, 22)

                        // Snapshot tiles
                        PGlassCard {
                            HStack(spacing: 10) {
                                PMetricTile(title: "Today", value: durationText(focusDay), subtitle: "Focus time")
                                PMetricTile(title: "Sessions", value: "\(daySessions.count)", subtitle: "Count")
                                PMetricTile(title: "Avg", value: "\(avgSessionMinutes(daySessions))m", subtitle: "Session")
                            }
                        }
                        .padding(.horizontal, 22)

                        // Rhythm
                        PGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Rhythm")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))
                                Text("Tap a day to replay.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))

                                PWeekBars(
                                    bars: bars,
                                    selectedDate: selectedDate,
                                    onTapDate: { d in
                                        Haptics.impact(.light)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                                            selectedDate = d
                                        }
                                    }
                                )
                                .frame(height: 74)
                            }
                        }
                        .padding(.horizontal, 22)

                        // Timeline (fixed height + scrub preview + commit on release)
                        PGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Timeline")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.95))
                                        Text("Drag to preview • Release to jump")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()

                                    FFPillSegmented<FFPTrendRange>(selection: $trendRange)
                                        .frame(width: 150)
                                }

                                PScrubSparkline(
                                    values: trendSeries,
                                    accentA: accentPrimary,
                                    accentB: accentSecondary,
                                    onCommitIndex: { idx in
                                        let d = dateForSeriesIndex(idx, anchor: selectedDate, days: trendDays)
                                        if !cal.isDate(d, inSameDayAs: selectedDate) {
                                            Haptics.impact(.light)
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                                                selectedDate = d
                                            }
                                        }
                                    }
                                )
                                .frame(height: 120)
                            }
                        }
                        .padding(.horizontal, 22)

                        // Task outcomes
                        let ratePct = dayTasks.scheduled > 0 ? Int(round(dayTasks.completionRate * 100)) : 0
                        PGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Task outcomes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))
                                Text("Progress without streak pressure.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))

                                HStack(spacing: 10) {
                                    PStatPill(label: "Completed", value: "\(dayTasks.completed)")
                                    PStatPill(label: "Scheduled", value: "\(dayTasks.scheduled)")
                                    PStatPill(label: "Rate", value: dayTasks.scheduled > 0 ? "\(ratePct)%" : "—")
                                }

                                if dayTasks.plannedMinutes > 0 {
                                    Text("Planned time: \(dayTasks.plannedMinutes)m")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            }
                        }
                        .padding(.horizontal, 22)

                        // Insights
                        let a7 = activeFocusDays(lastNDays: 7)
                        let a30 = activeFocusDays(lastNDays: 30)

                        PGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))
                                Text("Your rhythm, not streaks.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        PInsightCard(icon: "clock.fill", title: "Best window", value: bestTimeOfDayLabel, foot: "Last 30 days")
                                        PInsightCard(icon: "calendar", title: "Active days", value: "\(a7)/7", foot: "\(a30)/30 overall")
                                        PInsightCard(icon: "target", title: "Goal", value: "\(goalMins)m", foot: "Tap target to edit")
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding(.horizontal, 22)

                        // Replay
                        PGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Replay")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))
                                Text(dayTitle(selectedDate))
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))

                                if daySessions.isEmpty {
                                    Text("No focus sessions recorded.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    ForEach(Array(daySessions.prefix(4).enumerated()), id: \.offset) { _, s in
                                        let raw = (s.sessionName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        let title = raw.isEmpty ? "Focus session" : raw

                                        HStack {
                                            Text(title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.92))
                                                .lineLimit(1)
                                            Spacer()
                                            Text(durationText(s.duration))
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.72))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.10))
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 22)

                        // tab bar clearance
                        Spacer(minLength: 140)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .onAppear { iconPulse = true }
        .sheet(isPresented: $showGoalSheet) {
            PGoalSheet(currentGoalMinutes: stats.dailyGoalMinutes) { newGoal in
                stats.dailyGoalMinutes = newGoal
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDatePicker) {
            PDatePickerSheet(date: $selectedDate)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header (Goal is icon-only)

    private func header(scoreLabel: String) -> some View {
        let hasAny = stats.sessions.contains(where: { $0.duration > 0 })
        let active7 = activeFocusDays(lastNDays: 7)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: iconPulse)

                    Text("Progress")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    if hasAny {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(active7 >= 5 ? theme.accentPrimary : Color.white.opacity(0.35))
                                .frame(width: 8, height: 8)
                            Text(active7 >= 5 ? "In rhythm" : "Building rhythm")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Text(monthTitle(selectedDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showGoalSheet = true
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "target")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.20))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    showDatePicker = true
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "calendar")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.20))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Date bar (center tap opens picker)

    private var dateBar: some View {
        HStack(spacing: 10) {
            Button { stepDay(-1) } label: {
                Image(systemName: "chevron.left")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 38)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                showDatePicker = true
                Haptics.impact(.light)
            } label: {
                Text(dayTitle(selectedDate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button { stepDay(1) } label: {
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 38)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionHeader(dayTasks: TaskAgg) -> some View {
        let countText = "\(dayTasks.completed)/\(max(0, dayTasks.scheduled))"
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your day")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text("Replay + outcomes in one place.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle").imageScale(.small)
                Text(countText)
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())
            .foregroundColor(.white.opacity(0.9))
        }
    }
}

// =========================================================
// MARK: - Trend Range enum (for segmented pill)
// =========================================================

private enum FFPTrendRange: String, CaseIterable {
    case d7 = "7D"
    case d30 = "30D"
}

// =========================================================
// MARK: - Glass card container
// =========================================================

private struct PGlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

// =========================================================
// MARK: - Tiles / Pills (unique names; no collisions)
// =========================================================

private struct PMetricTile: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.80))
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.60))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct PStatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct PInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let foot: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)

            Text(foot)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.60))
                .lineLimit(1)
        }
        .frame(width: 190, height: 110, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

// =========================================================
// MARK: - Week Bars
// =========================================================

private struct PWeekBars: View {
    let bars: [(String, Double, Date)]
    let selectedDate: Date
    let onTapDate: (Date) -> Void

    private var cal: Calendar { .autoupdatingCurrent }

    var body: some View {
        GeometryReader { geo in
            let maxV = max(bars.map { $0.1 }.max() ?? 1, 1)
            let w = geo.size.width / CGFloat(max(1, bars.count))

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, item in
                    let isSelected = cal.isDate(item.2, inSameDayAs: selectedDate)

                    Button { onTapDate(item.2) } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(isSelected ? 0.55 : 0.22))
                                .frame(width: max(18, w - 18),
                                       height: max(8, CGFloat(item.1 / maxV) * 48))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(isSelected ? 0.22 : 0.12), lineWidth: 1)
                                )

                            Text(item.0)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.65))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// =========================================================
// MARK: - Timeline Sparkline (preview while dragging, commit on release)
// =========================================================

private struct PScrubSparkline: View {
    let values: [Double]
    let accentA: Color
    let accentB: Color
    let onCommitIndex: (Int) -> Void

    @State private var previewIndex: Int? = nil
    @State private var lockedHorizontal: Bool? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = max(values.max() ?? 1, 1)

            let pts: [CGPoint] = values.enumerated().map { i, v in
                let x = values.count <= 1 ? 0 : (CGFloat(i) / CGFloat(values.count - 1)) * w
                let y = h - (CGFloat(v / maxV) * (h - 14)) - 7
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: CGPoint(x: first.x, y: h))
                    p.addLine(to: first)
                    for pt in pts.dropFirst() { p.addLine(to: pt) }
                    if let last = pts.last { p.addLine(to: CGPoint(x: last.x, y: h)) }
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [accentA.opacity(0.22), accentB.opacity(0.06)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    for pt in pts.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(
                    LinearGradient(colors: [accentA.opacity(0.95), accentB.opacity(0.85)],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                if let idx = previewIndex, idx >= 0, idx < pts.count {
                    let pt = pts[idx]
                    Rectangle().fill(Color.white.opacity(0.16))
                        .frame(width: 1, height: h)
                        .position(x: pt.x, y: h / 2)

                    Circle().fill(Color.white.opacity(0.95))
                        .frame(width: 8, height: 8)
                        .position(pt)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        // Decide if this drag is meant to scrub horizontally (so vertical scroll doesn't freak out)
                        if lockedHorizontal == nil {
                            let dx = abs(g.translation.width)
                            let dy = abs(g.translation.height)
                            if dx + dy > 10 { // wait until user moved a bit
                                lockedHorizontal = (dx > dy * 1.15)
                            } else {
                                return
                            }
                        }

                        guard lockedHorizontal == true else { return }

                        let x = max(0, min(w, g.location.x))
                        let t = x / max(1, w)
                        let raw = t * CGFloat(max(1, values.count - 1))

                        // Use floor so it doesn’t “bounce” between indices on tiny moves.
                        let idx = Int(floor(raw + 0.0001))
                        let clamped = max(0, min(values.count - 1, idx))

                        if previewIndex != clamped {
                            previewIndex = clamped
                        }
                    }
                    .onEnded { _ in
                        if let idx = previewIndex, lockedHorizontal == true {
                            onCommitIndex(idx)  // ✅ commit once
                        }
                        withAnimation(.easeInOut(duration: 0.16)) {
                            previewIndex = nil
                        }
                        lockedHorizontal = nil
                    }
            )
        }
    }
}

// =========================================================
// MARK: - Sheets
// =========================================================

private struct PDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Pick a day")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 14, weight: .semibold))
            }

            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()

            Spacer()
        }
        .padding(18)
    }
}

private struct PGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goal: Int
    let onSave: (Int) -> Void

    init(currentGoalMinutes: Int, onSave: @escaping (Int) -> Void) {
        _goal = State(initialValue: max(0, currentGoalMinutes))
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Daily goal")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("Done") {
                    Haptics.impact(.light)
                    onSave(goal)
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
            }

            Text("\(goal) minutes")
                .font(.system(size: 28, weight: .semibold))
                .padding(.top, 4)

            Slider(
                value: Binding(
                    get: { Double(goal) },
                    set: { goal = Int(round($0 / 5.0)) * 5 }
                ),
                in: 0...240,
                step: 5
            )

            Spacer()
        }
        .padding(18)
    }
}
