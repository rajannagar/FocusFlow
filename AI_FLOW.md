# FocusFlow: Focus AI (Flow) - Complete Implementation Guide

**Deep dive into the GPT-4o powered productivity assistant**

---

## 🤖 What is Flow?

**Flow** is a **GPT-4o powered productivity assistant** integrated directly into FocusFlow. It's like having ChatGPT as your personal focus coach, understanding your tasks, patterns, and goals.

**Key Differentiators**:
- ✅ Integrated (not external service)
- ✅ Context-aware (knows your tasks & history)
- ✅ Action-oriented (actually does things, not just talks)
- ✅ Proactive (offers suggestions, not just reactive)
- ✅ Voice-enabled (speak naturally)
- ✅ Real-time (streaming responses)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│      FlowChatView (UI)              │
│  ├─ Message input field             │
│  ├─ Response display                │
│  ├─ Voice input button              │
│  └─ Action cards                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   FlowChatViewModel (State)         │
│  ├─ Conversation history            │
│  ├─ Message processing              │
│  ├─ Action handling                 │
│  └─ Voice transcription             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     FlowService (API Client)        │
│  ├─ Send message to API             │
│  ├─ Streaming handler               │
│  ├─ Token management                │
│  └─ Error handling                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Supabase Edge Function (/flow)    │
│  ├─ Auth verification               │
│  ├─ Context building                │
│  ├─ OpenAI API calls                │
│  ├─ Function calling                │
│  └─ Action execution                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    OpenAI API (GPT-4o)              │
│  ├─ Text generation                 │
│  ├─ Function calling                │
│  └─ Token counting                  │
└─────────────────────────────────────┘
```

---

## 💬 Message Flow

### **User sends message**

```
1. User types or speaks
   ↓
2. Message validated (not empty, <1000 chars)
   ↓
3. FlowChatViewModel.sendMessage() called
   ↓
4. Message added to conversation history
   ↓
5. Context built (tasks, settings, history)
   ↓
6. Conversation serialized to JSON
   ↓
7. FlowService.sendMessage() called
   ↓
8. HTTP POST to Supabase edge function
   Payload:
   {
     "message": "Create 5 tasks for my morning routine",
     "conversationHistory": [...],
     "context": {
       "currentTasks": [...],
       "userStats": {...},
       "preferences": {...}
     }
   }
   ↓
9. Wait for response (or stream)
   ↓
10. Parse response JSON
    {
      "content": "I'll create those 5 tasks...",
      "actions": [
        {
          "type": "createTask",
          "params": { "title": "Wake up at 6 AM", ... }
        },
        ...
      ]
    }
   ↓
11. Execute actions sequentially
    - createTask("Wake up at 6 AM")
    - createTask("Exercise...")
    - ... (5 tasks total)
   ↓
12. Update FlowChatViewModel
    - Add AI response to history
    - Update UI
    - Show action cards
    ↓
13. User sees response + executed actions
```

---

## 🔌 FlowService: API Communication

**Location**: `FocusFlow/Features/AI/Service/FlowService.swift`

### **Sending Messages**

**Non-Streaming (Complete Response)**:
```swift
func sendMessage(
    userMessage: String,
    conversationHistory: [FlowMessage],
    context: String
) async throws -> FlowResponse

// Returns complete response after waiting
// Best for: Small responses, quick interactions
```

**Streaming (Real-Time Response)**:
```swift
func sendStreamingMessage(
    userMessage: String,
    conversationHistory: [FlowMessage],
    context: String
) -> AsyncThrowingStream<String, Error>

// Returns stream of response chunks
// Best for: Long responses, perceived responsiveness
// User sees text appearing in real-time
```

### **Error Handling**

```swift
enum FlowError: LocalizedError {
    case notConfigured          // Missing API keys
    case networkError(String)   // Network issue
    case unauthorized           // Invalid auth token
    case rateLimited            // Too many requests
    case invalidResponse        // Bad response format
    case tokenLimitExceeded      // Too many tokens
    case actionFailed(String)   // Action execution failed
}
```

---

## 📝 FlowChatViewModel: State Management

**Location**: `FocusFlow/Features/AI/UI/FlowChatViewModel.swift`

### **Published State**

```swift
@MainActor
final class FlowChatViewModel: ObservableObject {
    
    @Published var messages: [FlowMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: FlowError?
    @Published var suggestedActions: [QuickAction] = []
    @Published var voiceInputActive: Bool = false
    @Published var streamingContent: String = ""
}
```

### **Key Methods**

```swift
func sendMessage() async
// User taps send
// Validates input
// Calls FlowService
// Updates state

func executeAction(_ action: FlowAction) async
// Called when user taps action card
// Performs task creation/update/delete
// Updates local stores
// Shows confirmation

func startVoiceInput() async
// Captures audio
// Sends to Whisper API
// Transcribes to text
// Auto-sends as message

func retryLastMessage() async
// Resends last failed message
// Useful if network error
```

---

## 🎙️ Voice Input System

**Location**: `FocusFlow/Features/AI/Voice/FlowVoiceInput.swift`

### **Voice Capture**

```swift
final class VoiceInputManager: NSObject, AVAudioRecorderDelegate {
    
    func startRecording()
    // Requests microphone permission
    // Starts audio capture
    // Shows listening UI
    
    func stopRecording()
    // Stops capture
    // Sends audio to Whisper API
    // Transcribes to text
    // Returns transcribed string
}
```

### **Whisper Transcription**

```
User taps microphone
    ↓
Says: "Create 5 tasks for my morning routine"
    ↓
Audio captured (max 30 seconds)
    ↓
Sent to OpenAI Whisper API
    ↓
Transcription: "Create 5 tasks for my morning routine"
    ↓
Returned to app
    ↓
Auto-sent as message
    ↓
Flow processes
```

### **Languages**
- Primary: English (en)
- Coming: Spanish, French, German, etc.

---

## 🎯 Available Actions

### **What Flow Can Do**

Flow executes actions via OpenAI function calling. These are the functions available:

#### **1. Create Task**
```swift
action.type == "createTask"
parameters:
  - title: String (required)
  - description: String? (optional)
  - dueDate: Date? (optional)
  - reminderDate: Date? (optional)
  - repeatRule: String? ("daily", "weekly", etc.)

Example:
"Create task: Buy milk, due tomorrow, remind me 1 hour before"
→ Flow creates task with all details
```

#### **2. Update Task**
```swift
action.type == "updateTask"
parameters:
  - taskId: UUID (required)
  - title: String? (optional)
  - description: String? (optional)
  - dueDate: Date? (optional)
  - isCompleted: Bool? (optional)

Example:
"Mark 'Write report' as done"
→ Flow updates task isCompleted = true
```

#### **3. Delete Task**
```swift
action.type == "deleteTask"
parameters:
  - taskId: UUID (required)
  - confirm: Bool (optional, requires confirmation)

Example:
"Delete old tasks from last week"
→ Flow finds matching tasks and deletes
```

#### **4. Create Preset**
```swift
action.type == "createPreset"
parameters:
  - name: String (required)
  - durationMinutes: Int (required)
  - sound: String? (optional)
  - ambiantMode: String? (optional)

Example:
"Create a 60-minute deep work preset with ocean sounds"
→ Flow creates preset with all settings
```

#### **5. Start Session**
```swift
action.type == "startSession"
parameters:
  - durationMinutes: Int (required)
  - presetName: String? (optional)
  - sound: String? (optional)

Example:
"Start a 45-minute study session"
→ Flow starts timer with 45 minutes
```

#### **6. Get Stats**
```swift
action.type == "getStats"
parameters:
  - timeRange: String ("today", "week", "month", "all")

Example:
"Show my week"
→ Flow returns weekly statistics and displays
```

#### **7. Set Daily Goal**
```swift
action.type == "setGoal"
parameters:
  - goalMinutes: Int (required)
  - notification: Bool (optional)

Example:
"Set my daily goal to 3 hours"
→ Flow updates goal and enables notifications
```

---

## 📊 Context Building

**Key Principle**: Send only necessary data to avoid token waste

### **Context Fields**

```swift
struct FlowContext {
    // User Info
    let userId: UUID
    let isPro: Bool
    
    // Current Data
    let activeTasks: [Task]              // Only active, not all
    let recentSessions: [FocusSession]   // Last 7 days
    let customPresets: [FocusPreset]
    
    // Statistics
    let todayStats: DailySummary
    let currentStreak: Int
    let totalXP: Int
    let currentLevel: Int
    
    // Preferences
    let dailyGoal: Int                   // Minutes
    let favoritePreset: String?
    let favoriteSound: String?
    
    // History
    let conversationHistory: [FlowMessage] // Last 5 exchanges
    
    // Time
    let currentDate: Date
    let currentTime: Date
    let timezone: TimeZone
}
```

### **Context Building Strategy**

```swift
struct LazyContextBuilder {
    
    // Only includes data when specifically needed
    
    func buildContext() -> String {
        var context = ""
        
        // Always include
        context += "Current time: \(Date())"
        context += "User is Pro: \(isPro)"
        
        // Only include if relevant
        if shouldIncludeTasks() {
            context += "Active tasks: \(activeTasks)"
        }
        
        if shouldIncludeHistory() {
            context += "Recent sessions: \(recentSessions)"
        }
        
        return context
    }
}
```

---

## 🧠 System Prompt

The system prompt defines Flow's personality and capabilities:

```
You are Flow, a productivity assistant built into the FocusFlow app.
Your purpose is to help users focus better, manage tasks, and track progress.

Key characteristics:
1. Professional but friendly
2. Action-oriented (actually do things)
3. Encouraging and positive
4. Context-aware (understand user's workload)
5. Proactive (suggest improvements)

Capabilities:
- Create/update/delete tasks
- Start focus sessions
- Show analytics
- Recommend presets
- Provide insights
- Answer productivity questions

Communication style:
- Use short, friendly messages
- Provide actionable advice
- Use emojis occasionally (not too many)
- Be encouraging
- Acknowledge effort

Never:
- Make up data
- Claim to know about features not implemented
- Make jokes about productivity (too flippant)
- Suggest illegal/harmful activities
```

---

## 🌊 Streaming Responses

For better UX, Flow uses streaming to show responses in real-time:

```
Server starts sending response
    ↓
"I'll create" (chunk 1)
    ↓
"I'll create those" (chunk 2)
    ↓
"I'll create those 5 tasks" (chunk 3)
    ↓
... (more chunks)
    ↓
Full response displayed
    ↓
User sees typing effect
    ↓
More engaging interaction
```

**Implementation**:
```swift
let stream = try FlowService.shared.sendStreamingMessage(...)

for try await chunk in stream {
    DispatchQueue.main.async {
        self.streamingContent += chunk
        // UI updates per chunk
    }
}
```

---

## 💡 Proactive System (FlowProactiveEngine)

**Location**: `FocusFlow/Features/AI/Proactive/FlowProactiveEngine.swift`

### **What is Proactive?**

Rather than waiting for user interaction, Flow can:
- Suggest tasks
- Offer encouragement
- Highlight opportunities
- Prevent procrastination
- Celebrate achievements

### **Proactive Triggers**

```
Time-Based:
├─ Morning (6-8 AM): "Ready to focus today?"
├─ Mid-day (12-1 PM): "Time for lunch + short session?"
├─ Evening (5-6 PM): "How'd your day go? Ready to wrap up?"
└─ Night (9-10 PM): "Tomorrow's plan? I can help organize"

Activity-Based:
├─ 0 sessions today: "Let's start! 25 min?"
├─ 3 sessions today: "Nice work! Keep it up? 🔥"
├─ Task added: "I can help prioritize these"
├─ Streak milestone (7, 14, 30 days): "🔥 Streak achievement!"
└─ Goal reached: "Daily goal hit! Great work!"

Pattern-Based:
├─ Most productive time detected: "You're sharpest now"
├─ Low activity this week: "Let's get back on track"
├─ Procrastination detected: "Start the hardest task?"
└─ New routine forming: "You're building great habits!"
```

### **Hint Types**

```swift
enum HintType: String {
    case motivationalBoost      // Encouragement
    case smartRecommendation   // What to do next
    case opportunityAlert      // Don't miss this
    case milestoneAnnouncement // Achievement unlocked
    case insightShare          // Pattern discovered
    case preventProcrastination // Get started nudge
}
```

---

## 🎨 UI Components

### **FlowChatView: Main Chat Interface**

```
┌──────────────────────────┐
│  Flow - Your AI Coach    │
├──────────────────────────┤
│                          │
│  [Message from Flow]     │
│  [Action Card 1]         │
│  [Action Card 2]         │
│                          │
│  [Message from User]     │
│                          │
├──────────────────────────┤
│ [Message input field]    │
│ [+] [🎙️ Voice] [Send] │
└──────────────────────────┘
```

### **FlowSpotlight: Floating Bubble**

```
┌──────────────────────────────┐
│                              │
│     ... (any screen)         │
│                              │
│                    [AI 💭]   │
│                              │
│  Float anywhere              │
│  Tap to open chat            │
│  Swipe to dismiss            │
└──────────────────────────────┘
```

**Position**: Bottom-right (customizable)
**Behavior**: 
- Minimized unless active
- Animated pulse when suggestions available
- Drags to custom position
- Can be hidden

### **Action Cards**

```
┌─────────────────────────┐
│ ✅ Task Created         │
├─────────────────────────┤
│ Wake up at 6 AM         │
│ Due: Tomorrow           │
│ Reminder: 1 hour before │
│                         │
│ [Edit] [Delete] [Done]  │
└─────────────────────────┘
```

---

## 🔒 Security & Privacy

### **Data Sent to OpenAI**

**What's Included**:
- User message (required)
- Conversation history (needed for context)
- Task titles (not full descriptions)
- Recent stats (summary, not raw data)

**What's Excluded**:
- Full task descriptions
- All-time history (only last 7 days)
- User email/phone
- Personal health data
- Sensitive passwords

### **Privacy Controls**

```
Settings → AI & Privacy
├─ [ ] Include task titles in context
├─ [ ] Include session history
├─ [ ] Allow voice input
├─ [ ] Enable proactive hints
└─ [Clear Chat History]
```

### **Data Retention**

- Chat history: Stored locally on device
- NOT synced to cloud
- Deleted on sign-out
- User can manually clear anytime

---

## 🔧 Configuration

**Location**: `FocusFlow/Features/AI/Core/FlowConfig.swift`

```swift
enum FlowConfig {
    
    // API Configuration
    static let supabaseURL = URL(string: "https://...")
    static let edgeFunctionURL = supabaseURL.appendingPathComponent("functions/v1/flow")
    
    // OpenAI Configuration
    static let modelName = "gpt-4o"
    static let maxTokens = 2000
    static let temperature = 0.7
    
    // Context Building
    static let maxContextTokens = 1500
    static let maxHistoryMessages = 10
    
    // Voice
    static let maxRecordingDuration: TimeInterval = 30
    static let audioQuality = "16000"
    
    // Proactive Engine
    static let hintMinimumProbability = 0.6
    static let proactiveCheckInterval: TimeInterval = 3600 // 1 hour
    
    // Validation
    static let isConfigured: Bool = {
        return supabaseURL != nil &&
               edgeFunctionURL != nil
    }()
}
```

---

## 🧪 Testing Flow

### **Unit Tests**

```swift
// Test message validation
func testMessageValidation() {
    let viewModel = FlowChatViewModel()
    
    // Empty message
    XCTAssertFalse(viewModel.canSendMessage())
    
    // Valid message
    viewModel.inputText = "Create a task"
    XCTAssertTrue(viewModel.canSendMessage())
    
    // Too long
    viewModel.inputText = String(repeating: "a", count: 1001)
    XCTAssertFalse(viewModel.canSendMessage())
}

// Test action execution
func testActionExecution_CreateTask() {
    let viewModel = FlowChatViewModel()
    let action = FlowAction.createTask(title: "Test Task", dueDate: nil)
    
    viewModel.executeAction(action)
    
    // Wait for completion
    waitForAsync()
    
    // Verify task created
    XCTAssertEqual(viewModel.store.tasks.count, 1)
    XCTAssertEqual(viewModel.store.tasks[0].title, "Test Task")
}
```

### **Integration Tests**

```swift
// Test full message flow
func testFullMessageFlow() {
    let viewModel = FlowChatViewModel()
    
    // Send message
    viewModel.inputText = "Create 3 tasks"
    viewModel.sendMessage()
    
    // Wait for response
    waitForAsync()
    
    // Verify response received
    XCTAssertGreater(viewModel.messages.count, 1)
    
    // Verify actions executed
    XCTAssertGreater(viewModel.store.tasks.count, 0)
}
```

---

## 🚀 Example Conversations

### **Example 1: Morning Planning**

```
User: "What should I focus on today?"

Flow: "Looking at your 8 active tasks, I recommend:

1. **Finish report** (3.5 hours priority)
   - This is due today at 5 PM
   - Suggest 2x 90-minute Deep Work sessions
   
2. **Team meeting prep** (30 minutes)
   - Quick wins to build momentum
   
3. **Email responses** (20 minutes)
   - Low effort, high impact

You're most productive 9-11 AM. 
Ready to start with the report?"

[Actions shown]:
- [Start 90-min Deep Work]
- [View all tasks]
- [Adjust priority]
```

---

### **Example 2: Batch Task Creation**

```
User: "Create 5 tasks for my morning routine"

Flow: "I'll create your morning routine tasks right now:

✅ Wake up at 6 AM
✅ Exercise for 30 minutes
✅ Healthy breakfast
✅ Review daily goals
✅ Check emails

All set! These are ready to go.

Want to:
- Set reminders for each?
- Schedule them in order?
- Start a morning session now?"

[Actions shown]:
- [Set reminders]
- [View tasks]
- [Start session]
```

---

### **Example 3: Insights & Recommendations**

```
User: "Show my week"

Flow: "Great week! Here's your summary:

📊 **This Week**
• Total focus: 18.5 hours (+22% vs last week!)
• Sessions: 23 (avg 48 minutes each)
• Tasks: 42/56 completed (75%)
• XP earned: 1,100 ⭐

🏆 **Highlights**
• Best day: Wednesday (4.5 hours)
• Longest session: 90 minutes
• Most used: Deep Work preset (used 12x)
• Streak: 12 days 🔥

💡 **Insights**
You're most productive 8-10 AM. 
Consider scheduling deep work then.

Next week goal: 20 hours? You're on pace!"

[Actions shown]:
- [Set next week goal]
- [View detailed stats]
- [Compare months]
```

---

## 🐛 Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Flow not responding" | API timeout | Check internet, retry |
| Actions not executing | Permission issue | Check task limits |
| Voice not transcribing | Mic permission | Enable in Settings |
| Context too large | Token overflow | Reduce history |
| Responses generic | Bad context | Provide more details |

---

## 📈 Future Enhancements

- **Text-to-Speech**: Read responses aloud
- **Conversation Threads**: Topic-specific chats
- **Memory**: Learn user preferences long-term
- **Integrations**: Slack, Calendar, Email
- **Collaborative**: Work with team members
- **Offline Mode**: Some AI features without internet

---

**Last Updated**: January 7, 2026  
**Status**: Production-ready
