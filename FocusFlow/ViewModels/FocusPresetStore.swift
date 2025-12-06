import Foundation
import Combine

final class FocusPresetStore: ObservableObject {
    static let shared = FocusPresetStore()

    @Published var presets: [FocusPreset] = [] {
        didSet { savePresets() }
    }

    @Published var activePresetID: UUID? {
        didSet { saveActivePresetID() }
    }

    private let presetsKey = "focus_presets"
    private let activePresetIDKey = "focus_active_preset_id"

    private init() {
        loadPresets()
        loadActivePresetID()
        seedDefaultsIfNeeded()
    }

    // MARK: - Public

    var activePreset: FocusPreset? {
        get {
            guard let id = activePresetID else { return nil }
            return presets.first(where: { $0.id == id })
        }
        set {
            activePresetID = newValue?.id
        }
    }

    /// Upsert helper used by older callsites.
    func upsert(_ preset: FocusPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
    }

    /// New nicer API for the editor – upserts and does small housekeeping.
    func save(_ preset: FocusPreset) {
        let isNew = !presets.contains(where: { $0.id == preset.id })
        upsert(preset)

        // If nothing is active yet and this is a brand-new preset, make it active.
        if isNew && activePresetID == nil {
            activePresetID = preset.id
        }
    }

    func delete(_ preset: FocusPreset) {
        presets.removeAll { $0.id == preset.id }
        if activePresetID == preset.id {
            activePresetID = nil
        }
    }

    /// Reorder presets without needing SwiftUI's `.move(fromOffsets:toOffset:)`
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        // 1. Grab the items being moved
        let movingItems = source.map { presets[$0] }

        // 2. Remove them from their original positions (highest index first)
        for index in source.sorted(by: >) {
            presets.remove(at: index)
        }

        // 3. Adjust destination index because the array is now smaller
        var targetIndex = destination
        let removedBeforeDestination = source.filter { $0 < destination }.count
        targetIndex -= removedBeforeDestination

        // 4. Insert at new location
        presets.insert(contentsOf: movingItems, at: targetIndex)
    }

    // MARK: - Defaults

    private func seedDefaultsIfNeeded() {
        guard presets.isEmpty else { return }

        // Use your real sound IDs from the bundle (from your screenshot)
        let defaults: [FocusPreset] = [
            FocusPreset(
                name: "Deep Work",
                durationSeconds: FocusPreset.minutes(50),
                soundID: "angelsbymyside",
                emoji: "🧠",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Study",
                durationSeconds: FocusPreset.minutes(40),
                soundID: "floatinggarden",
                emoji: "📚",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Writing",
                durationSeconds: FocusPreset.minutes(30),
                soundID: "light-rain-ambient",
                emoji: "✍️",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Reading",
                durationSeconds: FocusPreset.minutes(25),
                soundID: "fireplace",
                emoji: "📖",
                isSystemDefault: true
            )
        ]

        presets = defaults
        activePresetID = defaults.first?.id
    }

    // MARK: - Persistence

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: presetsKey) else {
            presets = []
            return
        }
        do {
            presets = try JSONDecoder().decode([FocusPreset].self, from: data)
        } catch {
            print("⚠️ Failed to decode FocusPresets:", error)
            presets = []
        }
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: presetsKey)
        } catch {
            print("⚠️ Failed to encode FocusPresets:", error)
        }
    }

    private func loadActivePresetID() {
        guard let idString = UserDefaults.standard.string(forKey: activePresetIDKey),
              let id = UUID(uuidString: idString) else {
            activePresetID = nil
            return
        }
        activePresetID = id
    }

    private func saveActivePresetID() {
        if let id = activePresetID {
            UserDefaults.standard.set(id.uuidString, forKey: activePresetIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activePresetIDKey)
        }
    }
}
