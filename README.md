High-level Summary

• Name (as shown in UI): FocusFlow
• Platform: iOS (SwiftUI)
• Purpose: A focus and habit app that helps users run focus sessions, track progress and streaks, view stats, and manage a personal profile. It supports cloud sync for sessions and stats when signed in, and a guest mode with local-only data.

FocusFlow is a calm, elegant app designed to help you get serious work done without distractions. Start focus sessions, build streaks, and track your progress over time. You’ll see your achievements, level up as you accumulate focus hours, and personalize your profile with a fun avatar and theme. You can use the app as a guest, or sign in to sync your sessions and stats securely in the cloud. The app greets you with a premium splash screen, then takes you to a clean tab-based experience: Focus, Habits, Stats, and Profile.

Feature List (plain-language summaries)
• Premium launch and onboarding
   • Beautiful animated splash screen and a welcoming auth landing page that explains the benefits and offers sign-in, email, or “Skip for now.”
• Simple authentication or guest mode
   • Use the app without an account, or sign in (including Sign in with Apple) to sync your data. Previously signed-in users are restored automatically.
• Tab-based layout that’s easy to navigate
   • Focus: Start, pause, and complete timed sessions with a glowing orb, smooth progress ring, and intention field.
   • Habits: Create small routines, add reminders and repeat schedules, and check them off daily with friendly swipe actions and a donut progress view.
   • Stats: See your total focused time, session counts, best streak, recent activity, achievements, and leveling progress (Stats screen referenced across the codebase; core stats and UI are implemented in Profile and Focus).
   • Profile: Customize your avatar and theme, view achievements and level, adjust settings, and manage your account.
• Focus sessions that feel great to use
   • One-tap start/pause with haptic feedback and subtle sounds.
   • Add a short “intention” for each session (e.g., “Deep work: writing”).
   • Choose presets for fast session setup; switch themes and sounds automatically with presets.
   • Live Activities integration (Dynamic Island) to pause/resume and keep the timer in sync when the app is backgrounded.
   • Optional ambient focus sounds or launch your external music app at the start of a session.
   • Automatic local notification when a session completes.
• Habit tracking you’ll actually maintain
   • Add/edit habits with name, date/time reminders, duration, and repeat options (none/daily/weekly/monthly/yearly).
   • Swipe to edit or delete; reorder habits; clean, glass-card UI.
   • Clear progress donut and supportive empty states.
• Stats that motivate
   • Totals: lifetime focus time, session count, and best streak.
   • Recent activity: latest sessions with names, durations, and timestamps.
   • Level up every 5 hours of total focus time; ranks from Novice → Master with a visual progress bar.
   • Achievements for milestones like first session, streaks (3, 7, 30 days), and time goals (10, 50, 100+ hours), with an Achievements Legend sheet that explains each badge.
• Personalization and settings
   • Themes: switch accent color palettes that update gradients and accents throughout the app.
   • Avatars: choose from a curated set of gradient SF Symbol avatars—no photo permissions needed.
   • Sounds and Haptics: enable/disable timer sounds and device haptics.
   • Daily Goal: set a daily focus target in minutes.
   • Preferences: pick an external music app or a built-in ambient sound.
   • Reset: a protected “type reset to confirm” flow.
• Cloud sync via Supabase (secure and resilient)
   • Syncs focus sessions and stats when signed in with a valid access token.
   • Smart sync engines:
      • Pull baseline on login and suppress echo pushes.
      • Debounced local changes for efficient network usage.
      • Tracks deletions safely with per-user tombstones, retries when possible.
      • Per-user isolation to prevent data mixing between accounts.
   • Separate APIs for sessions, stats settings, user preferences, and profile details.
   • Handles token refresh, 401 responses, and keeps the user signed in while safely clearing expired access tokens.
• Thoughtful design details
   • Gradient backgrounds, soft glows, and glass-style cards.
   • Monospaced duration text for clarity.
   • Haptics and short UI sounds for start/pause/completion/minute ticks.
   • Smooth animations on progress and interactions.

What’s implemented in the files you shared
• ContentView.swift􀰓
   • Splash/launch animation (FocusBarLaunchView)
   • Auth restoration and routing (AuthLandingView or main tabs)
   • TabView for Focus, Habits, Stats, Profile
• AuthLandingView.swift􀰓
   • Welcome screen with Sign in with Apple, email option, and “Skip for now”
   • Completes login and ensures a user profile exists in the cloud
• FocusView.swift􀰓
   • Full focus session experience: intention, presets, sound controls, Live Activities sync, local notifications, and rich animations
• HabitsView.swift􀰓
   • Full habit tracker with add/edit sheets, reminders, repeat schedules, durations, swipe actions, reordering, and donut progress
• ProfileView.swift􀰓
   • Avatar picker, edit profile sheet, achievements, level card and legend, hero stats, recent activity, settings sheet, and cloud sync of display name
• AuthManager.swift􀰓
   • Central auth state, session persistence, refresh-token flow, guest mode, and cloud profile creation
• AppSettings.swift􀰓
   • Global settings, themes, sound/haptic toggles, daily reminders, namespacing per account to avoid data bleed
   • Publishes snapshots to:
      • UserPreferencesSyncEngine (preferences like theme/sounds/reminders)
      • UserProfileSyncEngine (identity fields like full name/email)
• FocusSessionsAPI.swift􀰓
   • Supabase REST client for focus_sessions: fetch, bulk upsert, delete
• FocusStatsSettingsAPI.swift􀰓
   • Supabase REST client for focus_stats_settings: fetch and upsert singleton record
• FocusStatsSyncEngine.swift􀰓
   • Combine-driven sync engine coordinating sessions and stats settings; pull-on-auth, push-on-change, deletion tombstones, per-user isolation
• FocusStatsSettingsMapping.swift􀰓
   • Mapping between local snapshot and Supabase record, plus StatsManager snapshot helper
• UserPreferencesSyncEngine.swift􀰓
   • Sync for user_preferences (theme, reminders, sounds, etc.); pull-on-auth and debounced push
• UserProfileSyncEngine.swift􀰓
   • Sync for user_profiles (identity fields); pull-on-auth and debounced push
• UserProfileAPI.swift􀰓
   • Edge Function client to fetch/upsert user profile with proper Authorization and apikey headers
• SupabaseREST.swift􀰓
   • Generic REST helper reading URL and anon key from Info.plist or SupabaseConfig.shared; shared JSON encoders/decoders
