# FocusFlow API Reference

**Complete REST API and Edge Function documentation**

---

## 🌐 API Overview

FocusFlow uses **Supabase** for backend infrastructure:
- REST API for CRUD operations
- PostgreSQL with Row-Level Security
- Edge Functions for custom logic
- Real-time subscriptions (future)

---

## 🔑 Authentication

### **Bearer Token**

All API requests require authentication:

```
Authorization: Bearer <JWT_TOKEN>
```

**Token Format**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Obtaining Token**:
```swift
// Via Supabase Auth client
let session = try await supabase.auth.signIn(email: "user@example.com", password: "password")
let token = session.accessToken
```

---

## 📋 REST API Endpoints

### **1. Tasks**

#### **GET /rest/v1/tasks**

Fetch all user tasks

**Request**:
```bash
curl -X GET "https://project.supabase.co/rest/v1/tasks" \
  -H "Authorization: Bearer TOKEN"
```

**Response** (200):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Write proposal",
    "description": "Q1 product roadmap proposal",
    "due_date": "2025-01-15",
    "reminder_date": "2025-01-15T14:00:00Z",
    "is_completed": false,
    "repeat_rule": "none",
    "sort_index": 1,
    "created_at": "2025-01-07T10:00:00Z",
    "updated_at": "2025-01-07T10:00:00Z"
  }
]
```

---

#### **POST /rest/v1/tasks**

Create new task

**Request**:
```bash
curl -X POST "https://project.supabase.co/rest/v1/tasks" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "due_date": "2025-01-10",
    "repeat_rule": "weekly"
  }'
```

**Response** (201):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "title": "Buy groceries",
  "due_date": "2025-01-10",
  "created_at": "2025-01-07T10:05:00Z"
}
```

---

#### **PATCH /rest/v1/tasks?id=eq.{task_id}**

Update task

**Request**:
```bash
curl -X PATCH "https://project.supabase.co/rest/v1/tasks?id=eq.550e8400-e29b-41d4-a716-446655440002" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "is_completed": true,
    "completed_at": "2025-01-10T15:30:00Z"
  }'
```

**Response** (200):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "is_completed": true,
  "completed_at": "2025-01-10T15:30:00Z",
  "updated_at": "2025-01-10T15:30:00Z"
}
```

---

#### **DELETE /rest/v1/tasks?id=eq.{task_id}**

Delete task

**Request**:
```bash
curl -X DELETE "https://project.supabase.co/rest/v1/tasks?id=eq.550e8400-e29b-41d4-a716-446655440002" \
  -H "Authorization: Bearer TOKEN"
```

**Response** (204): No content

---

### **2. Focus Sessions**

#### **GET /rest/v1/focus_sessions**

Fetch all sessions

**Query Parameters**:
```
?user_id=eq.{user_id}
&start_time=gt.{date}
&order=start_time.desc
&limit=100
```

**Request**:
```bash
curl -X GET "https://project.supabase.co/rest/v1/focus_sessions?user_id=eq.550e8400-e29b-41d4-a716-446655440001&start_time=gt.2025-01-01&order=start_time.desc" \
  -H "Authorization: Bearer TOKEN"
```

**Response** (200):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440010",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "start_time": "2025-01-07T10:00:00Z",
    "end_time": "2025-01-07T10:25:00Z",
    "duration_seconds": 1500,
    "preset_id": "550e8400-e29b-41d4-a716-446655440003",
    "sound_used": "light_rain",
    "ambient_mode": "forest",
    "was_completed": true,
    "xp_earned": 25,
    "created_at": "2025-01-07T10:25:00Z"
  }
]
```

---

#### **POST /rest/v1/focus_sessions**

Create new session

**Request**:
```bash
curl -X POST "https://project.supabase.co/rest/v1/focus_sessions" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_time": "2025-01-07T14:00:00Z",
    "end_time": "2025-01-07T14:25:00Z",
    "duration_seconds": 1500,
    "preset_id": "550e8400-e29b-41d4-a716-446655440003",
    "sound_used": "light_rain",
    "was_completed": true,
    "xp_earned": 25
  }'
```

**Response** (201):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440011",
  "duration_seconds": 1500,
  "xp_earned": 25,
  "created_at": "2025-01-07T14:25:00Z"
}
```

---

### **3. Focus Presets**

#### **GET /rest/v1/focus_presets**

Fetch all presets

**Request**:
```bash
curl -X GET "https://project.supabase.co/rest/v1/focus_presets?user_id=eq.550e8400-e29b-41d4-a716-446655440001" \
  -H "Authorization: Bearer TOKEN"
```

**Response** (200):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Deep Work",
    "duration_seconds": 3000,
    "sound": "light_rain",
    "ambient_mode": "forest",
    "is_default": true,
    "usage_count": 45
  }
]
```

---

#### **POST /rest/v1/focus_presets**

Create preset

**Request**:
```bash
curl -X POST "https://project.supabase.co/rest/v1/focus_presets" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Custom Session",
    "duration_seconds": 4500,
    "sound": "coffee_shop",
    "ambient_mode": "ocean"
  }'
```

---

### **4. User Settings**

#### **GET /rest/v1/user_settings**

Fetch user settings

**Request**:
```bash
curl -X GET "https://project.supabase.co/rest/v1/user_settings?user_id=eq.550e8400-e29b-41d4-a716-446655440001" \
  -H "Authorization: Bearer TOKEN"
```

**Response** (200):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440020",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "theme": "forest",
    "daily_goal_minutes": 120,
    "current_streak": 12,
    "current_level": 15,
    "total_xp": 2850
  }
]
```

---

## 🎯 Edge Functions

### **1. Flow AI Endpoint**

**Endpoint**: `/functions/v1/flow`

**Purpose**: GPT-4o powered AI assistant

#### **Request**

```bash
curl -X POST "https://project.supabase.co/functions/v1/flow" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Create 5 tasks for my morning routine",
    "conversationHistory": [
      {
        "role": "user",
        "content": "Hi Flow"
      },
      {
        "role": "assistant",
        "content": "Hello! I'm Flow, your productivity assistant."
      }
    ],
    "context": {
      "activeTasks": 8,
      "userStats": {
        "currentStreak": 12,
        "totalXP": 2850,
        "currentLevel": 15
      },
      "preferences": {
        "theme": "forest",
        "dailyGoal": 120
      }
    }
  }'
```

#### **Response (200)**

```json
{
  "content": "I'll create 5 tasks for your morning routine right away!",
  "actions": [
    {
      "type": "createTask",
      "params": {
        "title": "Wake up at 6 AM",
        "dueDate": "2025-01-08"
      }
    },
    {
      "type": "createTask",
      "params": {
        "title": "Exercise for 30 minutes",
        "dueDate": "2025-01-08"
      }
    },
    {
      "type": "createTask",
      "params": {
        "title": "Healthy breakfast",
        "dueDate": "2025-01-08"
      }
    },
    {
      "type": "createTask",
      "params": {
        "title": "Review daily goals",
        "dueDate": "2025-01-08"
      }
    },
    {
      "type": "createTask",
      "params": {
        "title": "Check emails",
        "dueDate": "2025-01-08"
      }
    }
  ],
  "metadata": {
    "tokensUsed": 450,
    "responseTime": 2.3,
    "modelUsed": "gpt-4o"
  }
}
```

---

### **2. Whisper Transcription Endpoint** (Future)

**Endpoint**: `/functions/v1/transcribe`

**Purpose**: Convert audio to text

```bash
curl -X POST "https://project.supabase.co/functions/v1/transcribe" \
  -H "Authorization: Bearer TOKEN" \
  -F "audio=@voice_message.m4a"
```

**Response (200)**:
```json
{
  "text": "Create 5 tasks for my morning routine",
  "language": "en",
  "confidence": 0.95,
  "duration": 5.2
}
```

---

## 🔍 Query Examples

### **Get Tasks for Today**

```bash
curl -X GET "https://project.supabase.co/rest/v1/tasks?due_date=eq.2025-01-07&is_completed=eq.false" \
  -H "Authorization: Bearer TOKEN"
```

---

### **Get Weekly Stats**

```sql
SELECT
  DATE_TRUNC('day', start_time) as day,
  COUNT(*) as session_count,
  SUM(duration_seconds) / 60 as minutes
FROM focus_sessions
WHERE user_id = $1 AND start_time > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', start_time)
ORDER BY day DESC;
```

---

### **Get All Tasks for Sync**

```bash
curl -X GET "https://project.supabase.co/rest/v1/tasks?user_id=eq.$USER_ID&select=*&order=updated_at.desc" \
  -H "Authorization: Bearer TOKEN"
```

---

## 📊 Rate Limiting

Supabase imposes limits:
- **Requests**: 10,000/minute per project
- **Concurrent**: 100 concurrent requests
- **Payload**: 5 MB max per request

**Response**:
```json
{
  "error": "Too many requests",
  "status": 429,
  "retry_after": 60
}
```

---

## 🐛 Error Handling

### **Common Error Codes**

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Unauthorized | Refresh auth token |
| 403 | Forbidden (RLS) | Check permissions |
| 404 | Not found | Verify resource ID |
| 409 | Conflict | Handle sync conflict |
| 429 | Rate limited | Retry after delay |
| 500 | Server error | Retry with backoff |

### **Error Response Format**

```json
{
  "code": "auth.unauthorized",
  "message": "Invalid authentication token",
  "status": 401
}
```

---

## 🧪 Testing API

### **Using cURL**

```bash
# Set token
TOKEN="your_jwt_token"

# Test GET
curl -X GET "https://project.supabase.co/rest/v1/tasks" \
  -H "Authorization: Bearer $TOKEN"

# Test POST
curl -X POST "https://project.supabase.co/rest/v1/tasks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test"}'
```

### **Using Swift/iOS**

```swift
// Create client
let client = SupabaseClient(url: URL(string: "https://...")!, accessToken: token)

// Fetch tasks
let response = try await client
    .from("tasks")
    .select()
    .execute()

let tasks = try JSONDecoder().decode([Task].self, from: response.data)
```

---

## 📚 SDK Documentation

- **Supabase Client Library**: https://supabase.com/docs/reference/swift/introduction
- **PostgREST API**: https://postgrest.org/en/stable/api.html
- **JWT Authentication**: https://supabase.com/docs/guides/auth

---

**Last Updated**: January 7, 2026  
**API Version**: v1  
**Status**: Production
