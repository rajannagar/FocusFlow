# FocusFlow Notification System Audit Report
**Date:** January 5, 2026  
**Status:** ✅ System is well-architected with minor issues found

---

## Executive Summary

The notification system is **well-designed** with proper separation of concerns, namespace isolation, and comprehensive coverage of all notification types. The architecture follows best practices with a central coordinator pattern.

### Key Strengths
✅ Central `NotificationsCoordinator` orchestrates all scheduling  
✅ Namespace-scoped storage prevents data leakage between accounts  
✅ Proper cleanup on account switch  
✅ Separation between system notifications and in-app feed  
✅ Permission handling respects user denial  
✅ Task reminders support all repeat patterns with custom weekdays  

### Issues Found
🔴 **1 Critical Issue** - Daily Reminder Time Conversion Bug  
🟡 **3 Medium Issues** - Scheduling gaps and edge cases  
🟢 **2 Minor Issues** - Code quality improvements  

---

## 1. System Notifications Architecture ✅

### NotificationsCoordinator
**File:** [FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift](FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift)

**Status:** ✅ **Working Correctly**

- ✅ `reconcileAll()` is comprehensive and idempotent
- ✅ Called at appropriate times:
  - App launch
  - Auth state change (namespace switch)
  - Preference changes
  - Returning from Settings
- ✅ `cancelAll()` properly removes all notification types
- ✅ Respects master toggle and authorization status
- ✅ Delegates to appropriate managers

**Verified Call Sites:**
- [FocusFlowApp.swift#L61](FocusFlow/App/FocusFlowApp.swift#L61) - Launch
- [NotificationPreferencesStore.swift#L56](FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift#L56) - Account switch
- [NotificationPreferencesStore.swift#L72](FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift#L72) - After namespace change
- [NotificationPreferencesStore.swift#L158](FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift#L158) - Preference changes

---

## 2. Notification Types Coverage ✅

### 2.1 Daily Reminder (User-Configured Time)
**Implementation:** [FocusLocalNotificationManager.swift#L212-L247](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift#L212-L247)

**Status:** 🔴 **CRITICAL BUG FOUND**

#### Issue: Time Conversion Bug
The daily reminder uses `Date` for time storage but only needs hour/minute. This causes problems:

**Problem in NotificationPreferences.swift:**
```swift
var dailyReminderTime: Date {
    get {
        makeTime(hour: dailyReminderHour, minute: dailyReminderMinute)
    }
    set {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
        dailyReminderHour = comps.hour ?? 9
        dailyReminderMinute = comps.minute ?? 0
    }
}
```

**Problem in FocusLocalNotificationManager:**
```swift
func applyDailyReminderSettings(enabled: Bool, time: Date) {
    // ...
    self.scheduleDailyReminder(at: time) // ← Receives full Date
}

private func scheduleDailyReminder(at time: Date) {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
    var dateComponents = DateComponents()
    dateComponents.hour = comps.hour ?? 9  // ← May extract wrong time
    dateComponents.minute = comps.minute ?? 0
    // ...
}
```

**Impact:** If the Date object includes date components, time zone differences, or DST transitions, the extracted hour/minute may be incorrect.

**Recommendation:** 
```swift
// Option 1: Pass hour/minute directly
func applyDailyReminderSettings(enabled: Bool, hour: Int, minute: Int)

// Option 2: Use DateComponents throughout
var dailyReminderTime: DateComponents
```

---

### 2.2 Daily Nudges (3x Per Day)
**Implementation:** [FocusLocalNotificationManager.swift#L169-L200](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift#L169-L200)

**Status:** ✅ **Working Correctly**

- ✅ Hardcoded times (9 AM, 2 PM, 8 PM)
- ✅ Uses `UNCalendarNotificationTrigger` with repeats
- ✅ Proper cancellation
- ✅ Reconciliation respects preference toggle

**Note:** The preferences model includes individual nudge time fields but they're not currently used:
```swift
var morningNudgeHour: Int = 9
var afternoonNudgeHour: Int = 14
var eveningNudgeHour: Int = 20
```

**Recommendation:** Either remove unused fields or implement custom nudge times.

---

### 2.3 Daily Recap (Yesterday's Summary)
**Implementation:** [NotificationsCoordinator.swift#L158-L196](FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift#L158-L196)

**Status:** 🟡 **ISSUE: Static Content**

#### Issue: Generic Message
The recap notification cannot include actual stats because iOS doesn't support dynamic content at delivery time:

```swift
content.title = "Yesterday's Focus Recap 📊"
content.body = "See how your day went and keep the momentum going!"
```

**Impact:** Users get a generic message instead of "You completed 3 sessions, 2 hours" etc.

**Recommendation:** 
1. Keep current implementation (acceptable for MVP)
2. Consider push notifications with server-side stats calculation (future premium feature)
3. Add UNNotificationServiceExtension to fetch stats when notification is delivered (iOS 10+, complex)

---

### 2.4 Task Reminders (Per Task, with Repeat Support)
**Implementation:** 
- Scheduler: [TaskReminderScheduler.swift](FocusFlow/Features/Tasks/TaskReminderScheduler.swift)
- Notification Manager: [FocusLocalNotificationManager.swift#L272-L368](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift#L272-L368)

**Status:** ✅ **Excellent Implementation**

- ✅ Automatic reconciliation on task changes
- ✅ Supports all repeat rules:
  - None (one-time)
  - Daily
  - Weekly
  - Monthly
  - Yearly
  - Custom weekdays (multiple notifications per task)
- ✅ Namespace-aware cleanup on account switch
- ✅ Respects preference toggle
- ✅ Debounced reconciliation (250ms)
- ✅ Proper identifier management for custom weekdays

**Custom Weekday Implementation:**
```swift
case .customDays:
    let days = customWeekdays.isEmpty ? [weekdayFromDate] : Array(customWeekdays).sorted()
    for wd in days {
        let dc = DateComponents(hour: hour, minute: minute, weekday: wd)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let id = baseId + ".w\(wd)"  // ← Unique ID per weekday
        addRequest(id: id, trigger: trigger)
    }
```

**Minor Issue:** Past one-time reminders are skipped, but existing scheduled past reminders aren't cleaned up:
```swift
if repeatRule == .none, date <= Date() {
    print("🔔 Skipping past one-time task reminder for \(taskTitle)")
    return  // ← Doesn't cancel if already scheduled
}
```

**Recommendation:** Cancel the reminder if it exists:
```swift
if repeatRule == .none, date <= Date() {
    cancelTaskReminder(taskId: taskId)
    lastScheduled.removeValue(forKey: taskId)
    print("🔔 Cancelled past one-time task reminder for \(taskTitle)")
    return
}
```

---

### 2.5 Session Completion (When Timer Finishes)
**Implementation:** 
- Coordinator: [NotificationsCoordinator.swift#L136-L155](FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift#L136-L155)
- Manager: [FocusLocalNotificationManager.swift#L117-L155](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift#L117-L155)
- Usage: [FocusView.swift#L1423-L1427](FocusFlow/Features/Focus/FocusView.swift#L1423-L1427)

**Status:** ✅ **Working Correctly**

- ✅ Scheduled on-demand when timer starts
- ✅ Uses `UNTimeIntervalNotificationTrigger`
- ✅ Respects preferences and authorization
- ✅ Cancelled when user stops timer early
- ✅ Proper cleanup

**Verified Cancellation Points:**
- [FocusView.swift#L394](FocusFlow/Features/Focus/FocusView.swift#L394) - User stops
- [FocusView.swift#L1365](FocusFlow/Features/Focus/FocusView.swift#L1365) - Session ends
- [FocusView.swift#L1375](FocusFlow/Features/Focus/FocusView.swift#L1375) - Cancel action
- [FocusView.swift#L1452](FocusFlow/Features/Focus/FocusView.swift#L1452) - Pause
- [FocusView.swift#L1486](FocusFlow/Features/Focus/FocusView.swift#L1486) - Reset
- [FocusView.swift#L1598](FocusFlow/Features/Focus/FocusView.swift#L1598) - Cleanup

---

## 3. Scheduling Implementation ✅

### FocusLocalNotificationManager
**File:** [FocusFlow/Features/Focus/FocusLocalNotificationManager.swift](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift)

**Status:** ✅ **Well Implemented**

#### Calendar Triggers (Daily/Repeating)
- ✅ Daily reminder: `UNCalendarNotificationTrigger(dateMatching: {hour, minute}, repeats: true)`
- ✅ Daily nudges: Same pattern, 3 different times
- ✅ Weekly tasks: `{hour, minute, weekday}`
- ✅ Monthly tasks: `{day, hour, minute}`
- ✅ Yearly tasks: `{month, day, hour, minute}`

#### Time Interval Trigger (Session Completion)
- ✅ `UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)`
- ✅ Non-repeating, one-shot notification

#### Authorization Check Pattern
All scheduling methods follow this pattern:
```swift
checkAuthorizationAndSchedule { [weak self] auth in
    guard let self else { return }
    guard self.isAllowedToSchedule(auth) else { return }
    // ... schedule notification
}
```

**Status:** ✅ Good pattern, but note that this is **legacy behavior**. The new `NotificationsCoordinator` checks authorization before delegating, so this is redundant but harmless.

---

## 4. Preferences Storage ✅

### NotificationPreferencesStore
**File:** [FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift](FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift)

**Status:** ✅ **Excellent Implementation**

#### Namespace Scoping
```swift
private func key(_ base: String) -> String {
    "\(base)_\(activeNamespace)"  // ← guest or userId
}
```

- ✅ Namespace determined from `AuthManagerV2.shared.state`
- ✅ Guest uses "guest" namespace
- ✅ Signed-in users use `userId.uuidString`

#### Account Switch Handling
```swift
private func applyNamespace(for state: CloudAuthState) {
    let newNamespace = namespace(for: state)
    
    if hasInitialized && activeNamespace != newNamespace {
        Task {
            print("🔔 Cancelling all notifications before namespace switch: \(activeNamespace) → \(newNamespace)")
            await NotificationsCoordinator.shared.cancelAll()
        }
    }
    
    activeNamespace = newNamespace
    load()  // ← Load new account's preferences
    
    Task {
        try? await Task.sleep(nanoseconds: 500_000_000)  // ← Wait for other stores
        await NotificationsCoordinator.shared.reconcileAll(reason: "namespace changed")
    }
}
```

**Status:** ✅ Perfect cleanup sequence

#### Cloud Sync Support
```swift
private var isApplyingRemote = false

func applyRemotePreferences(_ prefs: NotificationPreferences) {
    isApplyingRemote = true
    defer { isApplyingRemote = false }
    preferences = prefs
    save() // Won't post notification due to flag
}
```

- ✅ Prevents sync loops
- ✅ Posts `NotificationPreferencesDidChange` only for local changes
- ✅ Ready for cloud sync integration

---

## 5. Authorization Handling ✅

### NotificationAuthorizationService
**File:** [FocusFlow/Core/Notifications/System/NotificationAuthorizationService.swift](FocusFlow/Core/Notifications/System/NotificationAuthorizationService.swift)

**Status:** ✅ **Perfect Implementation**

#### Key Features
- ✅ No auto-prompting (user must explicitly enable a feature)
- ✅ Silent status refresh via `refreshStatus()`
- ✅ Permission request only when user enables notification
- ✅ Respects denial gracefully

#### Authorization States
```swift
enum Authorization: Equatable {
    case authorized    // ← Can schedule
    case provisional   // ← Can schedule
    case denied        // ← Cannot schedule, show settings prompt
    case notDetermined // ← Haven't asked yet
    case unknown       // ← Error state
}
```

#### Permission Flow
```swift
var isAuthorized: Bool {
    status == .authorized || status == .provisional || status == .ephemeral
}

var isDenied: Bool {
    status == .denied
}

var shouldShowSettingsPrompt: Bool {
    status == .denied
}
```

**Usage in NotificationsCoordinator:**
```swift
let canSchedule = authService.isAuthorized

if !prefs.masterEnabled || !canSchedule {
    await cancelAll()
    return
}
```

✅ **Perfect integration** - coordinator checks authorization before any scheduling

---

## 6. In-App Notifications ✅

### NotificationCenterManager
**File:** [FocusFlow/Features/NotificationsCenter/NotificationCenterManager.swift](FocusFlow/Features/NotificationsCenter/NotificationCenterManager.swift)

**Status:** ✅ **Well Implemented**

#### Namespace Isolation
```swift
private func storageKey() -> String {
    "\(storageKeyBase)_\(activeNamespace)"
}

private func applyNamespace(for state: CloudAuthState) {
    let newNamespace = namespace(for: state)
    
    if activeNamespace == newNamespace { return }
    
    print("[NotificationCenterManager] Namespace switch: \(activeNamespace) → \(newNamespace)")
    activeNamespace = newNamespace
    load()  // ← Load new account's feed
}
```

✅ **No leakage** - each account has isolated feed

#### Notification Types
```swift
enum Kind: String, Codable {
    case sessionCompleted
    case taskCompleted
    case streak
    case levelUp
    case badgeUnlocked
    case goalUpdated
    case dailyRecap
    case general
}
```

✅ All expected types are supported

#### Features
- ✅ Add new notifications
- ✅ Mark as read/unread
- ✅ Delete individual notifications
- ✅ Clear all
- ✅ Automatic trimming (max 100)
- ✅ Navigation support with `navigateToDestination` event

#### Navigation Mapping
```swift
func destination(for kind: FocusNotification.Kind) -> NotificationDestination? {
    switch kind {
    case .dailyRecap:       return .journey
    case .streak:           return .journey
    case .levelUp:          return .profile
    case .badgeUnlocked:    return .profile
    case .goalUpdated:      return .progress
    case .sessionCompleted: return nil
    case .taskCompleted:    return nil
    case .general:          return nil
    }
}
```

✅ Sensible defaults with tap handling

---

## 7. Cleanup on Account Switch ✅

### Cleanup Sequence

**Trigger:** `AuthManagerV2.$state` publishes change

**Step 1:** NotificationPreferencesStore receives state change
```swift
// NotificationPreferencesStore.swift
private func applyNamespace(for state: CloudAuthState) {
    // ...
    if hasInitialized && activeNamespace != newNamespace {
        Task {
            await NotificationsCoordinator.shared.cancelAll()  // ← STEP 1
        }
    }
    
    activeNamespace = newNamespace
    load()  // ← STEP 2: Load new preferences
    
    Task {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await NotificationsCoordinator.shared.reconcileAll(reason: "namespace changed")  // ← STEP 3
    }
}
```

**Step 2:** TaskReminderScheduler clears tracking
```swift
// TaskReminderScheduler.swift
AuthManagerV2.shared.$state
    .receive(on: queue)
    .sink { [weak self] state in
        // ...
        if self.currentNamespace != newNamespace {
            self.currentNamespace = newNamespace
            self.lastScheduled.removeAll()  // ← Clear tracking
        }
    }
```

**Step 3:** NotificationCenterManager loads new feed
```swift
// NotificationCenterManager.swift
private func applyNamespace(for state: CloudAuthState) {
    let newNamespace = namespace(for: state)
    
    if activeNamespace == newNamespace { return }
    
    activeNamespace = newNamespace
    load()  // ← Load new account's in-app notifications
}
```

### Verification: No Leakage ✅

**System Notifications:**
- ✅ `cancelAll()` called before namespace switch
- ✅ New account's preferences loaded
- ✅ `reconcileAll()` schedules with new account's tasks and preferences
- ✅ Old account's task reminders cancelled (different task IDs)

**In-App Notifications:**
- ✅ Stored with namespace suffix: `focusflow.notifications_<userId>`
- ✅ Each account loads from own key
- ✅ No cross-contamination possible

**Preferences:**
- ✅ Stored with namespace suffix: `ff_notificationPreferences_<userId>`
- ✅ Default preferences for new accounts
- ✅ Migration from AppSettings on first load

---

## 8. Issues Summary

### 🔴 Critical Issues

#### Issue #1: Daily Reminder Time Conversion Bug
**Location:** [NotificationPreferences.swift#L66-L75](FocusFlow/Core/Notifications/Preferences/NotificationPreferences.swift#L66-L75)

**Problem:** Using `Date` for time-only storage can cause timezone/DST issues

**Fix:**
```swift
// Current (buggy):
var dailyReminderTime: Date {
    get { makeTime(hour: dailyReminderHour, minute: dailyReminderMinute) }
    set {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
        dailyReminderHour = comps.hour ?? 9
        dailyReminderMinute = comps.minute ?? 0
    }
}

// Proposed fix - Option 1 (simplest):
// Remove computed property, use hour/minute directly in UI
// DatePicker can still bind to a Date, but convert at UI layer

// Proposed fix - Option 2 (cleanest):
// Store DateComponents instead of Date
// Update all call sites
```

---

### 🟡 Medium Issues

#### Issue #2: Past One-Time Task Reminders Not Cancelled
**Location:** [FocusLocalNotificationManager.swift#L293-L297](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift#L293-L297)

**Problem:** If a task has a past one-time reminder already scheduled, changing it won't cancel the old one

**Fix:**
```swift
// Current:
if repeatRule == .none, date <= Date() {
    print("🔔 Skipping past one-time task reminder for \(taskTitle)")
    return
}

// Fixed:
if repeatRule == .none, date <= Date() {
    cancelTaskReminder(taskId: taskId)
    lastScheduled.removeValue(forKey: taskId)  // Update tracker in TaskReminderScheduler too
    print("🔔 Cancelled past one-time task reminder for \(taskTitle)")
    return
}
```

---

#### Issue #3: Daily Recap Uses Generic Message
**Location:** [NotificationsCoordinator.swift#L172-L176](FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift#L172-L176)

**Problem:** Cannot include actual stats in notification body

**Options:**
1. Keep as-is (acceptable for MVP)
2. Use UNNotificationServiceExtension (complex, requires app extension)
3. Add server-side push notifications (requires backend)

**Recommendation:** Keep as-is for now, consider push notifications for premium users

---

#### Issue #4: Unused Daily Nudge Customization Fields
**Location:** [NotificationPreferences.swift#L34-L41](FocusFlow/Core/Notifications/Preferences/NotificationPreferences.swift#L34-L41)

**Problem:** Preference model has individual nudge time fields but they're never used

```swift
var morningNudgeHour: Int = 9
var morningNudgeMinute: Int = 0
var afternoonNudgeHour: Int = 14
var afternoonNudgeMinute: Int = 0
var eveningNudgeHour: Int = 20
var eveningNudgeMinute: Int = 0
```

**Fix:** Either remove fields or implement custom nudge times in UI

---

### 🟢 Minor Issues

#### Issue #5: Legacy Authorization Check Pattern
**Location:** Multiple files using `checkAuthorizationAndSchedule`

**Problem:** `FocusLocalNotificationManager` still checks authorization, but `NotificationsCoordinator` already does this

**Impact:** None (redundant but harmless)

**Fix:** Remove authorization checks from manager methods since coordinator handles it

---

#### Issue #6: Debug Methods in Production
**Location:** [NotificationSettingsView.swift#L459-L493](FocusFlow/Features/Profile/NotificationSettingsView.swift#L459-L493)

**Problem:** Debug section exists in production code (wrapped in `#if DEBUG`)

**Fix:** None needed (properly wrapped), but consider removing before App Store release

---

## 9. Test Recommendations

### Manual Testing Checklist

**Daily Reminder:**
- [ ] Enable daily reminder, set time to 1 minute from now
- [ ] Lock device, wait for notification
- [ ] Change time, verify old notification cancelled
- [ ] Disable, verify notification cancelled
- [ ] Switch accounts, verify each account has own time

**Daily Nudges:**
- [ ] Enable nudges
- [ ] Set device time to 8:59 AM, wait 1 minute
- [ ] Verify nudge appears at 9 AM, 2 PM, 8 PM (may need time adjustment)
- [ ] Disable, verify cancelled

**Daily Recap:**
- [ ] Enable recap, set time
- [ ] Verify generic message (can't test stats without waiting)
- [ ] Disable, verify cancelled

**Task Reminders:**
- [ ] Create task with one-time reminder (1 min from now)
- [ ] Create task with daily reminder
- [ ] Create task with custom weekdays (Mon, Wed, Fri)
- [ ] Verify all fire correctly
- [ ] Delete task, verify reminders cancelled
- [ ] Switch accounts, verify reminders isolated

**Session Completion:**
- [ ] Start 1-minute focus session
- [ ] Lock device, wait for completion
- [ ] Start session, stop early, verify no notification
- [ ] Start session, pause, verify no notification while paused

**Account Switch:**
- [ ] Sign in as User A, enable reminders, create task reminders
- [ ] Verify `debugDumpPending()` shows User A's notifications
- [ ] Sign out, switch to User B
- [ ] Verify `debugDumpPending()` shows NO old notifications
- [ ] Enable different reminders for User B
- [ ] Switch back to User A, verify A's reminders restored

**Authorization:**
- [ ] Deny notifications in Settings
- [ ] Try enabling any notification type
- [ ] Verify no scheduling happens
- [ ] Verify UI shows "Open Settings" prompt
- [ ] Grant permission, verify scheduling works

---

## 10. Architecture Evaluation ✅

### Design Patterns
- ✅ **Coordinator Pattern:** `NotificationsCoordinator` orchestrates all scheduling
- ✅ **Manager Pattern:** Separate managers for system vs in-app notifications
- ✅ **Observer Pattern:** Observes auth state, preferences, tasks
- ✅ **Strategy Pattern:** Different triggers for different notification types

### Code Quality
- ✅ Clear separation of concerns
- ✅ Comprehensive logging
- ✅ Defensive programming (guard statements, optional handling)
- ✅ Proper cleanup and cancellation
- ✅ Namespace isolation prevents data leakage

### Scalability
- ✅ Easy to add new notification types
- ✅ Centralized reconciliation logic
- ✅ Cloud sync ready
- ✅ Supports custom notification times (prepared for future features)

### Maintainability
- ✅ Well-documented with comments
- ✅ Consistent naming conventions
- ✅ Single source of truth (NotificationsCoordinator)
- ✅ Easy to debug with print statements

---

## 11. Recommendations

### Priority 1 (Must Fix)
1. **Fix daily reminder time conversion bug** - Use hour/minute directly or DateComponents
2. **Cancel past one-time task reminders** - Don't leave orphaned notifications

### Priority 2 (Should Fix)
3. **Remove unused nudge time fields** - Or implement custom nudge times
4. **Add comprehensive unit tests** - Test all reconciliation scenarios

### Priority 3 (Nice to Have)
5. **Remove redundant authorization checks** - Coordinator already handles this
6. **Add notification content extension** - Show rich UI for session completion
7. **Server-side push for daily recap** - Include actual stats

### Priority 4 (Future Enhancement)
8. **Quiet hours support** - Model already has commented fields
9. **Custom nudge times** - UI for per-nudge time customization
10. **Notification categories with actions** - "Start Focus", "Snooze", etc.

---

## 12. Final Verdict

### Overall Grade: A- (90/100)

**Strengths:**
- Excellent architecture and separation of concerns
- Perfect namespace isolation
- Comprehensive coverage of all notification types
- Proper cleanup on account switch
- Good permission handling

**Weaknesses:**
- Daily reminder time conversion bug (critical)
- Past task reminders not cleaned up (medium)
- Some unused code and fields (minor)

**Conclusion:** The notification system is production-ready after fixing the daily reminder time bug. The architecture is solid and will scale well as the app grows. The namespace isolation is particularly well-implemented and prevents any data leakage between accounts.

---

## Appendix A: Notification Identifiers

```swift
// Session
"focusflow.sessionCompletion"

// Daily Nudges
"focusflow.nudge.morning"
"focusflow.nudge.afternoon"
"focusflow.nudge.evening"

// Daily Reminder
"focusflow.dailyReminder"

// Daily Recap
"focusflow.dailyRecap"

// Task Reminders
"focusflow.task.<taskId>"           // Base or specific repeat
"focusflow.task.<taskId>.w1"        // Monday (custom weekdays)
"focusflow.task.<taskId>.w2"        // Tuesday
// ... etc for w3-w7
```

---

## Appendix B: Key Files Reference

| Component | File | Lines |
|-----------|------|-------|
| Coordinator | [NotificationsCoordinator.swift](FocusFlow/Core/Notifications/System/NotificationsCoordinator.swift) | 227 |
| Notification Manager | [FocusLocalNotificationManager.swift](FocusFlow/Features/Focus/FocusLocalNotificationManager.swift) | 415 |
| Preferences Store | [NotificationPreferencesStore.swift](FocusFlow/Core/Notifications/Preferences/NotificationPreferencesStore.swift) | 176 |
| Preferences Model | [NotificationPreferences.swift](FocusFlow/Core/Notifications/Preferences/NotificationPreferences.swift) | 100 |
| Authorization | [NotificationAuthorizationService.swift](FocusFlow/Core/Notifications/System/NotificationAuthorizationService.swift) | 58 |
| In-App Manager | [NotificationCenterManager.swift](FocusFlow/Features/NotificationsCenter/NotificationCenterManager.swift) | 200 |
| Task Scheduler | [TaskReminderScheduler.swift](FocusFlow/Features/Tasks/TaskReminderScheduler.swift) | 150 |
| Settings UI | [NotificationSettingsView.swift](FocusFlow/Features/Profile/NotificationSettingsView.swift) | 616 |
| Identifiers | [NotificationIDs.swift](FocusFlow/Core/Notifications/System/NotificationIDs.swift) | 45 |

---

**End of Audit Report**
