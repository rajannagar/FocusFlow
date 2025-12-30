//
//  TasksSyncEngine.swift
//  FocusFlow
//
//  Syncs FFTaskItem ↔ tasks table
//  Syncs completedOccurrenceKeys ↔ task_completions table
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `tasks` table schema
struct TaskDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var notes: String?
    var reminderDate: Date?
    var repeatRule: String
    var customWeekdays: [Int]
    var durationMinutes: Int
    var convertToPreset: Bool
    var presetCreated: Bool
    var excludedDayKeys: [String]
    var sortIndex: Int
    var isArchived: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case notes
        case reminderDate = "reminder_date"
        case repeatRule = "repeat_rule"
        case customWeekdays = "custom_weekdays"
        case durationMinutes = "duration_minutes"
        case convertToPreset = "convert_to_preset"
        case presetCreated = "preset_created"
        case excludedDayKeys = "excluded_day_keys"
        case sortIndex = "sort_index"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `task_completions` table schema
struct TaskCompletionDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let taskId: UUID
    let dayKey: String
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case dayKey = "day_key"
        case completedAt = "completed_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class TasksSyncEngine {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?
    
    private var isApplyingRemote = false
    
    // MARK: - Start/Stop
    
    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true
        
        // Initial pull
        try await pullFromRemote(userId: userId)
        
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
        
        // Fetch tasks
        let remoteTasks: [TaskDTO] = try await client
            .from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_archived", value: false)
            .order("sort_index", ascending: true)
            .execute()
            .value
        
        // Fetch completions
        let remoteCompletions: [TaskCompletionDTO] = try await client
            .from("task_completions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        applyRemoteToLocal(tasks: remoteTasks, completions: remoteCompletions)
        
        #if DEBUG
        print("[TasksSyncEngine] Pulled \(remoteTasks.count) tasks, \(remoteCompletions.count) completions")
        #endif
    }
    
    // MARK: - Push to Remote
    
    /// Force push immediately (bypasses debounce) - used by sync queue
    func forcePushNow() async {
        await pushToRemote()
    }
    
    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }
        
        let store = TasksStore.shared
        let client = SupabaseManager.shared.client
        
        // Convert local tasks to DTOs
        let taskDTOs = store.tasks.map { task -> TaskDTO in
            TaskDTO(
                id: task.id,
                userId: userId,
                title: task.title,
                notes: task.notes,
                reminderDate: task.reminderDate,
                repeatRule: task.repeatRule.rawValue,
                customWeekdays: Array(task.customWeekdays),
                durationMinutes: task.durationMinutes,
                convertToPreset: task.convertToPreset,
                presetCreated: task.presetCreated,
                excludedDayKeys: Array(task.excludedDayKeys),
                sortIndex: task.sortIndex,
                isArchived: false
            )
        }
        
        do {
            // Upsert tasks
            if !taskDTOs.isEmpty {
                try await client
                    .from("tasks")
                    .upsert(taskDTOs, onConflict: "id")
                    .execute()
            }
            
            // For completions, we need to handle adds/removes
            // First, get existing remote completions
            let existingRemote: [TaskCompletionDTO] = try await client
                .from("task_completions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            let existingKeys = Set(existingRemote.map { "\($0.taskId.uuidString)|\($0.dayKey)" })
            let localKeys = store.completedOccurrenceKeys
            
            // Add new completions
            let toAdd = localKeys.subtracting(existingKeys)
            if !toAdd.isEmpty {
                var newCompletions: [TaskCompletionDTO] = []
                for key in toAdd {
                    let parts = key.split(separator: "|")
                    guard parts.count == 2,
                          let taskId = UUID(uuidString: String(parts[0])) else { continue }
                    newCompletions.append(TaskCompletionDTO(
                        id: UUID(),
                        userId: userId,
                        taskId: taskId,
                        dayKey: String(parts[1])
                    ))
                }
                if !newCompletions.isEmpty {
                    try await client
                        .from("task_completions")
                        .insert(newCompletions)
                        .execute()
                }
            }
            
            // Remove deleted completions
            let toRemove = existingKeys.subtracting(localKeys)
            for key in toRemove {
                let parts = key.split(separator: "|")
                guard parts.count == 2,
                      let taskId = UUID(uuidString: String(parts[0])) else { continue }
                let dayKey = String(parts[1])
                
                try await client
                    .from("task_completions")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("task_id", value: taskId.uuidString)
                    .eq("day_key", value: dayKey)
                    .execute()
            }
            
            // ✅ Clear local timestamps after successful push
            let namespace = userId.uuidString
            for task in store.tasks {
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "task_\(task.id.uuidString)", namespace: namespace)
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "task_completion_\(task.id.uuidString)", namespace: namespace)
            }
            
            #if DEBUG
            print("[TasksSyncEngine] Pushed tasks and completions to remote")
            #endif
        } catch {
            #if DEBUG
            print("[TasksSyncEngine] Push error: \(error)")
            #endif
        }
    }
    
    // MARK: - Delete Task
    
    func deleteTaskRemote(taskId: UUID) async {
        guard isRunning, let userId = userId else { return }
        
        do {
            // Archive instead of hard delete (preserves data)
            try await SupabaseManager.shared.client
                .from("tasks")
                .update(["is_archived": true])
                .eq("id", value: taskId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            #if DEBUG
            print("[TasksSyncEngine] Archived task \(taskId)")
            #endif
        } catch {
            #if DEBUG
            print("[TasksSyncEngine] Delete error: \(error)")
            #endif
        }
    }
    
    // MARK: - Apply Remote to Local
    
    private func applyRemoteToLocal(tasks: [TaskDTO], completions: [TaskCompletionDTO]) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        
        let store = TasksStore.shared
        guard let userId = userId else { return }
        let namespace = userId.uuidString
        
        // ✅ NEW: Merge remote tasks with local, preserving newer local changes
        var mergedTasks: [FFTaskItem] = []
        
        // Start with local tasks
        var localTasksMap: [UUID: FFTaskItem] = Dictionary(uniqueKeysWithValues: store.tasks.map { ($0.id, $0) })
        
        // Process remote tasks
        for dto in tasks {
            let repeatRule = FFTaskRepeatRule(rawValue: dto.repeatRule) ?? .none
            
            let remoteTask = FFTaskItem(
                id: dto.id,
                sortIndex: dto.sortIndex,
                title: dto.title,
                notes: dto.notes,
                reminderDate: dto.reminderDate,
                repeatRule: repeatRule,
                customWeekdays: Set(dto.customWeekdays),
                durationMinutes: dto.durationMinutes,
                convertToPreset: dto.convertToPreset,
                presetCreated: dto.presetCreated,
                excludedDayKeys: Set(dto.excludedDayKeys),
                createdAt: dto.createdAt ?? Date()
            )
            
            // Check if local version is newer
            let fieldKey = "task_\(dto.id.uuidString)"
            let remoteTimestamp = dto.updatedAt ?? dto.createdAt
            
            if let localTask = localTasksMap[dto.id] {
                // Task exists locally - check if local is newer
                if LocalTimestampTracker.shared.isLocalNewer(field: fieldKey, namespace: namespace, remoteTimestamp: remoteTimestamp) {
                    // Local is newer - keep local version
                    mergedTasks.append(localTask)
                    #if DEBUG
                    print("[TasksSyncEngine] Keeping local task '\(localTask.title)' (local is newer)")
                    #endif
                } else {
                    // Remote is newer or same - use remote
                    mergedTasks.append(remoteTask)
                    LocalTimestampTracker.shared.clearLocalTimestamp(field: fieldKey, namespace: namespace)
                    #if DEBUG
                    print("[TasksSyncEngine] Using remote task '\(remoteTask.title)' (remote is newer)")
                    #endif
                }
            } else {
                // New task from remote - add it
                mergedTasks.append(remoteTask)
                #if DEBUG
                print("[TasksSyncEngine] Adding new remote task '\(remoteTask.title)'")
                #endif
            }
            
            // Remove from local map (so we know which local tasks weren't in remote)
            localTasksMap.removeValue(forKey: dto.id)
        }
        
        // Add any local tasks that weren't in remote (if they're newer)
        for (_, localTask) in localTasksMap {
            let fieldKey = "task_\(localTask.id.uuidString)"
            // If local task has a timestamp, it means it was modified locally
            // Keep it even if not in remote (it will be pushed on next sync)
            if LocalTimestampTracker.shared.getLocalTimestamp(field: fieldKey, namespace: namespace) != nil {
                mergedTasks.append(localTask)
                #if DEBUG
                print("[TasksSyncEngine] Keeping local-only task '\(localTask.title)' (will be pushed)")
                #endif
            }
        }
        
        // Build completion keys - merge local and remote completions
        var completionKeys = Set<String>()
        for dto in completions {
            let key = "\(dto.taskId.uuidString)|\(dto.dayKey)"
            completionKeys.insert(key)
        }
        
        // Merge completions: keep local completions that are newer
        let localCompletions = store.completedOccurrenceKeys
        for localKey in localCompletions {
            let parts = localKey.split(separator: "|")
            guard parts.count == 2,
                  let taskId = UUID(uuidString: String(parts[0])) else { continue }
            
            let completionFieldKey = "task_completion_\(taskId.uuidString)"
            // If local completion has a timestamp, keep it
            if LocalTimestampTracker.shared.getLocalTimestamp(field: completionFieldKey, namespace: namespace) != nil {
                completionKeys.insert(localKey)
            }
        }
        
        // Apply merged state
        store.applyRemoteState(tasks: mergedTasks, completionKeys: completionKeys)
        
        #if DEBUG
        print("[TasksSyncEngine] Applied \(mergedTasks.count) tasks, \(completionKeys.count) completions to local (with conflict resolution)")
        #endif
    }
    
    // MARK: - Observe Local Changes
    
    private func observeLocalChanges() {
        let store = TasksStore.shared
        
        // Observe task list changes
        store.$tasks
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced from 1s to 0.5s for faster sync
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                
                // ✅ NEW: Enqueue task changes in sync queue (queue handles pushing)
                Task { @MainActor in
                    guard let userId = AuthManagerV2.shared.state.userId else { return }
                    let namespace = userId.uuidString
                    
                    for task in store.tasks {
                        if let timestamp = LocalTimestampTracker.shared.getLocalTimestamp(
                            field: "task_\(task.id.uuidString)",
                            namespace: namespace
                        ) {
                            SyncQueue.shared.enqueueTaskChange(
                                operation: .update,
                                task: task,
                                localTimestamp: timestamp
                            )
                        }
                    }
                    
                    // Process queue (will push if online)
                    await SyncQueue.shared.processQueue()
                }
            }
            .store(in: &cancellables)
        
        // Observe completion changes
        store.$completedOccurrenceKeys
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced from 1s to 0.5s for faster sync
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                
                // ✅ NEW: Enqueue completion changes in sync queue (queue handles pushing)
                Task { @MainActor in
                    guard let userId = AuthManagerV2.shared.state.userId else { return }
                    let namespace = userId.uuidString
                    
                    // Track completion changes per task
                    var taskIds = Set<UUID>()
                    for key in store.completedOccurrenceKeys {
                        let parts = key.split(separator: "|")
                        if let taskId = UUID(uuidString: String(parts[0])) {
                            taskIds.insert(taskId)
                        }
                    }
                    
                    for taskId in taskIds {
                        if let timestamp = LocalTimestampTracker.shared.getLocalTimestamp(
                            field: "task_completion_\(taskId.uuidString)",
                            namespace: namespace
                        ) {
                            // Enqueue completion change
                            if let task = store.tasks.first(where: { $0.id == taskId }) {
                                SyncQueue.shared.enqueueTaskChange(
                                    operation: .update,
                                    task: task,
                                    localTimestamp: timestamp
                                )
                            }
                        }
                    }
                    
                    // Process queue (will push if online)
                    await SyncQueue.shared.processQueue()
                }
            }
            .store(in: &cancellables)
    }
}
