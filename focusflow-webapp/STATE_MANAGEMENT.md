# State Management Architecture

## ✅ Completed Setup

### 1. **Zustand Stores** (`stores/`)
- ✅ `useAuthStore` - Authentication state (synced with AuthContext)
- ✅ `useTimerStore` - Focus timer state (phase, time, progress)
- ✅ `useTasksStore` - Task management (CRUD, filtering, views)
- ✅ `useSessionsStore` - Focus sessions (with computed stats)
- ✅ `usePresetsStore` - Focus presets (system + custom)
- ✅ `useSyncStore` - Sync status (syncing, errors, online status)

### 2. **React Query Setup**
- ✅ QueryClient configured with sensible defaults
- ✅ QueryProvider component for app-wide access
- ✅ Integrated into root layout

### 3. **Type System** (`types/`)
- ✅ Complete TypeScript types matching iOS app structure
- ✅ Task, FocusSession, FocusPreset, UserStats, UserSettings
- ✅ TimerPhase, SyncState types

### 4. **Utility Hooks** (`hooks/`)
- ✅ `useSyncAuth` - Syncs AuthContext ↔ Zustand auth store
- ✅ `useOnlineStatus` - Monitors online/offline status

### 5. **Dependencies Installed**
- ✅ `zustand` - State management
- ✅ `@tanstack/react-query` - Server state & caching
- ✅ `date-fns` - Date utilities
- ✅ `framer-motion` - Animations
- ✅ `react-hotkeys-hook` - Keyboard shortcuts

---

## 📦 Store Structure

### Auth Store
```typescript
useAuthStore()
- user: User | null
- session: Session | null
- loading: boolean
- setUser, setSession, setLoading, signOut
```

### Timer Store
```typescript
useTimerStore()
- phase: 'idle' | 'running' | 'paused' | 'completed'
- totalSeconds, remainingSeconds
- sessionName, presetId
- setPhase, setTotalSeconds, tick, reset
- getProgress(), getFormattedTime()
```

### Tasks Store
```typescript
useTasksStore()
- tasks: Task[]
- viewMode: 'list' | 'kanban' | 'calendar'
- filter: 'all' | 'active' | 'completed' | 'today'
- setTasks, addTask, updateTask, deleteTask
- getFilteredTasks(), getTasksByDate()
```

### Sessions Store
```typescript
useSessionsStore()
- sessions: FocusSession[]
- setSessions, addSession, updateSession, deleteSession
- getTotalFocusTime(), getTodayFocusTime()
- getThisWeekFocusTime(), getThisMonthFocusTime()
```

### Presets Store
```typescript
usePresetsStore()
- presets: FocusPreset[]
- selectedPresetId
- setPresets, addPreset, updatePreset, deletePreset
- getSystemPresets(), getCustomPresets()
```

### Sync Store
```typescript
useSyncStore()
- isSyncing: boolean
- lastSyncDate?: Date
- syncError?: Error | null
- isOnline: boolean
- setSyncing, setLastSyncDate, setSyncError, setOnline
```

---

## 🔄 Data Flow

```
User Action
    ↓
Zustand Store (Optimistic Update)
    ↓
React Query Mutation
    ↓
Supabase API
    ↓
Real-time Subscription
    ↓
Update Zustand Store
    ↓
UI Re-renders
```

---

## 📝 Usage Examples

### Using Timer Store
```typescript
import { useTimerStore } from '@/stores';

function TimerComponent() {
  const { phase, remainingSeconds, getFormattedTime, tick } = useTimerStore();
  
  useEffect(() => {
    if (phase === 'running') {
      const interval = setInterval(tick, 1000);
      return () => clearInterval(interval);
    }
  }, [phase, tick]);
  
  return <div>{getFormattedTime()}</div>;
}
```

### Using Tasks Store
```typescript
import { useTasksStore } from '@/stores';

function TasksList() {
  const { getFilteredTasks, addTask, updateTask } = useTasksStore();
  const tasks = getFilteredTasks();
  
  return (
    <div>
      {tasks.map(task => (
        <TaskItem key={task.id} task={task} />
      ))}
    </div>
  );
}
```

### Using React Query
```typescript
import { useQuery, useMutation } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';

function useSessions() {
  const supabase = createClient();
  
  return useQuery({
    queryKey: ['sessions'],
    queryFn: async () => {
      const { data } = await supabase
        .from('focus_sessions')
        .select('*')
        .order('started_at', { ascending: false });
      return data;
    },
  });
}
```

---

## 🚀 Next Steps

1. **Create Supabase Hooks** (`hooks/supabase/`)
   - Typed hooks for all database operations
   - React Query integration
   - Real-time subscriptions

2. **Build Dashboard**
   - Use stores to display data
   - Real-time updates
   - Command center layout

3. **Implement Focus Timer**
   - Use timer store
   - Connect to Supabase
   - Real-time sync

4. **Add Real-time Subscriptions**
   - Supabase realtime for live updates
   - Sync across tabs/devices

---

**Status**: ✅ State Management Complete
**Next**: Create Supabase hooks and start building features

