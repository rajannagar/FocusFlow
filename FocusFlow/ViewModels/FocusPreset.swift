// FocusPreset.swift

import Foundation

struct FocusPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationSeconds: Int
    var soundID: String
    var emoji: String?
    var isSystemDefault: Bool

    /// Optional raw theme value for this preset (AppTheme.rawValue).
    /// If nil, the preset does not override the app theme.
    var themeRaw: String?          // 👈 NEW

    /// Convenience: typed access to the preset's theme, if any.
    var theme: AppTheme? {
        guard let themeRaw,
              let value = AppTheme(rawValue: themeRaw) else {
            return nil
        }
        return value
    }

    init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int,
        soundID: String,
        emoji: String? = nil,
        isSystemDefault: Bool = false,
        themeRaw: String? = nil      // 👈 NEW (defaulted for backwards compatibility)
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.soundID = soundID
        self.emoji = emoji
        self.isSystemDefault = isSystemDefault
        self.themeRaw = themeRaw
    }
}

extension FocusPreset {
    static func minutes(_ minutes: Int) -> Int {
        minutes * 60
    }
}
