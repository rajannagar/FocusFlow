# FocusFlow Database Schema

**Complete Supabase PostgreSQL database structure**

---

## 📊 Tables Overview

```
users
├─ Authentication profiles
└─ Pro subscription status

tasks
├─ All user tasks
└─ References: users

task_completions
├─ Task completion records
└─ References: tasks, users

focus_sessions
├─ Focus session history
└─ References: users

focus_presets
├─ Custom focus presets
└─ References: users

user_settings
├─ User preferences & goals
└─ References: users
```

---

## 👥 Table: users

**Purpose**: Authentication profiles & Pro status mirror

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255),
    
    -- Pro subscription status (mirrors StoreKit)
    is_pro BOOLEAN DEFAULT FALSE,
    pro_started_at TIMESTAMP WITH TIME ZONE,
    pro_ends_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    CONSTRAINT email_lowercase CHECK (email = LOWER(email))
);

-- Indexes
CREATE INDEX users_email_idx ON users(email);
CREATE INDEX users_is_pro_idx ON users(is_pro);
CREATE INDEX users_created_at_idx ON users(created_at DESC);

-- Row Level Security
CREATE POLICY "Users can read own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);
```

---

## ✅ Table: tasks

**Purpose**: All user tasks with complete configuration

```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Core fields
    title VARCHAR(500) NOT NULL,
    description TEXT,
    
    -- Scheduling
    due_date DATE,
    reminder_date TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Repeat configuration
    repeat_rule VARCHAR(50) DEFAULT 'none',
    -- Values: 'none', 'daily', 'weekdays', 'weekends', 'weekly', 'biweekly', 'monthly'
    repeat_end_date DATE,
    
    -- Organization
    sort_index INTEGER DEFAULT 0,
    color_tag VARCHAR(50),
    priority VARCHAR(50) DEFAULT 'normal',
    -- Values: 'low', 'normal', 'high', 'urgent'
    
    -- Focus session context
    estimated_duration_minutes INTEGER,
    completed_duration_minutes INTEGER,
    preferred_preset_id UUID REFERENCES focus_presets(id) ON DELETE SET NULL,
    
    -- Timestamps (for sync conflict resolution)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    CONSTRAINT valid_repeat_rule CHECK (
        repeat_rule IN ('none', 'daily', 'weekdays', 'weekends', 'weekly', 'biweekly', 'monthly')
    )
);

-- Indexes
CREATE INDEX tasks_user_id_idx ON tasks(user_id);
CREATE INDEX tasks_user_id_completed_idx ON tasks(user_id, is_completed);
CREATE INDEX tasks_due_date_idx ON tasks(due_date);
CREATE INDEX tasks_updated_at_idx ON tasks(updated_at DESC);
CREATE INDEX tasks_user_created_idx ON tasks(user_id, created_at DESC);

-- Row Level Security
CREATE POLICY "Users can manage own tasks"
    ON tasks FOR ALL
    USING (auth.uid() = user_id);

-- Trigger: Update updated_at on change
CREATE TRIGGER tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

---

## 📋 Table: task_completions

**Purpose**: Track when tasks are completed (daily basis)

```sql
CREATE TABLE task_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    
    -- Completion date (for recurring tasks)
    completion_date DATE NOT NULL,
    completion_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Context
    session_id UUID REFERENCES focus_sessions(id) ON DELETE SET NULL,
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(task_id, completion_date)
);

-- Indexes
CREATE INDEX task_completions_user_id_idx ON task_completions(user_id);
CREATE INDEX task_completions_task_id_idx ON task_completions(task_id);
CREATE INDEX task_completions_date_idx ON task_completions(completion_date);
CREATE INDEX task_completions_user_date_idx ON task_completions(user_id, completion_date DESC);

-- Row Level Security
CREATE POLICY "Users can manage own completions"
    ON task_completions FOR ALL
    USING (auth.uid() = user_id);
```

---

## ⏱️ Table: focus_sessions

**Purpose**: Complete history of focus sessions

```sql
CREATE TABLE focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Timing
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    
    -- Session configuration
    preset_id UUID REFERENCES focus_presets(id) ON DELETE SET NULL,
    sound_used VARCHAR(100),
    ambient_mode VARCHAR(100),
    
    -- Session status
    was_completed BOOLEAN DEFAULT TRUE,
    -- true = completed full duration
    -- false = user stopped early
    
    completed_early BOOLEAN DEFAULT FALSE,
    -- true = completed <40% of full duration = "junk" session
    
    early_end_reason VARCHAR(255),
    -- "paused", "notification", "manual_stop", etc
    
    -- XP tracking
    xp_earned INTEGER,
    
    -- Associated task (if doing focused task)
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    
    -- Timestamps (for sync)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_duration CHECK (duration_seconds > 0),
    CONSTRAINT valid_times CHECK (end_time > start_time)
);

-- Indexes
CREATE INDEX focus_sessions_user_id_idx ON focus_sessions(user_id);
CREATE INDEX focus_sessions_user_date_idx ON focus_sessions(user_id, start_time DESC);
CREATE INDEX focus_sessions_created_at_idx ON focus_sessions(created_at DESC);
CREATE INDEX focus_sessions_updated_at_idx ON focus_sessions(updated_at DESC);

-- Row Level Security
CREATE POLICY "Users can manage own sessions"
    ON focus_sessions FOR ALL
    USING (auth.uid() = user_id);

-- Trigger: Update updated_at
CREATE TRIGGER focus_sessions_updated_at
    BEFORE UPDATE ON focus_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

---

## 🎯 Table: focus_presets

**Purpose**: Saved focus session configurations

```sql
CREATE TABLE focus_presets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Preset info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Configuration
    duration_seconds INTEGER NOT NULL,
    sound VARCHAR(100),
    ambient_mode VARCHAR(100),
    
    -- Metadata
    is_default BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    sort_index INTEGER DEFAULT 0,
    
    -- Settings (JSON for flexibility)
    settings JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_duration CHECK (duration_seconds >= 300 AND duration_seconds <= 5400),
    -- 5 minutes minimum, 90 minutes maximum
    
    CONSTRAINT valid_name CHECK (length(name) > 0 AND length(name) <= 255)
);

-- Indexes
CREATE INDEX focus_presets_user_id_idx ON focus_presets(user_id);
CREATE INDEX focus_presets_user_name_idx ON focus_presets(user_id, name);
CREATE INDEX focus_presets_updated_at_idx ON focus_presets(updated_at DESC);

-- Row Level Security
CREATE POLICY "Users can manage own presets"
    ON focus_presets FOR ALL
    USING (auth.uid() = user_id);

-- Trigger
CREATE TRIGGER focus_presets_updated_at
    BEFORE UPDATE ON focus_presets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

---

## ⚙️ Table: user_settings

**Purpose**: User preferences, goals, and application settings

```sql
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    -- Appearance
    theme VARCHAR(100) DEFAULT 'forest',
    dark_mode BOOLEAN DEFAULT true,
    font_size VARCHAR(50) DEFAULT 'medium',
    
    -- Focus preferences
    default_duration_minutes INTEGER DEFAULT 25,
    auto_start_next_session BOOLEAN DEFAULT FALSE,
    
    -- Notifications
    notifications_enabled BOOLEAN DEFAULT TRUE,
    notification_sound_enabled BOOLEAN DEFAULT TRUE,
    notification_style VARCHAR(100) DEFAULT 'toast',
    -- 'toast', 'banner', 'alert'
    
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    -- Goals
    daily_goal_minutes INTEGER DEFAULT 120,
    weekly_goal_minutes INTEGER DEFAULT 600,
    
    -- Gamification
    current_streak INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    total_xp INTEGER DEFAULT 0,
    
    -- Preferences
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(100),
    
    -- Advanced
    auto_delete_completed_tasks BOOLEAN DEFAULT FALSE,
    auto_delete_after_days INTEGER DEFAULT 90,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_daily_goal CHECK (daily_goal_minutes > 0),
    CONSTRAINT valid_streak CHECK (current_streak >= 0),
    CONSTRAINT valid_level CHECK (current_level > 0 AND current_level <= 50),
    CONSTRAINT valid_xp CHECK (total_xp >= 0)
);

-- Indexes
CREATE INDEX user_settings_user_id_idx ON user_settings(user_id);
CREATE INDEX user_settings_updated_at_idx ON user_settings(updated_at DESC);

-- Row Level Security
CREATE POLICY "Users can manage own settings"
    ON user_settings FOR ALL
    USING (auth.uid() = user_id);

-- Trigger
CREATE TRIGGER user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

---

## 🔧 Helper Functions

### **Update Timestamp Function**

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### **Calculate User Stats Function**

```sql
CREATE OR REPLACE FUNCTION calculate_user_stats(user_uuid UUID)
RETURNS TABLE(
    total_focus_minutes INTEGER,
    total_sessions INTEGER,
    total_tasks_completed INTEGER,
    current_streak INTEGER,
    total_xp INTEGER
) AS $$
BEGIN
    RETURN QUERY SELECT
        COALESCE(SUM(duration_seconds) / 60, 0)::INTEGER,
        COUNT(DISTINCT id)::INTEGER,
        COUNT(DISTINCT task_id)::INTEGER,
        (SELECT current_streak FROM user_settings WHERE user_id = user_uuid),
        (SELECT total_xp FROM user_settings WHERE user_id = user_uuid)
    FROM focus_sessions
    WHERE user_id = user_uuid AND created_at > NOW() - INTERVAL '1 year';
END;
$$ LANGUAGE plpgsql;
```

---

## 🔐 Security Policies Summary

```sql
-- All tables have RLS enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
-- Enforced at database level
-- No client-side checks needed
```

---

## 📈 Views (Optional)

```sql
-- User stats summary
CREATE VIEW user_stats_view AS
SELECT
    u.id,
    u.email,
    COUNT(DISTINCT fs.id) as total_sessions,
    SUM(fs.duration_seconds) / 60 as total_minutes,
    COUNT(DISTINCT tc.id) as total_completions,
    us.current_streak,
    us.total_xp,
    us.current_level
FROM users u
LEFT JOIN focus_sessions fs ON u.id = fs.user_id
LEFT JOIN task_completions tc ON u.id = tc.user_id
LEFT JOIN user_settings us ON u.id = us.user_id
GROUP BY u.id, u.email, us.current_streak, us.total_xp, us.current_level;

-- Weekly summary
CREATE VIEW weekly_summary_view AS
SELECT
    user_id,
    DATE_TRUNC('week', start_time) as week,
    COUNT(*) as session_count,
    SUM(duration_seconds) / 60 as total_minutes,
    AVG(duration_seconds) / 60 as avg_minutes
FROM focus_sessions
GROUP BY user_id, DATE_TRUNC('week', start_time);
```

---

## 🚀 Migrations

Migrations are managed via Supabase CLI:

```bash
# Create migration
supabase migration new create_tables

# Apply migrations
supabase db push

# Reset database (dev only)
supabase db reset
```

---

**Last Updated**: January 7, 2026  
**Version**: 2.0
