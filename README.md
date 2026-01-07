# FocusFlow - Comprehensive Application Overview

**FocusFlow** is a **cross-platform productivity app** that combines Pomodoro-style focus timers with AI-powered task management and multi-device cloud synchronization.

**Current Date**: January 7, 2026  
**Latest Version**: v2.0+ (Supabase V2 Architecture)

---

## 📋 Quick Navigation

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete technical architecture & system design
2. **[FEATURES.md](FEATURES.md)** - All features explained (Free & Pro)
3. **[PRO_VS_FREE.md](PRO_VS_FREE.md)** - Pricing comparison & monetization strategy
4. **[CLOUD_SYNC.md](CLOUD_SYNC.md)** - Data synchronization & cloud infrastructure
5. **[AI_FLOW.md](AI_FLOW.md)** - Focus AI assistant (GPT-4o powered)
6. **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Supabase tables & data models
7. **[API_REFERENCE.md](API_REFERENCE.md)** - REST API endpoints & edge functions

---

## 🎯 What is FocusFlow?

FocusFlow is a **comprehensive productivity ecosystem** designed to help users:

- ✅ **Focus Better** - Distraction-free Pomodoro timer with ambient sounds & visuals
- ✅ **Manage Tasks** - Organize, prioritize, and track task completion with reminders
- ✅ **Track Progress** - XP system, streaks, levels, journey reviews (Pro)
- ✅ **Sync Everywhere** - iPhone, iPad, Mac (future) with bidirectional cloud sync
- ✅ **Use AI** - GPT-4o powered "Flow" assistant for smart task management
- ✅ **Customize Experience** - 10+ themes, 11+ sounds, 14+ ambient backgrounds

---

## 🏗️ System Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                     FocusFlow App (SwiftUI)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Features:                                                  │
│  ├─ Focus Timer (Audio + Visual)                           │
│  ├─ Task Management (CRUD + Sync)                          │
│  ├─ Presets (Pomodoro Variants)                            │
│  ├─ Progress Tracking (XP, Levels, Streaks)                │
│  ├─ AI Chat (Flow) - GPT-4o                                │
│  ├─ Notifications (Local + In-App)                         │
│  ├─ Widgets (Small, Medium, Large) + Live Activity         │
│  └─ Onboarding (Multi-step setup flow)                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│           Core Infrastructure (Swift)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Local Managers:                                            │
│  ├─ TasksStore (Observable state)                          │
│  ├─ FocusTimerViewModel (Session management)               │
│  ├─ JourneyManager (Analytics & summaries)                 │
│  ├─ NotificationPreferencesStore (User prefs)              │
│  └─ ProGatingHelper (Free vs Pro logic)                    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│         Cloud Infrastructure (Supabase V2)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Authentication:                                            │
│  ├─ AuthManagerV2 (Auth state machine)                     │
│  └─ Session token persistence                              │
│                                                             │
│  Sync Engines (Pro only):                                   │
│  ├─ TasksSyncEngine ↔ tasks table                          │
│  ├─ SessionsSyncEngine ↔ focus_sessions table              │
│  ├─ PresetsSyncEngine ↔ focus_presets table                │
│  ├─ SettingsSyncEngine ↔ user_settings table               │
│  └─ Conflict Resolution (timestamp-based)                  │
│                                                             │
│  Infrastructure:                                            │
│  ├─ SyncCoordinator (Orchestration)                        │
│  ├─ SyncQueue (Offline-safe persistence)                   │
│  └─ LocalTimestampTracker (Merge logic)                    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│         AI Backend (Supabase Edge Function)                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Flow Service:                                              │
│  ├─ Message handling (non-streaming + streaming)           │
│  ├─ Action execution (create/update/delete)                │
│  ├─ Context building (smart, lazy-loaded)                  │
│  └─ Session management (multi-turn conversations)          │
│                                                             │
│  GPT-4o Integration:                                        │
│  ├─ System prompt (productivity coach)                      │
│  ├─ Function calling (OpenAI tools)                        │
│  └─ Token management (2000 token limit)                    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│    Supabase PostgreSQL Database                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Tables:                                                    │
│  ├─ users (Auth profiles)                                  │
│  ├─ tasks (All user tasks)                                 │
│  ├─ task_completions (Completion records)                  │
│  ├─ focus_sessions (Session history)                       │
│  ├─ focus_presets (Custom presets)                         │
│  └─ user_settings (Preferences & goals)                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **iPhone** | ✅ Fully Supported | Primary platform, optimized for all versions |
| **iPad** | ✅ Fully Supported | Tablet-optimized UI for larger screens |
| **Mac** | 🔄 Planned | Coming in future versions |
| **Web** | ✅ Webapp (Next.js) | Management dashboard at `focusflow-webapp/` |
| **Marketing Site** | ✅ Next.js | Landing page at `focusflow-site/` |

---

## 🔐 Authentication & Authorization

### **Sign-In Methods**
- ✅ **Email/Password** (Supabase Auth)
- ✅ **Google OAuth** (OAuth2)
- ✅ **Apple Sign-In** (OAuth2)
- ✅ **Guest Mode** (Local-only, no account needed)

### **Pro Status Handling**
- Pro status determined by StoreKit 2 subscription
- Supabase mirrors subscription state in `users.is_pro` table
- Free users can still pull cloud data (read-only)
- Pro users get full bidirectional sync

---

## 💾 Data Storage Strategy

### **Local Storage (All Users)**
```
UserDefaults with namespaced keys:
├─ focusflow_tasks_state_guest (Guest mode)
├─ focusflow_tasks_state_cloud_{userId} (After sign-in)
├─ focusflow_presets_state_{namespace}
├─ focusflow_sessions_state_{namespace}
├─ focusflow_settings_{namespace}
└─ focusflow_goal_history_{namespace}
```

### **Cloud Storage (Pro Only for Push)**
```
Supabase PostgreSQL:
├─ users table (auth + metadata)
├─ tasks table (with updated_at for conflicts)
├─ task_completions table (daily tracking)
├─ focus_sessions table (with duration & preset)
├─ focus_presets table (custom presets)
└─ user_settings table (goals, notifications, preferences)
```

### **Conflict Resolution**
- **Strategy**: Last-write-wins (timestamp-based)
- **Field**: `updated_at` on all tables
- **Process**: During initial pull, newer cloud data overwrites local
- **Ongoing**: Periodic sync every 30 seconds (configurable)

---

## 🎮 Core Features Breakdown

### **1. Focus Timer**
- **Duration**: 5 - 90 minutes (customizable)
- **Audio**: 11+ ambient sounds (Pro)
- **Visual**: 14+ background modes (Pro)
- **Controls**: Start, Pause, Resume, Stop
- **Persistence**: Survives app close/lock
- **Statistics**: Logged as FocusSession with duration, preset, sound

### **2. Task Management**
- **Free**: 3 active tasks maximum
- **Pro**: Unlimited active tasks
- **Features**: 
  - Create, edit, complete, delete
  - Set due dates & reminders
  - Repeat rules (daily, weekly, etc)
  - Drag-to-reorder
  - Unlimited completed task history
  - Batch operations (Pro AI feature)

### **3. Focus Presets**
- **Free**: 3 default presets (Deep Work, Study, Writing)
- **Pro**: Create unlimited custom presets
- **Configuration**: Duration, sound, ambiance mode
- **Quick Access**: Tap preset to start session instantly
- **Recommendations**: Flow AI suggests presets based on time of day

### **4. Progress Tracking (Pro)**
- **XP System**: Earn points per focus minute
- **Levels**: 50 levels total (unlocked progressively)
- **Streaks**: Consecutive days with focus activity
- **Journey View**: Daily summaries + weekly reviews
- **Analytics**: 
  - Total focus time (this week, month, all-time)
  - Most-used presets & sounds
  - Best focus day/time
  - Task completion rate
  - Productivity trends

### **5. Focus AI (Flow) - Pro Only**
- **Model**: GPT-4o (most advanced OpenAI model)
- **Access**: "Flow" tab + Spotlight bubble overlay
- **Capabilities**:
  - ✅ Create multiple tasks in one message
  - ✅ Update tasks with natural language
  - ✅ Delete/complete tasks
  - ✅ Recommend presets & session lengths
  - ✅ Show productivity insights
  - ✅ Start focus sessions
  - ✅ Voice input (speak instead of type)
  - ✅ Remember conversation history
  - ✅ Proactive hints & nudges

### **6. Cloud Sync (Pro)**
- **Bidirectional**: Local ↔ Cloud (real-time)
- **Engines**: 4 sync engines (tasks, sessions, presets, settings)
- **Queue**: Offline-safe persistence queue
- **Conflict Resolution**: Timestamp-based merge
- **Merge Strategy**: >7 days offline triggers smart merge
- **Devices**: iPhone, iPad, Mac (future)

### **7. Notifications**
- **Local Notifications**: System notifications for reminders
- **In-App Notifications**: Toast-style messages
- **Types**: Task reminders, streak milestones, achievement unlocks
- **Customization**: Per-feature toggle in settings

### **8. Widgets**
- **Small**: View focus stats (Free)
- **Medium**: Tasks list + stats (Pro)
- **Large**: Weekly overview (Pro)
- **Interactive**: Start/stop sessions from widget (Pro)
- **Live Activity**: Dynamic Island integration (Pro)

---

## 💳 Monetization Model

### **Free Tier Features**
- ✅ Full focus timer
- ✅ 3 active tasks
- ✅ 1 task reminder
- ✅ 3 default presets
- ✅ 2 themes
- ✅ 3 sounds
- ✅ 3 ambient modes
- ✅ Small widget (view-only)
- ✅ 3 days session history
- ✅ Cloud data pull (one-time, read-only)
- ✅ Local data storage

### **Pro Subscription ($59.99/year)**
- ✅ Everything in Free, plus:
- ✅ Unlimited active tasks
- ✅ Unlimited reminders
- ✅ Unlimited custom presets
- ✅ 10 total themes (8 premium)
- ✅ 11 total sounds (8 premium)
- ✅ 14 total ambient modes (11 premium)
- ✅ All widgets (interactive)
- ✅ Live Activity + Dynamic Island
- ✅ Full session history (all-time)
- ✅ Bidirectional cloud sync
- ✅ Multi-device support
- ✅ XP & Levels system
- ✅ Journey view & analytics
- ✅ Focus AI (Flow) - GPT-4o
- ✅ Voice input
- ✅ External music (Spotify, Apple Music)
- ✅ Early access to new features

### **Paywall Contexts**
When users hit a Pro feature, a context-aware paywall appears:
- `task` - "Unlock Unlimited Tasks"
- `preset` - "Create Unlimited Presets"
- `theme` - "Unlock All 10 Themes"
- `sound` - "Unlock All 11 Sounds"
- `ambiance` - "Unlock All 14 Backgrounds"
- `history` - "Your Complete History"
- `xpLevels` - "Track Your Progress"
- `journey` - "Your Focus Journey"
- `widget` - "Interactive Widgets"
- `liveActivity` - "Focus from Dynamic Island"
- `externalMusic` - "Connect Your Music"
- `cloudSync` - "Sync Everywhere"
- `ai` - "Focus AI Assistant"

---

## 🗂️ Project Structure

```
FocusFlow/
├── FocusFlow/                           # iOS App (SwiftUI)
│   ├── App/
│   │   ├── FocusFlowApp.swift          # App entry point
│   │   ├── AppDelegate.swift           # Lifecycle management
│   │   ├── AppSyncManager.swift        # Notification bridge
│   │   ├── ContentView.swift           # Main navigation
│   │   ├── FocusFlowLaunchView.swift   # Splash screen
│   │   └── PremiumAppBackground.swift  # Theme backgrounds
│   │
│   ├── Core/                            # Core systems
│   │   ├── AppSettings/                # App configuration
│   │   ├── Logging/                    # Debug logging
│   │   ├── Notifications/              # Push notifications
│   │   ├── UI/                         # Shared UI components
│   │   └── Utilities/                  # Helper functions
│   │
│   ├── Features/                        # Feature modules
│   │   ├── Focus/                      # Pomodoro timer + sounds
│   │   ├── Tasks/                      # Task management
│   │   ├── Presets/                    # Focus presets editor
│   │   ├── AI/                         # GPT-4o Flow assistant
│   │   │   ├── Service/               # API communication
│   │   │   ├── Core/                  # Business logic
│   │   │   ├── Actions/               # Task actions
│   │   │   ├── Proactive/             # Hints & nudges
│   │   │   ├── Voice/                 # Voice input
│   │   │   └── UI/                    # Chat interface
│   │   ├── Progress/                   # XP, levels, streaks
│   │   ├── Journey/                    # Analytics & reviews
│   │   ├── Profile/                    # Settings & account
│   │   ├── Auth/                       # Sign-in / sign-out
│   │   ├── Settings/                   # App preferences
│   │   ├── Onboarding/                 # First-run experience
│   │   └── NotificationsCenter/        # Notification UI
│   │
│   ├── Infrastructure/                  # Backend integration
│   │   └── Cloud/
│   │       ├── SupabaseManager.swift   # Supabase client
│   │       ├── AuthManagerV2.swift     # Auth state machine
│   │       ├── SyncCoordinator.swift   # Sync orchestration
│   │       ├── SyncQueue.swift         # Offline-safe queue
│   │       ├── Engines/                # 4 sync engines
│   │       └── GuestMigrationManager.swift
│   │
│   ├── Shared/                          # Shared types
│   │   ├── FocusSessionAttributes.swift # Live Activity
│   │   ├── FocusSessionBridge.swift     # Widget bridge
│   │   └── Intents/                     # AppKit intents
│   │
│   ├── Resources/                       # Assets
│   │   └── Localizable.strings
│   │
│   └── StoreKit/                        # In-app purchases
│       ├── ProEntitlementManager.swift  # Store management
│       └── PaywallView.swift            # Purchase UI
│
├── FocusFlowWidgets/                    # Widget extension
│   ├── FocusFlowWidget.swift            # Widget definitions
│   ├── FocusSessionLiveActivity.swift   # Live Activity
│   ├── WidgetDataProvider.swift         # Data bridge
│   └── Assets/
│
├── focusflow-webapp/                    # Web dashboard (Next.js)
│   ├── app/                            # Next.js app router
│   ├── components/                      # React components
│   ├── contexts/                        # React contexts
│   ├── hooks/                           # Custom hooks
│   ├── lib/                             # Utilities
│   ├── stores/                          # Zustand state (optional)
│   └── types/                           # TypeScript types
│
├── focusflow-site/                      # Marketing site (Next.js)
│   ├── app/                            # Homepage + pages
│   ├── components/                      # Marketing components
│   ├── lib/                             # Utilities
│   └── public/                          # Static assets
│
├── supabase/                            # Database + Edge Functions
│   ├── config.toml                      # Supabase config
│   ├── functions/                       # Edge functions
│   │   └── flow/                       # GPT-4o endpoint
│   └── migrations/                      # SQL migrations
│
└── FocusFlow.xcodeproj/                 # Xcode project

```

---

## 🔄 Data Flow Example

### **Creating a Task (Free User)**
```
User taps "+" in Tasks tab
  ↓
TasksView sends FFTaskItem to TasksStore
  ↓
TasksStore updates local state (@Published)
  ↓
TasksStore saves to UserDefaults (guest namespace)
  ↓
UI re-renders, task appears in list
  ✅ Done - No cloud sync
```

### **Creating a Task (Pro User, Signed In)**
```
User taps "+" in Tasks tab
  ↓
TasksView sends FFTaskItem to TasksStore
  ↓
TasksStore updates local state (@Published)
  ↓
TasksStore saves to UserDefaults (cloud namespace)
  ↓
AppSyncManager observes local change
  ↓
SyncQueue queues PUSH operation
  ↓
Background process sends to Supabase
  ↓
TasksSyncEngine updates tasks table
  ↓
Other devices' TasksSyncEngine pulls change (periodic)
  ↓
Tasks appear on all devices
  ✅ Done - Full sync
```

### **Completing a Focus Session (Pro User)**
```
Session timer completes
  ↓
FocusTimerViewModel logs FocusSession
  ↓
Session saved to local UserDefaults
  ↓
AppSyncManager notifies JourneyManager
  ↓
JourneyManager updates XP, streak, level
  ↓
SyncQueue queues PUSH for both
  ↓
SessionsSyncEngine + SettingsSyncEngine push to cloud
  ↓
Next sync, other devices pull session
  ↓
XP/streak updates appear everywhere
  ✅ Done - Cross-device achievement
```

---

## 🚀 Getting Started for Developers

### **Prerequisites**
- Xcode 15+ with iOS 16+ deployment target
- CocoaPods (for dependencies)
- Supabase project with API keys
- OpenAI API key (for Flow AI)
- StoreKit configuration for testing purchases

### **Setup Steps**
1. Clone the repository
2. Create `Config.xcconfig` with API keys
3. Run `pod install` (if using CocoaPods)
4. Open `FocusFlow.xcodeproj` in Xcode
5. Select target and run on simulator/device

### **Key Configuration**
- `FlowConfig.swift` - All API endpoints
- `ProGatingHelper.swift` - Free/Pro limits
- `AppSettings.swift` - Default preferences

---

## 📊 Key Metrics & KPIs

### **User Engagement**
- Daily active users (DAU)
- Weekly active users (WAU)
- Session completion rate (%)
- Average session duration
- Focus time per user (minutes/day)

### **Task Management**
- Tasks created per user
- Task completion rate (%)
- Active task count (average)
- Reminder engagement (%)

### **Monetization**
- Free to Pro conversion rate (%)
- Pro subscriber count
- Churn rate
- Lifetime value (LTV)
- Paywall context performance

### **Quality**
- Crash rate
- App launch time
- Sync success rate
- Data consistency rate

---

## 🔒 Security & Privacy

### **Authentication**
- ✅ Supabase Auth (industry-standard)
- ✅ OAuth2 for third-party providers
- ✅ Secure token storage (Keychain)
- ✅ Token refresh on demand

### **Data Protection**
- ✅ HTTPS for all API calls
- ✅ Row-level security (RLS) on Supabase
- ✅ User data isolated by user_id
- ✅ No tracking without consent

### **Privacy**
- ✅ Local-first storage (before sign-in)
- ✅ Optional cloud sync
- ✅ Clear data deletion on sign-out
- ✅ GDPR-compliant data handling

---

## 📖 Documentation Files

This README provides the overview. See detailed docs for:

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical deep-dive into system design
2. **[FEATURES.md](FEATURES.md)** - Complete feature list with examples
3. **[PRO_VS_FREE.md](PRO_VS_FREE.md)** - Monetization & pricing details
4. **[CLOUD_SYNC.md](CLOUD_SYNC.md)** - Sync architecture & conflict resolution
5. **[AI_FLOW.md](AI_FLOW.md)** - Focus AI system & capabilities
6. **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Supabase table structures
7. **[API_REFERENCE.md](API_REFERENCE.md)** - REST API & edge function docs

---

## 🤝 Contributing

Developers should:
1. Follow existing code structure
2. Use reactive patterns (Combine, @Published)
3. Implement proper error handling
4. Add unit tests for business logic
5. Document complex features
6. Use meaningful commit messages

---

## 📄 License

All rights reserved. FocusFlow is proprietary software.

---

**Last Updated**: January 7, 2026  
**Status**: Production Ready (v2.0+)
