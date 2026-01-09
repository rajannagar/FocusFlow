# 🤖 Flow AI Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [File Structure](#file-structure)
4. [User Interface](#user-interface)
5. [AI Tools & Functions](#ai-tools--functions)
6. [System Prompt](#system-prompt)
7. [Context Building](#context-building)
8. [Voice Input](#voice-input)
9. [AI Memory System](#ai-memory-system)
10. [Proactive Engine](#proactive-engine)
11. [Backend Integration](#backend-integration)
12. [Premium Gating](#premium-gating)
13. [Configuration](#configuration)

---

## Overview

Flow AI is FocusFlow's intelligent productivity coach powered by OpenAI's GPT-4o. It provides conversational assistance for managing focus sessions, tasks, and productivity habits with the ability to take direct actions within the app.

### Key Features

- **Conversational Interface** - ChatGPT-style chat with streaming responses
- **26 App Actions** - AI can directly create tasks, start focus sessions, update settings, and more
- **Voice Input** - Hands-free interaction using iOS Speech framework
- **Rich Cards** - Inline displays for tasks, stats, and presets
- **AI Memory** - Learns user preferences and patterns over time
- **Proactive Suggestions** - Intelligent nudges at optimal times
- **Context Awareness** - Full access to user's tasks, progress, and settings

### Pro Feature

Flow AI is a **Pro-only feature**. Non-Pro users see a paywall prompt when accessing the Flow tab.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLOW AI ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          USER INTERFACE                                │ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │                      FlowChatView                               │  │ │
│  │  │                                                                 │  │ │
│  │  │  • Message list with user/AI bubbles                           │  │ │
│  │  │  • Rich inline cards (tasks, stats, presets)                   │  │ │
│  │  │  • Text input field with send button                           │  │ │
│  │  │  • Voice input button                                          │  │ │
│  │  │  • Quick action chips                                          │  │ │
│  │  │  • Typing indicator with animations                            │  │ │
│  │  │                                                                 │  │ │
│  │  └───────────────────────────┬─────────────────────────────────────┘  │ │
│  │                              │                                         │ │
│  │  ┌───────────────────────────┴─────────────────────────────────────┐  │ │
│  │  │                  FlowVoiceInputManager                          │  │ │
│  │  │                                                                 │  │ │
│  │  │  • Speech recognition (SFSpeechRecognizer)                     │  │ │
│  │  │  • Audio level visualization                                   │  │ │
│  │  │  • Real-time transcription                                     │  │ │
│  │  │                                                                 │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                         │
│  ┌─────────────────────────────────┴──────────────────────────────────────┐ │
│  │                         VIEW MODEL LAYER                               │ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │                    FlowChatViewModel                            │  │ │
│  │  │                                                                 │  │ │
│  │  │  • Manages messages array (@Published)                         │  │ │
│  │  │  • Handles user input (text/voice)                             │  │ │
│  │  │  • Coordinates AI requests                                     │  │ │
│  │  │  • Executes returned actions                                   │  │ │
│  │  │  • Manages loading/error states                                │  │ │
│  │  │                                                                 │  │ │
│  │  └───────────────────────────┬─────────────────────────────────────┘  │ │
│  │                              │                                         │ │
│  └──────────────────────────────┼─────────────────────────────────────────┘ │
│                                 │                                            │
│         ┌───────────────────────┼───────────────────────┐                   │
│         ▼                       ▼                       ▼                   │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────────┐   │
│  │  FlowContext    │   │   FlowService   │   │   FlowActionHandler     │   │
│  │   Builder       │   │                 │   │                         │   │
│  │                 │   │  • HTTP POST    │   │  • Executes actions     │   │
│  │  • User data    │   │  • Auth header  │   │  • Task CRUD            │   │
│  │  • Tasks        │   │  • Streaming    │   │  • Focus control        │   │
│  │  • Progress     │   │  • Error        │   │  • Navigation           │   │
│  │  • Presets      │   │    handling     │   │  • Settings updates     │   │
│  │  • Memory       │   │                 │   │                         │   │
│  └────────┬────────┘   └────────┬────────┘   └────────────┬────────────┘   │
│           │                     │                         │                 │
│           └─────────────────────┼─────────────────────────┘                 │
│                                 │                                            │
│                                 ▼                                            │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SUPABASE EDGE FUNCTION                              │ │
│  │                       /functions/ai-chat                               │ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │  1. Validate JWT token                                          │  │ │
│  │  │  2. Parse request (messages, context, tools)                    │  │ │
│  │  │  3. Build system prompt with context                            │  │ │
│  │  │  4. Call OpenAI API (gpt-4o-mini)                              │  │ │
│  │  │  5. Parse tool calls into actions                               │  │ │
│  │  │  6. Return response text + actions array                        │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                        │ │
│  └────────────────────────────────┬───────────────────────────────────────┘ │
│                                   │                                          │
│                                   ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          OPENAI API                                    │ │
│  │                                                                        │ │
│  │  Model: gpt-4o-mini (backend) / gpt-4o (display)                      │ │
│  │  Temperature: 0.6                                                      │ │
│  │  Max tokens: 4,000                                                     │ │
│  │  Tools: 26 function definitions                                        │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## File Structure

### UI Layer (`FocusFlow/Features/AI/Views/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowChatView.swift` | ~1600 | Main chat interface with message list, input field, voice button, quick actions |
| `FlowInlineCards.swift` | ~879 | Rich inline cards for tasks, presets, and stats displayed in AI responses |
| `FlowChatAnimations.swift` | - | UI animations for typing indicators and message transitions |
| `FlowSpotlightIntegration.swift` | - | iOS Spotlight search integration |

### Core Layer (`FocusFlow/Features/AI/Core/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowConfig.swift` | ~158 | Central configuration - API URLs, rate limits, timeouts, feature flags |
| `FlowContextBuilder.swift` | ~440 | Builds rich context including user data, tasks, presets, progress |
| `FlowMessage.swift` | ~341 | Message model with sender, state, actions, attachments |
| `FlowMemoryManager.swift` | ~501 | AI memory system - learns user preferences and patterns |
| `FlowNavigationBridge.swift` | ~295 | Bridges AI navigation requests to app navigation system |
| `FlowAnalytics.swift` | - | Performance monitoring and analytics |

### Actions Layer (`FocusFlow/Features/AI/Actions/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowAction.swift` | ~775 | All action types Flow can execute (tasks, presets, focus, navigation, settings) |
| `FlowActionHandler.swift` | ~1210 | Executes all Flow AI actions within the app |

### Service Layer (`FocusFlow/Features/AI/Services/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowService.swift` | ~643 | Handles HTTP communication with Supabase Edge Function |

### Voice Layer (`FocusFlow/Features/AI/Voice/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowVoiceInputManager.swift` | ~485 | Voice input using iOS Speech framework |

### Proactive Layer (`FocusFlow/Features/AI/Proactive/`)

| File | Lines | Purpose |
|------|-------|---------|
| `FlowProactiveEngine.swift` | ~639 | Intelligent nudge system that learns from user behavior |
| `FlowHints.swift` | - | Contextual hints and suggestions |

### Backend (`supabase/functions/ai-chat/`)

| File | Lines | Purpose |
|------|-------|---------|
| `index.ts` | ~915 | Edge Function - OpenAI API calls, system prompt, tool definitions |

---

## User Interface

### Chat Interface Components

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Header                                │   │
│  │  Flow AI                                    [···] Menu   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Message List                            │   │
│  │                                                          │   │
│  │  ┌──────────────────────────────────────────────────┐   │   │
│  │  │ 🤖 Flow                                          │   │   │
│  │  │ "Good morning! You've got 3 tasks today.         │   │   │
│  │  │  Ready to focus?"                                │   │   │
│  │  │                                                  │   │   │
│  │  │  ┌────────────────────────────────────────────┐ │   │   │
│  │  │  │  📋 Today's Tasks                          │ │   │   │
│  │  │  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │ │   │   │
│  │  │  │  ○ Review project proposal                 │ │   │   │
│  │  │  │  ○ Team standup meeting                    │ │   │   │
│  │  │  │  ○ Prepare presentation slides             │ │   │   │
│  │  │  └────────────────────────────────────────────┘ │   │   │
│  │  └──────────────────────────────────────────────────┘   │   │
│  │                                                          │   │
│  │                    ┌────────────────────────────────┐   │   │
│  │                    │ 👤 You                         │   │   │
│  │                    │ "Start a 25 minute focus       │   │   │
│  │                    │  session for deep work"        │   │   │
│  │                    └────────────────────────────────┘   │   │
│  │                                                          │   │
│  │  ┌──────────────────────────────────────────────────┐   │   │
│  │  │ 🤖 Flow                                          │   │   │
│  │  │ "Done! ⏱️ Started a 25-minute focus session.     │   │   │
│  │  │  Let's crush it!"                                │   │   │
│  │  └──────────────────────────────────────────────────┘   │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Quick Actions                           │   │
│  │  [Start Focus] [My Tasks] [How am I doing?] [Plan Day]  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Input Area                            │   │
│  │  ┌────────────────────────────────────┐  [🎤]  [➤]      │   │
│  │  │ Ask Flow anything...               │                  │   │
│  │  └────────────────────────────────────┘                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Rich Inline Cards

Flow AI displays rich cards for different content types:

**Task Card**
```
┌─────────────────────────────────────────────────┐
│  📋 Today's Tasks                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ○ Review project proposal                      │
│  ✓ Team standup meeting                         │
│  ○ Prepare presentation slides                  │
│                                                 │
│  2 of 3 completed                               │
└─────────────────────────────────────────────────┘
```

**Stats Card**
```
┌─────────────────────────────────────────────────┐
│  📊 Today's Progress                            │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                 │
│  Focus Time        2h 15m                       │
│  Sessions          4                            │
│  Daily Goal        ████████░░  80%              │
│                                                 │
│  🔥 7 day streak                                │
└─────────────────────────────────────────────────┘
```

**Preset Card**
```
┌─────────────────────────────────────────────────┐
│  ⏱️ Focus Presets                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                 │
│  🌲 Deep Work          45 min                   │
│  ⚡ Quick Focus        15 min                   │
│  📖 Study Session      30 min                   │
│                                                 │
│  [▶ Start]                                      │
└─────────────────────────────────────────────────┘
```

---

## AI Tools & Functions

Flow AI has access to **26 tools** that can directly interact with the app:

### Task Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `create_task` | `title`, `notes?`, `reminder?`, `duration?`, `repeatRule?` | Create a new task with optional reminder and recurrence |
| `update_task` | `id` or `title`, `newTitle?`, `notes?`, `reminder?` | Update an existing task by ID or title |
| `delete_task` | `id` or `title` | Delete a task by ID or title |
| `toggle_task_completion` | `id` or `title` | Mark task as complete/incomplete |
| `list_tasks` | `period` | List tasks for period (today/tomorrow/this_week/next_week/upcoming/all) |
| `list_future_tasks` | - | List all upcoming tasks |
| `complete_all_tasks` | - | Mark all tasks as complete |
| `clear_completed_tasks` | - | Delete all completed tasks |

### Focus Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `start_focus` | `minutes`, `presetID?`, `presetName?`, `sessionName?` | Start a focus session |
| `pause_focus` | - | Pause current session |
| `resume_focus` | - | Resume paused session |
| `end_focus` | - | End session early |
| `extend_focus` | `minutes` | Add extra minutes to current session |

### Preset Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `set_preset` | `id` or `name` | Activate a preset without starting |
| `create_preset` | `name`, `durationSeconds`, `soundID?` | Create a new focus preset |
| `update_preset` | `id` or `name`, `newName?`, `durationSeconds?` | Update an existing preset |
| `delete_preset` | `id` or `name` | Delete a preset |

### Settings Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `update_setting` | `setting`, `value` | Update app settings (dailyGoal, theme, soundEnabled, hapticsEnabled, displayName, tagline, focusSound) |

### Stats & Analysis Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `get_stats` | `period` | Get statistics for period (today/week/month/alltime) |
| `analyze_sessions` | - | Provide productivity analysis and recommendations |
| `generate_daily_plan` | - | Generate personalized daily plan |
| `suggest_break` | - | Suggest break based on activity |
| `motivate` | - | Provide personalized motivation |
| `generate_weekly_report` | - | Comprehensive weekly productivity report |
| `show_welcome` | - | Personalized welcome with current status |

### Navigation Functions

| Tool | Parameters | Description |
|------|------------|-------------|
| `navigate` | `screen` | Navigate to screen (focus/tasks/progress/profile/settings/presets/journey/notifications) |
| `show_paywall` | - | Show premium upgrade screen |

### Example Tool Call Flow

```
User: "Create a task to review the quarterly report by Friday"

       │
       ▼

AI determines intent → Calls create_task tool:
{
  "name": "create_task",
  "arguments": {
    "title": "Review quarterly report",
    "reminder": "2026-01-10T09:00:00Z"
  }
}

       │
       ▼

FlowActionHandler executes:
  1. Creates TaskItem with title and reminder
  2. Saves to TasksStore
  3. Schedules notification
  4. Returns success result

       │
       ▼

AI generates response: "Done! ✓ Created 'Review quarterly report' 
with a reminder for Friday at 9 AM."
```

---

## System Prompt

The system prompt defines Flow's personality and behavior guidelines:

### Personality

```
You are Flow, a warm, confident, and concise productivity coach integrated 
into the FocusFlow app. You're professional but friendly - never robotic.
```

### Core Rules

1. **ACTION FIRST** - If something can be done, DO IT with a tool. Don't just describe what you could do.

2. **ACCURACY** - Only use data from context. Never invent statistics, task names, or progress data.

3. **BREVITY** - Keep responses short:
   - Simple confirmations: 1 sentence
   - Explanations: 2-3 sentences max
   - Lists: Clean bullet points

### Formatting Guidelines

| Type | Format |
|------|--------|
| **Confirmations** | One short sentence ("Done! Started a 25-minute focus session.") |
| **Lists** | Bullet points with clean formatting |
| **Progress/Stats** | Card-style format with separators (━━━) |
| **Planning** | Numbered steps with time blocks |
| **Motivation** | 2-3 sentences max, reference actual progress |

### Emoji Usage

- Use 1-2 emojis MAX per response
- Place at beginning or end, not inline
- Celebrate wins genuinely but briefly

### What to Avoid

- Long paragraphs
- Filler words ("Sure!", "Of course!", "Absolutely!")
- Repeating what user said
- Over-explaining simple actions
- Multiple emojis in a row
- Markdown headers (use clean separators instead)

---

## Context Building

The `FlowContextBuilder` assembles rich context sent with each AI request:

### Context Sections

```swift
struct FlowContext {
    // 1. Current Context
    let userName: String           // User's display name
    let currentTime: Date          // Current timestamp
    let dayOfWeek: String          // "Monday", "Tuesday", etc.
    
    // 2. Profile
    let displayName: String
    let selectedTheme: String
    let dailyGoalMinutes: Int
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    
    // 3. Today's Progress
    let todayFocusMinutes: Int
    let todaySessions: Int
    let currentStreak: Int
    let weekTotalMinutes: Int
    let goalProgress: Double       // 0.0 - 1.0
    
    // 4. Tasks
    let todaysTasks: [TaskItem]    // Tasks due today
    let upcomingTasks: [TaskItem]  // Future tasks
    
    // 5. Presets
    let presets: [FocusPreset]     // All user presets with UUIDs
    
    // 6. Recent Sessions
    let recentSessions: [ProgressSession]  // Last few sessions
    
    // 7. Memory
    let preferredFocusDuration: Int?
    let motivationStyle: String?
    let peakProductivityHours: [Int]
    let commonTaskTypes: [String]
    
    // 8. Capabilities
    let availableActions: [String] // What Flow can do
}
```

### Context Limits

| Setting | Value |
|---------|-------|
| Max context characters | 24,000 |
| Context cache duration | 30 seconds |
| Max conversation history | 30 messages |

### Example Context (Formatted for AI)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 CURRENT CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User: Alex
Time: Thursday, January 9, 2026 at 10:30 AM

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 TODAY'S PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Focus Time: 45 minutes
Sessions: 2
Daily Goal: 120 minutes (38% complete)
Current Streak: 7 days 🔥

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TODAY'S TASKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
○ Review project proposal (id: abc-123)
✓ Team standup meeting (id: def-456)
○ Prepare presentation slides (id: ghi-789)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️ PRESETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Deep Work - 45 min (id: preset-001)
• Quick Focus - 15 min (id: preset-002)
• Study Session - 30 min (id: preset-003)
```

---

## Voice Input

### Technology Stack

- **Framework**: iOS Speech Framework (`Speech.framework`)
- **Audio**: AVFoundation (`AVAudioEngine`)
- **Recognition**: `SFSpeechRecognizer` with `SFSpeechAudioBufferRecognitionRequest`

### FlowVoiceInputManager

```swift
@MainActor
final class FlowVoiceInputManager: ObservableObject {
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0.0  // 0.0 - 1.0
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
}
```

### Voice Input Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     VOICE INPUT FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. User taps microphone button                                  │
│           │                                                      │
│           ▼                                                      │
│  2. Check authorization (speech + microphone)                    │
│           │                                                      │
│           ├── Not authorized → Request permission                │
│           │                                                      │
│           ▼                                                      │
│  3. Configure audio session (.record mode)                       │
│           │                                                      │
│           ▼                                                      │
│  4. Install tap on audio engine input node                       │
│           │                                                      │
│           ▼                                                      │
│  5. Start audio engine + recognition task                        │
│           │                                                      │
│           ▼                                                      │
│  6. Stream audio buffers → SFSpeechAudioBufferRecognitionRequest │
│           │                                                      │
│           ▼                                                      │
│  7. Recognition task returns partial transcriptions              │
│     (displayed in real-time)                                     │
│           │                                                      │
│           ▼                                                      │
│  8. User taps "Send" or stops speaking                          │
│           │                                                      │
│           ▼                                                      │
│  9. Final transcription sent to AI                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Voice Input UI

```
┌─────────────────────────────────────────────────────────────────┐
│                                                          [✕]    │
│                                                                 │
│                         ┌─────────┐                             │
│                       ╱           ╲                             │
│                      │  ┌─────┐   │    ← Animated pulse rings   │
│                      │  │ 🎤  │   │      respond to audio level │
│                      │  └─────┘   │                             │
│                       ╲           ╱                             │
│                         └─────────┘                             │
│                                                                 │
│                        Listening...                             │
│                    │││││││││                                    │
│                    ← Animated bars                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ "Start a 25 minute focus session for deep work"         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                    ↑ Real-time transcription                    │
│                                                                 │
│                       [   Send   ]                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## AI Memory System

### FlowMemoryManager

The memory system helps Flow learn user preferences and patterns over time.

```swift
@MainActor
final class FlowMemoryManager: ObservableObject {
    @Published var totalConversations: Int = 0
    @Published var totalSessions: Int = 0
    @Published var positiveInteractions: Int = 0
    @Published var negativeInteractions: Int = 0
    
    @Published var preferredFocusDuration: Int?      // Learned from usage
    @Published var motivationStyle: MotivationStyle? // encouraging/direct
    @Published var actionFrequency: [String: Int] = [:]
    @Published var hourlyPatterns: [Int: Int] = [:]  // Hour → action count
    @Published var commonTaskTypes: [String] = []
    @Published var peakProductivityHours: [Int] = []
}
```

### What Flow Remembers

| Category | Data Points |
|----------|-------------|
| **Usage Stats** | Total conversations, sessions, positive/negative interactions |
| **Focus Patterns** | Preferred duration, common session lengths, peak hours |
| **Communication** | Motivation style preference (encouraging vs. direct) |
| **Tasks** | Common task types, recurring themes |
| **Behavior** | Hourly action patterns, feature usage frequency |

### Memory Persistence

| Setting | Value |
|---------|-------|
| Storage | UserDefaults with versioned keys |
| Conversation summaries | Last 50 retained |
| Pattern data retention | 30 days |
| Session insights | Persisted indefinitely |

### Memory Usage in Context

```swift
// Memory influences AI responses
let memoryContext = """
USER PREFERENCES (learned):
• Preferred focus duration: 25 minutes
• Motivation style: Encouraging
• Peak productivity: 9-11 AM, 2-4 PM
• Common tasks: Code review, Writing, Meetings
"""
```

---

## Proactive Engine

### FlowProactiveEngine

The proactive engine provides intelligent nudges at optimal times without being intrusive.

```swift
@MainActor
final class FlowProactiveEngine: ObservableObject {
    @Published var currentInsight: FlowInsight?
    @Published var nudgeCount: Int = 0
    
    private let maxNudgesPerDay = 10
    private let analysisInterval: TimeInterval = 300  // 5 minutes
}
```

### Insight Types

| Type | Trigger | Example Message |
|------|---------|-----------------|
| `optimalTime` | User's productive hour detected | "It's 9 AM - your most productive hour! Perfect time to focus." |
| `habitReminder` | User usually focuses at this time | "You typically start a focus session around now. Ready?" |
| `goalProgress` | Close to daily goal | "Just 15 more minutes to hit your daily goal! 💪" |
| `taskReminder` | Important task due soon | "Don't forget: 'Project review' is due in 2 hours." |
| `streakAlert` | Streak at risk | "Quick 15-minute session will keep your 7-day streak alive!" |
| `breakSuggestion` | Extended focus detected | "You've been focused for 90 minutes. Time for a break?" |

### Proactive Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROACTIVE ENGINE FLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Every 5 minutes:                                                │
│           │                                                      │
│           ▼                                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Analyze User Context                        │    │
│  │                                                          │    │
│  │  • Current time vs peak hours                           │    │
│  │  • Daily goal progress                                   │    │
│  │  • Streak status                                         │    │
│  │  • Upcoming tasks                                        │    │
│  │  • Time since last session                               │    │
│  │  • Historical patterns                                   │    │
│  │                                                          │    │
│  └───────────────────────────┬─────────────────────────────┘    │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Check Nudge Eligibility                     │    │
│  │                                                          │    │
│  │  • Under daily limit (10)?                              │    │
│  │  • Enough time since last nudge?                        │    │
│  │  • User not currently in session?                       │    │
│  │  • Insight relevance score high enough?                 │    │
│  │                                                          │    │
│  └───────────────────────────┬─────────────────────────────┘    │
│                              │                                   │
│              ┌───────────────┴───────────────┐                  │
│              │                               │                  │
│              ▼                               ▼                  │
│        Eligible                        Not Eligible             │
│              │                               │                  │
│              ▼                               ▼                  │
│     Show insight card                   Skip cycle              │
│     in Flow tab                                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Backend Integration

### Edge Function (`supabase/functions/ai-chat/index.ts`)

```typescript
// Request structure
interface AIRequest {
  messages: ChatMessage[];
  context: FlowContext;
  tools: ToolDefinition[];
  stream?: boolean;
}

// Response structure
interface AIResponse {
  text: string;
  actions: FlowAction[];
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}
```

### Request Flow

```
iOS App                    Edge Function                 OpenAI
   │                            │                           │
   │  POST /ai-chat             │                           │
   │  Authorization: Bearer JWT │                           │
   │  {messages, context}       │                           │
   │ ─────────────────────────► │                           │
   │                            │                           │
   │                            │  Validate JWT             │
   │                            │  Build system prompt      │
   │                            │  Attach tools             │
   │                            │                           │
   │                            │  POST /chat/completions   │
   │                            │  Authorization: API Key   │
   │                            │ ─────────────────────────►│
   │                            │                           │
   │                            │◄─────────────────────────│
   │                            │  Response + tool calls    │
   │                            │                           │
   │                            │  Parse tool calls         │
   │                            │  Convert to actions       │
   │                            │                           │
   │◄───────────────────────────│                           │
   │  {text, actions}           │                           │
   │                            │                           │
```

### Security

- **JWT Validation**: Edge function validates Supabase JWT token
- **API Key Protection**: OpenAI API key stored in Supabase secrets
- **No Client Exposure**: API keys never sent to or stored on client

---

## Premium Gating

### Implementation

```swift
struct FlowChatView: View {
    @EnvironmentObject private var pro: ProEntitlementManager
    
    var body: some View {
        Group {
            if pro.isPro {
                chatInterface
            } else {
                FlowPaywallPrompt()
            }
        }
    }
}
```

### Gating Points

| Feature | Free | Pro |
|---------|------|-----|
| Flow AI Access | ❌ | ✅ |
| Voice Input | ❌ | ✅ |
| Proactive Insights | ❌ | ✅ |
| AI Memory | ❌ | ✅ |
| Function Calling | ❌ | ✅ |

### Paywall Contexts

```swift
enum PaywallContext {
    case ai           // "Unlock Flow AI"
    case preset       // "Unlock custom presets"
    case theme        // "Unlock premium themes"
    case stats        // "Unlock detailed stats"
    case general      // "Upgrade to Pro"
}
```

---

## Configuration

### FlowConfig Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `model` | `gpt-4o-mini` | OpenAI model (backend) |
| `displayModel` | `gpt-4o` | Model shown to users |
| `temperature` | `0.6` | Response creativity (0-1) |
| `maxTokens` | `4,000` | Max response length |
| `streamingEnabled` | `false` | Streaming disabled for stability |
| `requestTimeout` | `60s` | HTTP request timeout |
| `streamTimeout` | `90s` | Streaming response timeout |
| `voiceInputEnabled` | `true` | Voice input feature flag |
| `proactiveEnabled` | `true` | Proactive suggestions flag |
| `memoryEnabled` | `true` | AI memory feature flag |
| `memoryRetention` | `30 days` | How long patterns are retained |

### Rate Limits (Configured but Pro-gated)

| Tier | Messages/Minute | Messages/Day |
|------|-----------------|--------------|
| Free | 5 | 25 |
| Pro | Unlimited | Unlimited |

---

## Related Documentation

- [iOS App Documentation](./IOS_APP.md) - Full iOS app architecture
- [Backend Documentation](./Backend.md) - Supabase and Edge Functions
- [Architecture Documentation](./ARCHITECTURE.md) - System design overview
