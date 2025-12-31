-- =========================================================
-- Database Migration: Add Goal History and Notification Preferences
-- =========================================================
-- This migration adds two new JSONB columns to the user_settings table
-- to enable cloud sync for per-day goal history and notification preferences.
--
-- Run this migration on your Supabase database before deploying the app update.
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

-- Optional: Create index on goal_history for faster queries (if needed in future)
-- CREATE INDEX IF NOT EXISTS idx_user_settings_goal_history ON user_settings USING GIN (goal_history);

-- =========================================================
-- Verification Query
-- =========================================================
-- Run this to verify the migration:
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'user_settings' 
-- AND column_name IN ('goal_history', 'notification_preferences');

