import Foundation
import Combine

// MARK: - Cloud rows

/// IMPORTANT:
/// PostgREST (Supabase) requires that when you POST an **array** of JSON objects,
/// every object must have the **exact same keys**.
/// Swift's default Codable encoding **omits nil optionals**, which causes mixed keys
/// across rows (some include `emoji`, others omit it), triggering:
/// PGRST102: "All object keys must match"
///
/// So we custom-encode optionals as explicit `null` to keep keys stable.
private struct FocusPresetRow: Encodable {
    let userId: UUID
    let id: UUID
    let name: String
    let durationSeconds: Int
    let soundId: String
    let emoji: String?
    let isSystemDefault: Bool
    let themeRaw: String?
    let externalMusicAppRaw: String?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case id
        case name
        case durationSeconds = "duration_seconds"
        case soundId = "sound_id"
        case emoji
        case isSystemDefault = "is_system_default"
        case themeRaw = "theme_raw"
        case externalMusicAppRaw = "external_music_app_raw"
        case sortOrder = "sort_order"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userId, forKey: .userId)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(soundId, forKey: .soundId)

        // ✅ Encode nils as explicit null so every object has same keys.
        if let emoji { try c.encode(emoji, forKey: .emoji) } else { try c.encodeNil(forKey: .emoji) }
        try c.encode(isSystemDefault, forKey: .isSystemDefault)
        if let themeRaw { try c.encode(themeRaw, forKey: .themeRaw) } else { try c.encodeNil(forKey: .themeRaw) }
        if let externalMusicAppRaw { try c.encode(externalMusicAppRaw, forKey: .externalMusicAppRaw) } else { try c.encodeNil(forKey: .externalMusicAppRaw) }

        try c.encode(sortOrder, forKey: .sortOrder)
    }
}

/// Settings is a single object (not an array) so key-mismatch isn't an issue,
/// but we still encode nil as null for consistency.
private struct FocusPresetSettingsRow: Encodable {
    let userId: UUID
    let activePresetId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activePresetId = "active_preset_id"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userId, forKey: .userId)
        if let activePresetId { try c.encode(activePresetId, forKey: .activePresetId) }
        else { try c.encodeNil(forKey: .activePresetId) }
    }
}

// MARK: - Engine

@MainActor
final class FocusPresetSyncEngine {

    static let shared = FocusPresetSyncEngine()

    private var cancellables = Set<AnyCancellable>()

    private var activeUserId: UUID?
    private var hasPulledOnce = false

    private var suppressPresetsPush = false
    private var suppressSettingsPush = false

    private var lastKnownRemoteIds = Set<UUID>()

    // ✅ Prevent double pulls when auth state flaps quickly
    private var pullInFlight = false

    private init() {}

    func disableSyncAndResetCloudState() {
        activeUserId = nil
        hasPulledOnce = false
        suppressPresetsPush = false
        suppressSettingsPush = false
        lastKnownRemoteIds = []
        pullInFlight = false
        cancellables.removeAll()
    }

    func start(
        presetsPublisher: AnyPublisher<[FocusPreset], Never>,
        activePresetIdPublisher: AnyPublisher<UUID?, Never>,
        getLocalPresets: @escaping () -> [FocusPreset],
        getLocalActivePresetId: @escaping () -> UUID?,
        seedDefaults: @escaping () -> [FocusPreset],
        applyRemote: @escaping (_ presets: [FocusPreset], _ activePresetId: UUID?) -> Void
    ) {
        cancellables.removeAll()

        // Observe auth changes
        AuthManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.handleAuthState(
                    state,
                    getLocalPresets: getLocalPresets,
                    getLocalActivePresetId: getLocalActivePresetId,
                    seedDefaults: seedDefaults,
                    applyRemote: applyRemote
                )
            }
            .store(in: &cancellables)

        // Push presets on change (debounced)
        presetsPublisher
            .dropFirst()
            .debounce(for: .milliseconds(450), scheduler: DispatchQueue.main)
            .sink { [weak self] presets in
                guard let self else { return }
                Task { await self.pushPresetsIfAllowed(presets: presets, reason: "presetsChanged") }
            }
            .store(in: &cancellables)

        // Push active preset id on change (debounced)
        activePresetIdPublisher
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { [weak self] activeId in
                guard let self else { return }
                Task { await self.pushSettingsIfAllowed(activePresetId: activeId, reason: "activePresetChanged") }
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(
        _ state: AuthState,
        getLocalPresets: @escaping () -> [FocusPreset],
        getLocalActivePresetId: @escaping () -> UUID?,
        seedDefaults: @escaping () -> [FocusPreset],
        applyRemote: @escaping (_ presets: [FocusPreset], _ activePresetId: UUID?) -> Void
    ) {
        guard case .authenticated(let session) = state,
              session.isGuest == false,
              let token = session.accessToken
        else {
            // guest/unauthenticated
            activeUserId = nil
            hasPulledOnce = false
            lastKnownRemoteIds = []
            pullInFlight = false
            return
        }

        let uid = session.userId

        // user switched
        if activeUserId != uid {
            activeUserId = uid
            hasPulledOnce = false
            lastKnownRemoteIds = []
            pullInFlight = false
        }

        // ✅ No double pull
        guard hasPulledOnce == false, pullInFlight == false else { return }
        pullInFlight = true

        Task {
            await pullOnce(
                userId: uid,
                bearerToken: token,
                getLocalPresets: getLocalPresets,
                getLocalActivePresetId: getLocalActivePresetId,
                seedDefaults: seedDefaults,
                applyRemote: applyRemote
            )
        }
    }

    private func pullOnce(
        userId: UUID,
        bearerToken: String,
        getLocalPresets: @escaping () -> [FocusPreset],
        getLocalActivePresetId: @escaping () -> UUID?,
        seedDefaults: @escaping () -> [FocusPreset],
        applyRemote: @escaping (_ presets: [FocusPreset], _ activePresetId: UUID?) -> Void
    ) async {
        defer { pullInFlight = false }

        // ✅ Snapshot local BEFORE we apply anything from cloud.
        // This prevents the "remote empty -> applyRemote wipes local -> bootstrap sees empty local" bug.
        let localBefore = getLocalPresets()
        let localActiveBefore = getLocalActivePresetId()

        do {
            // 1) Pull presets
            let presetsData = try await SupabaseREST.request(
                path: "rest/v1/focus_presets",
                method: "GET",
                query: [
                    URLQueryItem(name: "select", value: "*"),
                    URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                    URLQueryItem(name: "order", value: "sort_order.asc")
                ],
                bearerToken: bearerToken
            )

            // Decode permissively; include sortOrder from row.
            struct FocusPresetRowDecodable: Decodable {
                let userId: UUID
                let id: UUID
                let name: String
                let durationSeconds: Int
                let soundId: String
                let emoji: String?
                let isSystemDefault: Bool
                let themeRaw: String?
                let externalMusicAppRaw: String?
                let sortOrder: Int

                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case id
                    case name
                    case durationSeconds = "duration_seconds"
                    case soundId = "sound_id"
                    case emoji
                    case isSystemDefault = "is_system_default"
                    case themeRaw = "theme_raw"
                    case externalMusicAppRaw = "external_music_app_raw"
                    case sortOrder = "sort_order"
                }
            }

            let rows = (try? SupabaseJSON.decoder.decode([FocusPresetRowDecodable].self, from: presetsData)) ?? []
            let remotePresets: [FocusPreset] = rows.map {
                FocusPreset(
                    id: $0.id,
                    name: $0.name,
                    durationSeconds: $0.durationSeconds,
                    soundID: $0.soundId,
                    emoji: $0.emoji,
                    isSystemDefault: $0.isSystemDefault,
                    themeRaw: $0.themeRaw,
                    externalMusicAppRaw: $0.externalMusicAppRaw
                )
            }

            // 2) Pull settings
            let settingsData = try await SupabaseREST.request(
                path: "rest/v1/focus_preset_settings",
                method: "GET",
                query: [
                    URLQueryItem(name: "select", value: "*"),
                    URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                    URLQueryItem(name: "limit", value: "1")
                ],
                bearerToken: bearerToken
            )

            struct FocusPresetSettingsRowDecodable: Decodable {
                let userId: UUID
                let activePresetId: UUID?

                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case activePresetId = "active_preset_id"
                }
            }

            let settingsRows = (try? SupabaseJSON.decoder.decode([FocusPresetSettingsRowDecodable].self, from: settingsData)) ?? []
            let remoteActiveId = settingsRows.first?.activePresetId

            print("SYNC[PRESETS] pulled=\(remotePresets.count)")

            // ✅ If cloud is empty but we have local data, DO NOT wipe local.
            // Instead: treat local as source-of-truth and bootstrap push.
            if remotePresets.isEmpty, !localBefore.isEmpty {
                hasPulledOnce = true
                // lastKnownRemoteIds stays empty here; we will update it after a successful push.
                await pushPresets(force: true, presets: localBefore, reason: "pushLocalBootstrap(remoteEmpty)")
                if remoteActiveId == nil, let localActiveBefore {
                    await pushSettings(force: true, activePresetId: localActiveBefore, reason: "bootstrapActivePreset(remoteEmpty)")
                }
                return
            }

            // Normal path: apply remote to local
            lastKnownRemoteIds = Set(remotePresets.map { $0.id })

            suppressPresetsPush = true
            suppressSettingsPush = true
            applyRemote(remotePresets, remoteActiveId)
            hasPulledOnce = true

            // If cloud is empty AND local was also empty, seed defaults then push.
            if remotePresets.isEmpty, localBefore.isEmpty {
                let seeded = seedDefaults()
                if !seeded.isEmpty {
                    // Apply seeded locally (optional, but helps UI immediately)
                    suppressPresetsPush = true
                    suppressSettingsPush = true
                    applyRemote(seeded, remoteActiveId ?? localActiveBefore)
                    await pushPresets(force: true, presets: seeded, reason: "seedDefaults")
                }
            }

            // If settings missing but local has an active id, push it
            if remoteActiveId == nil, let localActive = localActiveBefore {
                await pushSettings(force: true, activePresetId: localActive, reason: "bootstrapActivePreset")
            }
        } catch {
            print("SYNC[PRESETS] pull failed: \(error)")
        }
    }

    private func pushPresetsIfAllowed(presets: [FocusPreset], reason: String) async {
        guard suppressPresetsPush == false else {
            suppressPresetsPush = false
            print("SYNC[PRESETS] suppressedPush=true (after pull)")
            return
        }
        await pushPresets(force: false, presets: presets, reason: reason)
    }

    private func pushSettingsIfAllowed(activePresetId: UUID?, reason: String) async {
        guard suppressSettingsPush == false else {
            suppressSettingsPush = false
            print("SYNC[PRESETS_SETTINGS] suppressedPush=true (after pull)")
            return
        }
        await pushSettings(force: false, activePresetId: activePresetId, reason: reason)
    }

    private func pushPresets(force: Bool, presets: [FocusPreset], reason: String) async {
        guard case .authenticated(let session) = AuthManager.shared.state,
              session.isGuest == false,
              let token = session.accessToken
        else { return }

        let userId = session.userId
        if activeUserId != userId { return }
        if force == false && hasPulledOnce == false { return }

        // ✅ HARD SAFETY: never wipe cloud due to transient empty local list
        if presets.isEmpty, !lastKnownRemoteIds.isEmpty, force == false {
            print("SYNC[PRESETS] ⚠️ skip empty push to avoid accidental wipe. reason=\(reason)")
            return
        }

        do {
            let localIds = Set(presets.map { $0.id })
            let removed = lastKnownRemoteIds.subtracting(localIds)

            // Delete removed ids
            if !removed.isEmpty {
                let ids = removed.map { $0.uuidString }.joined(separator: ",")
                _ = try await SupabaseREST.request(
                    path: "rest/v1/focus_presets",
                    method: "DELETE",
                    query: [
                        URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                        URLQueryItem(name: "id", value: "in.(\(ids))")
                    ],
                    bearerToken: token
                )
            }

            // Upsert current list (with sort_order)
            let payload: [FocusPresetRow] = presets.enumerated().map { idx, p in
                FocusPresetRow(
                    userId: userId,
                    id: p.id,
                    name: p.name,
                    durationSeconds: p.durationSeconds,
                    soundId: p.soundID,
                    emoji: p.emoji,
                    isSystemDefault: p.isSystemDefault,
                    themeRaw: p.themeRaw,
                    externalMusicAppRaw: p.externalMusicAppRaw,
                    sortOrder: idx
                )
            }

            let body = try SupabaseJSON.encoder.encode(payload)

            _ = try await SupabaseREST.request(
                path: "rest/v1/focus_presets",
                method: "POST",
                query: [
                    URLQueryItem(name: "on_conflict", value: "user_id,id")
                ],
                bearerToken: token,
                body: body,
                extraHeaders: [
                    "Prefer": "resolution=merge-duplicates,return=minimal"
                ]
            )

            lastKnownRemoteIds = localIds
            print("SYNC[PRESETS] pushed=\(presets.count) reason=\(reason)")
        } catch {
            print("SYNC[PRESETS] push failed reason=\(reason) error=\(error)")
        }
    }

    private func pushSettings(force: Bool, activePresetId: UUID?, reason: String) async {
        guard case .authenticated(let session) = AuthManager.shared.state,
              session.isGuest == false,
              let token = session.accessToken
        else { return }

        let userId = session.userId
        if activeUserId != userId { return }
        if force == false && hasPulledOnce == false { return }

        do {
            let row = FocusPresetSettingsRow(userId: userId, activePresetId: activePresetId)
            let body = try SupabaseJSON.encoder.encode(row)

            _ = try await SupabaseREST.request(
                path: "rest/v1/focus_preset_settings",
                method: "POST",
                query: [
                    URLQueryItem(name: "on_conflict", value: "user_id")
                ],
                bearerToken: token,
                body: body,
                extraHeaders: [
                    "Prefer": "resolution=merge-duplicates,return=minimal"
                ]
            )

            print("SYNC[PRESETS_SETTINGS] pushed reason=\(reason) active=\(activePresetId?.uuidString ?? "nil")")
        } catch {
            print("SYNC[PRESETS_SETTINGS] push failed reason=\(reason) error=\(error)")
        }
    }
}
