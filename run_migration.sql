-- =========================================================
-- READY-TO-RUN Migration Script
-- =========================================================
-- Copy and paste this entire file into Supabase SQL Editor
-- =========================================================

-- Add goal_history column (stores per-day goals as JSON: {"2024-01-15": 60, "2024-01-16": 120})
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS goal_history JSONB DEFAULT '{}'::jsonb;

-- Add notification_preferences column (stores NotificationPreferences as JSON)
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}'::jsonb;

-- Add comments for documentation
COMMENT ON COLUMN user_settings.goal_history IS 'Per-day goal history stored as JSON object: date string (YYYY-MM-DD) -> goal minutes (integer)';
COMMENT ON COLUMN user_settings.notification_preferences IS 'User notification preferences stored as JSON (NotificationPreferences struct)';

-- Verification: Check if columns were added successfully
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_settings' 
AND column_name IN ('goal_history', 'notification_preferences');

