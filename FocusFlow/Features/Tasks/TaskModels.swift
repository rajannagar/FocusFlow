import Foundation

// =========================================================
// MARK: - Tasks Models
// =========================================================

/// Keep the FF prefix to avoid name collisions with Swift Concurrency's `Task`.
enum FFTaskRepeatRule: String, CaseIterable, Identifiable, Codable {
    case none, daily, weekly, monthly, yearly, customDays

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .customDays: return "Custom"
        }
    }
}

struct FFTaskItem: Identifiable, Equatable, Codable {
    let id: UUID

    /// Stable manual ordering (smaller comes first).
    var sortIndex: Int

    var title: String
    var notes: String?

    /// If nil, reminders are OFF.
    var reminderDate: Date?

    var repeatRule: FFTaskRepeatRule
    var customWeekdays: Set<Int>

    /// 0 means no duration.
    var durationMinutes: Int

    /// UI intent: when true, the UI will create a focus preset one time.
    /// After creation, this is set back to false and `presetCreated` is set to true.
    var convertToPreset: Bool

    /// Persisted guard so we never create duplicate presets on relaunch.
    var presetCreated: Bool

    /// Outlook-style series exception: hide this task on specific days (YYYY-MM-DD).
    var excludedDayKeys: Set<String>

    var createdAt: Date

    init(
        id: UUID = UUID(),
        sortIndex: Int = 0,
        title: String,
        notes: String? = nil,
        reminderDate: Date? = nil,
        repeatRule: FFTaskRepeatRule = .none,
        customWeekdays: Set<Int> = [],
        durationMinutes: Int = 0,
        convertToPreset: Bool = false,
        presetCreated: Bool = false,
        excludedDayKeys: Set<String> = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.title = title
        self.notes = notes
        self.reminderDate = reminderDate
        self.repeatRule = repeatRule
        self.customWeekdays = customWeekdays
        self.durationMinutes = durationMinutes
        self.convertToPreset = convertToPreset
        self.presetCreated = presetCreated
        self.excludedDayKeys = excludedDayKeys
        self.createdAt = createdAt
    }

    // MARK: - Codable (backwards compatible)

    private enum CodingKeys: String, CodingKey {
        case id
        case sortIndex
        case title
        case notes
        case reminderDate
        case repeatRule
        case customWeekdays
        case durationMinutes
        case convertToPreset
        case presetCreated
        case excludedDayKeys
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(UUID.self, forKey: .id)
        sortIndex = try c.decodeIfPresent(Int.self, forKey: .sortIndex) ?? 0

        title = try c.decode(String.self, forKey: .title)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)

        reminderDate = try c.decodeIfPresent(Date.self, forKey: .reminderDate)

        repeatRule = try c.decodeIfPresent(FFTaskRepeatRule.self, forKey: .repeatRule) ?? .none
        customWeekdays = try c.decodeIfPresent(Set<Int>.self, forKey: .customWeekdays) ?? []

        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 0
        convertToPreset = try c.decodeIfPresent(Bool.self, forKey: .convertToPreset) ?? false
        presetCreated = try c.decodeIfPresent(Bool.self, forKey: .presetCreated) ?? false
        excludedDayKeys = try c.decodeIfPresent(Set<String>.self, forKey: .excludedDayKeys) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encode(sortIndex, forKey: .sortIndex)

        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(notes, forKey: .notes)

        try c.encodeIfPresent(reminderDate, forKey: .reminderDate)

        try c.encode(repeatRule, forKey: .repeatRule)
        try c.encode(customWeekdays, forKey: .customWeekdays)

        try c.encode(durationMinutes, forKey: .durationMinutes)
        try c.encode(convertToPreset, forKey: .convertToPreset)
        try c.encode(presetCreated, forKey: .presetCreated)
        try c.encode(excludedDayKeys, forKey: .excludedDayKeys)
        try c.encode(createdAt, forKey: .createdAt)
    }

    // MARK: - Date helpers

    static func dayKey(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let d = calendar.startOfDay(for: date)
        let c = calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: - Scheduling / Visibility

    func occurs(on day: Date, calendar: Calendar) -> Bool {
        let target = calendar.startOfDay(for: day)

        // Series exception support (Outlook-style "delete only this day")
        if excludedDayKeys.contains(Self.dayKey(target, calendar: calendar)) {
            return false
        }

        let anchor = calendar.startOfDay(for: reminderDate ?? createdAt)

        if repeatRule != .none, target < anchor { return false }

        switch repeatRule {
        case .none:
            // If no reminder date, show only on the created date (one-time task)
            guard let remDate = reminderDate else {
                return calendar.isDate(target, inSameDayAs: calendar.startOfDay(for: createdAt))
            }
            return calendar.isDate(target, inSameDayAs: anchor)

        case .daily:
            return target >= anchor

        case .weekly:
            return calendar.component(.weekday, from: target) == calendar.component(.weekday, from: anchor) && target >= anchor

        case .monthly:
            return calendar.component(.day, from: target) == calendar.component(.day, from: anchor) && target >= anchor

        case .yearly:
            return calendar.component(.month, from: target) == calendar.component(.month, from: anchor)
                && calendar.component(.day, from: target) == calendar.component(.day, from: anchor)
                && target >= anchor

        case .customDays:
            return customWeekdays.contains(calendar.component(.weekday, from: target)) && target >= anchor
        }
    }

    func showsIndicator(on day: Date, calendar: Calendar) -> Bool {
        if reminderDate == nil && repeatRule == .none { return false }
        return occurs(on: day, calendar: calendar)
    }
}

struct FFDateID: Hashable {
    let value: Int

    init(_ date: Date) {
        let c = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: date)
        self.value = (c.year! * 10000) + (c.month! * 100) + c.day!
    }
}
