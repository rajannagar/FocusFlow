# FocusFlow Web App - Design & Architecture

## 📊 Current App Understanding

### Core Features
1. **Focus Timer**
   - Ambient backgrounds (14 options)
   - Focus sounds (12 ambient tracks)
   - Themes (10 options: Forest, Neon + 8 Pro themes)
   - Custom presets (duration, sound, theme, music app)
   - Pause/resume functionality
   - Live Activities support

2. **Task Management**
   - Tasks with notes
   - Reminders & scheduling
   - Repeat rules (daily, weekly, monthly, yearly, custom days)
   - Series exceptions (Outlook-style)
   - Task-to-preset conversion
   - Duration tracking per task

3. **Progress & Gamification**
   - Focus sessions tracking
   - XP system with 50 levels
   - Streaks (current & best)
   - Daily goals
   - Lifetime statistics
   - Journey visualization

4. **Cloud Sync (Supabase)**
   - Real-time sync across devices
   - Tables: `focus_sessions`, `user_stats`, `focus_presets`, `tasks`, `task_completions`, `user_settings`
   - Conflict resolution with timestamps
   - Guest mode support

### Database Schema
```sql
focus_sessions:
  - id (UUID)
  - user_id (UUID)
  - started_at (timestamp)
  - duration_seconds (int)
  - session_name (text, nullable)
  - created_at, updated_at

user_stats:
  - user_id (UUID)
  - lifetime_focus_seconds (int)
  - lifetime_session_count (int)
  - lifetime_best_streak (int)
  - current_streak (int)
  - last_focus_date (date)
  - total_xp (int)
  - current_level (int)

focus_presets:
  - id (UUID)
  - user_id (UUID)
  - name (text)
  - duration_seconds (int)
  - sound_id (text)
  - emoji (text, nullable)
  - theme_raw (text, nullable)
  - external_music_app_raw (text, nullable)
  - ambiance_mode_raw (text, nullable)

tasks:
  - id (UUID)
  - user_id (UUID)
  - title (text)
  - notes (text, nullable)
  - reminder_date (timestamp, nullable)
  - repeat_rule (text)
  - custom_weekdays (int[])
  - duration_minutes (int)
  - sort_index (int)
  - excluded_day_keys (text[])
  - created_at (timestamp)
```

---

## 🚀 Vision: Next-Generation Web App

### Design Philosophy
**"A web-native experience that amplifies focus, not just replicates mobile"**

The web app should leverage:
- **Larger screens** → Rich data visualization, multi-panel layouts
- **Keyboard shortcuts** → Power user productivity
- **Real-time collaboration** → Future team features
- **Advanced analytics** → Deep insights into focus patterns
- **Browser APIs** → Notifications, audio, background sync

---

## 🎨 Core Design Concepts

### 1. **Command Center Dashboard**
A powerful, information-dense dashboard that gives users complete control:

**Layout:**
- **Left Sidebar**: Navigation, quick stats, shortcuts
- **Main Panel**: Focus timer (large, prominent)
- **Right Panel**: Active tasks, upcoming reminders
- **Bottom Bar**: Recent sessions, quick actions

**Features:**
- Real-time focus timer with ambient background
- Keyboard shortcuts (Space = start/pause, R = reset, etc.)
- Live session stats
- Quick preset selection
- Task quick-add

### 2. **Advanced Analytics & Insights**
Web-native data visualization:

**Insights Dashboard:**
- **Focus Heatmap**: Calendar view showing focus intensity
- **Time Distribution**: Pie/bar charts of focus by time of day
- **Productivity Trends**: Line charts showing focus over time
- **Task Completion Rates**: Success metrics
- **Streak Visualization**: Beautiful streak calendar
- **Level Progress**: XP bar, next level requirements
- **Focus Patterns**: AI-powered insights (best times, most productive days)

**Advanced Features:**
- Export data (CSV, JSON)
- Custom date ranges
- Comparison views (this week vs last week)
- Goal tracking with projections

### 3. **Enhanced Task Management**
Web-optimized task experience:

**Features:**
- **Kanban Board View**: Drag-and-drop task organization
- **Calendar View**: See tasks on calendar with reminders
- **List View**: Traditional list with filters
- **Gantt Chart**: Timeline view for project planning
- **Bulk Actions**: Select multiple tasks, bulk edit/complete
- **Smart Suggestions**: AI-powered task prioritization
- **Task Templates**: Reusable task sets

**Advanced:**
- Task dependencies
- Subtasks
- Task notes with rich text
- File attachments (future)
- Task sharing (future)

### 4. **Focus Timer Enhancements**
Web-specific timer features:

**Features:**
- **Full-screen Focus Mode**: Distraction-free immersive experience
- **Ambient Backgrounds**: Animated, interactive backgrounds
- **Sound Library**: Play focus sounds directly in browser
- **Pomodoro Techniques**: Built-in Pomodoro, Flowtime, etc.
- **Session History**: See all past sessions with details
- **Session Notes**: Add notes after completion
- **Session Tags**: Categorize sessions (work, study, creative, etc.)

**Advanced:**
- **Focus Rooms**: Virtual co-working spaces (future)
- **Focus Challenges**: Community challenges
- **Focus Music Integration**: Spotify/Apple Music web players

### 5. **Real-Time Sync Status**
Transparent sync experience:

**Features:**
- **Sync Indicator**: Visual status of sync state
- **Conflict Resolution UI**: When conflicts occur, show both versions
- **Sync History**: See what synced when
- **Manual Sync**: Force sync button
- **Offline Mode**: Queue changes when offline, sync when back

### 6. **Preset Management**
Advanced preset system:

**Features:**
- **Preset Library**: Visual grid of all presets
- **Preset Editor**: Rich editor with preview
- **Preset Categories**: Organize by type (work, study, break, etc.)
- **Preset Sharing**: Share presets with others (future)
- **Preset Analytics**: See which presets you use most

### 7. **Journey & Gamification**
Enhanced XP system:

**Features:**
- **Level Progress**: Beautiful progress bar, next level requirements
- **Achievements**: Unlock achievements, badges
- **Milestones**: Celebrate milestones (100 sessions, 1000 hours, etc.)
- **Leaderboards**: Compare with friends (future, opt-in)
- **Challenges**: Daily/weekly challenges

### 8. **Settings & Customization**
Comprehensive settings:

**Features:**
- **Appearance**: Theme, accent colors, layout preferences
- **Notifications**: Browser notification settings
- **Keyboard Shortcuts**: Customize all shortcuts
- **Data Management**: Export, import, backup
- **Privacy**: Data deletion, account management
- **Integrations**: Connect other apps (future)

---

## 🏗️ Technical Architecture

### Frontend Stack
- **Next.js 16** (App Router) - Already set up
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling (already configured)
- **Recharts** - Data visualization
- **Zustand** - State management (lightweight, perfect for sync state)
- **React Query** - Server state management & caching
- **Supabase Realtime** - Real-time subscriptions

### Key Libraries to Add
```json
{
  "recharts": "^2.10.0",           // Charts & graphs
  "zustand": "^4.4.0",             // State management
  "@tanstack/react-query": "^5.0.0", // Server state
  "date-fns": "^3.0.0",            // Date utilities
  "framer-motion": "^10.16.0",     // Animations
  "react-hotkeys-hook": "^4.4.0",  // Keyboard shortcuts
  "react-beautiful-dnd": "^13.1.0" // Drag & drop
}
```

### Data Flow
```
User Action → Zustand Store → React Query Mutation → Supabase
                ↓
         Optimistic Update
                ↓
         Real-time Subscription → Update Store → UI Update
```

### Real-time Sync Strategy
1. **Optimistic Updates**: Update UI immediately
2. **Queue System**: Queue changes when offline
3. **Conflict Resolution**: Last-write-wins with timestamp comparison
4. **Real-time Subscriptions**: Listen to Supabase changes
5. **Debouncing**: Batch rapid changes

---

## 📱 Page Structure

### 1. **Dashboard** (`/dashboard`)
- Command center layout
- Focus timer (main)
- Quick stats
- Recent sessions
- Active tasks

### 2. **Focus** (`/focus`)
- Full-screen focus mode
- Timer with ambient background
- Session controls
- Session history

### 3. **Tasks** (`/tasks`)
- Multiple view modes (list, kanban, calendar)
- Task management
- Filters & search
- Bulk actions

### 4. **Progress** (`/progress`)
- Analytics dashboard
- Charts & visualizations
- Insights
- Export options

### 5. **Presets** (`/presets`)
- Preset library
- Preset editor
- Categories

### 6. **Journey** (`/journey`)
- Level progress
- Achievements
- Milestones
- Streak calendar

### 7. **Settings** (`/settings`)
- All app settings
- Account management
- Data export/import

---

## 🎯 MVP Features (Phase 1)

### Must Have
1. ✅ Authentication (DONE)
2. ✅ Dashboard with basic stats (DONE - needs enhancement)
3. Focus timer with basic controls
4. Task list view with CRUD
5. Progress view with basic charts
6. Preset management
7. Real-time sync

### Nice to Have (Phase 2)
1. Advanced analytics
2. Multiple task views
3. Keyboard shortcuts
4. Full-screen focus mode
5. Export functionality

### Future (Phase 3)
1. Focus rooms
2. Task sharing
3. Preset sharing
4. Team features
5. Integrations

---

## 🎨 Design Principles

1. **Information Density**: Web allows more info, use it wisely
2. **Keyboard First**: Power users should be able to do everything via keyboard
3. **Real-time Feedback**: Show sync status, live updates
4. **Progressive Enhancement**: Works offline, enhances online
5. **Performance**: Fast, responsive, smooth animations
6. **Accessibility**: WCAG 2.1 AA compliance

---

## 🚀 Next Steps

1. **Set up state management** (Zustand + React Query)
2. **Create Supabase hooks** (typed, reusable)
3. **Build dashboard layout** (command center)
4. **Implement focus timer** (with ambient backgrounds)
5. **Build task management** (list view first)
6. **Add progress analytics** (basic charts)
7. **Implement real-time sync** (subscriptions)

---

## 💡 Innovation Ideas

1. **Focus Score**: AI-powered productivity score
2. **Focus Forecast**: Predict best focus times
3. **Distraction Blocker**: Browser extension integration
4. **Focus Music Discovery**: Curated playlists
5. **Focus Challenges**: Community challenges
6. **Focus Insights**: Weekly email reports
7. **Focus Rooms**: Virtual co-working spaces
8. **Focus API**: Allow integrations

---

**Created**: 2026-01-04
**Status**: Design Complete - Ready for Implementation

