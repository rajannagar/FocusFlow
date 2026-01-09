# 📊 FocusFlow Widgets Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Widget Types](#widget-types)
4. [Live Activities](#live-activities)
5. [Data Sharing](#data-sharing)
6. [Deep Links](#deep-links)
7. [App Intents](#app-intents)
8. [Theme System](#theme-system)
9. [Implementation Details](#implementation-details)
10. [Troubleshooting](#troubleshooting)

---

## Overview

FocusFlow includes a comprehensive WidgetKit extension providing Home Screen widgets and Live Activities for real-time session tracking on the Lock Screen and Dynamic Island.

### Widget Extension Target

- **Target Name:** `FocusFlowWidgets`
- **Bundle ID:** `ca.softcomputers.FocusFlow.FocusFlowWidgets`
- **Minimum iOS:** 17.0
- **Frameworks:** WidgetKit, SwiftUI, ActivityKit, AppIntents

### Supported Widget Sizes

| Widget | Small | Medium | Large |
|--------|-------|--------|-------|
| Progress Widget | ✓ | ✓ | ✗ |
| Preset Selector | ✗ | ✓ | ✗ |
| Live Activity | N/A (Lock Screen + Dynamic Island) |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                      WIDGET ARCHITECTURE                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                     MAIN APP                                    │   │
│  │                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │              WidgetDataManager                          │   │   │
│  │  │                                                         │   │   │
│  │  │  • Writes data to App Group                            │   │   │
│  │  │  • Called by stores on data changes                    │   │   │
│  │  │  • Triggers widget timeline refresh                    │   │   │
│  │  │                                                         │   │   │
│  │  └───────────────────────┬─────────────────────────────────┘   │   │
│  │                          │                                      │   │
│  │  ┌───────────────────────┴─────────────────────────────────┐   │   │
│  │  │              FocusLiveActivityManager                   │   │   │
│  │  │                                                         │   │   │
│  │  │  • Starts/updates/ends Live Activities                 │   │   │
│  │  │  • Syncs with FocusTimerViewModel                      │   │   │
│  │  │                                                         │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  │                                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                          │                                             │
│                          ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    APP GROUP STORAGE                            │  │
│  │              group.ca.softcomputers.FocusFlow                   │  │
│  │                                                                 │  │
│  │  Keys:                                                          │  │
│  │  • widget.todayFocusSeconds                                     │  │
│  │  • widget.dailyGoalMinutes                                      │  │
│  │  • widget.currentStreak                                         │  │
│  │  • widget.presetsJSON                                           │  │
│  │  • widget.isSessionActive                                       │  │
│  │  • widget.selectedTheme                                         │  │
│  │  • widget.isPro                                                 │  │
│  │  • ...more                                                      │  │
│  │                                                                 │  │
│  └──────────────────────────────┬──────────────────────────────────┘  │
│                                 │                                      │
│                                 ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                   WIDGET EXTENSION                              │  │
│  │                                                                 │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │              WidgetDataProvider                         │   │  │
│  │  │                                                         │   │  │
│  │  │  • Reads data from App Group                           │   │  │
│  │  │  • Provides WidgetData struct to views                 │   │  │
│  │  │                                                         │   │  │
│  │  └───────────────────────┬─────────────────────────────────┘   │  │
│  │                          │                                      │  │
│  │  ┌───────────────────────┴─────────────────────────────────┐   │  │
│  │  │                  Widget Views                           │   │  │
│  │  │                                                         │   │  │
│  │  │  • SmallWidgetContent                                   │   │  │
│  │  │  • MediumWidgetContent                                  │   │  │
│  │  │  • FocusSessionLiveActivity                             │   │  │
│  │  │                                                         │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  │                                                                 │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Widget Types

### 1. Small Widget

**Purpose:** Quick view of today's progress with start button

```
┌─────────────────────────────┐
│  ● FocusFlow               │
│                             │
│        45m                  │
│     ━━━━━━━━━━━             │
│      75% of goal            │
│                             │
│  🔥 7 day streak           │
│                             │
│     [▶ Start]              │
└─────────────────────────────┘
```

**Features:**
- Today's focus time
- Goal progress bar
- Current streak
- Quick start button
- Theme-matched colors

**Code Structure:**
```swift
struct SmallWidgetContent: View {
    let entry: FocusFlowWidgetEntry
    
    var body: some View {
        ZStack {
            WidgetBackground(theme: theme)
            
            VStack {
                // Header with status indicator
                // Focus time display
                // Progress bar
                // Streak indicator
                // Start button
            }
        }
    }
}
```

### 2. Medium Widget

**Purpose:** Progress overview + preset quick selection

```
┌─────────────────────────────────────────────────────────────┐
│  ● FocusFlow           45m / 60m goal          🔥 7 days   │
│                                                             │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐     │
│  │  🧠 Deep Work │ │  ⚡ Quick    │ │  📚 Study    │     │
│  │    50 min     │ │    25 min    │ │    45 min    │     │
│  └───────────────┘ └───────────────┘ └───────────────┘     │
│                                                             │
│                        [▶ Start]                           │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- All small widget features
- Preset selector cards
- Tap preset to select, tap Start to begin
- Active session state display

**Code Structure:**
```swift
struct MediumWidgetContent: View {
    let entry: FocusFlowWidgetEntry
    
    var body: some View {
        ZStack {
            WidgetBackground(theme: theme)
            
            VStack {
                // Progress header row
                // Preset selection grid
                // Start/control button
            }
        }
    }
}
```

### 3. Active Session Widget State

When a session is running, widgets transform:

**Small (Running):**
```
┌─────────────────────────────┐
│  ● Running                  │
│                             │
│        23:45                │
│     ━━━━━━━━━━━━━━━━━━━━━   │
│       Deep Work             │
│                             │
│  [❚❚ Pause] [✕ End]        │
└─────────────────────────────┘
```

**Small (Paused):**
```
┌─────────────────────────────┐
│  ● Paused                   │
│                             │
│        23:45                │
│     ━━━━━━━━━━━             │
│       Deep Work             │
│                             │
│  [▶ Resume] [✕ End]        │
└─────────────────────────────┘
```

---

## Live Activities

### FocusSessionLiveActivity

**Location:** `FocusFlowWidgets/FocusSessionLiveActivity.swift`

Live Activities appear on the Lock Screen and Dynamic Island during active focus sessions.

### Lock Screen View

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Deep Work                                    [⏸/▶]       │
│                                                             │
│        23:45                                               │
│                                                             │
│   ● In progress                                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Session name
- Live countdown timer
- Play/Pause button (interactive)
- Status indicator
- Theme-matched colors

### Dynamic Island

**Compact (Minimal):**
```
┌──────────┐
│  23:45   │
└──────────┘
```

**Compact (Leading):**
```
┌────────────────────┐
│ ⏱ 23:45           │
└────────────────────┘
```

**Expanded:**
```
┌─────────────────────────────────────────┐
│                                         │
│   Deep Work           23:45             │
│   ● In progress                         │
│                                         │
└─────────────────────────────────────────┘
```

### Activity Attributes

```swift
// FocusSessionAttributes (in Shared/)
struct FocusSessionAttributes: ActivityAttributes {
    public typealias ContentState = SessionState
    
    let sessionName: String
    let presetID: UUID?
    
    struct SessionState: Codable, Hashable {
        var endDate: Date
        var isPaused: Bool
        var isCompleted: Bool
        var themeID: String
        var pausedDisplayTime: String
    }
}
```

### Live Activity Manager

```swift
// FocusLiveActivityManager (in Shared/)
@MainActor
final class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()
    
    private var currentActivity: Activity<FocusSessionAttributes>?
    
    func startActivity(
        sessionName: String,
        endDate: Date,
        presetID: UUID?,
        themeID: String
    )
    
    func updateActivity(
        endDate: Date? = nil,
        isPaused: Bool? = nil,
        themeID: String? = nil
    )
    
    func endActivity(completed: Bool = false)
    
    func pauseActivity(remainingSeconds: Int)
    
    func resumeActivity(newEndDate: Date)
}
```

---

## Data Sharing

### App Group Configuration

**App Group ID:** `group.ca.softcomputers.FocusFlow`

Both the main app and widget extension must include this App Group in their entitlements.

### WidgetDataProvider

**Location:** `FocusFlowWidgets/WidgetDataProvider.swift`

Reads data from App Group for widget display:

```swift
struct WidgetDataProvider {
    static let appGroupID = "group.ca.softcomputers.FocusFlow"
    
    struct WidgetData {
        let todayFocusSeconds: TimeInterval
        let dailyGoalMinutes: Int
        let currentStreak: Int
        let lifetimeSessionCount: Int
        let lifetimeFocusHours: Double
        let lastUpdated: Date
        let selectedTheme: String
        let displayName: String
        let presets: [WidgetPreset]
        let isSessionActive: Bool
        let activeSessionName: String?
        let activeSessionEndDate: Date?
        let activeSessionIsPaused: Bool
        let activeSessionTotalSeconds: Int
        let activeSessionRemainingSeconds: Int
        let selectedPresetID: String?
        let isPro: Bool
        
        // Computed properties
        var sessionProgress: Double { ... }
        var todayProgress: Double { ... }
        var todayFocusFormatted: String { ... }
    }
    
    static func readData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .placeholder
        }
        // Read all keys and return WidgetData
    }
}
```

### WidgetDataManager (Main App)

**Location:** `FocusFlow/Shared/WidgetDataManager.swift`

Writes data to App Group from main app:

```swift
@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    static let appGroupID = "group.ca.softcomputers.FocusFlow"
    
    func syncAll() {
        syncProgress()
        syncPresets()
        syncSettings()
        syncSessionState()
        
        // Trigger widget timeline refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func syncProgress() {
        let progress = ProgressStore.shared
        defaults?.set(progress.totalToday, forKey: "widget.todayFocusSeconds")
        defaults?.set(progress.dailyGoalMinutes, forKey: "widget.dailyGoalMinutes")
        // ...more
    }
    
    private func syncPresets() {
        let presets = FocusPresetStore.shared.presets.map { preset in
            WidgetPreset(
                id: preset.id.uuidString,
                name: preset.name,
                emoji: preset.emoji,
                durationMinutes: preset.durationSeconds / 60
            )
        }
        if let data = try? JSONEncoder().encode(presets) {
            defaults?.set(data, forKey: "widget.presetsJSON")
        }
    }
    
    func syncSessionState(
        isActive: Bool,
        sessionName: String?,
        endDate: Date?,
        isPaused: Bool,
        totalSeconds: Int,
        remainingSeconds: Int
    ) {
        defaults?.set(isActive, forKey: "widget.isSessionActive")
        defaults?.set(sessionName, forKey: "widget.activeSessionName")
        defaults?.set(endDate, forKey: "widget.activeSessionEndDate")
        // ...more
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          DATA SYNC FLOW                                  │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   MAIN APP                         APP GROUP              WIDGET         │
│                                                                          │
│   ProgressStore ──┐                                                      │
│                   │                                                      │
│   TasksStore ─────┼──► WidgetDataManager ──► UserDefaults ──► WidgetData│
│                   │         │                (Shared)            │       │
│   PresetStore ────┘         │                                    │       │
│                             │                                    ▼       │
│   AppSettings ──────────────┘                            Widget Views    │
│                                                                          │
│   FocusTimerVM ──► FocusLiveActivityManager ──► ActivityKit ──► Live    │
│                                                               Activity   │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Deep Links

Widgets use URL schemes to communicate with the main app:

### Supported Deep Links

| URL | Action |
|-----|--------|
| `focusflow://start` | Navigate to Focus tab |
| `focusflow://startfocus` | Start session (uses selected preset if any) |
| `focusflow://preset/{id}` | Select preset AND start session |
| `focusflow://selectpreset/{id}` | Select preset only (no start) |
| `focusflow://switchpreset/{id}` | Switch preset with confirmation |
| `focusflow://pause` | Pause current session |
| `focusflow://resume` | Resume paused session |
| `focusflow://resetconfirm` | End session with confirmation |
| `focusflow://tasks` | Navigate to Tasks tab |
| `focusflow://progress` | Navigate to Progress tab |

### Widget Button Implementation

```swift
// Start Button
Link(destination: URL(string: "focusflow://startfocus")!) {
    Text("Start")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.accent)
        .clipShape(Capsule())
}

// Preset Selection
Button(intent: SelectPresetIntent(presetID: preset.id)) {
    PresetCard(preset: preset)
}
```

---

## App Intents

### StartFocusIntent

```swift
// StartFocusIntent.swift
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Starts a focus session")
    
    @Parameter(title: "Preset")
    var presetID: String?
    
    func perform() async throws -> some IntentResult {
        // Store selected preset in App Group
        let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
        defaults?.set(presetID, forKey: "widget.selectedPresetID")
        
        // The app will pick this up via deep link handling
        return .result()
    }
}
```

### ToggleFocusPauseIntent

```swift
// Used in Live Activity for Play/Pause button
struct ToggleFocusPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Pause"
    
    func perform() async throws -> some IntentResult {
        // Read current state
        let bridge = FocusSessionBridge.shared
        let isPaused = bridge.isPaused
        
        if isPaused {
            bridge.resume()
        } else {
            bridge.pause()
        }
        
        return .result()
    }
}
```

### SelectPresetIntent

```swift
struct SelectPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Preset"
    
    @Parameter(title: "Preset ID")
    var presetID: String
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
        defaults?.set(presetID, forKey: "widget.selectedPresetID")
        
        // Refresh widget to show selection
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
```

---

## Theme System

Widgets support all 10 FocusFlow themes:

### WidgetTheme

```swift
struct WidgetTheme {
    let top: Color         // Background gradient top
    let bottom: Color      // Background gradient bottom
    let accent: Color      // Primary accent
    let accentSecondary: Color  // Secondary accent
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func theme(for id: String) -> WidgetTheme {
        switch id {
        case "forest":
            return WidgetTheme(
                top: Color(red: 0.05, green: 0.11, blue: 0.09),
                bottom: Color(red: 0.13, green: 0.22, blue: 0.18),
                accent: Color(red: 0.55, green: 0.90, blue: 0.70),
                accentSecondary: Color(red: 0.42, green: 0.78, blue: 0.62)
            )
        case "neon": // ...
        case "peach": // ...
        case "cyber": // ...
        case "ocean": // ...
        case "sunrise": // ...
        case "amber": // ...
        case "mint": // ...
        case "royal": // ...
        case "slate": // ...
        default: return forest
        }
    }
}
```

### Theme-Aware Background

```swift
struct WidgetBackground: View {
    let theme: WidgetTheme
    
    var body: some View {
        ZStack {
            // Base gradient
            theme.backgroundGradient
            
            // Accent glow top-left
            RadialGradient(
                colors: [theme.accent.opacity(0.15), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 140
            )
            
            // Secondary glow bottom-right
            RadialGradient(
                colors: [theme.accentSecondary.opacity(0.10), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 120
            )
        }
    }
}
```

---

## Implementation Details

### Timeline Provider

```swift
struct FocusFlowWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> FocusFlowWidgetEntry {
        FocusFlowWidgetEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusFlowWidgetEntry) -> Void) {
        let entry = FocusFlowWidgetEntry(
            date: Date(),
            data: WidgetDataProvider.readData()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusFlowWidgetEntry>) -> Void) {
        let currentDate = Date()
        let data = WidgetDataProvider.readData()
        let entry = FocusFlowWidgetEntry(date: currentDate, data: data)
        
        // Refresh interval based on session state
        let refreshInterval: TimeInterval = data.isSessionActive && !data.activeSessionIsPaused
            ? 60       // Active session: refresh every minute
            : 5 * 60   // Idle: refresh every 5 minutes
        
        let refreshDate = currentDate.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}
```

### Widget Entry

```swift
struct FocusFlowWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataProvider.WidgetData
}
```

### Widget Bundle

```swift
// FocusFlowWidgetsBundle.swift
@main
struct FocusFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowWidget()
        
        if #available(iOSApplicationExtension 18.0, *) {
            FocusSessionLiveActivity()
        }
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. Widget Shows Placeholder Data

**Cause:** App Group not properly configured or data not synced

**Solution:**
- Verify App Group ID matches in both targets
- Ensure entitlements file includes App Group
- Call `WidgetDataManager.shared.syncAll()` after data changes

#### 2. Live Activity Not Appearing

**Cause:** Activity not started or already ended

**Solution:**
- Check `ActivityAuthorizationInfo` for permission
- Verify `FocusLiveActivityManager.startActivity()` called
- Check iOS settings for Live Activity permission

#### 3. Theme Mismatch

**Cause:** Theme ID not synced to App Group

**Solution:**
- Ensure `widget.selectedTheme` key is updated
- Reload widget timelines after theme change

#### 4. Deep Links Not Working

**Cause:** URL scheme not registered or handler not set up

**Solution:**
- Verify `focusflow` URL scheme in Info.plist
- Check `onOpenURL` handler in FocusFlowApp

### Debug Tips

```swift
// Enable widget preview logging
#if DEBUG
print("[Widget] Data: \(WidgetDataProvider.readData())")
#endif

// Force widget refresh
WidgetCenter.shared.reloadAllTimelines()

// Check Live Activity status
if let activity = Activity<FocusSessionAttributes>.activities.first {
    print("Activity state: \(activity.activityState)")
}
```

---

## File Reference

| File | Purpose |
|------|---------|
| `FocusFlowWidget.swift` | Home Screen widget views |
| `FocusSessionLiveActivity.swift` | Lock Screen + Dynamic Island |
| `WidgetDataProvider.swift` | App Group data reader |
| `FocusFlowWidgetsBundle.swift` | Widget bundle entry |
| `AppIntent.swift` | Basic app intents |
| `StartFocusIntent.swift` | Start focus intent |
| `WidgetDataManager.swift` (Main App) | App Group data writer |
| `FocusLiveActivityManager.swift` (Shared) | Activity lifecycle |
| `FocusSessionAttributes.swift` (Shared) | Activity data model |
| `FocusSessionBridge.swift` (Shared) | Session state bridge |

---

*Last Updated: January 2026*
