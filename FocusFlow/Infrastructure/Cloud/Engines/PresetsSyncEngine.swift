//
//  PresetsSyncEngine.swift
//  FocusFlow
//
//  Syncs FocusPreset ↔ focus_presets table
//  Syncs active preset ↔ focus_preset_settings table
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `focus_presets` table schema
struct FocusPresetDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var durationSeconds: Int
    var soundId: String?
    var emoji: String?
    var isSystemDefault: Bool
    var themeRaw: String?
    var externalMusicAppRaw: String?
    var ambianceModeRaw: String?
    var sortOrder: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case durationSeconds = "duration_seconds"
        case soundId = "sound_id"
        case emoji
        case isSystemDefault = "is_system_default"
        case themeRaw = "theme_raw"
        case externalMusicAppRaw = "external_music_app_raw"
        case ambianceModeRaw = "ambiance_mode_raw"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `focus_preset_settings` table schema
struct FocusPresetSettingsDTO: Codable {
    let userId: UUID
    var activePresetId: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activePresetId = "active_preset_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class PresetsSyncEngine {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?

    private var isApplyingRemote = false

    // MARK: - Start/Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        // Initial sync
        try await pullFromRemote(userId: userId)

        // Push local presets that don't exist remotely (first-time sync)
        await pushNewLocalPresets()

        // Observe local changes
        observeLocalChanges()
    }

    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
    }

    // MARK: - Pull from Remote

    func pullFromRemote(userId: UUID) async throws {
        let client = SupabaseManager.shared.client

        // Fetch presets
        let remotePresets: [FocusPresetDTO] = try await client
            .from("focus_presets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value

        // ✅ Don't restore active preset from remote - presets should only be active when:
        // 1. User explicitly selects one in the current session
        // 2. A focus session is running with that preset
        // Active preset selection should NOT persist across app launches
        // Always pass nil to ensure no preset is active by default on app launch
        applyRemoteToLocal(presets: remotePresets, activePresetId: nil)

        #if DEBUG
        print("[PresetsSyncEngine] Pulled \(remotePresets.count) presets")
        #endif
    }
    
    // MARK: - Merge with Remote (Resubscription)
    
    /// ✅ NEW: Merge strategy for resubscription - timestamp-based
    /// Strategy:
    /// - Presets that exist in both: keep the newer version
    /// - Presets only in local: keep them (created while free)
    /// - Presets only in remote but deleted locally: delete from remote (local deletion wins)
    func mergeWithRemote(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true
        
        let client = SupabaseManager.shared.client
        let store = FocusPresetStore.shared
        let namespace = userId.uuidString
        
        #if DEBUG
        print("[PresetsSyncEngine] 🔄 Starting timestamp merge for presets...")
        #endif
        
        // Step 1: Fetch all remote presets
        let remotePresets: [FocusPresetDTO] = try await client
            .from("focus_presets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value
        
        #if DEBUG
        print("[PresetsSyncEngine] Remote has \(remotePresets.count) presets")
        print("[PresetsSyncEngine] Local has \(store.presets.count) presets")
        #endif
        
        // Step 2: Build maps for comparison
        var remotePresetMap: [UUID: FocusPresetDTO] = Dictionary(uniqueKeysWithValues: remotePresets.map { ($0.id, $0) })
        let localPresetMap: [UUID: FocusPreset] = Dictionary(uniqueKeysWithValues: store.presets.map { ($0.id, $0) })
        
        var mergedPresets: [FocusPreset] = []
        var presetsToDeleteRemotely: [UUID] = []
        var presetsToUpsertRemotely: [FocusPresetDTO] = []
        
        // Step 3: Process local presets
        for (id, localPreset) in localPresetMap {
            if let remoteDTO = remotePresetMap[id] {
                // Preset exists in both - compare timestamps
                let localTimestamp = LocalTimestampTracker.shared.getLocalTimestamp(
                    field: "preset_\(id.uuidString)",
                    namespace: namespace
                )
                let remoteTimestamp = remoteDTO.updatedAt ?? remoteDTO.createdAt ?? Date.distantPast
                
                if let localTs = localTimestamp, localTs > remoteTimestamp {
                    // Local is newer - keep local and push to remote
                    mergedPresets.append(localPreset)
                    presetsToUpsertRemotely.append(presetToDTO(localPreset, userId: userId, sortOrder: mergedPresets.count - 1))
                    #if DEBUG
                    print("[PresetsSyncEngine] Preset '\(localPreset.name)': keeping LOCAL (newer)")
                    #endif
                } else {
                    // Remote is newer - use remote
                    mergedPresets.append(dtoToPreset(remoteDTO))
                    #if DEBUG
                    print("[PresetsSyncEngine] Preset '\(localPreset.name)': keeping REMOTE (newer)")
                    #endif
                }
                remotePresetMap.removeValue(forKey: id)
            } else {
                // Preset only in local - keep it (created while free)
                mergedPresets.append(localPreset)
                presetsToUpsertRemotely.append(presetToDTO(localPreset, userId: userId, sortOrder: mergedPresets.count - 1))
                #if DEBUG
                print("[PresetsSyncEngine] Preset '\(localPreset.name)': LOCAL-ONLY, will push to remote")
                #endif
            }
        }
        
        // Step 4: Process remaining remote-only presets
        // Check if they were deleted locally (local deletion wins)
        for (id, remoteDTO) in remotePresetMap {
            // Check if this preset was deleted locally
            let wasDeletedLocally = LocalTimestampTracker.shared.getLocalTimestamp(
                field: "preset_deleted_\(id.uuidString)",
                namespace: namespace
            ) != nil
            
            if wasDeletedLocally {
                // Local deletion wins - delete from remote
                presetsToDeleteRemotely.append(id)
                #if DEBUG
                print("[PresetsSyncEngine] Preset '\(remoteDTO.name)': DELETED LOCALLY, deleting from remote")
                #endif
            } else {
                // Remote-only preset that was never seen locally - add it
                mergedPresets.append(dtoToPreset(remoteDTO))
                #if DEBUG
                print("[PresetsSyncEngine] Preset '\(remoteDTO.name)': REMOTE-ONLY, adding to local")
                #endif
            }
        }
        
        #if DEBUG
        print("[PresetsSyncEngine] Merged \(mergedPresets.count) presets")
        #endif
        
        // Step 5: Apply merged state to local store
        store.applyRemoteState(presets: mergedPresets, activePresetId: nil)
        
        // Step 6: Push local-only and newer-local presets to remote
        if !presetsToUpsertRemotely.isEmpty {
            do {
                try await client
                    .from("focus_presets")
                    .upsert(presetsToUpsertRemotely, onConflict: "id")
                    .execute()
            } catch let error as PostgrestError {
                // Handle missing column error gracefully
                if error.code == "PGRST204" && error.message.contains("ambiance_mode_raw") {
                    let dtosWithoutAmbiance = presetsToUpsertRemotely.map { dto in
                        var dtoCopy = dto
                        dtoCopy.ambianceModeRaw = nil
                        return dtoCopy
                    }
                    try await client
                        .from("focus_presets")
                        .upsert(dtosWithoutAmbiance, onConflict: "id")
                        .execute()
                } else {
                    throw error
                }
            }
            #if DEBUG
            print("[PresetsSyncEngine] Pushed \(presetsToUpsertRemotely.count) presets to remote")
            #endif
        }
        
        // Step 7: Delete locally-deleted presets from remote
        for presetId in presetsToDeleteRemotely {
            try await client
                .from("focus_presets")
                .delete()
                .eq("id", value: presetId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        }
        if !presetsToDeleteRemotely.isEmpty {
            #if DEBUG
            print("[PresetsSyncEngine] Deleted \(presetsToDeleteRemotely.count) presets from remote")
            #endif
        }
        
        #if DEBUG
        print("[PresetsSyncEngine] ✅ Merge complete - \(mergedPresets.count) presets")
        #endif
    }
    
    // MARK: - Helper: Convert between DTO and Model
    
    private func presetToDTO(_ preset: FocusPreset, userId: UUID, sortOrder: Int) -> FocusPresetDTO {
        FocusPresetDTO(
            id: preset.id,
            userId: userId,
            name: preset.name,
            durationSeconds: preset.durationSeconds,
            soundId: preset.soundID.isEmpty ? nil : preset.soundID,
            emoji: preset.emoji,
            isSystemDefault: preset.isSystemDefault,
            themeRaw: preset.themeRaw,
            externalMusicAppRaw: preset.externalMusicAppRaw,
            ambianceModeRaw: preset.ambianceModeRaw,
            sortOrder: sortOrder
        )
    }
    
    private func dtoToPreset(_ dto: FocusPresetDTO) -> FocusPreset {
        FocusPreset(
            id: dto.id,
            name: dto.name,
            durationSeconds: dto.durationSeconds,
            soundID: dto.soundId ?? "",
            emoji: dto.emoji,
            isSystemDefault: dto.isSystemDefault,
            themeRaw: dto.themeRaw,
            externalMusicAppRaw: dto.externalMusicAppRaw,
            ambianceModeRaw: dto.ambianceModeRaw
        )
    }

    // MARK: - Push to Remote

    /// Force immediate push (bypasses debounce) - use when app is entering background/terminating
    func forcePushNow() async {
        guard isRunning else { return }
        await pushToRemote()
    }

    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }

        let store = FocusPresetStore.shared
        let client = SupabaseManager.shared.client

        // Convert local presets to DTOs
        let presetDTOs: [FocusPresetDTO] = store.presets.enumerated().map { index, preset in
            FocusPresetDTO(
                id: preset.id,
                userId: userId,
                name: preset.name,
                durationSeconds: preset.durationSeconds,
                soundId: preset.soundID.isEmpty ? nil : preset.soundID,
                emoji: preset.emoji,
                isSystemDefault: preset.isSystemDefault,
                themeRaw: preset.themeRaw,
                externalMusicAppRaw: preset.externalMusicAppRaw,
                ambianceModeRaw: preset.ambianceModeRaw,
                sortOrder: index
            )
        }

        do {
            if !presetDTOs.isEmpty {
                do {
                    try await client
                        .from("focus_presets")
                        .upsert(presetDTOs, onConflict: "id")
                        .execute()
                } catch let error as PostgrestError {
                    // ✅ Handle missing column error gracefully
                    if error.code == "PGRST204" && error.message.contains("ambiance_mode_raw") {
                        #if DEBUG
                        print("[PresetsSyncEngine] Database missing 'ambiance_mode_raw' column - pushing without it")
                        #endif
                        // Retry without ambiance_mode_raw field - create new DTOs without it
                        let dtosWithoutAmbiance = presetDTOs.map { dto in
                            var dtoCopy = dto
                            dtoCopy.ambianceModeRaw = nil // Exclude ambiance field
                            return dtoCopy
                        }
                        try await client
                            .from("focus_presets")
                            .upsert(dtosWithoutAmbiance, onConflict: "id")
                            .execute()
                    } else {
                        throw error
                    }
                }
            }

            // ✅ Use activePresetID (published), not activePreset (computed)
            let settingsDTO = FocusPresetSettingsDTO(
                userId: userId,
                activePresetId: store.activePresetID
            )

            try await client
                .from("focus_preset_settings")
                .upsert(settingsDTO, onConflict: "user_id")
                .execute()

            // ✅ After successful push, clear local timestamps so remote becomes source of truth
            // This prevents the next pull from overwriting with older remote data
            let namespace = userId.uuidString
            for preset in store.presets {
                let fieldKey = "preset_\(preset.id.uuidString)"
                LocalTimestampTracker.shared.clearLocalTimestamp(field: fieldKey, namespace: namespace)
            }

            #if DEBUG
            print("[PresetsSyncEngine] Pushed \(presetDTOs.count) presets to remote")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Push error: \(error)")
            #endif
        }
    }

    // MARK: - Push New Local Presets

    private func pushNewLocalPresets() async {
        guard let userId = userId else { return }

        let store = FocusPresetStore.shared
        let client = SupabaseManager.shared.client

        // ✅ Fetch remote IDs - use lightweight struct for ID-only query
        struct PresetIdOnly: Codable {
            let id: UUID
        }
        
        let remoteIds: Set<UUID> = Set(
            ((try? await client
                .from("focus_presets")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value) as [PresetIdOnly]?)?.map { $0.id } ?? []
        )

        let localOnly = store.presets.filter { !remoteIds.contains($0.id) }
        guard !localOnly.isEmpty else { return }

        let dtos: [FocusPresetDTO] = localOnly.enumerated().map { offset, preset in
            FocusPresetDTO(
                id: preset.id,
                userId: userId,
                name: preset.name,
                durationSeconds: preset.durationSeconds,
                soundId: preset.soundID.isEmpty ? nil : preset.soundID,
                emoji: preset.emoji,
                isSystemDefault: preset.isSystemDefault,
                themeRaw: preset.themeRaw,
                externalMusicAppRaw: preset.externalMusicAppRaw,
                ambianceModeRaw: preset.ambianceModeRaw,
                sortOrder: store.presets.count + offset
            )
        }

        do {
            // ✅ Use upsert instead of insert to handle case where preset was already pushed
            // This prevents duplicate key errors if pushToRemote() already upserted these presets
            do {
                try await client
                    .from("focus_presets")
                    .upsert(dtos, onConflict: "id")
                    .execute()
            } catch let error as PostgrestError {
                    // ✅ Handle missing column error gracefully
                    if error.code == "PGRST204" && error.message.contains("ambiance_mode_raw") {
                        #if DEBUG
                        print("[PresetsSyncEngine] Database missing 'ambiance_mode_raw' column - pushing without it")
                        #endif
                        // Retry without ambiance_mode_raw field - create new DTOs without it
                        let dtosWithoutAmbiance = dtos.map { dto in
                            var dtoCopy = dto
                            dtoCopy.ambianceModeRaw = nil // Exclude ambiance field
                            return dtoCopy
                        }
                        try await client
                            .from("focus_presets")
                            .upsert(dtosWithoutAmbiance, onConflict: "id")
                            .execute()
                    } else {
                        throw error
                    }
            }

            // ✅ After successful push, clear local timestamps for pushed presets
            let namespace = userId.uuidString
            for preset in localOnly {
                let fieldKey = "preset_\(preset.id.uuidString)"
                LocalTimestampTracker.shared.clearLocalTimestamp(field: fieldKey, namespace: namespace)
            }

            #if DEBUG
            print("[PresetsSyncEngine] Pushed \(dtos.count) new local presets to remote")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Push new presets error: \(error)")
            #endif
        }
    }

    // MARK: - Delete Preset

    func deletePresetRemote(presetId: UUID) async {
        guard isRunning, let userId = userId else { return }

        do {
            try await SupabaseManager.shared.client
                .from("focus_presets")
                .delete()
                .eq("id", value: presetId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[PresetsSyncEngine] Deleted preset \(presetId)")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Delete error: \(error)")
            #endif
        }
    }

    // MARK: - Apply Remote to Local

    private func applyRemoteToLocal(presets: [FocusPresetDTO], activePresetId: UUID?) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let store = FocusPresetStore.shared
        guard let userId = userId else { return }
        let namespace = userId.uuidString

        // ✅ NEW: Merge remote presets with local, preserving newer local changes
        var mergedPresets: [FocusPreset] = []
        
        // Start with local presets
        var localPresetsMap: [UUID: FocusPreset] = Dictionary(uniqueKeysWithValues: store.presets.map { ($0.id, $0) })
        
        // Process remote presets
        for dto in presets {
            let remotePreset = FocusPreset(
                id: dto.id,
                name: dto.name,
                durationSeconds: dto.durationSeconds,
                soundID: dto.soundId ?? "",
                emoji: dto.emoji,
                isSystemDefault: dto.isSystemDefault,
                themeRaw: dto.themeRaw,
                externalMusicAppRaw: dto.externalMusicAppRaw,
                ambianceModeRaw: dto.ambianceModeRaw
            )
            
            // Check if local version is newer
            let fieldKey = "preset_\(dto.id.uuidString)"
            let remoteTimestamp = dto.updatedAt ?? dto.createdAt
            
            if let localPreset = localPresetsMap[dto.id] {
                // Preset exists locally - use field-level conflict resolution for name
                let nameFieldKey = "preset_\(dto.id.uuidString)_name"
                let localNameIsNewer = LocalTimestampTracker.shared.isLocalNewer(field: nameFieldKey, namespace: namespace, remoteTimestamp: remoteTimestamp)
                let localOverallIsNewer = LocalTimestampTracker.shared.isLocalNewer(field: fieldKey, namespace: namespace, remoteTimestamp: remoteTimestamp)
                
                var mergedPreset: FocusPreset
                
                if localOverallIsNewer {
                    // Local is newer overall - keep local, but use remote name if remote name is newer
                    if localNameIsNewer {
                        // Local name is also newer - keep full local preset
                        mergedPreset = localPreset
                    } else {
                        // Remote name is newer - merge: local preset with remote name
                        mergedPreset = FocusPreset(
                            id: localPreset.id,
                            name: remotePreset.name,
                            durationSeconds: localPreset.durationSeconds,
                            soundID: localPreset.soundID,
                            emoji: localPreset.emoji,
                            isSystemDefault: localPreset.isSystemDefault,
                            themeRaw: localPreset.themeRaw,
                            externalMusicAppRaw: localPreset.externalMusicAppRaw,
                            ambianceModeRaw: localPreset.ambianceModeRaw
                        )
                    }
                    #if DEBUG
                    print("[PresetsSyncEngine] Keeping local preset '\(mergedPreset.name)' (local is newer)")
                    #endif
                } else {
                    // Remote is newer overall - use remote, but keep local name if local name is newer
                    if localNameIsNewer {
                        // Local name is newer - merge: remote preset with local name
                        mergedPreset = FocusPreset(
                            id: remotePreset.id,
                            name: localPreset.name, // Keep local name
                            durationSeconds: remotePreset.durationSeconds,
                            soundID: remotePreset.soundID,
                            emoji: remotePreset.emoji,
                            isSystemDefault: remotePreset.isSystemDefault,
                            themeRaw: remotePreset.themeRaw,
                            externalMusicAppRaw: remotePreset.externalMusicAppRaw,
                            ambianceModeRaw: remotePreset.ambianceModeRaw
                        )
                    } else {
                        // Remote is newer for all fields including name - use remote
                        mergedPreset = remotePreset
                    }
                    LocalTimestampTracker.shared.clearLocalTimestamp(field: fieldKey, namespace: namespace)
                    #if DEBUG
                    print("[PresetsSyncEngine] Using remote preset '\(mergedPreset.name)' (remote is newer)")
                    #endif
                }
                
                mergedPresets.append(mergedPreset)
            } else {
                // New preset from remote - add it
                mergedPresets.append(remotePreset)
                #if DEBUG
                print("[PresetsSyncEngine] Adding new remote preset '\(remotePreset.name)'")
                #endif
            }
            
            // Remove from local map (so we know which local presets weren't in remote)
            localPresetsMap.removeValue(forKey: dto.id)
        }
        
        // Add any local presets that weren't in remote (if they're newer)
        for (_, localPreset) in localPresetsMap {
            let fieldKey = "preset_\(localPreset.id.uuidString)"
            // If local preset has a timestamp, it means it was modified locally
            // Keep it even if not in remote (it will be pushed on next sync)
            if LocalTimestampTracker.shared.getLocalTimestamp(field: fieldKey, namespace: namespace) != nil {
                mergedPresets.append(localPreset)
                #if DEBUG
                print("[PresetsSyncEngine] Keeping local-only preset '\(localPreset.name)' (will be pushed)")
                #endif
            }
        }

        // Single source of truth lives in FocusPresetStore.swift
        store.applyRemoteState(presets: mergedPresets, activePresetId: activePresetId)

        #if DEBUG
        print("[PresetsSyncEngine] Applied \(mergedPresets.count) presets to local (with conflict resolution)")
        #endif
    }

    // MARK: - Observe Local Changes

    private func observeLocalChanges() {
        let store = FocusPresetStore.shared

        // Preset list changes
        store.$presets
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced from 1s to 0.5s for faster sync
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                
                // ✅ NEW: Enqueue preset changes in sync queue
                // Track which presets changed for reliable sync
                Task { @MainActor in
                    guard let userId = AuthManagerV2.shared.state.userId else { return }
                    let namespace = userId.uuidString
                    
                    for preset in store.presets {
                        if let timestamp = LocalTimestampTracker.shared.getLocalTimestamp(
                            field: "preset_\(preset.id.uuidString)",
                            namespace: namespace
                        ) {
                            SyncQueue.shared.enqueuePresetChange(
                                operation: .update,
                                preset: preset,
                                localTimestamp: timestamp
                            )
                        }
                    }
                }
                
                // Also push immediately (optimistic sync)
                Task { await self.pushToRemote() }
            }
            .store(in: &cancellables)

        // ✅ Active preset changes (observe published ID, not computed activePreset)
        store.$activePresetID
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main) // Reduced from 0.5s to 0.3s
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task { await self.pushToRemote() }
            }
            .store(in: &cancellables)
    }
}
