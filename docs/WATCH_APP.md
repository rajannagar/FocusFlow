# ⌚ FocusFlow Apple Watch App - Technical Specification

> **Status:** Phase 1 Complete ✅  
> **Target:** watchOS 10.0+  
> **Availability:** Pro Users Only  
> **Last Updated:** January 9, 2026

---

## Implementation Progress

### ✅ Completed (Phase 1)

| Component | File | Status |
|-----------|------|--------|
| Watch Target | `FocusFlowWatch Watch App/` | ✅ Created & building |
| Entry Point | `FocusFlowWatchApp.swift` | ✅ Complete |
| Pro Gate | `ContentView.swift` | ✅ Complete |
| Tab Navigation | `MainTabView.swift` | ✅ 5-tab structure |
| Launch Screen | `Launch/WatchLaunchView.swift` | ✅ Branded animation |
| Focus View | `Views/Focus/WatchFocusView.swift` | ✅ Orb + corner icons |
| Orb Component | `Components/WatchOrbView.swift` | ✅ Animated, all states |
| Presets View | `Views/Presets/WatchPresetsView.swift` | ✅ List + activation |
| Tasks View | `Views/Tasks/WatchTasksView.swift` | ✅ List + toggle |
| Progress View | `Views/Progress/WatchProgressView.swift` | ✅ Stats + ring |
| Profile View | `Views/Profile/WatchProfileView.swift` | ✅ Level, XP, badges |
| Badges View | `Views/Profile/WatchBadgesView.swift` | ✅ Badge grid |
| Settings View | `Views/Settings/WatchSettingsView.swift` | ✅ All settings |
| Pro Required | `Views/ProRequiredView.swift` | ✅ Free user gate |
| Data Manager | `ViewModels/WatchDataManager.swift` | ✅ State management |
| Watch Connectivity | `Connectivity/WatchConnectivityManager.swift` | ✅ Two-way sync |
| iPhone Connectivity | `iPhoneWatchConnectivityManager.swift` | ✅ Stub (needs wiring) |
| Haptics | `Components/WatchHaptics.swift` | ✅ Feedback patterns |
| Assets | `Assets.xcassets/` | ✅ Created |

### 🔄 In Progress (Phase 2)

| Component | Status |
|-----------|--------|
| Wire iPhone connectivity to ViewModels | Pending |
| App Group capability in Xcode | Pending |
| Real data sync testing | Pending |

### 📋 Remaining Phases

- **Phase 2:** Timer logic, bidirectional sync, Digital Crown
- **Phase 3:** Quick add preset/task, enhanced animations
- **Phase 4:** Flow AI integration
- **Phase 5:** Complications & polish
- **Phase 6:** Launch prep

---

## Table of Contents

1. [Overview](#overview)
2. [Pro-Only Strategy](#pro-only-strategy)
3. [App Architecture](#app-architecture)
4. [Navigation & Views](#navigation--views)
5. [The Orb - Core UI](#the-orb---core-ui)
6. [Flow AI Integration](#flow-ai-integration)
7. [Data Sync Architecture](#data-sync-architecture)
8. [Complications](#complications)
9. [Settings](#settings)
10. [File Structure](#file-structure)
11. [Implementation Phases](#implementation-phases)

---

## Overview

### Vision

Create an Apple-grade Watch companion app that provides seamless focus session control from the wrist. The app centers around the iconic FocusFlow orb, enabling users to start, pause, and control focus sessions without reaching for their iPhone.

### Key Characteristics

- **Pro-Only Feature** — Exclusive to FocusFlow Pro subscribers
- **100% SwiftUI** — Modern watchOS development
- **Apple-Grade Sync** — Instant, invisible synchronization with iPhone
- **Orb-Centric Design** — Same beautiful orb from iOS app
- **Flow AI Enabled** — Long-press orb to activate voice assistant
- **5-Tab Navigation** — Focus, Presets, Tasks, Progress, Profile

### Supported Features

| Feature | Description |
|---------|-------------|
| Focus Timer | Start, pause, resume, end sessions |
| Presets | Quick-start from saved presets |
| Tasks | View and complete tasks |
| Progress | Daily stats, streak, session count |
| Profile | Level, XP, badges |
| Flow AI | Voice-activated assistant |
| Complications | Watch face integration |
| Haptics | Tactile feedback for session events |

---

## Pro-Only Strategy

### Rationale

The Apple Watch app is exclusively available to Pro subscribers because:

1. **Strong Value Proposition** — Tangible, visible benefit for upgrading
2. **Premium Audience** — Watch users already invest in premium products
3. **Development Simplicity** — No tier logic complexity on Watch
4. **Clean UX** — No awkward upgrade prompts on tiny screen
5. **Support Efficiency** — Pro users are typically more engaged

### Free User Experience

When a Free user opens the Watch app:

```
┌────────────────────────────────────────┐
│                                        │
│         ╭─────────────╮                │
│        │     🎯      │                │
│         ╰─────────────╯                │
│                                        │
│       FocusFlow Watch                  │
│                                        │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                        │
│   The Watch app is available           │
│   with FocusFlow Pro.                  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │    Learn More on iPhone        │  │
│   └────────────────────────────────┘  │
│                                        │
│   Already Pro? Make sure you're       │
│   signed in on iPhone.                │
│                                        │
└────────────────────────────────────────┘
```

### Implementation

```swift
struct ContentView: View {
    @ObservedObject var dataManager = WatchDataManager.shared
    
    var body: some View {
        if dataManager.isPro {
            MainTabView()
        } else {
            ProRequiredView()
        }
    }
}
```

---

## App Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WATCH APP SYSTEM ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ┌─────────────────────┐                            │
│                         │   SUPABASE CLOUD    │                            │
│                         │   (via iPhone)      │                            │
│                         └──────────┬──────────┘                            │
│                                    │                                        │
│                                    ▼                                        │
│   ┌───────────────┐    ════════════════════════    ┌───────────────────┐  │
│   │               │    ║  WatchConnectivity   ║    │                   │  │
│   │  APPLE WATCH  │◄══►║  + App Group         ║◄══►│     iPHONE        │  │
│   │               │    ║  (Real-time sync)    ║    │                   │  │
│   └───────────────┘    ════════════════════════    └───────────────────┘  │
│                                                                             │
│   Watch App Features:              iPhone Responsibilities:                │
│   • Timer UI & control             • Source of truth for data              │
│   • Task display & completion      • Pro status verification               │
│   • Progress visualization         • Cloud sync (Supabase)                 │
│   • Flow AI interface              • Flow AI processing                    │
│   • Complications                  • Heavy computation                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      WATCH APP ARCHITECTURE                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                  FocusFlowWatch App                          │   │
│   │  ┌──────────────┐  ┌─────────────────┐  ┌────────────────┐  │   │
│   │  │ WatchFocusView│  │WatchProgressView│  │WatchPresetsView│  │   │
│   │  └──────┬───────┘  └────────┬────────┘  └───────┬────────┘  │   │
│   │         └──────────────┬────┴───────────────────┘           │   │
│   │                        ▼                                     │   │
│   │           ┌───────────────────────────┐                     │   │
│   │           │  WatchSessionManager      │ ◄── Single source   │   │
│   │           │  (ObservableObject)       │     of truth        │   │
│   │           └───────────┬───────────────┘                     │   │
│   └───────────────────────┼─────────────────────────────────────┘   │
│                           │                                          │
│   ┌───────────────────────┼─────────────────────────────────────┐   │
│   │          SHARED INFRASTRUCTURE                               │   │
│   │                       │                                      │   │
│   │   ┌───────────────────▼───────────────────────┐             │   │
│   │   │    WatchConnectivityManager               │             │   │
│   │   │    • Session state sync                   │             │   │
│   │   │    • Preset sync                          │             │   │
│   │   │    • Progress data sync                   │             │   │
│   │   └───────────────────────────────────────────┘             │   │
│   │                                                              │   │
│   │   ┌───────────────────────────────────────────┐             │   │
│   │   │    App Group (group.ca.softcomputers...)  │             │   │
│   │   │    • Shared UserDefaults                  │             │   │
│   │   │    • Offline data persistence             │             │   │
│   │   └───────────────────────────────────────────┘             │   │
│   └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Navigation & Views

### Tab Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WATCH APP NAVIGATION (TabView)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ◄ Swipe ►                                                                 │
│                                                                             │
│   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐     │
│   │         │   │         │   │         │   │         │   │         │     │
│   │  FOCUS  │   │ PRESETS │   │  TASKS  │   │PROGRESS │   │ PROFILE │     │
│   │  (Orb)  │   │  List   │   │  List   │   │  Stats  │   │ XP/Badge│     │
│   │         │   │         │   │         │   │         │   │         │     │
│   └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘     │
│       ●             ○             ○             ○             ○            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Complete Navigation Map

```
🚀 LAUNCH
   │
   └──► WatchLaunchView (branded, 1.2s)
           │
           ▼
📱 MAIN APP (TabView)
   │
   ├──► Tab 1: FOCUS
   │       • Orb (tap = timer, hold = Flow AI)
   │       • Corner icons (duration, music, reset, ambiance)
   │
   ├──► Tab 2: PRESETS
   │       • List of presets
   │       • Tap → Focus view with preset applied
   │       • + New Preset → Quick create sheet
   │
   ├──► Tab 3: TASKS
   │       • Task list with checkboxes
   │       • Tap circle → Toggle complete
   │       • + Quick Task → Voice input sheet
   │
   ├──► Tab 4: PROGRESS
   │       • Daily progress ring
   │       • Streak count
   │       • Quick stats
   │
   └──► Tab 5: PROFILE
           • Level/XP card
           • Recent badges
           • ⚙️ Settings gear → Settings sheet
                   │
                   ├──► Theme
                   ├──► Haptics
                   ├──► Notifications
                   ├──► Complications
                   ├──► Sync
                   └──► About
```

### View Mockups

#### Tab 1: Focus View (The Orb)

```
┌────────────────────────────────────┐
│  ⏱️                           🎵  │  ← Duration, Music
│                                    │
│        ╭─────────────╮             │
│      ╭───────────────────╮         │
│     │                     │        │
│     │      25:00          │        │  ← Glowing orb
│     │    Deep Work        │        │  ← Session name
│     │                     │        │
│      ╰───────────────────╯         │
│        ╰─────────────╯             │
│                                    │
│  🔄                           🌿  │  ← Reset, Ambiance
│                                    │
│            ● ○ ○ ○ ○              │
└────────────────────────────────────┘

INTERACTIONS:
• Tap orb → Start/Pause
• Long press (0.5s) → Activate Flow AI
• Digital Crown → Adjust time (when idle)
• Corner icons → Quick toggles
```

#### Tab 2: Presets

```
┌────────────────────────────────────┐
│         Presets                    │
│  ┌──────────────────────────────┐  │
│  │ 🎯 Deep Work           25m   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ 💡 Creative            45m   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ 📚 Study               50m   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ ➕ New Preset                │  │
│  └──────────────────────────────┘  │
│            ○ ● ○ ○ ○              │
└────────────────────────────────────┘

• Tap preset → Apply settings, navigate to Focus, ready to start
• New Preset → Name (voice) + Duration (crown) only
• Advanced editing → "Edit on iPhone"
```

#### Tab 3: Tasks

```
┌────────────────────────────────────┐
│          Tasks                     │
│  ┌──────────────────────────────┐  │
│  │ ○ Review PR                  │  │
│  │   Due: Today                 │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ ○ Write docs                 │  │
│  │   Due: Tomorrow              │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ ✓ Team meeting               │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ ➕ Quick Task                │  │
│  └──────────────────────────────┘  │
│            ○ ○ ● ○ ○              │
└────────────────────────────────────┘

• Tap circle → Toggle complete
• Quick Task → Voice dictation + due date
• Swipe left → Delete
```

#### Tab 4: Progress

```
┌────────────────────────────────────┐
│        Today                       │
│                                    │
│      ╭─────────────╮               │
│     ╱    1h 45m    ╲              │
│    │   ─────────    │              │
│     ╲   / 2h goal  ╱              │
│      ╰─────────────╯               │
│                                    │
│   🔥 12 day streak                │
│                                    │
│   Sessions: 4                      │
│   Avg Focus: 26 min                │
│                                    │
│            ○ ○ ○ ● ○              │
└────────────────────────────────────┘
```

#### Tab 5: Profile

```
┌────────────────────────────────────┐
│   PRO ✦                       ⚙️  │
│          Level 24                  │
│      ╭─────────────╮               │
│     │   ⚡ 2,450    │              │
│     │     XP       │              │
│      ╰─────────────╯               │
│    ━━━━━━━━━━━━━○ 550 to 25       │
│                                    │
│   Recent Badges:                   │
│   🏆 🔥 📚 ⭐ 🎯                   │
│                                    │
│   ┌────────────────────────────┐  │
│   │      View All Badges       │  │
│   └────────────────────────────┘  │
│            ○ ○ ○ ○ ●              │
└────────────────────────────────────┘
```

---

## The Orb - Core UI

### Orb States

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ORB VISUAL STATES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   IDLE                    RUNNING                 PAUSED                    │
│   ─────                   ───────                 ──────                    │
│                                                                             │
│   ╭───────╮               ╭───────╮               ╭───────╮                │
│  │ Gentle  │             │ Pulsing │             │ Dimmed  │               │
│  │ glow    │             │ + ring  │             │ static  │               │
│  │ 25:00   │             │ 24:32   │             │ 18:45   │               │
│   ╰───────╯               ╰───────╯               ╰───────╯                │
│   Soft breathing          Progress ring           Subtle pulse             │
│   animation               animates                "waiting"                │
│                                                                             │
│   COMPLETING              COMPLETED               FLOW AI                   │
│   ──────────              ─────────               ───────                   │
│                                                                             │
│   ╭───────╮               ╭───────╮               ╭───────╮                │
│  │ Intense │             │ Burst!  │             │   🎤   │               │
│  │ 0:05    │             │   🎉    │             │ Flow   │               │
│   ╰───────╯               ╰───────╯               ╰───────╯                │
│   Last 10 sec             Celebration             Waveform                 │
│   builds energy           + haptics               animation                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Orb Interactions

| Gesture | Action |
|---------|--------|
| **Tap** | Start/Pause timer |
| **Long Press (0.5s)** | Activate Flow AI |
| **Digital Crown** | Adjust duration (when idle) |
| **Double Tap** | Quick end session (optional) |

### Corner Icons

| Position | Icon | Function |
|----------|------|----------|
| Top-Left | ⏱️ | Duration picker (15/25/45/60 min) |
| Top-Right | 🎵 | Toggle sound/music |
| Bottom-Left | 🔄 | Reset timer |
| Bottom-Right | 🌿 | Toggle ambiance |

---

## Flow AI Integration

### Activation Flow

```
┌────────────────────────────────────┐
│         ╭─────────────╮            │
│        │   25:00      │            │
│        │   ● ● ●      │  ← Pulses  │
│         ╰─────────────╯    on hold │
│      Hold for Flow...              │
└────────────────────────────────────┘
              │ (0.5s hold)
              ▼
┌────────────────────────────────────┐
│        ╭─────────────╮             │
│       │   🎤         │             │
│       │   Flow       │  ← Morphs   │
│       │   Listening  │    to Flow  │
│        ╰─────────────╯             │
│      "Start a 45-minute session"   │
└────────────────────────────────────┘
              │ (Processing)
              ▼
┌────────────────────────────────────┐
│        ╭─────────────╮             │
│       │   ✨         │             │
│       │   45:00      │  ← Acts     │
│       │   Starting   │             │
│        ╰─────────────╯             │
│      "Starting 45 minute focus"    │
└────────────────────────────────────┘
```

### Flow Capabilities on Watch

| Command Type | Examples |
|--------------|----------|
| **Timer Control** | "Start a deep work session", "Pause", "How much time left?" |
| **Task Management** | "Add task: call mom tomorrow", "What's my next task?", "Complete review PR" |
| **Presets** | "Start my study preset", "Create 30 minute reading preset" |
| **Progress** | "How much have I focused today?", "What's my streak?" |
| **Quick Queries** | "When should I take a break?", "How am I doing this week?" |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FLOW AI ON WATCH - ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   APPLE WATCH                           iPHONE                              │
│                                                                             │
│   ┌─────────────────┐                   ┌─────────────────┐                │
│   │  Voice Input    │                   │   Flow AI       │                │
│   │  (on-device     │   Transcribed     │   Engine        │                │
│   │   recognition)  │───────────────────►   (GPT/Claude)  │                │
│   └────────┬────────┘      text         └────────┬────────┘                │
│            │                                      │                         │
│            │                                      │ Response                │
│            ▼                                      ▼                         │
│   ┌─────────────────┐                   ┌─────────────────┐                │
│   │  Execute Action │◄──────────────────│  Process &      │                │
│   │  Locally        │    Action +       │  Generate       │                │
│   │  • Start timer  │    Response       │  Response       │                │
│   │  • Create task  │                   │                 │                │
│   └─────────────────┘                   └─────────────────┘                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Offline Fallback

Basic commands work without iPhone via local parsing:

```swift
enum LocalFlowCommand {
    case startTimer(minutes: Int)
    case pauseTimer
    case resumeTimer
    case endSession
    case readTimeRemaining
    case readTodayProgress
}
```

---

## Data Sync Architecture

### Sync Layers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SEAMLESS SYNC ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                        ┌─────────────────────┐                              │
│                        │   CLOUD (Supabase)  │                              │
│                        │   • Session history │                              │
│                        │   • Stats rollup    │                              │
│                        └──────────┬──────────┘                              │
│                                   │ (iPhone handles)                        │
│         ┌─────────────────────────┼─────────────────────────┐               │
│         │                         │                         │               │
│         ▼                         ▼                         ▼               │
│  ┌─────────────┐    ════════════════════════    ┌─────────────────┐        │
│  │   iPhone    │    ║  WatchConnectivity   ║    │   Apple Watch   │        │
│  │             │◄══►║  (Real-time bridge)  ║◄══►│                 │        │
│  │ FocusFlow   │    ════════════════════════    │ FocusFlow Watch │        │
│  └──────┬──────┘              │                 └────────┬────────┘        │
│         │                     │                          │                  │
│         │         ┌───────────▼───────────┐              │                  │
│         │         │      App Group        │              │                  │
│         └────────►│  (Shared UserDefaults)│◄─────────────┘                  │
│                   │  • Session state      │                                 │
│                   │  • Presets            │                                 │
│                   │  • User prefs         │                                 │
│                   └───────────────────────┘                                 │
│                              │                                              │
│              ┌───────────────┼───────────────┐                              │
│              ▼               ▼               ▼                              │
│        ┌──────────┐   ┌───────────┐   ┌─────────────┐                      │
│        │  Widget  │   │Complication│   │Live Activity│                      │
│        └──────────┘   └───────────┘   └─────────────┘                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Sync Methods

| Method | Use Case | Latency |
|--------|----------|---------|
| **sendMessage()** | Real-time updates when both apps active | <100ms |
| **transferUserInfo()** | Guaranteed delivery, queued | Eventually |
| **updateApplicationContext()** | Latest state snapshot | When received |
| **App Group UserDefaults** | Offline persistence, widget data | Instant |

### Key Sync Scenarios

#### 1. Start Session on iPhone → Watch Mirrors

```swift
// iPhone
func startSession() {
    let state = SessionState(phase: .running, endDate: endDate, name: name)
    WatchConnectivityManager.shared.sendSessionState(state)
    SharedDataProvider.saveSessionState(state)
}

// Watch receives instantly
func didReceiveMessage(_ message: [String: Any]) {
    if let state = SessionState(from: message) {
        sessionManager.mirror(state)
    }
}
```

#### 2. Control Session on Watch → iPhone Updates

```swift
// Watch
func pauseFromWatch() {
    let state = sessionManager.pause()
    WCSession.default.sendMessage(state.toDictionary(), replyHandler: nil)
}

// iPhone receives and updates
func didReceiveMessage(_ message: [String: Any]) {
    if let state = SessionState(from: message) {
        focusTimerViewModel.applyState(state)
    }
}
```

#### 3. Watch Works Without iPhone

```swift
// Watch can run independently
func startIndependentSession(preset: FocusPreset) {
    let state = SessionState(...)
    sessionManager.start(state)
    
    // Queue for iPhone sync when reconnects
    WCSession.default.transferUserInfo(state.toDictionary())
    SharedDataProvider.saveSessionState(state)
}
```

### Data Payloads

```swift
struct WatchSyncPayload: Codable {
    let isPro: Bool
    let presets: [FocusPreset]
    let tasks: [FocusTask]
    let availableThemes: [String]
    let todayFocusSeconds: TimeInterval
    let currentStreak: Int
    let level: Int
    let xp: Int
    let recentBadges: [Badge]
}
```

---

## Complications

### Available Complications

| Type | Shows | Use Case |
|------|-------|----------|
| **Circular** | Daily progress ring | Activity-like ring |
| **Modular Large** | Timer + session name | When running |
| **Graphic Corner** | Streak + flame icon | Quick glance |
| **Graphic Bezel** | Full progress around face | Detailed view |
| **Rectangular** | Today stats summary | Infograph face |

### Complication Updates

```swift
func sessionStateDidChange(_ state: SessionState) {
    let server = CLKComplicationServer.sharedInstance()
    for complication in server.activeComplications ?? [] {
        server.reloadTimeline(for: complication)
    }
}
```

---

## Settings

### Settings Structure

```
Settings (sheet from Profile)
├── 🎨 Theme
│   ├── Sync with iPhone (default)
│   └── Manual theme selection
├── 📳 Haptics
│   ├── Enable/Disable
│   ├── Intensity (Light → Strong)
│   └── Events (Start, Complete, Milestones, Breaks)
├── 🔔 Notifications
│   ├── Session alerts
│   └── Sound selection
├── ⌚ Complications
│   └── Guide to available types
├── 🔄 Sync
│   ├── Connection status
│   ├── Last synced timestamp
│   └── Manual sync button
└── ℹ️ About
    ├── Version
    ├── Privacy Policy
    └── Terms of Service
```

### Settings That Sync vs. Local

| Setting | Behavior |
|---------|----------|
| Theme | Option: "Sync with iPhone" or override locally |
| Haptics | Watch-only (no equivalent on iPhone) |
| Notifications | Watch-specific |
| Daily Goal | Synced from iPhone (source of truth) |
| Presets | Synced bidirectionally |

---

## File Structure

```
FocusFlowWatch Watch App/                 # ← Xcode-generated folder name
├── FocusFlowWatchApp.swift              # ✅ @main entry point
├── ContentView.swift                     # ✅ Pro gate + launch animation
├── MainTabView.swift                     # ✅ 5-tab navigation
│
├── Launch/
│   └── WatchLaunchView.swift            # ✅ Branded launch (matches iPhone)
│
├── Views/
│   ├── Focus/
│   │   └── WatchFocusView.swift         # ✅ Main focus tab with orb
│   │
│   ├── Presets/
│   │   └── WatchPresetsView.swift       # ✅ Preset list + activation
│   │
│   ├── Tasks/
│   │   └── WatchTasksView.swift         # ✅ Task list + completion
│   │
│   ├── Progress/
│   │   └── WatchProgressView.swift      # ✅ Daily stats & ring
│   │
│   ├── Profile/
│   │   ├── WatchProfileView.swift       # ✅ Level, XP, settings gear
│   │   └── WatchBadgesView.swift        # ✅ Badge grid
│   │
│   ├── Settings/
│   │   └── WatchSettingsView.swift      # ✅ All settings in one file
│   │
│   └── ProRequiredView.swift            # ✅ Free user gate
│
├── Components/
│   ├── WatchOrbView.swift               # ✅ Animated orb component
│   └── WatchHaptics.swift               # ✅ Haptic feedback patterns
│
├── ViewModels/
│   └── WatchDataManager.swift           # ✅ Central data & state
│
├── Connectivity/
│   └── WatchConnectivityManager.swift   # ✅ WCSession handling
│
├── Assets.xcassets/                     # ✅ Watch-specific assets
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   └── AppIcon.appiconset/
│
└── FocusFlowWatch.entitlements          # ✅ App Group capability

iPhone Side:
└── FocusFlow/Infrastructure/WatchConnectivity/
    └── iPhoneWatchConnectivityManager.swift  # ✅ Stub (needs wiring)
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2) ✅ COMPLETE

- [x] Create Watch target in Xcode
- [x] Set up project structure
- [x] Implement WatchConnectivityManager (Watch side)
- [x] Implement iPhoneWatchConnectivityManager (iPhone side stub)
- [x] Create WatchLaunchView (branded)
- [x] Implement Pro gate (ContentView)
- [x] 5-tab TabView navigation structure
- [x] WatchOrbView with animations
- [x] WatchFocusView with corner icons
- [x] WatchPresetsView
- [x] WatchTasksView
- [x] WatchProgressView
- [x] WatchProfileView + WatchBadgesView
- [x] WatchSettingsView (all settings combined)
- [x] WatchDataManager (central state)
- [x] WatchHaptics (feedback patterns)
- [x] ProRequiredView (free user gate)

**Commit:** `094d0ec` - "Add Apple Watch app (Phase 1)"

### Phase 2: Core Timer & Sync (Week 2-3) 🔄 IN PROGRESS

- [ ] Wire iPhoneWatchConnectivityManager to actual ViewModels
- [ ] Add App Group capability to Watch target in Xcode
- [ ] Bidirectional session sync testing
- [ ] Real timer logic with countdown
- [ ] Duration adjustment (Digital Crown)
- [ ] Session end/complete flow
- [ ] Live session mirroring between devices

### Phase 3: Supporting Features (Week 3-4)

- [ ] Quick add preset (voice + crown)
- [ ] Quick add task (voice input)
- [ ] Enhanced orb animations (completing state)
- [ ] Session completion celebration
- [ ] Task swipe-to-delete
- [ ] Preset editing on Watch

### Phase 4: Flow AI (Week 4-5)

- [ ] Flow activation gesture (long press orb)
- [ ] Voice recognition integration
- [ ] Flow UI states (listening, thinking, responding)
- [ ] iPhone-side Flow processing relay
- [ ] Action execution on Watch
- [ ] Offline fallback for basic commands

### Phase 5: Complications & Polish (Week 5-6)

- [ ] Circular complication (daily ring)
- [ ] Modular Large complication
- [ ] Graphic Corner complication
- [ ] Theme sync with iPhone
- [ ] Edge case handling
- [ ] Performance optimization
- [ ] Device testing

### Phase 6: Launch Prep (Week 6-7)

- [ ] App Store assets (Watch screenshots)
- [ ] Marketing materials update
- [ ] Documentation
- [ ] Beta testing
- [ ] Submit for review

---

## Technical Requirements

### Minimum Requirements

- **watchOS:** 10.0+
- **Paired iPhone:** iOS 17.0+ with FocusFlow installed
- **Subscription:** FocusFlow Pro

### Dependencies

- WatchConnectivity framework
- WidgetKit (for complications)
- Speech framework (for Flow voice input)
- AVFoundation (for audio feedback)

### App Group

Uses existing: `group.ca.softcomputers.FocusFlow`

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Watch → iPhone sync latency | <100ms |
| Independent session reliability | 99.9% |
| Complication accuracy | Always current |
| App launch time | <1.5s |
| Pro conversion lift | +15% |

---

## Open Questions

1. **Siri Integration:** Add App Intents for Siri shortcuts?
2. **Handoff:** Implement handoff from Watch to iPhone?
3. **Ultra Support:** Special UI for Apple Watch Ultra?
4. **Always-On Display:** Custom always-on state for timer?

---

*Document created: January 9, 2026*  
*Phase 1 completed: January 9, 2026*
