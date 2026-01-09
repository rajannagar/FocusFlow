# ☁️ FocusFlow Backend Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Supabase Setup](#supabase-setup)
4. [Authentication](#authentication)
5. [Database Schema](#database-schema)
6. [Sync System](#sync-system)
7. [Edge Functions](#edge-functions)
8. [Flow AI Integration](#flow-ai-integration)
9. [Security](#security)
10. [Deployment](#deployment)

---

## Overview

FocusFlow uses Supabase as its backend-as-a-service platform, providing:

- **Authentication** - Email/password, OAuth (Google, Apple)
- **PostgreSQL Database** - User data, sessions, tasks, presets
- **Edge Functions** - Serverless AI chat endpoint
- **Row Level Security** - User data isolation
- **Realtime** - Cross-device sync (future)

### Infrastructure Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         FOCUSFLOW BACKEND                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                            SUPABASE                                  │ │
│  │                                                                      │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │                        AUTH SERVICE                            │ │ │
│  │  │                                                                │ │ │
│  │  │  • Email/Password Authentication                               │ │ │
│  │  │  • OAuth Providers (Google, Apple)                             │ │ │
│  │  │  • Magic Links                                                 │ │ │
│  │  │  • Password Reset                                              │ │ │
│  │  │  • Session Management (JWT)                                    │ │ │
│  │  │  • PKCE Flow for Mobile                                        │ │ │
│  │  │                                                                │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                      │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │                     POSTGRESQL DATABASE                        │ │ │
│  │  │                                                                │ │ │
│  │  │  Tables:                                                       │ │ │
│  │  │  • progress_sessions - Focus session records                   │ │ │
│  │  │  • tasks - User tasks                                          │ │ │
│  │  │  • task_completions - Task completion records                  │ │ │
│  │  │  • presets - Focus presets                                     │ │ │
│  │  │  • user_settings - App settings                                │ │ │
│  │  │  • profiles - User profile data                                │ │ │
│  │  │                                                                │ │ │
│  │  │  Features:                                                     │ │ │
│  │  │  • Row Level Security (RLS)                                    │ │ │
│  │  │  • Timestamp-based conflict resolution                         │ │ │
│  │  │                                                                │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                      │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │                     EDGE FUNCTIONS                             │ │ │
│  │  │                                                                │ │ │
│  │  │  ai-chat/                                                      │ │ │
│  │  │  • Proxies OpenAI API calls                                    │ │ │
│  │  │  • Validates JWT tokens                                        │ │ │
│  │  │  • Handles function calling                                    │ │ │
│  │  │                                                                │ │ │
│  │  │  delete-user/ (future)                                         │ │ │
│  │  │  • Account deletion                                            │ │ │
│  │  │                                                                │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                      │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                           OPENAI API                                 │ │
│  │                                                                      │ │
│  │  • GPT-4o Model                                                      │ │
│  │  • Function Calling (Tools)                                          │ │
│  │  • Streaming Responses                                               │ │
│  │                                                                      │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Supabase Setup

### Configuration File

**Location:** `supabase/config.toml`

```toml
[functions."ai-chat"]
verify_jwt = false  # JWT verified manually in function
```

### Project Configuration

```
Project URL:     https://xxx.supabase.co
Anon Key:        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Service Key:     (secret - never expose)
Database URL:    postgresql://postgres:xxx@xxx.supabase.co:5432/postgres
```

### iOS App Configuration

In `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>https://xxx.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</string>
```

### SupabaseManager (iOS)

```swift
// FocusFlow/Infrastructure/Cloud/SupabaseManager.swift

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    static let redirectScheme = "ca.softcomputers.FocusFlow"
    static let redirectURL = URL(string: "\(redirectScheme)://login-callback")!
    
    private init() {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              let supabaseURL = URL(string: url) else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist")
        }
        
        let config = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                redirectToURL: Self.redirectURL,
                flowType: .pkce,
                emitLocalSessionAsInitialSession: true
            )
        )
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: config
        )
    }
}
```

---

## Authentication

### Supported Auth Methods

| Method | Status | Description |
|--------|--------|-------------|
| Email/Password | ✅ | Traditional signup/signin |
| Google OAuth | ✅ | Sign in with Google |
| Apple OAuth | ✅ | Sign in with Apple |
| Magic Link | ✅ | Passwordless email |
| Guest Mode | ✅ | Local-only, no account |

### Auth States

```swift
enum CloudAuthState: Equatable {
    case unknown        // App initializing
    case guest          // Local-only mode
    case signedIn(userId: UUID)  // Authenticated
    case signedOut      // Logged out
}
```

### Auth Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION FLOW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   App Launch                                                            │
│       │                                                                 │
│       ▼                                                                 │
│   Check for existing session                                            │
│       │                                                                 │
│       ├── Session exists ──► state = .signedIn(userId)                 │
│       │                           │                                     │
│       │                           ▼                                     │
│       │                   Start SyncCoordinator                         │
│       │                                                                 │
│       ├── Guest mode flag ──► state = .guest                           │
│       │                           │                                     │
│       │                           ▼                                     │
│       │                   Local-only storage                            │
│       │                                                                 │
│       └── No session ──► state = .signedOut                            │
│                               │                                         │
│                               ▼                                         │
│                         AuthLandingView                                 │
│                               │                                         │
│       ┌───────────────────────┼───────────────────────┐                │
│       │                       │                       │                │
│       ▼                       ▼                       ▼                │
│   Email Auth           Google OAuth            Continue as Guest       │
│       │                       │                       │                │
│       ▼                       ▼                       ▼                │
│   Sign In/Up            OAuth Flow             Set guest flag          │
│       │                       │                       │                │
│       └───────────────────────┴───────────────────────┘                │
│                               │                                         │
│                               ▼                                         │
│                   state = .signedIn / .guest                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Deep Link Handling (OAuth)

```swift
// URL Scheme: ca.softcomputers.FocusFlow://login-callback

func handleDeepLink(_ url: URL) async -> Bool {
    guard url.scheme?.lowercased() == "ca.softcomputers.focusflow" else {
        return false
    }
    
    do {
        try await client.auth.session(from: url)
        return true
    } catch {
        print("Deep link error: \(error)")
        return false
    }
}
```

### AuthManagerV2

```swift
// FocusFlow/Infrastructure/Cloud/AuthManagerV2.swift

@MainActor
final class AuthManagerV2: ObservableObject {
    static let shared = AuthManagerV2()
    
    @Published private(set) var state: CloudAuthState = .unknown
    
    // Sign In
    func signInWithEmail(email: String, password: String) async throws {
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        state = .signedIn(userId: response.user.id)
    }
    
    // Sign Up
    func signUpWithEmail(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            redirectTo: SupabaseManager.redirectURL
        )
        // User needs to verify email before signedIn state
    }
    
    // OAuth
    func signInWithGoogle() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: SupabaseManager.redirectURL
        )
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }
    
    // Sign Out
    func signOut() async {
        try? await supabase.auth.signOut()
        state = .signedOut
    }
    
    // Guest Mode
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: "AuthManagerV2.isGuestMode")
        state = .guest
    }
}
```

---

## Database Schema

### Tables Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATABASE SCHEMA                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     progress_sessions                          │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  id              UUID PRIMARY KEY                              │    │
│  │  user_id         UUID REFERENCES auth.users(id)                │    │
│  │  duration        INTEGER (seconds)                             │    │
│  │  session_name    TEXT                                          │    │
│  │  recorded_at     TIMESTAMPTZ                                   │    │
│  │  created_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  │  updated_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                         tasks                                  │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  id              UUID PRIMARY KEY                              │    │
│  │  user_id         UUID REFERENCES auth.users(id)                │    │
│  │  title           TEXT NOT NULL                                 │    │
│  │  notes           TEXT                                          │    │
│  │  reminder_date   TIMESTAMPTZ                                   │    │
│  │  repeat_rule     TEXT ('none', 'daily', 'weekly', etc.)        │    │
│  │  custom_weekdays INTEGER[]                                     │    │
│  │  duration_minutes INTEGER DEFAULT 0                            │    │
│  │  sort_index      INTEGER DEFAULT 0                             │    │
│  │  excluded_day_keys TEXT[]                                      │    │
│  │  is_deleted      BOOLEAN DEFAULT false                         │    │
│  │  created_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  │  updated_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     task_completions                           │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  id              UUID PRIMARY KEY                              │    │
│  │  user_id         UUID REFERENCES auth.users(id)                │    │
│  │  task_id         UUID REFERENCES tasks(id)                     │    │
│  │  completed_date  DATE                                          │    │
│  │  created_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                         presets                                │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  id              UUID PRIMARY KEY                              │    │
│  │  user_id         UUID REFERENCES auth.users(id)                │    │
│  │  name            TEXT NOT NULL                                 │    │
│  │  duration_seconds INTEGER                                      │    │
│  │  sound_id        TEXT                                          │    │
│  │  emoji           TEXT                                          │    │
│  │  is_system_default BOOLEAN DEFAULT false                       │    │
│  │  theme_raw       TEXT                                          │    │
│  │  music_app_raw   TEXT                                          │    │
│  │  ambiance_raw    TEXT                                          │    │
│  │  is_deleted      BOOLEAN DEFAULT false                         │    │
│  │  created_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  │  updated_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     user_settings                              │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  user_id         UUID PRIMARY KEY REFERENCES auth.users(id)    │    │
│  │  daily_goal_minutes INTEGER DEFAULT 60                         │    │
│  │  theme_id        TEXT DEFAULT 'forest'                         │    │
│  │  sound_enabled   BOOLEAN DEFAULT true                          │    │
│  │  haptics_enabled BOOLEAN DEFAULT true                          │    │
│  │  display_name    TEXT                                          │    │
│  │  tagline         TEXT                                          │    │
│  │  avatar_id       TEXT                                          │    │
│  │  created_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  │  updated_at      TIMESTAMPTZ DEFAULT now()                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE progress_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own sessions"
ON progress_sessions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
ON progress_sessions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
ON progress_sessions FOR UPDATE
USING (auth.uid() = user_id);

-- Similar policies for other tables...
```

---

## Sync System

### Sync Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SYNC SYSTEM                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    SyncCoordinator                             │    │
│  │                                                                │    │
│  │  • Orchestrates all sync engines                               │    │
│  │  • Observes auth state changes                                 │    │
│  │  • Observes Pro status changes                                 │    │
│  │  • Handles periodic sync (60s interval)                        │    │
│  │  • Pro required for sync                                       │    │
│  │                                                                │    │
│  └───────────────────────────┬────────────────────────────────────┘    │
│                              │                                          │
│          ┌──────────────────────────────────────────┐                  │
│          │                   │                      │                  │
│          ▼                   ▼                      ▼                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐         │
│  │SettingsSync  │    │ TasksSync    │    │ SessionsSync     │         │
│  │Engine        │    │ Engine       │    │ Engine           │         │
│  └──────────────┘    └──────────────┘    └──────────────────┘         │
│          │                   │                      │                  │
│          │                   │                      │                  │
│          ▼                   ▼                      ▼                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐         │
│  │ PresetsSync  │    │  SyncQueue   │    │LocalTimestamp    │         │
│  │ Engine       │    │              │    │Tracker           │         │
│  └──────────────┘    └──────────────┘    └──────────────────┘         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Sync Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SYNC FLOW                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  User Signs In (with Pro)                                               │
│       │                                                                 │
│       ▼                                                                 │
│  SyncCoordinator.handleAuthStateChange()                                │
│       │                                                                 │
│       ▼                                                                 │
│  Check gap since last sync                                              │
│       │                                                                 │
│       ├── Gap > 7 days ──► Merge local + remote (keep both)            │
│       │                                                                 │
│       └── Gap ≤ 7 days ──► Normal sync (timestamp-based)               │
│                               │                                         │
│                               ▼                                         │
│                     ┌─────────────────────────────────────┐             │
│                     │        For each engine:             │             │
│                     │  1. Pull from remote                │             │
│                     │  2. Compare timestamps              │             │
│                     │  3. Merge (remote wins if newer)    │             │
│                     │  4. Push local changes              │             │
│                     └─────────────────────────────────────┘             │
│                                                                         │
│  Background Sync (every 60s)                                            │
│       │                                                                 │
│       ▼                                                                 │
│  pullFromRemote() ──► Check for changes from other devices              │
│                                                                         │
│  User Makes Change                                                      │
│       │                                                                 │
│       ▼                                                                 │
│  Store.save() ──► LocalTimestampTracker.recordChange()                 │
│       │                      │                                          │
│       │                      ▼                                          │
│       │            SyncQueue.enqueue() (if offline)                    │
│       │                                                                 │
│       └──► SyncCoordinator.pushToRemote()                              │
│                                                                         │
│  App Goes to Background                                                 │
│       │                                                                 │
│       ▼                                                                 │
│  forcePushAllPending() ──► Flush SyncQueue                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Conflict Resolution

```swift
// Timestamp-based conflict resolution
// Remote wins if its timestamp is newer

func resolve(local: Data, remote: Data) -> Data {
    let localTimestamp = LocalTimestampTracker.shared.lastChange(for: field)
    let remoteTimestamp = remote.updated_at
    
    if remoteTimestamp > localTimestamp {
        // Remote is newer - use remote
        return remote
    } else {
        // Local is newer - push to remote
        return local
    }
}
```

### Pro Gating

```swift
// Only Pro users can sync
guard ProGatingHelper.shared.canUseCloudSync else {
    // Show upgrade prompt or stay local-only
    return
}

// ProGatingHelper.canUseCloudSync =
//   ProEntitlementManager.shared.isPro && AuthManagerV2.shared.state.isSignedIn
```

---

## Edge Functions

### AI Chat Function

**Location:** `supabase/functions/ai-chat/`

The `ai-chat` Edge Function proxies requests to OpenAI, keeping the API key secure on the server.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       AI CHAT FUNCTION FLOW                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   iOS App                                                               │
│      │                                                                  │
│      │  POST /functions/v1/ai-chat                                      │
│      │  Headers:                                                        │
│      │    Authorization: Bearer {user_jwt}                              │
│      │    apikey: {supabase_anon_key}                                   │
│      │  Body:                                                           │
│      │    { userMessage, conversationHistory, context }                 │
│      │                                                                  │
│      ▼                                                                  │
│   Edge Function (Deno)                                                  │
│      │                                                                  │
│      ├── Verify JWT token                                               │
│      │                                                                  │
│      ├── Get OPENAI_API_KEY from secrets                                │
│      │                                                                  │
│      ├── Build messages array with system prompt + context              │
│      │                                                                  │
│      ├── Call OpenAI API (gpt-4o)                                       │
│      │      │                                                           │
│      │      ├── Function calling for actions                            │
│      │      │                                                           │
│      │      └── Response text                                           │
│      │                                                                  │
│      ├── Parse response + actions                                       │
│      │                                                                  │
│      └── Return JSON response                                           │
│              │                                                          │
│              ▼                                                          │
│   iOS App ──► Execute actions (create task, start focus, etc.)          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Function Code Structure

```typescript
// supabase/functions/ai-chat/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AIChatRequest {
  userMessage: string
  conversationHistory: Array<{ sender: string; text: string }>
  context: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Verify authorization
  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  // Get OpenAI API key
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  
  // Parse request
  const { userMessage, conversationHistory, context } = await req.json()
  
  // Build messages with system prompt
  const messages = [
    { role: 'system', content: SYSTEM_PROMPT + '\n\n' + context },
    ...conversationHistory.map(msg => ({
      role: msg.sender === 'user' ? 'user' : 'assistant',
      content: msg.text
    })),
    { role: 'user', content: userMessage }
  ]
  
  // Call OpenAI
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages,
      tools,  // Function definitions
      tool_choice: 'auto',
    }),
  })
  
  // Parse and return
  const result = await response.json()
  const assistantMessage = result.choices[0].message
  
  // Extract actions from tool calls
  const actions = parseToolCalls(assistantMessage.tool_calls)
  
  return new Response(JSON.stringify({
    response: assistantMessage.content,
    actions,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
```

### Available Tool Functions

```typescript
const tools = [
  // Task Management
  {
    type: "function",
    function: {
      name: "create_task",
      description: "Create a new task",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string" },
          reminderDate: { type: "string", format: "date-time" },
          repeatRule: { type: "string", enum: ["none", "daily", "weekly", "monthly"] },
          notes: { type: "string" },
          durationMinutes: { type: "integer" }
        },
        required: ["title"]
      }
    }
  },
  { name: "complete_task", ... },
  { name: "delete_task", ... },
  { name: "list_tasks", ... },
  
  // Focus Management
  { name: "start_focus", ... },
  { name: "pause_focus", ... },
  { name: "resume_focus", ... },
  { name: "end_focus", ... },
  
  // Settings
  { name: "set_daily_goal", ... },
  { name: "create_preset", ... },
  
  // Information
  { name: "get_progress", ... },
  { name: "get_streak", ... },
]
```

---

## Flow AI Integration

### Client-Side Setup

```swift
// FlowConfig.swift
enum FlowConfig {
    static var apiURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            return ""
        }
        return "\(url)/functions/v1/ai-chat"
    }
    
    static var isConfigured: Bool {
        !apiURL.isEmpty
    }
    
    static let requestTimeout: TimeInterval = 30
    static let streamTimeout: TimeInterval = 60
    static let maxContextCharacters = 24000
    static let maxConversationHistory = 20
    static let modelName = "gpt-4o"
}
```

### FlowService

```swift
// FlowService.swift

@MainActor
final class FlowService {
    static let shared = FlowService()
    
    func sendMessage(
        userMessage: String,
        conversationHistory: [FlowMessage],
        context: String
    ) async throws -> FlowResponse {
        
        // Get auth token
        let authToken = try await SupabaseManager.shared.currentUserToken()
        
        // Build request
        let body: [String: Any] = [
            "userMessage": userMessage,
            "conversationHistory": history,
            "context": context,
        ]
        
        var request = URLRequest(url: URL(string: FlowConfig.apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["response"] as? String ?? ""
        let actions = parseActions(json?["actions"])
        
        return FlowResponse(content: content, actions: actions)
    }
}
```

### Action Execution

```swift
// FlowActionHandler.swift

@MainActor
final class FlowActionHandler {
    static let shared = FlowActionHandler()
    
    func execute(_ action: FlowAction) async -> ActionResult {
        switch action {
        case .createTask(let title, let reminderDate, let repeatRule):
            let task = FFTaskItem(
                title: title,
                reminderDate: reminderDate,
                repeatRule: repeatRule ?? .none
            )
            TasksStore.shared.upsert(task)
            return .success("Created task '\(title)'")
            
        case .startFocus(let minutes, let name, let presetId):
            // Navigate to focus tab and start session
            FlowNavigationCoordinator.shared.navigateToFocus(
                startSession: true,
                duration: minutes,
                presetId: presetId
            )
            return .success("Starting \(minutes)-minute focus session")
            
        case .setDailyGoal(let minutes):
            ProgressStore.shared.dailyGoalMinutes = minutes
            return .success("Set daily goal to \(minutes) minutes")
            
        // ... more cases
        }
    }
}
```

---

## Security

### Security Measures

| Layer | Measure | Implementation |
|-------|---------|----------------|
| **Transport** | HTTPS | All API calls encrypted |
| **Authentication** | JWT | Supabase Auth tokens |
| **Authorization** | RLS | Row Level Security on all tables |
| **API Keys** | Server-side | OpenAI key never exposed to client |
| **OAuth** | PKCE | Secure mobile OAuth flow |
| **Sessions** | Auto-refresh | Token refresh before expiry |

### Never Expose

```
❌ SUPABASE_SERVICE_KEY (admin access)
❌ OPENAI_API_KEY
❌ Database connection string
❌ JWT signing secret
```

### Client-Safe

```
✅ SUPABASE_URL (public)
✅ SUPABASE_ANON_KEY (public, rate-limited)
✅ APP_STORE_URL
```

---

## Deployment

### Supabase CLI Commands

```bash
# Login to Supabase
supabase login

# Link to project
supabase link --project-ref your-project-ref

# Deploy Edge Functions
supabase functions deploy ai-chat

# Set secrets
supabase secrets set OPENAI_API_KEY=sk-proj-...

# View logs
supabase functions logs ai-chat

# Run locally
supabase functions serve ai-chat --env-file .env.local
```

### Environment Variables

**Edge Function Secrets:**
```bash
supabase secrets set OPENAI_API_KEY=sk-proj-...
```

**Local Development (.env.local):**
```
OPENAI_API_KEY=sk-proj-...
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=...
```

### Monitoring

- **Supabase Dashboard:** Auth, Database, Edge Function logs
- **OpenAI Dashboard:** Usage, costs, rate limits

---

## Troubleshooting

### Common Issues

#### 1. "Unauthorized" Error

**Cause:** Invalid or expired JWT token

**Solution:**
- Check token refresh logic in `SupabaseManager.currentUserToken()`
- Verify token format: `Bearer eyJhbG...`

#### 2. RLS Blocking Queries

**Cause:** Missing or incorrect RLS policies

**Solution:**
- Verify `auth.uid()` matches `user_id` column
- Check policy exists for the operation (SELECT, INSERT, UPDATE, DELETE)

#### 3. Edge Function Timeout

**Cause:** OpenAI API slow response

**Solution:**
- Increase function timeout in config
- Implement streaming for long responses

#### 4. Sync Conflicts

**Cause:** Simultaneous edits from multiple devices

**Solution:**
- Timestamp-based resolution (newer wins)
- Merge strategy for >7 day gaps

---

*Last Updated: January 2026*
