# FocusFlow - Complete Feature Documentation

**Comprehensive guide to every feature in FocusFlow**

---

## 🎯 Feature Categories

1. **Core Focus** - Timer, sounds, visual modes
2. **Task Management** - Creation, tracking, reminders
3. **Progress Tracking** - XP, levels, streaks, journey
4. **AI Assistant** - GPT-4o powered Flow
5. **Cloud Sync** - Multi-device synchronization
6. **Notifications** - Reminders and alerts
7. **Widgets** - Home screen integration
8. **Customization** - Themes, sounds, preferences
9. **Onboarding** - First-time setup
10. **Social** - Sharing and community

---

## 🔴 Core Focus Feature

### **Focus Timer**

**Purpose**: Timed focus sessions with ambient sound and visual effects

**Functionality**:
- ✅ Customizable duration (5-90 minutes)
- ✅ Start, pause, resume, stop controls
- ✅ Real-time countdown display
- ✅ Optional ambient sound (11 total sounds in Pro)
- ✅ Optional background mode (14 ambient backgrounds in Pro)
- ✅ Sound control (mute, volume)
- ✅ Survives app close/lock
- ✅ Completion tracking

**How It Works**:
```
1. User opens Focus tab
2. User selects:
   - Duration (default 25 min)
   - Preset (which includes duration)
   - Sound (from available list)
   - Ambient mode (background visual)
3. User taps "Start Session"
4. Timer begins counting down
5. Sound plays continuously
6. Background animates
7. When complete:
   - Sound stops
   - Notification appears
   - Session logged
   - XP earned
   - Journey updated
```

**Free vs Pro**:
| Feature | Free | Pro |
|---------|------|-----|
| Timer access | ✅ | ✅ |
| Duration range | ✅ 5-90 min | ✅ 5-90 min |
| Default sounds | ✅ 3 | ✅ 11 |
| Ambient modes | ✅ 3 | ✅ 14 |
| External music | ❌ | ✅ Spotify/Apple Music |
| Multiple concurrent | ❌ | ❌ (1 per device) |

**Technical Details**:
```swift
// Located in: FocusFlow/Features/Focus/FocusTimerViewModel.swift
@MainActor
final class FocusTimerViewModel: ObservableObject {
    @Published var totalSeconds: Int
    @Published var remainingSeconds: Int
    @Published var phase: Phase // idle, running, paused, completed
    
    func start(seconds: Int, preset: FocusPreset)
    func pause()
    func resume()
    func stop()
    func logSession()
}
```

**Session Logging**:
When a session completes, it's stored as FocusSession:
```swift
struct FocusSession {
    let id: UUID
    let duration: Int              // seconds
    let presetUsed: FocusPreset    // which preset
    let soundUsed: FocusSound      // which sound
    let ambientMode: AmbientMode   // which background
    let startTime: Date
    let endTime: Date
    let wasCompleted: Bool         // vs manual stop
    let completedEarly: Bool       // if stopped before 40%
}
```

---

### **Ambient Sounds**

**Audio Library**:

**Free (3 sounds)**:
1. Light Rain - Peaceful, gentle ambient
2. Fireplace - Warm, cozy crackling
3. Sound Ambience - Generic ambient tone

**Pro Additional (8 sounds)**:
4. Coffee Shop - Bustling café sounds
5. White Noise - Pure white noise
6. Ocean Waves - Rhythmic wave sounds
7. Thunderstorm - Intense weather sounds
8. Pink Noise - Softer white noise
9. Brown Noise - Deep, rumbling noise
10. Forest - Birds and nature sounds
11. Wind - Gentle wind through trees

**Audio Quality**:
- 128 kbps AAC codec
- Looped seamlessly (no interruptions)
- Volume adjustable in-app
- Mute available anytime

**Persistence**:
- Last used sound remembered
- Can set as "always use" for session type
- Per-preset sound selection

---

### **Ambient Visual Backgrounds**

**Purpose**: Immersive visual experiences during focus

**Free (3 modes)**:
1. **Minimal** - Clean, flat color (theme-dependent)
2. **Stars** - Twinkling stars on dark background
3. **Forest** - Tree silhouettes

**Pro Additional (11 modes)**:
4. **Ocean** - Waves and water
5. **Desert** - Sand dunes at sunset
6. **Mountains** - Snowy peaks
7. **Northern Lights** - Aurora borealis animation
8. **Cherry Blossom** - Falling sakura petals
9. **Rain** - Animated raindrops
10. **Snow** - Falling snowflakes
11. **Sunset** - Gradient sunset colors
12. **Fireplace** - Animated fire
13. **Clouds** - Floating clouds
14. **Sakura** - Pink blossoms

**Visual Effects**:
- Smooth 60 FPS animations
- Battery-optimized (stops animating when inactive)
- Themed colors (respect app theme)
- Full-screen immersive

---

### **Focus Presets**

**Purpose**: Save common session configurations for quick access

**Default Presets (Free)**:
```
1. Deep Work
   Duration: 50 minutes
   Sound: Light Rain
   Ambiance: Forest
   Description: "Deep concentration session"

2. Study
   Duration: 45 minutes
   Sound: Coffee Shop
   Ambiance: Minimal
   Description: "Academic focus"

3. Writing
   Duration: 60 minutes
   Sound: Fireplace
   Ambiance: Minimal
   Description: "Creative writing session"
```

**Custom Presets (Pro)**:
- Unlimited custom presets
- Full customization (duration, sound, ambiance)
- Drag-to-reorder
- Quick favorites

**UI Flow**:
```
Focus Tab
├─ [Preset 1] - Duration | Sound | Ambiance
├─ [Preset 2]
├─ [Preset 3]
├─ [+ Add Custom] (Pro only, after 3 created)
├─ [Edit Preset] (long press)
└─ Confirm selection → Start
```

**Preset Usage**:
- Quick-tap to start session immediately
- Preset info shown before starting
- Can override duration before start
- Saved sessions track which preset used

---

## ✅ Task Management Feature

### **Task Creation**

**Basic Task**:
```swift
struct FFTaskItem {
    let id: UUID
    var title: String              // Required
    var description: String?       // Optional
    var dueDate: Date?            // Optional
    var reminderDate: Date?       // When to remind
    var isCompleted: Bool         // Completion status
    var repeatRule: FFTaskRepeatRule
    var sortIndex: Int            // Drag-to-reorder
    var createdAt: Date
    var updatedAt: Date           // For sync conflict resolution
}
```

**Repeat Rules**:
```swift
enum FFTaskRepeatRule: String, CaseIterable {
    case none                // One-time task
    case daily              // Every day
    case weekdays           // Mon-Fri only
    case weekends           // Sat-Sun only
    case weekly(dayOfWeek)  // Specific day each week
    case biweekly
    case monthly            // Same day each month
}
```

**Creation Flow**:
```
Tasks Tab → "+" Button
├─ Title input (required)
├─ Description (optional)
├─ Due date picker (optional)
├─ Reminder toggle + date
├─ Repeat rule selector
├─ Color/tag selector (future)
└─ Save

Free limit: 3 active tasks
Pro limit: Unlimited
```

---

### **Task Display & Organization**

**Views**:
1. **Today View** - Tasks due today
2. **Upcoming** - Next 14 days
3. **All Tasks** - No date filter
4. **Completed** - Historical completions

**Sorting**:
- Primary: Due date (early to late)
- Secondary: Sort index (drag-to-reorder)
- Tertiary: Creation date

**Grouping**:
- By date (Today, Tomorrow, This Week, Later)
- By status (Active, Completed)
- Collapsible sections

---

### **Task Completion**

**Marking Complete**:
- Swipe left to mark done
- Checkbox tap
- Pinch gesture
- Flow AI command

**Completion Tracking**:
```
Task completion recorded as:
├─ completion_date (which day)
├─ completion_time (optional)
└─ session_context (if completed during focus)
```

**UI Feedback**:
- Task moves to "Completed" section
- Strikethrough effect
- XP reward notification (Pro)
- Streak increment check

---

### **Task Reminders**

**Free**: 1 total reminder across all tasks  
**Pro**: Unlimited reminders

**Reminder Types**:
- **Date/Time** - Specific day & time
- **Before Due** - X hours before due date
- **Repeat Reminders** - Daily/weekly repeating

**Notification**:
```
User taps reminder in settings
    ↓
System notification scheduled (local)
    ↓
At scheduled time:
  - Notification appears
  - Sound plays (if enabled)
  - Can open app from notification
```

**Implementation**:
```swift
// Located in: FocusFlow/Features/Tasks/TaskReminderScheduler.swift
final class TaskReminderScheduler: ObservableObject {
    func scheduleReminder(for task: FFTaskItem)
    func cancelReminder(taskId: UUID)
    func updateReminder(for task: FFTaskItem)
}
```

---

### **Task Deletion**

**Methods**:
- Swipe left → Delete option
- Long-press → Context menu → Delete
- Edit mode → Select multiple → Delete

**Behavior**:
- Immediate removal from local state
- Queued for cloud deletion (Pro)
- Completion records preserved (for analytics)
- Undo available for 5 seconds

---

## 📊 Progress Tracking (Pro Only)

### **XP System**

**XP Earning**:
- 1 XP = 1 minute of focus time
- 25-minute session = 25 XP (minimum)
- 90-minute session = 90 XP (maximum)
- Bonus XP for streaks (5% bonus per streak day)
- Bonus XP for hitting daily goal

**Example**:
```
Session 1: 25 min focused
  → 25 XP earned

Session 2: 45 min focused + 5-day streak
  → 45 XP + (45 × 5% = 2.25) = 47.25 XP

Total today: 72 XP
```

---

### **Level System**

**Progression**:
- Level 1-10: 100 XP per level
- Level 11-20: 150 XP per level
- Level 21-30: 200 XP per level
- Level 31-40: 250 XP per level
- Level 41-50: 300 XP per level

**Total XP to Max**:
```
L1-10: 1,000 XP
L11-20: 1,500 XP
L21-30: 2,000 XP
L31-40: 2,500 XP
L41-50: 3,000 XP
────────────
Total: 10,000 XP (estimated)
```

**Level Rewards**:
- Visual progression bar
- Achievement badges (every 5 levels)
- Leaderboard rank (future)
- Special theme unlock (future)

---

### **Streak System**

**How Streaks Work**:
- Streak = consecutive days with focus activity
- Any focus session = day marked active
- Miss a day = streak broken, reset to 0
- Can maintain on rest days if you used focus (future: rest day toggle)

**Streak Milestones**:
```
Day 1:  🔥 "First step!"
Day 7:  🔥 "One week of focus!"
Day 14: 🔥 "Two weeks strong!"
Day 30: 🔥 "One month challenge!"
Day 100: 🔥 "Century club!"
```

**Notifications**:
- Milestone achievements
- Daily reminder (at preferred time)
- End-of-day summary

---

### **Journey View (Analytics Dashboard)**

**Components**:

#### **Daily Summary Card**
```
Today: January 7, 2025

📊 Focus Time: 2h 45m
🎯 Sessions: 3
⏱️  Longest: 45 minutes
✅ Tasks: 4/8 completed

🔥 Streak: 12 days
⭐ XP Today: 165 XP
📈 Level: 15 (42% to 16)

💡 "You're most productive in the mornings!
    Consider scheduling deep work then."
```

#### **Weekly Overview**
```
This Week: Jan 1-7, 2025

📊 Total Focus: 18.5 hours
🎯 Sessions: 23
✅ Tasks: 42/56 completed
⭐ XP Earned: 1,100 XP

🏆 Best Day: Wednesday (4.5h)
⏱️  Avg Duration: 48 minutes
🎵 Most Used: Deep Work preset
```

#### **Trends & Insights**
```
Weekly Comparison:
This Week: 18.5h
Last Week: 15.2h
Δ: +3.3h (+22%)

Best Time: 8 AM - 10 AM
Most Used Preset: Deep Work
Most Used Sound: Light Rain
Goal Status: 15/20 hours (75% toward goal)
```

---

### **Goal Setting (Pro)**

**Daily Goal**:
- Set target focus minutes (default: 120)
- Visual progress bar
- Daily reset
- Achievement notification when hit

**Weekly Review**:
- Compare to previous week
- Identify patterns
- AI suggestions (Future: Flow tips)

---

## 🤖 Focus AI Assistant (Flow)

**Status**: Pro Only | Requires Sign-in

### **What is Flow?**

Flow is a GPT-4o powered productivity assistant built directly into FocusFlow. It understands your tasks, focus patterns, and goals to provide personalized guidance.

### **Access Points**

1. **Flow Tab** - Dedicated chat interface
2. **Spotlight Bubble** - Floating AI button (any screen)
3. **Context Hints** - Proactive suggestions
4. **Voice Input** - Speak instead of type

### **Capabilities**

#### **1. Task Management**
```
User: "Create 5 tasks for my morning routine"
Flow: ✅ Creates:
      - Wake up at 6 AM
      - Exercise for 30 minutes
      - Healthy breakfast
      - Review daily goals
      - Check emails

User: "Update all gym tasks to 45 minutes"
Flow: ✅ Batch updates all matching tasks

User: "Delete completed tasks from last week"
Flow: ✅ Removes old completed tasks
```

#### **2. Session Recommendations**
```
User: "What should I focus on?"
Flow: "I see you have 8 tasks. I recommend:
       1. 'Write proposal' (45 min, Deep Work)
       2. 'Review feedback' (15 min, Study)
       
       Ready to start?"

User: "Start 60-minute writing session"
Flow: ✅ Starts 60-min session with Writing preset
```

#### **3. Multi-Step Workflows**
```
User: "Prepare for my presentation tomorrow"
Flow: ✅ Creates task: "Finalize slides"
      ✅ Creates task: "Practice presentation"
      ✅ Sets reminders for both
      ✅ Suggests 90-minute Deep Work preset
      ✅ Offers to start session immediately
      
      All in one conversation!
```

#### **4. Analytics & Insights**
```
User: "How am I doing?"
Flow: "Great! You've completed 2 hours of focus today.
       You're on a 5-day streak! 🔥
       
       You have 3 tasks left:
       - Finish report (30 min)
       - Team meeting prep (15 min)  
       - Email responses (20 min)
       
       Want to tackle the report next?"
```

#### **5. Proactive Suggestions**
```
Morning: "Good morning! You're most productive now.
         Want to start a deep work session?"

After 3 sessions: "🔥 You're on fire! 3 sessions today!"

Evening: "Wrap up? You've earned it! 💪"
```

---

### **Conversation Features**

**Message Types**:
- Text input (typing)
- Voice input (microphone)
- Rich action cards (tap to execute)
- Quick action chips (preset responses)

**Memory**:
- Remembers conversation history
- Context-aware responses
- Learns user preferences over time
- Session state tracking

**Streaming Responses**:
- Real-time typing animation
- More engaging interaction
- Better perceived responsiveness

---

### **Flow Spotlight Bubble**

**Appearance**:
- Floating AI button (any screen)
- Bottom-right corner (customizable)
- Animated pulse when ideas available
- Collapses when not needed

**Interactions**:
- Tap to open chat
- Long-press to quick actions
- Swipe to dismiss
- Settings to customize position

**Quick Actions**:
```
[What should I focus on?]
[Show my progress]
[Create a task]
[Start session]
[Help me organize]
```

---

### **Voice Input**

**How It Works**:
```
User taps microphone icon
    ↓
"Listening..." animation
    ↓
User speaks naturally
    ↓
Transcription via OpenAI Whisper API
    ↓
Flow processes as if typed
    ↓
Response generated
    ↓
Optional: Text-to-speech (future)
```

**Supported Languages**: English (initial), more coming

---

### **Technical Details**

```swift
// Located in: FocusFlow/Features/AI/

Service/FlowService.swift           // API communication
Core/FlowConfig.swift               // Configuration
Core/FlowPerformance.swift          // Optimization
Core/FlowNavigationCoordinator.swift// Navigation logic
Actions/FlowActionHandler.swift     // Action execution
UI/FlowChatView.swift               // Chat interface
UI/FlowChatViewModel.swift          // State management
UI/FlowSpotlight.swift              // Floating bubble
Voice/FlowVoiceInput.swift          // Voice handling
Proactive/FlowProactiveEngine.swift // Hints & nudges
```

---

## ☁️ Cloud Sync (Pro)

**Status**: Pro Only | Requires Sign-in

### **How Sync Works**

**Free User (No Sync)**:
```
Local Edit
    ↓
Saved to UserDefaults
    ↓
[STOP - No cloud push]
```

**Pro User (Full Sync)**:
```
Local Edit
    ↓
Saved to UserDefaults
    ↓
SyncQueue detects change
    ↓
Push to Supabase
    ↓
Cloud updated
    ↓
Other devices pull (every 30s)
    ↓
Devices updated
```

### **Real-World Examples**

**Scenario 1: Create Task on iPhone**
```
iPhone (9:00 AM):
  User creates "Write proposal"
  → Saved locally
  → Queued for sync
  
iPad (9:01 AM):
  Sync pulls from cloud
  → Task appears on iPad
  
Mac (9:02 AM):
  Sync pulls from cloud
  → Task appears on Mac (future)
```

**Scenario 2: Offline Work**
```
iPhone (offline):
  User creates 3 tasks
  → Saved locally
  → Queued for sync
  
iPhone comes online
  → SyncQueue processes
  → All 3 tasks pushed to cloud
  
iPad:
  → Pulls all 3 tasks
  → Synced automatically
```

**Scenario 3: Conflict Resolution**
```
iPad: Edited task at 2:00 PM
      → updated_at: 2:00 PM

iPhone: Edited same task at 1:00 PM
        → updated_at: 1:00 PM

Result: iPad version wins (2:00 PM > 1:00 PM)
        iPhone gets iPad's version next sync
```

---

## 🔔 Notifications System

### **Local Push Notifications**

**Types**:
1. **Task Reminders** - Alert for due task
2. **Streak Milestones** - "7-day streak!"
3. **Achievement Unlocks** - "Level 10!"
4. **Session Complete** - "Great session!"
5. **Goal Reached** - "Daily goal hit!"

**Control**:
- Toggle per type
- Custom sounds
- Grouped notifications
- Time-based delivery

---

### **In-App Notifications**

**Toast Notifications** (pop-up banners):
- "Task created!"
- "Session logged"
- "Achievement unlocked"
- "Synced to cloud"

**Timing**:
- Auto-dismiss after 3 seconds
- Swipe to dismiss
- Tap to expand
- Stacked (multiple can appear)

---

## 🎨 Customization

### **Themes (10 Total)**

**Free (2)**:
1. Forest (green/natural)
2. Neon (bright/vibrant)

**Pro (8 additional)**:
3. Ocean (blues/teals)
4. Sunset (oranges/purples)
5. Midnight (dark/cool)
6. Cherry Blossom (pinks)
7. Lavender (purples)
8. Desert (warm/sandy)
9. Arctic (cool/crisp)
10. Autumn (oranges/reds)

**Customization**:
- Primary color
- Accent color
- Background brightness
- Font size (accessibility)

---

### **Settings & Preferences**

**Appearance**:
- Theme selection
- Font size (for accessibility)
- Dark mode toggle

**Focus**:
- Default duration
- Default sound
- Default ambiance
- Auto-start next session

**Notifications**:
- Reminder toggle
- Sound toggle
- Notification style
- Time windows (quiet hours)

**Privacy**:
- Data tracking consent
- Analytics opt-out
- Cloud backup setting
- Account deletion

---

## 📱 Onboarding Experience

### **First-Time User Flow**

```
Welcome Screen
    ↓
    "What's your focus goal?"
    ├─ Productivity
    ├─ Learning
    ├─ Creativity
    └─ Health
    ↓
    "How long can you focus?"
    ├─ 15-25 minutes
    ├─ 30-45 minutes
    └─ 60+ minutes
    ↓
    "Notification preferences"
    [Allow Push Notifications]
    ↓
    "Quick preferences"
    ├─ Theme selection
    ├─ Sound preference
    └─ Daily goal (minutes)
    ↓
    "Tour: Focus tab demo"
    ↓
    "Tour: Tasks tab demo"
    ↓
    "Tour: Progress tracking (Pro hint)"
    ↓
    "Tour: AI Assistant (Pro hint)"
    ↓
    "Ready to begin!"
```

**Skip Option**: Users can skip steps and access settings later

---

## 🎁 Widgets & Home Screen

### **Small Widget (Free)**

**Display**:
```
┌─────────────────┐
│   FocusFlow     │
│                 │
│  Today: 2h 30m  │
│  Streak: 12 🔥  │
│  Level 15       │
└─────────────────┘
```

**Interaction**: View-only (no controls)

---

### **Medium Widget (Pro)**

**Display**:
```
┌──────────────────────────┐
│   FocusFlow              │
│                          │
│   Today's Tasks:         │
│   ✅ Morning review      │
│   ⏳ Write proposal      │
│   ⏳ Team meeting prep   │
│                          │
│   2h 30m • Streak: 12 🔥 │
└──────────────────────────┘
```

**Interaction**: 
- Tap task to open app
- Tap timer to start session

---

### **Large Widget (Pro)**

**Display**:
```
┌────────────────────────────┐
│   FocusFlow - This Week    │
│                            │
│   Mon  2.5h  ████████      │
│   Tue  3h    ██████████    │
│   Wed  4.5h  █████████████ │
│   Thu  2h    ██████        │
│   Fri  3.5h  ███████████   │
│   Sat  1h    ███           │
│   Sun  1.5h  ████          │
│                            │
│   Total: 18.5h             │
│   Avg: 2.6h/day            │
│   Best: Wednesday 🏆       │
└────────────────────────────┘
```

---

### **Live Activity / Dynamic Island (Pro)**

**Display** (during active session):
```
🎯 Deep Work  [⏸]
25:34 remaining

[Lock to continue]
```

**Actions**:
- Pause session
- View timer
- Quick actions (mute, skip)

---

## 🌐 Web Dashboard (Webapp)

**URL**: focusflow-webapp (Next.js)

**Features**:
- View all tasks (desktop-friendly)
- Create/edit tasks
- View analytics dashboards
- Export data
- Account management
- Download session history

**Tech Stack**:
- Next.js 15+
- React 19
- TailwindCSS
- Supabase client

---

## 🚀 Sharing & Social (Future)

**Planned Features**:
- Share weekly summary
- Compare stats with friends
- Leaderboards
- Group challenges
- Achievement badges

---

**Last Updated**: January 7, 2026  
**Status**: All features documented and current
