# 📱 FocusFlow iOS App Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [App Entry Point](#app-entry-point)
4. [Core Systems](#core-systems)
5. [Feature Modules](#feature-modules)
6. [Design System](#design-system)
7. [Infrastructure](#infrastructure)
8. [Data Models](#data-models)
9. [Navigation Flow](#navigation-flow)
10. [State Management](#state-management)

---

## Overview

The FocusFlow iOS app is a 100% SwiftUI application targeting iOS 17.0+, built with modern Swift concurrency and Combine for reactive programming. The app follows a modular architecture with clear separation of concerns.

### Key Characteristics

- **100% SwiftUI** - No UIKit storyboards
- **Swift Concurrency** - async/await throughout
- **MVVM Architecture** - ViewModels for business logic
- **Singleton Stores** - Shared state managers
- **Namespace Isolation** - User data separated by auth state
- **Widget Integration** - Deep App Group integration

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          APP ARCHITECTURE                                 │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                       PRESENTATION LAYER                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐  │   │
│  │  │  FocusView  │ │  TasksView  │ │ FlowChatView│ │ProfileView │  │   │
│  │  └─────┬───────┘ └─────┬───────┘ └─────┬───────┘ └─────┬──────┘  │   │
│  │        │               │               │               │          │   │
│  │  ┌─────┴───────────────┴───────────────┴───────────────┴──────┐  │   │
│  │  │                   VIEW MODELS                               │  │   │
│  │  │ FocusTimerViewModel │ FlowChatViewModel │ etc.              │  │   │
│  │  └────────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│  ┌──────────────────────────────────┴────────────────────────────────┐  │
│  │                        DOMAIN LAYER                               │  │
│  │  ┌────────────────────────────────────────────────────────────┐   │  │
│  │  │                    SINGLETON STORES                        │   │  │
│  │  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌─────────┐  │   │  │
│  │  │  │ProgressStore│ │ TasksStore │ │PresetStore │ │AppSettings│ │   │  │
│  │  │  └────────────┘ └────────────┘ └────────────┘ └─────────┘  │   │  │
│  │  └────────────────────────────────────────────────────────────┘   │  │
│  │                                                                   │  │
│  │  ┌────────────────────────────────────────────────────────────┐   │  │
│  │  │                    MANAGERS                                │   │  │
│  │  │  AppSyncManager │ NotificationCenterManager │ JourneyManager│  │  │
│  │  └────────────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                    │                                     │
│  ┌──────────────────────────────────┴────────────────────────────────┐  │
│  │                     INFRASTRUCTURE LAYER                          │  │
│  │  ┌────────────────┐ ┌────────────────┐ ┌────────────────────────┐ │  │
│  │  │SupabaseManager │ │  AuthManagerV2 │ │   SyncCoordinator      │ │  │
│  │  └────────────────┘ └────────────────┘ └────────────────────────┘ │  │
│  │  ┌────────────────┐ ┌────────────────┐ ┌────────────────────────┐ │  │
│  │  │  SyncEngines   │ │   SyncQueue    │ │ ProEntitlementManager  │ │  │
│  │  └────────────────┘ └────────────────┘ └────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## App Entry Point

### FocusFlowApp.swift

The main app entry point initializes all critical singletons and sets up the app lifecycle.

```swift
@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var pro = ProEntitlementManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared

    init() {
        // V2 Cloud Infrastructure
        _ = SupabaseManager.shared        // Supabase client
        _ = AuthManagerV2.shared          // Auth state observer
        _ = SyncCoordinator.shared        // Sync orchestration
        _ = SyncQueue.shared              // Offline queue
        
        // Local Managers
        _ = AppSyncManager.shared         // Cross-view sync
        _ = JourneyManager.shared         // Gamification
        _ = TaskReminderScheduler.shared  // Task reminders
        
        // Data Stores
        _ = ProgressStore.shared
        _ = TasksStore.shared
        _ = FocusPresetStore.shared
    }
}
```

### RootView Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                      RootView                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   hasCompletedOnboarding?                                   │
│         │                                                   │
│         ├── NO ──► OnboardingView (5 pages)                │
│         │              │                                    │
│         │              └── After completion ──► ContentView │
│         │                                                   │
│         └── YES ──► ContentView                            │
│                          │                                  │
│                          └── AuthState Switch:             │
│                                 │                           │
│                                 ├── .unknown ──► Loading    │
│                                 ├── .signedOut ──► AuthLandingView │
│                                 └── .guest/.signedIn ──► MainTabs  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Main Tab Structure

```swift
enum AppTab: Int, Hashable {
    case focus = 0      // Timer tab
    case tasks = 1      // Task management
    case flow = 2       // AI assistant
    case progress = 3   // Statistics
    case profile = 4    // Settings & profile
}
```

---

## Core Systems

### 1. AppSettings

Central configuration manager handling user preferences with namespace isolation.

**Location:** `FocusFlow/Core/AppSettings/AppSettings.swift`

```swift
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Theme
    @Published var profileTheme: AppTheme
    @Published var selectedTheme: AppTheme
    
    // Sound
    @Published var soundEnabled: Bool
    @Published var selectedFocusSound: FocusSound?
    @Published var hapticsEnabled: Bool
    
    // Music Integration
    @Published var selectedExternalMusicApp: ExternalMusicApp?
    
    // Profile
    @Published var displayName: String
    @Published var tagline: String
    @Published var avatarID: String
    
    // Notifications
    @Published var dailyReminderEnabled: Bool
    @Published var dailyReminderTime: Date
}
```

### 2. AppSyncManager

Cross-view synchronization manager that broadcasts events app-wide.

**Location:** `FocusFlow/App/AppSyncManager.swift`

```swift
final class AppSyncManager: ObservableObject {
    static let shared = AppSyncManager()
    
    // Notification Names
    static let sessionCompleted = Notification.Name("AppSync.sessionCompleted")
    static let taskCompleted = Notification.Name("AppSync.taskCompleted")
    static let streakUpdated = Notification.Name("AppSync.streakUpdated")
    static let xpUpdated = Notification.Name("AppSync.xpUpdated")
    static let badgeUnlocked = Notification.Name("AppSync.badgeUnlocked")
    static let levelUp = Notification.Name("AppSync.levelUp")
    static let themeChanged = Notification.Name("AppSync.themeChanged")
    
    // Methods
    func sessionDidComplete(duration: TimeInterval, sessionName: String)
    func taskDidComplete(taskId: UUID, taskTitle: String, on date: Date)
    func themeDidChange(to theme: AppTheme)
    func forceRefresh()
}
```

### 3. Theme System

10 premium themes with complete color definitions.

```swift
enum AppTheme: String, CaseIterable {
    case forest, neon, peach, cyber      // Core themes
    case ocean, sunrise, amber, mint     // Extended themes
    case royal, slate                    // Premium themes
    
    var accentPrimary: Color { ... }
    var accentSecondary: Color { ... }
    var backgroundColors: [Color] { ... }
    var displayName: String { ... }
}
```

**Theme Color Palette:**

| Theme | Primary | Secondary | Background |
|-------|---------|-----------|------------|
| Forest | Mint Green | Sage | Dark Green |
| Neon | Cyan | Purple | Deep Blue |
| Peach | Coral | Cream | Warm Brown |
| Cyber | Purple | Blue | Dark Violet |
| Ocean | Sky Blue | Teal | Navy |
| Sunrise | Coral | Gold | Plum |
| Amber | Gold | Orange | Brown |
| Mint | Mint | Aqua | Teal |
| Royal | Lavender | Blue | Indigo |
| Slate | Silver | Gray | Charcoal |

---

## Feature Modules

### 1. Focus Module 🎯

**Location:** `FocusFlow/Features/Focus/`

The core focus timer feature with ambient backgrounds, sounds, and Live Activity support.

```
Focus/
├── FocusView.swift              # Main timer UI (1971 lines)
├── FocusTimerViewModel.swift    # Timer logic & state
├── FocusSoundManager.swift      # Audio playback
├── FocusSound.swift             # Sound definitions
├── FocusSoundPicker.swift       # Sound selection UI
├── AmbientBackgrounds.swift     # Animated backgrounds
├── FocusInfoSheet.swift         # Timer info overlay
├── FocusLocalNotificationManager.swift  # Session alerts
└── ExternalMusicLauncher.swift  # Spotify/Apple Music
```

**Timer States:**
```swift
enum Phase: Equatable {
    case idle       // Ready to start
    case running    // Active countdown
    case paused     // Temporarily stopped
    case completed  // Session finished
}
```

**Timer Features:**
- Customizable duration (1 min - 4 hours)
- Session name/intention setting
- Ambient background animations
- Focus sounds (Rain, Ocean, Fire, etc.)
- Live Activity with Dynamic Island
- Early end detection (40% rule)
- Session persistence across app kills
- Widget state synchronization

### 2. Tasks Module ✅

**Location:** `FocusFlow/Features/Tasks/`

Full-featured task management with reminders and recurring tasks.

```
Tasks/
├── TasksView.swift              # Task list UI
├── TasksStore.swift             # Task data store
├── TaskModels.swift             # Task data structures
├── TaskReminderScheduler.swift  # Notification scheduling
└── TasksInfoSheet.swift         # Task help overlay
```

**Task Model:**
```swift
struct FFTaskItem: Identifiable, Codable {
    let id: UUID
    var sortIndex: Int
    var title: String
    var notes: String?
    var reminderDate: Date?
    var repeatRule: FFTaskRepeatRule
    var customWeekdays: Set<Int>
    var durationMinutes: Int
    var convertToPreset: Bool
    var excludedDayKeys: Set<String>
    var createdAt: Date
}

enum FFTaskRepeatRule: String, CaseIterable {
    case none, daily, weekly, monthly, yearly, customDays
}
```

**Task Features:**
- Create, edit, delete tasks
- Due date reminders
- Recurring tasks (daily, weekly, monthly, yearly, custom)
- Manual reordering
- Task-to-preset conversion
- Calendar day view
- Completion tracking
- XP rewards for completions

### 3. Flow AI Module 🤖

**Location:** `FocusFlow/Features/AI/`

ChatGPT-powered AI assistant for productivity coaching.

```
AI/
├── Core/
│   ├── FlowConfig.swift         # API configuration
│   ├── FlowContext.swift        # Context builder
│   ├── FlowMemory.swift         # Conversation memory
│   ├── FlowMessage.swift        # Message models
│   ├── FlowNavigationCoordinator.swift  # Navigation actions
│   └── FlowPerformance.swift    # Performance monitoring
├── Service/
│   └── FlowService.swift        # API communication
├── UI/
│   ├── FlowChatView.swift       # Chat interface
│   ├── FlowChatViewModel.swift  # Chat logic
│   ├── FlowResponseCards.swift  # Rich response UI
│   ├── FlowAnimations.swift     # Chat animations
│   └── FlowSpotlight.swift      # Feature discovery
├── Actions/
│   ├── FlowAction.swift         # Action definitions
│   └── FlowActionHandler.swift  # Action execution
├── Proactive/
│   ├── FlowProactiveEngine.swift    # Proactive suggestions
│   └── FlowHintSystem.swift         # Contextual hints
└── Voice/
    └── FlowVoiceInput.swift     # Voice transcription
```

**Flow AI Capabilities:**
```swift
// Available Tool Functions
create_task(title, reminderDate?, repeatRule?)
complete_task(taskId, date?)
delete_task(taskId)
list_tasks(timeRange?)
start_focus(minutes, sessionName?, presetId?)
pause_focus()
resume_focus()
end_focus()
get_progress()
create_preset(name, duration, sound?, theme?)
set_daily_goal(minutes)
```

**Context Building:**
The AI receives rich context including:
- User profile (name, theme, settings)
- Today's progress (focus time, goal %)
- Active tasks (today, upcoming, overdue)
- Focus presets available
- Recent sessions
- Conversation memory
- Time of day awareness

### 4. Progress Module 📊

**Location:** `FocusFlow/Features/Progress/`

Statistics, streaks, and gamification tracking.

```
Progress/
├── ProgressViewV2.swift         # Stats dashboard
└── ProgressStore.swift          # Progress data store
```

**Progress Data:**
```swift
struct ProgressSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let sessionName: String?
}
```

**Tracked Metrics:**
- Today's focus time
- Daily goal progress
- Current streak
- Lifetime focus hours
- Total session count
- Best streak ever
- Weekly/monthly trends

### 5. Presets Module 📝

**Location:** `FocusFlow/Features/Presets/`

Customizable focus session presets.

```
Presets/
├── FocusPreset.swift            # Preset model
├── FocusPresetStore.swift       # Preset data store
├── FocusPresetManagerView.swift # Preset list UI
└── FocusPresetEditorView.swift  # Preset editor UI
```

**Preset Model:**
```swift
struct FocusPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationSeconds: Int
    var soundID: String
    var emoji: String?
    var isSystemDefault: Bool
    var themeRaw: String?
    var externalMusicAppRaw: String?
    var ambianceModeRaw: String?
}
```

**Default Presets:**
| Name | Duration | Emoji |
|------|----------|-------|
| Deep Work | 50 min | 🧠 |
| Quick Focus | 25 min | ⚡ |
| Study Session | 45 min | 📚 |

### 6. Account Module 👤

**Location:** `FocusFlow/Features/Account/`

Authentication, profile, and settings.

```
Account/
├── Auth/
│   ├── AuthLandingView.swift        # Login/signup screen
│   ├── EmailAuthView.swift          # Email auth flow
│   ├── EmailVerifiedView.swift      # Verification success
│   ├── SetNewPasswordView.swift     # Password reset
│   ├── PasswordRecoveryManager.swift # Recovery flow
│   └── DataMigrationSheet.swift     # Guest data migration
├── Profile/
│   └── ProfileView.swift            # Profile tab
└── Settings/
    ├── SettingsView.swift           # App settings
    └── NotificationSettingsView.swift # Notification prefs
```

**Auth States:**
```swift
enum CloudAuthState: Equatable {
    case unknown      // Loading initial state
    case guest        // Local-only mode
    case signedIn(userId: UUID)  // Authenticated
    case signedOut    // Logged out
}
```

### 7. Journey Module 🎮

**Location:** `FocusFlow/Features/Journey/`

Gamification and milestone tracking.

```
Journey/
├── JourneyManager.swift         # Badge/level logic
└── JourneyView.swift            # Journey dashboard
```

**Gamification System:**
- **XP System:** Earn XP for focus sessions and task completions
- **Levels:** Progress through titles (Beginner → Master)
- **Badges:** Unlock achievements
- **Streaks:** Consecutive day tracking
- **Milestones:** Celebrate significant accomplishments

### 8. Onboarding Module 🚀

**Location:** `FocusFlow/Features/Onboarding/`

First-time user experience.

```
Onboarding/
├── OnboardingView.swift             # Container
├── OnboardingManager.swift          # State management
├── OnboardingIntroPage.swift        # Welcome
├── OnboardingTourPage.swift         # Feature tour
├── OnboardingQuickPrefsPage.swift   # Quick settings
├── OnboardingNotificationsPage.swift # Permission request
└── OnboardingFinishPage.swift       # Completion + auth
```

**Onboarding Flow:**
```
Page 1: Welcome Introduction
    │
Page 2: Feature Tour (Focus, Tasks, Progress)
    │
Page 3: Quick Preferences (Goal, Theme)
    │
Page 4: Notification Permission
    │
Page 5: Finish + Sign In/Guest Choice
```

### 9. NotificationsCenter Module 🔔

**Location:** `FocusFlow/Features/NotificationsCenter/`

In-app notification system.

```
NotificationsCenter/
├── FocusNotification.swift          # Notification model
├── NotificationCenterManager.swift  # Notification logic
├── NotificationCenterView.swift     # Notification list UI
└── LegacyNotificationCleanup.swift  # Migration helpers
```

---

## Design System

**Location:** `FocusFlow/DesignSystem/`

```
DesignSystem/
├── Theme/
│   └── FFDesignSystem.swift     # Design tokens
├── Components/
│   ├── Buttons/                 # Button components
│   ├── Cards/                   # Card components
│   ├── Forms/                   # Input components
│   ├── Feedback/                # Alerts, toasts
│   ├── Navigation/              # Nav components
│   └── LiquidGlass/             # Glass effect components
└── Utilities/
    └── Modifiers/               # View modifiers
```

### Design Tokens

```swift
enum FFDesignSystem {
    // Spacing Scale (4pt base)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // Corner Radius
    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    
    // Typography
    enum Font {
        static let caption: CGFloat = 11
        static let body: CGFloat = 15
        static let headline: CGFloat = 18
        static let title: CGFloat = 24
        static let display: CGFloat = 44
    }
    
    // Glass Effects
    enum Glass {
        static let thin: Double = 0.05
        static let regular: Double = 0.08
        static let thick: Double = 0.12
    }
    
    // Animations
    enum Animation {
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.9)
        static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}
```

---

## Infrastructure

### 1. SupabaseManager

**Location:** `FocusFlow/Infrastructure/Cloud/SupabaseManager.swift`

Single source of truth for Supabase client.

```swift
@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    static let redirectScheme = "ca.softcomputers.FocusFlow"
    static let redirectURL = URL(string: "\(redirectScheme)://login-callback")!
    
    var auth: AuthClient { client.auth }
    var currentUserId: UUID? { client.auth.currentUser?.id }
    var isAuthenticated: Bool { client.auth.currentUser != nil }
    
    func currentUserToken(forceRefresh: Bool = false) async throws -> String
    func handleDeepLink(_ url: URL) async -> Bool
}
```

### 2. AuthManagerV2

**Location:** `FocusFlow/Infrastructure/Cloud/AuthManagerV2.swift`

Authentication state management.

```swift
@MainActor
final class AuthManagerV2: ObservableObject {
    static let shared = AuthManagerV2()
    
    @Published private(set) var state: CloudAuthState = .unknown
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // Auth Methods
    func signInWithEmail(email: String, password: String) async throws
    func signUpWithEmail(email: String, password: String) async throws
    func signInWithGoogle() async throws
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async
    func resetPassword(email: String) async throws
    func updatePassword(newPassword: String) async throws
    func deleteAccount() async throws
    func continueAsGuest()
}
```

### 3. SyncCoordinator

**Location:** `FocusFlow/Infrastructure/Cloud/SyncCoordinator.swift`

Orchestrates data sync across devices.

```swift
@MainActor
final class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator()
    
    // Sync Engines
    private let settingsEngine = SettingsSyncEngine()
    private let tasksEngine = TasksSyncEngine()
    private let sessionsEngine = SessionsSyncEngine()
    private let presetsEngine = PresetsSyncEngine()
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    
    // Pro required for sync
    func startSyncWithMergeIfNeeded(userId: UUID) async
    func pullFromRemote() async
    func forcePushAllPending() async
}
```

### 4. ProEntitlementManager

**Location:** `FocusFlow/StoreKit/ProEntitlementManager.swift`

StoreKit 2 subscription management.

```swift
@MainActor
final class ProEntitlementManager: ObservableObject {
    static let monthlyID = "com.softcomputers.focusflow.pro.monthly"
    static let yearlyID = "com.softcomputers.focusflow.pro.yearly"
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    
    func loadProducts() async
    func refreshEntitlement() async
    func purchase(_ product: Product) async
    func restorePurchases() async
    func openManageSubscriptions() async
}
```

---

## Data Models

### Core Models

| Model | Location | Purpose |
|-------|----------|---------|
| `ProgressSession` | ProgressStore.swift | Focus session record |
| `FFTaskItem` | TaskModels.swift | Task data |
| `FocusPreset` | FocusPreset.swift | Timer preset |
| `FlowMessage` | FlowMessage.swift | AI chat message |
| `FocusNotification` | FocusNotification.swift | In-app notification |
| `AppTheme` | AppSettings.swift | Theme configuration |

### Persistence Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                     DATA PERSISTENCE                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    LOCAL STORAGE                         │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │  │
│  │  │ UserDefaults│  │ App Groups │  │ Keychain (tokens)│  │  │
│  │  │ (Settings) │  │  (Widgets) │  │                    │  │  │
│  │  └────────────┘  └────────────┘  └────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                    │
│  ┌──────────────────────────┴───────────────────────────────┐  │
│  │                    NAMESPACE ISOLATION                   │  │
│  │                                                          │  │
│  │  Guest:   key_guest          (local only)               │  │
│  │  User:    key_{userID}       (synced to cloud)          │  │
│  │                                                          │  │
│  │  On auth change: switch namespace, preserve guest data  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                    │
│  ┌──────────────────────────┴───────────────────────────────┐  │
│  │                    CLOUD STORAGE (Pro)                   │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │                   SUPABASE                         │  │  │
│  │  │  Tables: progress_sessions, tasks, presets,        │  │  │
│  │  │          user_settings                             │  │  │
│  │  │  Conflict Resolution: timestamp-based merge        │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Navigation Flow

### Deep Link Handling

```swift
// URL Schemes Supported:
// focusflow://start          - Navigate to Focus tab
// focusflow://startfocus     - Start session from widget
// focusflow://preset/{id}    - Start with specific preset
// focusflow://selectpreset/{id} - Select preset (no start)
// focusflow://pause          - Pause current session
// focusflow://resume         - Resume paused session
// focusflow://tasks          - Navigate to Tasks tab
// focusflow://progress       - Navigate to Progress tab

// Auth Deep Links:
// ca.softcomputers.FocusFlow://login-callback - OAuth callback
```

### Notification-Based Navigation

```swift
// Internal navigation via NotificationCenter
NotificationCenter.default.post(
    name: NotificationCenterManager.navigateToDestination,
    object: nil,
    userInfo: [
        "destination": NotificationDestination.focus,
        "presetID": presetID,
        "autoStart": true
    ]
)

enum NotificationDestination {
    case focus, tasks, progress, profile, journey
}
```

---

## State Management

### ObservableObject Pattern

All major stores are `@MainActor` singletons with `@Published` properties:

```swift
@MainActor
final class SomeStore: ObservableObject {
    static let shared = SomeStore()
    
    @Published private(set) var data: [Model] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe auth changes for namespace switching
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyAuthState(state)
            }
            .store(in: &cancellables)
    }
}
```

### EnvironmentObject Injection

```swift
// In FocusFlowApp
WindowGroup {
    RootView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager.shared)
        .environmentObject(OnboardingManager.shared)
}
```

---

## Performance Considerations

1. **Lazy Loading:** Views use `@StateObject` for expensive initializations
2. **Debouncing:** Context updates debounced to prevent excessive rebuilds
3. **Background Tasks:** Heavy operations use Swift Concurrency
4. **Memory Management:** Weak references in closures to prevent retain cycles
5. **Widget Updates:** Batched via `WidgetCenter.shared.reloadAllTimelines()`

---

## Testing

### Unit Test Targets
- `FocusFlowTests` - Core logic tests
- `FocusFlowUITests` - UI automation tests

### Debug Features
- `#if DEBUG` print statements throughout
- StoreKit Configuration for sandbox testing
- Network logging for Supabase calls

---

*Last Updated: January 2026*
