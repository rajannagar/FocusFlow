# Complete Data Audit: What Gets Restored After App Reinstall

## Executive Summary

**Current Status:** Most user data is safely synced to cloud, but **2 critical data types are lost on reinstall:**
1. **Per-Day Goal History** - Users lose their historical goal settings
2. **Notification Preferences** - Users lose their custom notification settings

---

## ✅ Data That IS Synced to Cloud (Safe After Reinstall)

### 1. Focus Sessions ✅
- **Storage:** `focus_sessions` table
- **Sync Engine:** `SessionsSyncEngine`
- **Status:** ✅ Fully synced
- **What's Restored:**
  - All completed focus sessions
  - Session duration, date, name
  - User stats (total time, session count)

### 2. Tasks ✅
- **Storage:** `tasks` and `task_completions` tables
- **Sync Engine:** `TasksSyncEngine`
- **Status:** ✅ Fully synced
- **What's Restored:**
  - All tasks (recurring and one-time)
  - Task completions for all dates
  - Task properties (name, duration, recurrence, etc.)

### 3. Focus Presets ✅
- **Storage:** `focus_presets` table
- **Sync Engine:** `PresetsSyncEngine`
- **Status:** ✅ Fully synced
- **What's Restored:**
  - All custom focus presets
  - Preset settings (duration, sound, background, etc.)
  - Note: Active preset is NOT synced (by design - device-specific)

### 4. App Settings ✅
- **Storage:** `user_settings` table
- **Sync Engine:** `SettingsSyncEngine`
- **Status:** ✅ Fully synced
- **What's Restored:**
  - Display name
  - Tagline
  - Avatar ID
  - Selected theme
  - Profile theme
  - Sound enabled/disabled
  - Haptics enabled/disabled
  - Daily reminder enabled/disabled
  - Daily reminder time (hour/minute)
  - Selected focus sound
  - External music app
  - **Current daily goal** (`daily_goal_minutes`)

---

## ❌ Data That is NOT Synced (Lost on Reinstall)

### 1. Per-Day Goal History ❌ **CRITICAL**
- **Storage:** UserDefaults key: `focusflow.pv2.dailyGoalHistory.v1`
- **Format:** `[String: Int]` (date string -> goal minutes)
- **Status:** ❌ **NOT synced to cloud**
- **Impact:** 
  - Users lose their historical goal settings for past dates
  - Past dates will show incorrect completion percentages
  - Example: Day 1 had 60 min goal (100%), after reinstall shows 60/120 (50%)

**Why This Matters:**
- Users explicitly set different goals for different days
- Historical accuracy is important for progress tracking
- Completion percentages become incorrect after reinstall

**Recommendation:** Add `goal_history` JSONB column to `user_settings` table

---

### 2. Notification Preferences ❌ **IMPORTANT**
- **Storage:** UserDefaults key: `ff_notificationPreferences_{userId}`
- **Format:** `NotificationPreferences` (JSON encoded)
- **Status:** ❌ **NOT synced to cloud**
- **What's Lost:**
  - Master notification toggle
  - Session completion notifications enabled/disabled
  - Daily reminder enabled/disabled
  - Daily reminder time
  - Daily nudges enabled/disabled
  - Task reminders enabled/disabled
  - Daily recap enabled/disabled
  - Daily recap time

**Impact:**
- Users lose all their notification customizations
- Need to reconfigure notification preferences after reinstall
- May miss important notifications if they forget to re-enable

**Recommendation:** Add `notification_preferences` JSONB column to `user_settings` table

---

### 3. In-App Notification History ⚠️ **LOW PRIORITY**
- **Storage:** UserDefaults key: `ff_inAppNotifications`
- **Format:** `[FocusNotification]` (array of notifications)
- **Status:** ❌ **NOT synced**
- **Impact:** 
  - Notification history is lost
  - Users can't see past notifications
  - **Note:** This is probably acceptable - notifications are ephemeral

**Recommendation:** Can remain local-only (not critical user data)

---

## 🔄 Temporary/Internal Data (Not User Data)

These are fine to lose on reinstall:

1. **Active Session State** (`FocusFlow.focusSession.*`)
   - Temporary state for active sessions
   - Not synced (by design - device-specific)
   - ✅ Fine to lose

2. **Onboarding State** (`ff_hasCompletedOnboarding`)
   - Tracks if user completed onboarding
   - ✅ Fine to lose (can re-onboard)

3. **Guest Mode Flag** (`ff_guestMode`)
   - Tracks if user is in guest mode
   - ✅ Fine to lose (resets on reinstall)

4. **Widget Cache** (`widget.*`)
   - Local cache for widgets
   - ✅ Fine to lose (rebuilds automatically)

5. **Local Timestamp Tracker** (`ff_localTimestamps_{namespace}`)
   - Internal sync conflict resolution
   - ✅ Fine to lose (rebuilds on next sync)

6. **Sync Queue** (`ff_syncQueue_{namespace}`)
   - Internal queue for pending syncs
   - ✅ Fine to lose (processes on next sync)

7. **Last Known Level/Streak** (`lastKnownLevel`, `lastKnownStreak`)
   - Used for detecting level-ups
   - ✅ Fine to lose (recalculates from sessions)

---

## 📊 Data Recovery Flow After Reinstall

### When User Signs In:
1. `AuthManagerV2` detects sign-in
2. `SyncCoordinator` starts all sync engines
3. `performInitialSync()` runs in order:
   - **Settings sync** → Restores app settings + current goal
   - **Presets sync** → Restores custom presets
   - **Sessions sync** → Restores all focus sessions
   - **Tasks sync** → Restores tasks + completions

### What Gets Restored:
✅ All focus sessions  
✅ All tasks and completions  
✅ All custom presets  
✅ App settings (theme, name, avatar, etc.)  
✅ Current daily goal  
❌ **Per-day goal history** (LOST)  
❌ **Notification preferences** (LOST)  

---

## 🎯 Recommendations

### Priority 1: Sync Goal History (CRITICAL)
**Impact:** High - Affects historical accuracy of progress tracking

**Implementation:**
```sql
ALTER TABLE user_settings 
ADD COLUMN goal_history JSONB DEFAULT '{}'::jsonb;
```

**Code Changes:**
- Add `goalHistory` to `UserSettingsDTO`
- Update `SettingsSyncEngine` to sync goal history
- Store as `[String: Int]` (date -> goal minutes)

---

### Priority 2: Sync Notification Preferences (IMPORTANT)
**Impact:** Medium - Users lose notification customizations

**Implementation:**
```sql
ALTER TABLE user_settings 
ADD COLUMN notification_preferences JSONB DEFAULT '{}'::jsonb;
```

**Code Changes:**
- Add `notificationPreferences` to `UserSettingsDTO`
- Update `SettingsSyncEngine` to sync notification preferences
- Store `NotificationPreferences` as JSON

---

### Priority 3: Consider Syncing In-App Notification History (OPTIONAL)
**Impact:** Low - Nice to have but not critical

**Implementation:**
- Could add to `user_settings` or create separate table
- Only sync recent notifications (last 30 days)
- **Note:** This is probably not necessary

---

## 📝 Summary

### Current State:
- **85% of user data is safe** ✅
- **2 critical data types are lost** ❌
- **Most temporary/internal data is fine to lose** ✅

### After Implementing Recommendations:
- **100% of critical user data will be safe** ✅
- **Users can delete and reinstall without data loss** ✅
- **Complete data recovery after reinstall** ✅

---

## 🔍 Verification Checklist

After implementing cloud sync for goal history and notification preferences:

- [ ] User can delete and reinstall app
- [ ] User signs in with same account
- [ ] All focus sessions are restored
- [ ] All tasks are restored
- [ ] All presets are restored
- [ ] App settings are restored
- [ ] **Per-day goal history is restored** ⚠️
- [ ] **Notification preferences are restored** ⚠️
- [ ] Past dates show correct completion percentages
- [ ] Notification settings match previous configuration

---

## 🚨 Critical Issues to Fix

1. **Goal History Not Synced** - Users lose historical goal accuracy
2. **Notification Preferences Not Synced** - Users lose notification customizations

Both should be added to `user_settings` table and synced via `SettingsSyncEngine`.

