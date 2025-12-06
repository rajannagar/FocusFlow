import Foundation
import SwiftUI
import Combine

// MARK: - Theme model

enum AppTheme: String, CaseIterable, Identifiable {
    // Core favourites (kept)
    case forest
    case neon
    case peach
    case cyber

    // New themes (6x)
    case ocean
    case sunrise
    case amber
    case mint
    case royal
    case slate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forest:  return "Forest"
        case .neon:    return "Neon Glow"
        case .peach:   return "Soft Peach"
        case .cyber:   return "Cyber Violet"

        case .ocean:   return "Ocean Mist"
        case .sunrise: return "Sunrise Coral"
        case .amber:   return "Solar Amber"
        case .mint:    return "Mint Aura"
        case .royal:   return "Royal Indigo"
        case .slate:   return "Cosmic Slate"
        }
    }

    /// Background gradient colors for screens
    var backgroundColors: [Color] {
        switch self {
        case .forest:
            return [
                Color(red: 0.05, green: 0.11, blue: 0.09),
                Color(red: 0.13, green: 0.22, blue: 0.18)
            ]
        case .neon:
            return [
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.13, green: 0.02, blue: 0.24)
            ]
        case .peach:
            return [
                Color(red: 0.16, green: 0.08, blue: 0.11),
                Color(red: 0.31, green: 0.15, blue: 0.18)
            ]
        case .cyber:
            return [
                Color(red: 0.06, green: 0.04, blue: 0.18),
                Color(red: 0.18, green: 0.09, blue: 0.32)
            ]
        case .ocean:
            return [
                Color(red: 0.02, green: 0.08, blue: 0.15),
                Color(red: 0.03, green: 0.27, blue: 0.32)
            ]
        case .sunrise:
            return [
                Color(red: 0.10, green: 0.06, blue: 0.20),
                Color(red: 0.33, green: 0.17, blue: 0.24)
            ]
        case .amber:
            return [
                Color(red: 0.10, green: 0.06, blue: 0.04),
                Color(red: 0.30, green: 0.18, blue: 0.10)
            ]
        case .mint:
            return [
                Color(red: 0.02, green: 0.10, blue: 0.09),
                Color(red: 0.08, green: 0.30, blue: 0.26)
            ]
        case .royal:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.16),
                Color(red: 0.11, green: 0.17, blue: 0.32)
            ]
        case .slate:
            return [
                Color(red: 0.06, green: 0.07, blue: 0.11),
                Color(red: 0.16, green: 0.18, blue: 0.24)
            ]
        }
    }

    /// Main accent color
    var accentPrimary: Color {
        switch self {
        case .forest:
            return Color(red: 0.55, green: 0.90, blue: 0.70)
        case .neon:
            return Color(red: 0.25, green: 0.95, blue: 0.85)
        case .peach:
            return Color(red: 1.00, green: 0.72, blue: 0.63)
        case .cyber:
            return Color(red: 0.80, green: 0.60, blue: 1.00)
        case .ocean:
            return Color(red: 0.48, green: 0.84, blue: 1.00)
        case .sunrise:
            return Color(red: 1.00, green: 0.62, blue: 0.63)
        case .amber:
            return Color(red: 1.00, green: 0.78, blue: 0.45)
        case .mint:
            return Color(red: 0.60, green: 0.96, blue: 0.78)
        case .royal:
            return Color(red: 0.65, green: 0.72, blue: 1.00)
        case .slate:
            return Color(red: 0.75, green: 0.82, blue: 0.96)
        }
    }

    /// Secondary accent (for gradients)
    var accentSecondary: Color {
        switch self {
        case .forest:
            return Color(red: 0.42, green: 0.78, blue: 0.62)
        case .neon:
            return Color(red: 0.60, green: 0.40, blue: 1.00)
        case .peach:
            return Color(red: 1.00, green: 0.85, blue: 0.70)
        case .cyber:
            return Color(red: 0.38, green: 0.86, blue: 1.00)
        case .ocean:
            return Color(red: 0.23, green: 0.95, blue: 0.96)
        case .sunrise:
            return Color(red: 1.00, green: 0.80, blue: 0.55)
        case .amber:
            return Color(red: 1.00, green: 0.60, blue: 0.40)
        case .mint:
            return Color(red: 0.46, green: 0.88, blue: 0.92)
        case .royal:
            return Color(red: 0.50, green: 0.60, blue: 1.00)
        case .slate:
            return Color(red: 0.70, green: 0.76, blue: 0.90)
        }
    }

    var accentColor: Color { accentPrimary }
}

// MARK: - App-wide settings / profile

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Focus sound source helper

    /// Which engine should the timer use for focus sound.
    enum FocusSoundSource {
        case builtin
        case spotify
    }

    // MARK: - Published properties

    @Published var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: Keys.displayName) }
    }

    @Published var tagline: String {
        didSet { UserDefaults.standard.set(tagline, forKey: Keys.tagline) }
    }

    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: Keys.selectedTheme) }
    }

    @Published var profileTheme: AppTheme {
        didSet { UserDefaults.standard.set(profileTheme.rawValue, forKey: Keys.profileTheme) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    @Published var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled) }
    }

    /// Selected looping focus sound (background sound while timer runs)
    @Published var selectedFocusSound: FocusSound? {
        didSet {
            let raw = selectedFocusSound?.rawValue
            UserDefaults.standard.set(raw, forKey: Keys.selectedFocusSound)
        }
    }

    @Published var dailyReminderTime: Date {
        didSet {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
            UserDefaults.standard.set(comps.hour ?? 9, forKey: Keys.reminderHour)
            UserDefaults.standard.set(comps.minute ?? 0, forKey: Keys.reminderMinute)
        }
    }

    @Published var profileImageData: Data? {
        didSet {
            let defaults = UserDefaults.standard
            if let data = profileImageData {
                defaults.set(data, forKey: Keys.profileImageData)
            } else {
                defaults.removeObject(forKey: Keys.profileImageData)
            }
        }
    }

    // MARK: - Spotify focus settings

    /// Whether focus timer should use Spotify instead of built-in sounds.
    @Published var spotifyEnabledForFocus: Bool {
        didSet {
            UserDefaults.standard.set(spotifyEnabledForFocus, forKey: Keys.spotifyEnabledForFocus)
        }
    }

    /// Selected Spotify track to use for focus (URI + display).
    @Published var spotifyTrackURI: String? {
        didSet {
            let defaults = UserDefaults.standard
            if let uri = spotifyTrackURI {
                defaults.set(uri, forKey: Keys.spotifyTrackURI)
            } else {
                defaults.removeObject(forKey: Keys.spotifyTrackURI)
            }
        }
    }

    @Published var spotifyTrackName: String? {
        didSet {
            let defaults = UserDefaults.standard
            if let name = spotifyTrackName {
                defaults.set(name, forKey: Keys.spotifyTrackName)
            } else {
                defaults.removeObject(forKey: Keys.spotifyTrackName)
            }
        }
    }

    @Published var spotifyArtistName: String? {
        didSet {
            let defaults = UserDefaults.standard
            if let artist = spotifyArtistName {
                defaults.set(artist, forKey: Keys.spotifyArtistName)
            } else {
                defaults.removeObject(forKey: Keys.spotifyArtistName)
            }
        }
    }

    /// Convenience: true when Spotify is selected and we have a URI.
    var hasSpotifyFocusTrack: Bool {
        spotifyEnabledForFocus && spotifyTrackURI != nil
    }

    /// Convenience: which source should we actually use right now.
    var currentFocusSoundSource: FocusSoundSource {
        hasSpotifyFocusTrack ? .spotify : .builtin
    }

    /// Convenience: nice display text for the chosen Spotify track.
    var spotifyDisplayTitle: String? {
        guard let name = spotifyTrackName else { return nil }
        if let artist = spotifyArtistName, !artist.isEmpty {
            return "\(name) • \(artist)"
        } else {
            return name
        }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        self.displayName = defaults.string(forKey: Keys.displayName) ?? "You"
        self.tagline = defaults.string(forKey: Keys.tagline) ?? "Staying focused."

        let initialTheme: AppTheme
        if let raw = defaults.string(forKey: Keys.selectedTheme),
           let savedTheme = AppTheme(rawValue: raw) {
            initialTheme = savedTheme
        } else {
            initialTheme = .forest
        }
        self.selectedTheme = initialTheme

        if let rawProfile = defaults.string(forKey: Keys.profileTheme),
           let savedProfile = AppTheme(rawValue: rawProfile) {
            self.profileTheme = savedProfile
        } else {
            self.profileTheme = initialTheme
        }

        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        self.dailyReminderEnabled = defaults.object(forKey: Keys.dailyReminderEnabled) as? Bool ?? false

        if let rawSound = defaults.string(forKey: Keys.selectedFocusSound),
           let sound = FocusSound(rawValue: rawSound) {
            self.selectedFocusSound = sound
        } else {
            self.selectedFocusSound = .lightRainAmbient
        }

        let hour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        self.dailyReminderTime = Calendar.current.date(from: comps) ?? Date()

        self.profileImageData = defaults.data(forKey: Keys.profileImageData)

        // Spotify (defaults to off so existing users keep built-in sounds)
        self.spotifyEnabledForFocus = defaults.object(forKey: Keys.spotifyEnabledForFocus) as? Bool ?? false
        self.spotifyTrackURI = defaults.string(forKey: Keys.spotifyTrackURI)
        self.spotifyTrackName = defaults.string(forKey: Keys.spotifyTrackName)
        self.spotifyArtistName = defaults.string(forKey: Keys.spotifyArtistName)
    }

    // MARK: - Keys

    private struct Keys {
        static let displayName = "ff_displayName"
        static let tagline = "ff_tagline"
        static let selectedTheme = "ff_selectedTheme"
        static let profileTheme = "ff_profileTheme"
        static let soundEnabled = "ff_soundEnabled"
        static let hapticsEnabled = "ff_hapticsEnabled"
        static let dailyReminderEnabled = "ff_dailyReminderEnabled"
        static let reminderHour = "ff_reminderHour"
        static let reminderMinute = "ff_reminderMinute"
        static let profileImageData = "ff_profileImageData"
        static let selectedFocusSound = "ff_selectedFocusSound"

        // Spotify integration
        static let spotifyEnabledForFocus = "ff_spotifyEnabledForFocus"
        static let spotifyTrackURI = "ff_spotifyTrackURI"
        static let spotifyTrackName = "ff_spotifyTrackName"
        static let spotifyArtistName = "ff_spotifyArtistName"
    }
}
