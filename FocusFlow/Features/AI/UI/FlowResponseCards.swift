import SwiftUI

// MARK: - Flow Response Cards

/// Rich inline cards that display in AI responses for tasks, presets, stats, etc.

// MARK: - Task Card

struct FlowTaskCard: View {
    let task: FFTaskItem
    let isCompleted: Bool
    let theme: AppTheme
    var onToggle: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onToggle?()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? theme.accentPrimary : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Circle()
                            .fill(theme.accentPrimary)
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(isCompleted, color: .white.opacity(0.5))
                    .opacity(isCompleted ? 0.6 : 1)
                
                HStack(spacing: 8) {
                    if let reminder = task.reminderDate {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                            Text(formatReminderDate(reminder))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(isOverdue(reminder) ? .red : theme.accentSecondary)
                    }
                    
                    if task.durationMinutes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(task.durationMinutes) min")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08).opacity(0.8),
                            Color.white.opacity(0.08).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isCompleted ? theme.accentPrimary.opacity(0.3) : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && !isCompleted
    }
}

// MARK: - Preset Card

struct FlowPresetCard: View {
    let preset: FocusPreset
    let theme: AppTheme
    var onSelect: (() -> Void)?
    var onStartFocus: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: presetIcon)
                        .font(.system(size: 18))
                        .foregroundColor(theme.accentPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formatDuration(preset.durationSeconds))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Sound indicator
                if !preset.soundID.isEmpty && preset.soundID != "none" {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11))
                        Text(formatSoundName(preset.soundID))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }
            }
            
            // Action buttons
            HStack(spacing: 10) {
                if let onStartFocus = onStartFocus {
                    Button(action: onStartFocus) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                            Text("Start Focus")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentPrimary, theme.accentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let onSelect = onSelect {
                    Button(action: onSelect) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                            Text("Select")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08).opacity(0.9),
                            Color.white.opacity(0.08).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accentPrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var presetIcon: String {
        let name = preset.name.lowercased()
        if name.contains("deep") || name.contains("work") { return "brain.head.profile" }
        if name.contains("break") || name.contains("rest") { return "cup.and.saucer.fill" }
        if name.contains("quick") || name.contains("short") { return "bolt.fill" }
        if name.contains("pomodoro") { return "timer" }
        if name.contains("meditat") { return "leaf.fill" }
        return "timer"
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return remainingMins > 0 ? "\(hours)h \(remainingMins)m" : "\(hours) hour\(hours > 1 ? "s" : "")"
        }
        return "\(minutes) minutes"
    }
    
    private func formatSoundName(_ soundID: String) -> String {
        soundID
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

// MARK: - Focus Session Card

struct FlowFocusSessionCard: View {
    let duration: Int // in minutes
    let sessionName: String?
    let theme: AppTheme
    var onStart: (() -> Void)?
    var onEdit: (() -> Void)?
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer display
            HStack {
                // Animated glow circle
                ZStack {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: isAnimating ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.accentPrimary)
                }
                .onAppear { isAnimating = true }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionName ?? "Focus Session")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(duration) minutes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentPrimary)
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if let onStart = onStart {
                    Button(action: onStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Start Now")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.3).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [theme.accentPrimary.opacity(0.4), theme.accentSecondary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Stats Card

struct FlowStatsCard: View {
    let title: String
    let stats: [StatItem]
    let theme: AppTheme
    
    struct StatItem: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let icon: String
        let trend: Trend?
        
        enum Trend {
            case up, down, neutral
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentPrimary)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(stats) { stat in
                    statItemView(stat)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func statItemView(_ stat: StatItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: stat.icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(stat.value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let trend = stat.trend {
                        Image(systemName: trendIcon(trend))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(trendColor(trend))
                    }
                }
                
                Text(stat.label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func trendIcon(_ trend: StatItem.Trend) -> String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
    
    private func trendColor(_ trend: StatItem.Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .white.opacity(0.5)
        }
    }
}

// MARK: - Action Preview Card

struct FlowActionPreviewCard: View {
    let actionType: String
    let description: String
    let details: [String]
    let theme: AppTheme
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    
    @State private var isConfirming = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with action type
            HStack {
                ZStack {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: actionIcon)
                        .font(.system(size: 14))
                        .foregroundColor(theme.accentPrimary)
                }
                
                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Details
            if !details.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(details, id: \.self) { detail in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(theme.accentSecondary.opacity(0.5))
                                .frame(width: 4, height: 4)
                            
                            Text(detail)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.leading, 4)
            }
            
            // Action buttons
            HStack(spacing: 10) {
                if let onCancel = onCancel {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let onConfirm = onConfirm {
                    Button {
                        withAnimation {
                            isConfirming = true
                        }
                        onConfirm()
                    } label: {
                        HStack(spacing: 6) {
                            if isConfirming {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            Text("Confirm")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isConfirming)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var actionIcon: String {
        switch actionType {
        case "create_task": return "plus.circle"
        case "delete_task": return "trash"
        case "start_focus": return "play.circle"
        case "create_preset": return "plus.square.on.square"
        case "update_setting": return "gearshape"
        default: return "sparkles"
        }
    }
}

// MARK: - Weekly Report Card

struct FlowWeeklyReportCard: View {
    let weekData: WeekData
    let theme: AppTheme
    
    struct WeekData {
        let totalMinutes: Int
        let sessionsCount: Int
        let avgSessionLength: Int
        let goalAchievedDays: Int
        let streak: Int
        let comparedToLastWeek: Int // percentage change
        let bestDay: String
        let peakHour: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(theme.accentPrimary)
                
                Text("Weekly Report")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if weekData.comparedToLastWeek != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: weekData.comparedToLastWeek > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(abs(weekData.comparedToLastWeek))%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(weekData.comparedToLastWeek > 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((weekData.comparedToLastWeek > 0 ? Color.green : Color.red).opacity(0.2))
                    )
                }
            }
            
            // Main stat
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(weekData.totalMinutes)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("minutes")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
            }
            
            // Stats grid
            HStack(spacing: 16) {
                miniStat(icon: "flame.fill", value: "\(weekData.sessionsCount)", label: "Sessions")
                miniStat(icon: "target", value: "\(weekData.goalAchievedDays)/7", label: "Goals Hit")
                miniStat(icon: "bolt.fill", value: "\(weekData.streak)", label: "Streak")
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Insights
            VStack(alignment: .leading, spacing: 8) {
                insightRow(icon: "star.fill", text: "Best day: \(weekData.bestDay)")
                insightRow(icon: "clock.fill", text: "Peak productivity: \(weekData.peakHour)")
                insightRow(icon: "timer", text: "Avg session: \(weekData.avgSessionLength) min")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.3).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.accentPrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentPrimary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func insightRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.accentSecondary)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Tasks List Card

struct FlowTasksListCard: View {
    let title: String
    let tasks: [FFTaskItem]
    let completedTaskIDs: Set<UUID>
    let theme: AppTheme
    var onToggleTask: ((FFTaskItem) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentPrimary)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.filter { !completedTaskIDs.contains($0.id) }.count) pending")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Tasks
            if tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(theme.accentPrimary.opacity(0.5))
                        Text("No tasks")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(5)) { task in
                        taskRow(task, isCompleted: completedTaskIDs.contains(task.id))
                    }
                    
                    if tasks.count > 5 {
                        Text("+ \(tasks.count - 5) more")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func taskRow(_ task: FFTaskItem, isCompleted: Bool) -> some View {
        Button {
            onToggleTask?(task)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isCompleted ? theme.accentPrimary : .white.opacity(0.3))
                
                Text(task.title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(isCompleted ? 0.5 : 1))
                    .strikethrough(isCompleted, color: .white.opacity(0.3))
                    .lineLimit(1)
                
                Spacer()
                
                if let reminder = task.reminderDate, !isCompleted {
                    Text(formatTime(reminder))
                        .font(.system(size: 11))
                        .foregroundColor(reminder < Date() ? .red : .white.opacity(0.4))
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
