import Foundation
import Combine

// MARK: - Cloud rows

private struct FocusPresetRow: Codable {
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

private struct FocusPresetSettingsRow: Codable {
    let userId: UUID
    let activePresetId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activePresetId = "active_preset_id"
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

            let rows = (try? SupabaseJSON.decoder.decode([FocusPresetRow].self, from: presetsData)) ?? []
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

            lastKnownRemoteIds = Set(remotePresets.map { $0.id })

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

            let settingsRows = (try? SupabaseJSON.decoder.decode([FocusPresetSettingsRow].self, from: settingsData)) ?? []
            let remoteActiveId = settingsRows.first?.activePresetId

            // Apply remote -> local
            suppressPresetsPush = true
            suppressSettingsPush = true
            applyRemote(remotePresets, remoteActiveId)
            hasPulledOnce = true

            print("SYNC[PRESETS] pulled=\(remotePresets.count)")

            // If cloud is empty, bootstrap from local or defaults (and push)
            if remotePresets.isEmpty {
                let local = getLocalPresets()
                if local.isEmpty {
                    let seeded = seedDefaults()
                    if !seeded.isEmpty {
                        await pushPresets(force: true, presets: seeded, reason: "seedDefaults")
                    }
                } else {
                    await pushPresets(force: true, presets: local, reason: "pushLocalBootstrap")
                }
            }

            // If settings missing but local has an active id, push it
            if remoteActiveId == nil, let localActive = getLocalActivePresetId() {
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
