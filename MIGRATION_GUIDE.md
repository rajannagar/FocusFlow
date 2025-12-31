# Database Migration Guide

## Quick Start: Run Migration via Supabase Dashboard

### Step 1: Open Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sign in to your account
3. Select your **FocusFlow** project

### Step 2: Open SQL Editor
1. In the left sidebar, click **SQL Editor**
2. Click **New Query** (or use the existing query editor)

### Step 3: Copy and Paste Migration SQL
Copy the entire contents of `DATABASE_MIGRATION.sql` and paste it into the SQL editor:

```sql
-- Add goal_history column
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS goal_history JSONB DEFAULT '{}'::jsonb;

-- Add notification_preferences column
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}'::jsonb;

-- Add comments for documentation
COMMENT ON COLUMN user_settings.goal_history IS 'Per-day goal history stored as JSON object: date string (YYYY-MM-DD) -> goal minutes (integer)';
COMMENT ON COLUMN user_settings.notification_preferences IS 'User notification preferences stored as JSON (NotificationPreferences struct)';
```

### Step 4: Run the Migration
1. Click **Run** (or press `Cmd+Enter` / `Ctrl+Enter`)
2. Wait for the success message: "Success. No rows returned"

### Step 5: Verify the Migration
Run this verification query in the SQL editor:

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_settings' 
AND column_name IN ('goal_history', 'notification_preferences');
```

You should see both columns listed with:
- `column_name`: `goal_history` and `notification_preferences`
- `data_type`: `jsonb`
- `column_default`: `'{}'::jsonb`

---

## Alternative: Using Supabase CLI (If Installed)

If you have Supabase CLI installed, you can run:

```bash
# Navigate to your project directory
cd "/Users/rajannagar/Rajan Nagar/FocusFlow"

# Run the migration
supabase db push --file supabase/migrations/$(date +%Y%m%d%H%M%S)_add_goal_history_and_notification_prefs.sql
```

Or create a migration file and run it:

```bash
# Create migration file
cat DATABASE_MIGRATION.sql > supabase/migrations/$(date +%Y%m%d%H%M%S)_add_goal_history_and_notification_prefs.sql

# Apply migration
supabase db push
```

---

## What the Migration Does

1. **Adds `goal_history` column:**
   - Type: JSONB
   - Default: `{}` (empty JSON object)
   - Stores per-day goals as: `{"2024-01-15": 60, "2024-01-16": 120}`

2. **Adds `notification_preferences` column:**
   - Type: JSONB
   - Default: `{}` (empty JSON object)
   - Stores notification preferences as JSON

3. **Adds documentation comments** to both columns

---

## Troubleshooting

### Error: "column already exists"
- This means the migration was already run
- The `IF NOT EXISTS` clause prevents errors, so you can safely run it again
- Check the verification query to confirm columns exist

### Error: "permission denied"
- Make sure you're using the correct database role
- You may need to run as a database admin
- Check your Supabase project permissions

### Error: "relation user_settings does not exist"
- The `user_settings` table doesn't exist yet
- You may need to create it first or check your table name
- Verify the table exists: `SELECT * FROM information_schema.tables WHERE table_name = 'user_settings';`

---

## After Migration

Once the migration is complete:
1. ✅ The app code is already updated to use these columns
2. ✅ New data will automatically sync to cloud
3. ✅ Existing users' data will be preserved
4. ✅ Test by setting goals and notification preferences, then reinstalling the app

---

## Need Help?

If you encounter any issues:
1. Check the Supabase dashboard logs
2. Verify your database connection
3. Make sure you're running the migration on the correct database (production vs. development)

