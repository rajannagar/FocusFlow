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
    var themeRaw: String?

    /// Optional raw external music app value (AppSettings.ExternalMusicApp.rawValue).
    /// If nil, this preset does not launch a music app.
    var externalMusicAppRaw: String?    // "spotify", "appleMusic", "youtubeMusic", or nil

    /// Optional raw ambiance mode value (AmbientMode.rawValue).
    /// If nil, the preset uses the default ambiance mode.
    var ambianceModeRaw: String?

    // MARK: - Typed accessors

    /// Typed access to the preset's theme, if any.
    var theme: AppTheme? {
        guard let themeRaw,
              let value = AppTheme(rawValue: themeRaw) else {
            return nil
        }
        return value
    }

    /// Typed access to the preset's external music app, if any.
    var externalMusicApp: AppSettings.ExternalMusicApp? {
        guard let raw = externalMusicAppRaw else { return nil }
        return AppSettings.ExternalMusicApp(rawValue: raw)
    }

    /// Typed access to the preset's ambiance mode, if any.
    var ambianceMode: AmbientMode? {
        guard let raw = ambianceModeRaw else { return nil }
        return AmbientMode(rawValue: raw)
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int,
        soundID: String,
        emoji: String? = nil,
        isSystemDefault: Bool = false,
        themeRaw: String? = nil,
        externalMusicAppRaw: String? = nil,
        ambianceModeRaw: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.soundID = soundID
        self.emoji = emoji
        self.isSystemDefault = isSystemDefault
        self.themeRaw = themeRaw
        self.externalMusicAppRaw = externalMusicAppRaw
        self.ambianceModeRaw = ambianceModeRaw
    }
}

extension FocusPreset {
    static func minutes(_ minutes: Int) -> Int {
        minutes * 60
    }
}
