# Task Display & Management - Corrected Logic

## What Changed
Fixed the task filtering to show ALL tasks where appropriate.

## How Tasks Appear Now

### TODAY Section
Shows: **ALL tasks that user is working on today**
- ✅ Tasks WITHOUT reminder dates (user hasn't scheduled them yet - they're for today)
- ✅ Tasks WITH reminder set for TODAY
- ❌ Tasks WITH reminder set for TOMORROW or later (those are for future days)

**Example**: If you have 4 tasks:
1. "Finish report" (no reminder) → Shows in TODAY ✓
2. "Call mom at 3pm" (reminder: today) → Shows in TODAY ✓  
3. "Plan next week" (reminder: tomorrow) → Does NOT show in TODAY, but shows in ALL TASKS
4. "Annual review" (reminder: next month) → Does NOT show in TODAY, but shows in ALL TASKS

Result: `TODAY: 0/2 completed` (only tasks 1 & 2)

### ALL TASKS Section  
Shows: **Every task in your system**
- All tasks (up to 25 shown, with "... and X more" if over 25)
- Each task shows:
  - ✓ if completed, ○ if not completed
  - Title
  - Reminder date if set (shows "upcoming" or "past")
  - Duration if set
  - Repeat rule if set
  - UUID in brackets so AI can modify it

**Example output**:
```
ALL TASKS (use IDs for modifications):
  [UUID-123] ✓ Finish report
  [UUID-456] ○ Call mom at 3pm (upcoming: today 3:00 PM)
  [UUID-789] ○ Plan next week (upcoming: tomorrow 9:00 AM)
  [UUID-012] ○ Annual review (upcoming: Jan 20, 2026) [30 min] [repeats: yearly]
```

## What AI Can Do
With this setup, the AI can:
- ✅ Count how many tasks you have "today" - shows only today's tasks
- ✅ List all your tasks - shows everything
- ✅ Delete/modify any specific task - uses the UUID
- ✅ Mark tasks complete/incomplete - uses the UUID
- ✅ Create new tasks - can set reminder or leave blank for today

## Logic Details

### Task Inclusion Logic
```
TODAY_TASKS = all tasks WHERE:
  (task.reminderDate == TODAY)  OR
  (task.reminderDate == NULL)   OR  
  (task.reminderDate < NOW)
  
ALL_TASKS = all tasks (no exclusion)
```

### Completion Tracking
Each task can be marked complete/incomplete. The count shows:
`TODAY: [completed count]/[total today count] completed`

## Fixed Issues
✅ Tasks without reminders now show in TODAY section (they're today's tasks by default)
✅ All tasks visible in ALL TASKS section
✅ AI can work with any task using the UUID
✅ Counts are accurate and match what user sees

---

**Status**: Ready to deploy  
**Testing**: Ask AI:
- "How many tasks do I have today?" → Shows correct TODAY count
- "Show me all my tasks" → Lists all tasks with UUIDs
- "Delete [task name]" or "Mark [task name] complete" → Works on that task
