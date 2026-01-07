# FocusFlow Architecture Documentation

**Comprehensive Technical Architecture & System Design**

---

## 📐 Architecture Overview

FocusFlow uses a **modular, reactive architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│              UI Layer (SwiftUI Views)                   │
│  (FocusView, TasksView, FlowChatView, ProfileView)     │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│         State Management Layer (ObservableObject)       │
│  • FocusTimerViewModel                                  │
│  • TasksStore                                           │
│  • JourneyManager                                       │
│  • FlowChatViewModel                                    │
│  • NotificationPreferencesStore                         │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│        Business Logic Layer (Services & Managers)       │
│  • FocusSessionLogger                                   │
│  • TaskReminderScheduler                                │
│  • ProGatingHelper                                      │
│  • FlowService (AI)                                     │
│  • AppSyncManager (Notification bridge)                │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│        Data Layer (Local + Cloud Infrastructure)        │
│                                                          │
│  LOCAL:                                                 │
│  • UserDefaults (namespaced)                            │
│  • Local timestamp tracking                             │
│                                                          │
│  CLOUD:                                                 │
│  • Supabase Client                                      │
│  • Auth Manager                                         │
│  • Sync Coordinator + 4 Engines                         │
│  • Sync Queue (offline-safe)                            │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│         Backend Services (Supabase + OpenAI)           │
│  • PostgreSQL Database                                  │
│  • Edge Function (GPT-4o)                              │
│  • Auth (OAuth2 + Email)                               │
│  • Storage (future for attachments)                    │
└─────────────────────────────────────────────────────────┘
```

---

## 🔌 Design Patterns Used

### **1. Reactive Pattern (Combine + @Published)**
Every observable object uses Combine publishers to broadcast state changes:

```swift
@MainActor
final class TasksStore: ObservableObject {
    @Published private(set) var tasks: [FFTaskItem] = []
    @Published private(set) var completedOccurrenceKeys: Set<String> = []
    
    // Views subscribe to these publishers
}
```

**Benefits**:
- ✅ Automatic UI updates
- ✅ No manual setState calls
- ✅ Testable state transitions
- ✅ Efficient diffing

---

### **2. Singleton Pattern (Shared Instances)**
Critical services are singletons to ensure single source of truth:

```swift
final class AuthManagerV2: ObservableObject {
    static let shared = AuthManagerV2()
    private init() { /* initialize */ }
}
```

**Used by**:
- `AuthManagerV2` - Auth state machine
- `SyncCoordinator` - Sync orchestration
- `TasksStore` - Task data
- `JourneyManager` - Analytics
- `FlowService` - AI communication
- `ProEntitlementManager` - Pro status

---

### **3. Observer Pattern (Combine Subscriptions)**
Components observe state changes via subscriptions:

```swift
AuthManagerV2.shared.$state
    .receive(on: DispatchQueue.main)
    .sink { [weak self] state in
        self?.applyAuthState(state)
    }
    .store(in: &cancellables)
```

**Used for**:
- Auth state changes → trigger sync
- Sync completion → update UI
- Focus session end → update journey
- Pro status changes → update paywalls

---

### **4. Namespace Pattern (Data Isolation)**
All local data is namespaced to prevent conflicts:

```swift
Keys.guest                              // Guest mode
Keys.cloud(userId: UUID)               // Signed-in user
```

**Benefits**:
- ✅ Switch between accounts seamlessly
- ✅ Guest → Pro migration without overwriting
- ✅ Clear data separation
- ✅ Multi-user device support

---

### **5. Dependency Injection (Explicit Parameters)**
Services receive dependencies rather than creating them:

```swift
// Bad: Hard to test
class TasksView: View {
    let store = TasksStore.shared
}

// Good: Testable
class TasksView: View {
    let store: TasksStore
    init(store: TasksStore = .shared) { }
}
```

---

## 🏢 Core Components Explained

### **AuthManagerV2: Authentication State Machine**

**Responsibility**: Manage auth state and user session

**State Enum**:
```swift
enum CloudAuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(userId: UUID, email: String)
    case error(String)
}
```

**Key Methods**:
- `signUp(email:password:)` - Create account
- `signIn(email:password:)` - Sign in
- `signOut()` - Sign out
- `restoreSession()` - Resume session from token
- `deleteAccount()` - Permanently delete user

**Triggers**:
- App launch → `restoreSession()`
- Sign-in button → `signIn()`
- Sign-out button → `signOut()`
- Auth changes → broadcast via `$state`

---

### **SyncCoordinator: Sync Orchestration**

**Responsibility**: Start/stop sync engines based on auth and Pro status

**Engines Managed**:
```swift
private let settingsEngine = SettingsSyncEngine()
private let tasksEngine = TasksSyncEngine()
private let sessionsEngine = SessionsSyncEngine()
private let presetsEngine = PresetsSyncEngine()
```

**State Machine**:
```
[Unauthenticated]
       ↓
[Authenticating] → Start initial pull
       ↓
[Authenticated + NonPro] → One-time pull only
       ↓
[Authenticated + Pro] → Start all engines + periodic sync
```

**Key Methods**:
- `startAllEngines(userId:)` - Start Pro sync
- `performInitialPullOnly(userId:)` - Free user one-time pull
- `stopAllEngines()` - Stop on sign-out
- `forceSyncNow()` - Manual sync trigger

**Published State**:
- `@Published var isSyncing: Bool`
- `@Published var lastSyncDate: Date?`
- `@Published var syncError: Error?`

---

### **TasksStore: Task Data Management**

**Responsibility**: Centralized task state with local + cloud persistence

**Published Data**:
```swift
@Published private(set) var tasks: [FFTaskItem] = []
@Published private(set) var completedOccurrenceKeys: Set<String> = []
```

**Key Methods**:
- `tasksVisible(on:)` - Get tasks for a specific day
- `isCompleted(taskId:on:)` - Check if task completed on day
- `orderedTasks()` - Get sorted task list
- `addTask(_:)` - Create task
- `updateTask(_:)` - Update task
- `deleteTask(id:)` - Delete task
- `toggleTask(id:on:)` - Mark completed/incomplete

**Persistence**:
- Saves to UserDefaults on every change
- Uses namespace (guest vs cloud_{userId})
- Observes AuthManager for namespace switches

**Syncing**:
- Publishes changes to AppSyncManager
- SyncQueue picks up and pushes to cloud
- Cloud changes pulled and applied locally

---

### **FocusTimerViewModel: Session Management**

**Responsibility**: Manage focus session state with persistence

**State**:
```swift
enum Phase: Equatable {
    case idle
    case running
    case paused
    case completed
}
```

**Key Properties**:
```swift
@Published var totalSeconds: Int
@Published var remainingSeconds: Int
@Published var phase: Phase
@Published var sessionName: String
```

**Persistence**: Survives app close/lock via UserDefaults
```swift
private enum PersistKey {
    static let isActive = "FocusFlow.focusSession.isActive"
    static let plannedSeconds = "FocusFlow.focusSession.plannedSeconds"
    static let startDate = "FocusFlow.focusSession.startDate"
    static let pausedRemaining = "FocusFlow.focusSession.pausedRemaining"
}
```

**Key Methods**:
- `start(seconds:preset:)` - Start timer
- `pause()` - Pause (don't lose progress)
- `resume()` - Resume from pause
- `stop()` - End session manually
- `logSession()` - Save to FocusSession + Journey

---

### **JourneyManager: Analytics & Progress**

**Responsibility**: Track progress metrics and generate insights

**Tracks**:
- Daily focus time (sum of session durations)
- Session count
- Task completion rate
- Streaks (consecutive days with activity)
- XP earned (minutes × 1 XP/minute)
- Levels (0-50, unlocked progressively)
- Achievements/badges

**Key Methods**:
- `getDailySummary(for:)` - Summary for specific day
- `getWeeklySummary()` - Last 7 days
- `getMonthlyTrends()` - Patterns & insights
- `addSession(_:)` - Log focus session
- `calculateXP()` - Update XP/levels
- `updateStreaks()` - Check streak logic

**Published**:
```swift
@Published var currentStreak: Int
@Published var currentLevel: Int
@Published var totalXP: Int
@Published var dailySummaries: [Date: DailySummary]
```

---

### **FlowService: AI Communication**

**Responsibility**: Communicate with GPT-4o via Supabase Edge Function

**Flow**:
```
User message
    ↓
Build context (tasks, history, settings)
    ↓
Call Supabase edge function (/flow)
    ↓
OpenAI processes message
    ↓
Execute any actions (create tasks, etc)
    ↓
Return response + metadata
    ↓
Update FlowChatViewModel
    ↓
Display in UI
```

**Key Methods**:
- `sendMessage(userMessage:conversationHistory:context:)` - Non-streaming
- `sendStreamingMessage(...)` - Streaming response
- `executeAction(_:)` - Perform AI action
- `buildContext()` - Smart context building

**Token Management**:
- Max 2000 tokens per message
- Conversation history included
- Lazy-loads context (only needed fields)

---

### **ProGatingHelper: Subscription Gating**

**Responsibility**: Check Pro status and gate features

**Key Constants**:
```swift
static let freeTaskLimit = 3
static let freeReminderLimit = 1
static let freeHistoryDays = 3
static let freePresetLimit = 3

static let freeThemes = [.forest, .neon]
static let freeSounds = [.lightRain, .fireplace, .soundAmbience]
static let freeAmbianceModes = [.minimal, .stars, .forest]
```

**Key Methods**:
```swift
shared.isPro                           // Check Pro status
shared.canAddTask(count: 2)           // Check if can add task
shared.canAddPreset(count: 3)         // Check if can add preset
shared.isThemeLocked(.ocean)          // Check theme access
shared.isSoundLocked(.whitenoise)     // Check sound access
shared.canAccessXPLevels              // Check XP access
shared.canUseLiveActivity             // Check widget access
```

**Paywall Triggers**:
- Locked feature access → Show paywall with context
- Premium content tap → Show relevant paywall
- Limit exceeded → Show context-aware paywall

---

## 🔄 Sync Architecture Deep Dive

### **Sync Engines: 4-Way Synchronization**

Each engine handles one data type with conflict resolution:

#### **TasksSyncEngine**
- **Table**: `tasks` + `task_completions`
- **Pull**: Download all user tasks from cloud
- **Push**: Upload local task changes
- **Conflict**: Timestamp-based (updated_at)
- **Frequency**: Every 30 seconds + on-demand

#### **SessionsSyncEngine**
- **Table**: `focus_sessions`
- **Pull**: Download session history
- **Push**: Upload newly completed sessions
- **Conflict**: Timestamp-based
- **Frequency**: Every 30 seconds + on-demand

#### **PresetsSyncEngine**
- **Table**: `focus_presets`
- **Pull**: Download custom presets
- **Push**: Upload new/modified presets
- **Conflict**: Timestamp-based
- **Frequency**: Every 30 seconds + on-demand

#### **SettingsSyncEngine**
- **Table**: `user_settings`
- **Pull**: Download user preferences, goals
- **Push**: Upload setting changes
- **Conflict**: Timestamp-based
- **Frequency**: Every 30 seconds + on-demand

### **SyncQueue: Offline-Safe Persistence**

Ensures no changes are lost when offline:

**Queue Structure**:
```swift
struct SyncOperation: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: SyncType              // tasks, sessions, presets, settings
    let operation: SyncOperationType // create, update, delete
    let payload: Data               // JSON-encoded data
    let status: SyncStatus          // pending, processing, success, failed
    let retryCount: Int
}
```

**Workflow**:
```
Local change detected
    ↓
Queue PUSH operation
    ↓
Save queue to UserDefaults
    ↓
When online: Process queue
    ↓
Send to Supabase
    ↓
Mark as success
    ↓
Remove from queue
```

**Retry Logic**:
- Exponential backoff (1s, 2s, 4s, 8s...)
- Max 5 retries per operation
- Manual retry button if failed

---

### **Conflict Resolution Strategy**

**When Conflicts Occur**:
1. During initial pull after sign-in
2. During periodic sync (every 30s)
3. When resubscribing (>7 days offline)

**Resolution Logic**:
```
If local.updated_at > cloud.updated_at
    → Keep local (user's newest version)
Else
    → Keep cloud (server's newest version)
```

**Example**:
```
Local task: "Write report" (updated_at: 2:00 PM)
Cloud task: "Write report" (updated_at: 1:00 PM)
Result: Keep local version (newer)

Local task: "Buy milk" (updated_at: 1:00 PM)
Cloud task: "Buy milk" (updated_at: 3:00 PM)
Result: Keep cloud version (newer)
```

---

### **Multi-Device Sync Example**

```
User A (iPhone):
  1:00 PM - Create "Write proposal"
  1:01 PM - SyncQueue pushes to cloud
  
User A (iPad):
  1:02 PM - SessionsSyncEngine pulls
  1:02 PM - Task appears on iPad
  
User A (iPhone):
  2:00 PM - Completes "Write proposal"
  2:01 PM - SessionsSyncEngine pushes completion
  
User A (iPad):
  2:02 PM - SessionsSyncEngine pulls
  2:02 PM - Task shows completed on iPad
  
Result: Real-time sync across devices ✅
```

---

## 🤖 AI Architecture (Flow)

### **Flow System Components**

```
┌────────────────────────────────┐
│   FlowChatView (UI)            │
│  ├─ Message input              │
│  ├─ Response display           │
│  └─ Voice input                │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│  FlowChatViewModel             │
│  ├─ Conversation history       │
│  ├─ Message processing         │
│  ├─ Action handling            │
│  └─ Voice transcription        │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│  FlowService                   │
│  ├─ API communication          │
│  ├─ Streaming handler          │
│  ├─ Token management           │
│  └─ Error handling             │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│  Supabase Edge Function (/flow)│
│  ├─ Auth verification          │
│  ├─ Context building           │
│  ├─ OpenAI API calls           │
│  ├─ Function calling           │
│  └─ Action execution           │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│  OpenAI GPT-4o                 │
│  ├─ Message understanding      │
│  ├─ Action planning            │
│  └─ Response generation        │
└────────────────────────────────┘
```

### **Available Actions**

Flow can execute these actions via function calling:

| Action | Purpose | Example |
|--------|---------|---------|
| `createTask` | Create new task | "Create task 'Buy milk'" |
| `updateTask` | Modify existing task | "Mark done" or "Change to 30 min" |
| `deleteTask` | Remove task | "Delete completed tasks" |
| `createPreset` | Create custom preset | "Create 60-min deep work preset" |
| `startSession` | Begin focus session | "Start 25-min session" |
| `showStats` | Display analytics | "Show my week" |
| `updateSetting` | Change preference | "Use Neon theme" |

### **Context Building**

Smart context is built to provide relevant information without overwhelming GPT-4o:

```
Context includes:
├─ Current date/time
├─ Active tasks (limited)
├─ Recent sessions (last 7 days)
├─ Current streaks
├─ Pro status
├─ User preferences
├─ Conversation history (last 5 exchanges)
└─ Available presets
```

Lazy-loading prevents unnecessary data:
- Only include task titles (not descriptions)
- Recent history only (not all-time)
- Summary stats (not raw data)
- Non-sensitive info only

---

### **Proactive System (Hints & Nudges)**

**FlowHintSystem** provides context-aware suggestions:

```swift
enum HintContext: String {
    case onboarding      // First-time setup
    case taskCreation    // When creating tasks
    case focusSession    // During/after sessions
    case achievements    // Milestone reaches
    case dailyRoutine    // Morning/evening
    case productivity    // Low activity detected
}

enum HintPriority: Int {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
}
```

**Example Hints**:
```
Context: User launched app
Priority: Normal
Hint: "Ready to focus? You're most productive mornings!"
Action: [Start Session] [Show Tasks]

Context: User completed 3 sessions
Priority: High
Hint: "🔥 You've crushed it today! 2-hour streak!"
Action: [View Stats] [Share]

Context: User hasn't opened app in 2 days
Priority: Critical
Hint: "We miss you! Pick up where you left off 👋"
Action: [Show Tasks] [Dismiss]
```

---

## 🛢️ Data Layer Architecture

### **Local Storage: UserDefaults**

**Namespacing Strategy**:
```
Guest Mode:
  - focusflow_tasks_state_guest
  - focusflow_presets_state_guest
  - focusflow_sessions_state_guest
  - focusflow_settings_guest
  - focusflow_goal_history_guest

Signed-in User:
  - focusflow_tasks_state_cloud_{userId}
  - focusflow_presets_state_cloud_{userId}
  - focusflow_sessions_state_cloud_{userId}
  - focusflow_settings_cloud_{userId}
  - focusflow_goal_history_cloud_{userId}
  - focusflow_sync_queue (shared across users)
```

**Advantages**:
- ✅ Instant access (no network latency)
- ✅ Works offline
- ✅ Easy namespace switching
- ✅ Persistent across app launches

**Disadvantages**:
- ❌ Limited to ~10MB
- ❌ Not encrypted by default
- ❌ Not suitable for large media

---

### **Cloud Storage: Supabase PostgreSQL**

**Table Structure**:

#### **users**
```sql
id (UUID, Primary Key)
email (String)
is_pro (Boolean) -- mirrors StoreKit subscription
created_at (Timestamp)
updated_at (Timestamp)
```

#### **tasks**
```sql
id (UUID, Primary Key)
user_id (UUID, Foreign Key)
title (String)
description (String, nullable)
due_date (Date, nullable)
reminder_date (Date, nullable)
is_completed (Boolean)
repeat_rule (String: "none", "daily", "weekly", "monthly")
sort_index (Int)
created_at (Timestamp)
updated_at (Timestamp) -- for conflict resolution
```

#### **task_completions**
```sql
id (UUID, Primary Key)
user_id (UUID, Foreign Key)
task_id (UUID, Foreign Key)
completion_date (Date)
created_at (Timestamp)
-- Used to track which days task was completed
```

#### **focus_sessions**
```sql
id (UUID, Primary Key)
user_id (UUID, Foreign Key)
duration_seconds (Int)
start_time (Timestamp)
end_time (Timestamp)
preset_id (UUID, Foreign Key, nullable)
sound_used (String, nullable)
ambient_mode (String, nullable)
was_completed (Boolean) -- vs manual end
completed_early (Boolean)
created_at (Timestamp)
updated_at (Timestamp)
```

#### **focus_presets**
```sql
id (UUID, Primary Key)
user_id (UUID, Foreign Key)
name (String)
duration_seconds (Int)
sound (String)
ambient_mode (String)
is_default (Boolean)
created_at (Timestamp)
updated_at (Timestamp)
```

#### **user_settings**
```sql
id (UUID, Primary Key)
user_id (UUID, Foreign Key)
theme (String: "forest", "neon", "ocean", ...)
daily_goal_minutes (Int)
notification_enabled (Boolean)
notification_style (String)
reminder_times (JSON array)
current_streak (Int)
current_level (Int)
total_xp (Int)
created_at (Timestamp)
updated_at (Timestamp)
```

---

### **Row-Level Security (RLS)**

All tables have RLS enabled:

```sql
-- Users can only see their own tasks
CREATE POLICY "Users can view own tasks"
  ON tasks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can modify own tasks"
  ON tasks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks"
  ON tasks FOR DELETE USING (auth.uid() = user_id);
```

**Benefits**:
- ✅ Impossible to access other user's data
- ✅ Enforced at database level
- ✅ No dependency on client-side checks

---

## 🎯 Performance Optimizations

### **1. Lazy Loading**
- Conversation history truncated (not all-time)
- Task lists paginated (not all at once)
- Image assets loaded on-demand
- Analytics computed at summary level

### **2. Caching**
- Recent tasks cached locally
- Sync results cached for 30s
- Theme assets pre-loaded
- User preferences cached in memory

### **3. Background Processing**
- Sync runs in background (even after app close)
- Notifications scheduled async
- Analytics computed off main thread
- Voice transcription async

### **4. Memory Management**
- Weak references for delegation
- Cancellables cleaned up on deinit
- Task lists limited to visible range
- Images resized before display

---

## 🧪 Testing Strategy

### **Unit Tests**
- Test state transitions (auth, sync)
- Test business logic (XP calc, conflict resolution)
- Test data persistence
- Test error handling

### **Integration Tests**
- Test sync workflows
- Test task CRUD with sync
- Test AI action execution
- Test auth flows

### **UI Tests**
- Test user workflows
- Test accessibility
- Test responsive design
- Test gesture handling

### **Performance Tests**
- Sync throughput
- Memory usage
- Battery consumption
- Load times

---

## 🔒 Security Checklist

- ✅ All API calls use HTTPS
- ✅ Auth tokens stored in Keychain
- ✅ RLS enforced on all tables
- ✅ No sensitive data in logs
- ✅ User data isolated by user_id
- ✅ GDPR-compliant deletion
- ✅ Rate limiting on API
- ✅ Input validation on API

---

**Last Updated**: January 7, 2026  
**Version**: 2.0+
