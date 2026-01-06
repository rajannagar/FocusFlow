# 🚀 GPT-4o Feature Implementation Guide

## Quick Start: Build Your First AI Feature

This guide shows you exactly how to add powerful new AI features to your app using GPT-4o.

---

## 🎯 Feature #1: AI Productivity Coach (Recommended First)

### What It Does
Gives real-time coaching and motivation during focus sessions and throughout the day.

**Example Messages:**
- "You're on a 9-day streak! 🔥 Keep it up!"
- "You've focused 38 minutes. Just 7 more to beat your personal best!"
- "Your energy is dropping. Perfect time for a 5-minute break and some water."
- "This is your peak focus hour. You're doing amazing work!"

---

## Step 1: Create Backend Function

### File: `supabase/functions/ai-coaching/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CoachingRequest {
  userStats: {
    todayMinutes: number
    dailyGoalMinutes: number
    currentStreak: number
    bestStreak: number
    bestHour: string
    focusQuality: number // 0-100
    recentMood: string // "energized" | "focused" | "tired" | "distracted"
  }
  context: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders })
    }

    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      return new Response(JSON.stringify({ error: 'Server configuration error' }), { status: 500, headers: corsHeaders })
    }

    const requestBody: CoachingRequest = await req.json()
    const { userStats, context } = requestBody

    // Build coaching prompt
    const coachingPrompt = `
You are an AI Productivity Coach for FocusFlow, a focus timer app.

USER STATS:
- Today's focus: ${userStats.todayMinutes}/${userStats.dailyGoalMinutes} minutes (${Math.round(userStats.todayMinutes/userStats.dailyGoalMinutes*100)}%)
- Current streak: ${userStats.currentStreak} days
- Best streak: ${userStats.bestStreak} days
- Peak focus hour: ${userStats.bestHour}
- Focus quality: ${userStats.focusQuality}%
- Current mood: ${userStats.recentMood}

CONTEXT:
${context}

INSTRUCTIONS:
1. Analyze the user's current state
2. Provide personalized, specific motivation (NOT generic)
3. Use emojis sparingly (max 2 per message)
4. Keep message short (1-2 sentences max)
5. Reference specific achievements when possible
6. If mood is "tired" - be gentle and suggest break
7. If mood is "energized" - celebrate and encourage more
8. If quality is < 40% - suggest a 10-minute break
9. If user is close to goal - motivate them to finish
10. Never ask questions - always make statements

COACHING STYLES TO CONSIDER:
- Achievement-focused: Highlight progress and records
- Numbers-focused: Use specific metrics
- Emotional: Appeal to feelings and growth
- Competitive: Compare to personal bests

Write ONE powerful coaching message (2 sentences max, under 100 characters).
`

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: 'You are an expert productivity coach. Be concise, specific, and motivating.'
          },
          {
            role: 'user',
            content: coachingPrompt
          }
        ],
        temperature: 0.8,
        max_tokens: 150
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI error: ${response.statusText}`)
    }

    const data = await response.json()
    const message = data.choices[0].message.content

    return new Response(
      JSON.stringify({ message: message.trim() }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: corsHeaders }
    )
  }
})
```

### Deploy
```bash
cd supabase
supabase functions deploy ai-coaching
```

---

## Step 2: Create Swift ViewModel

### File: `FocusFlow/Features/AI/AICoachingViewModel.swift`

```swift
import Foundation

@MainActor
final class AICoachingViewModel: ObservableObject {
    @Published var coachingMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseClient = SupabaseClient.shared
    
    func getCoachingMessage(userStats: UserStats, context: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CoachingRequest(
                userStats: userStats,
                context: context
            )
            
            let response = await supabaseClient.callEdgeFunction(
                name: "ai-coaching",
                body: request
            )
            
            if let message = response["message"] as? String {
                coachingMessage = message
            }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct CoachingRequest: Codable {
    let userStats: UserStats
    let context: String
}

struct UserStats: Codable {
    let todayMinutes: Int
    let dailyGoalMinutes: Int
    let currentStreak: Int
    let bestStreak: Int
    let bestHour: String
    let focusQuality: Int
    let recentMood: String
}
```

---

## Step 3: Create UI View

### File: `FocusFlow/Features/AI/AICoachingView.swift`

```swift
import SwiftUI

struct AICoachingView: View {
    @StateObject private var viewModel = AICoachingViewModel()
    @EnvironmentObject private var progressStore: ProgressStore
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    var body: some View {
        VStack(spacing: 16) {
            // Coaching message
            if !viewModel.coachingMessage.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(theme.accentPrimary)
                    
                    Text(viewModel.coachingMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(3)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            }
            
            // Refresh button
            Button(action: { loadCoaching() }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentPrimary))
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Get Coaching", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(theme.accentPrimary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .onAppear { loadCoaching() }
    }
    
    private func loadCoaching() {
        let stats = UserStats(
            todayMinutes: Int(progressStore.todayFocusSeconds / 60),
            dailyGoalMinutes: progressStore.dailyGoalMinutes,
            currentStreak: calculateCurrentStreak(),
            bestStreak: progressStore.lifetimeBestStreak,
            bestHour: findBestHour(),
            focusQuality: calculateFocusQuality(),
            recentMood: getRecentMood()
        )
        
        let context = """
        The user just started the app / is during a focus session.
        Give them a personal, specific coaching message to motivate them.
        """
        
        Task {
            await viewModel.getCoachingMessage(userStats: stats, context: context)
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        // Implement streak calculation
        return progressStore.lifetimeSessionCount
    }
    
    private func findBestHour() -> String {
        // Find hour with most focus time
        return "8 AM"
    }
    
    private func calculateFocusQuality() -> Int {
        // Calculate based on session consistency
        return 85
    }
    
    private func getRecentMood() -> String {
        // Could be set by user or inferred from patterns
        return "focused"
    }
}
```

---

## Step 4: Integrate Into Your App

### Option A: Add to Dashboard/Progress Tab
```swift
// In ProgressView.swift
VStack {
    // Existing progress content
    
    AICoachingView()
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
}
```

### Option B: Add to Focus Session View
```swift
// In FocusSessionView.swift, when session is running
ZStack {
    // Existing focus content
    
    VStack {
        Spacer()
        
        // Show coaching message
        AICoachingView()
            .padding(16)
    }
}
```

### Option C: Floating Card in Main View
```swift
// In ContentView.swift
NavigationView {
    ZStack {
        // Main content
        
        VStack {
            Spacer()
            
            AICoachingView()
                .padding(16)
                .background(Color.black.opacity(0.2))
                .cornerRadius(16)
        }
    }
}
```

---

## Step 5: Update System Prompt

Add to `AIContextBuilder.swift` buildSystemPrompt():

```swift
COACHING SYSTEM:
When user requests or receives coaching:
• Analyze current productivity metrics
• Provide SPECIFIC, PERSONALIZED motivation
• Reference actual achievements (streak, records, etc.)
• Use appropriate tone based on mood/energy
• Keep messages SHORT (1-2 sentences, under 100 chars)
• Include relevant emoji (max 1-2)
• Never ask questions, always make statements
• If tired → suggest break
• If energized → celebrate and encourage more
• If approaching goal → motivate to finish

COACHING EXAMPLES:
Good: "9-day streak! You're building an amazing habit. 🔥"
Bad: "You should keep focusing!"

Good: "Your energy is dropping. 5-min break + water = back to peak!"
Bad: "Do you want a break?"
```

---

## 🧪 Test Cases

```swift
// Test coaching messages
let testStats = UserStats(
    todayMinutes: 45,
    dailyGoalMinutes: 60,
    currentStreak: 9,
    bestStreak: 9,
    bestHour: "8 AM",
    focusQuality: 92,
    recentMood: "energized"
)
// Expected: "9-day streak! Keep crushing it! 🔥"

let tiredStats = UserStats(
    todayMinutes: 120,
    dailyGoalMinutes: 60,
    currentStreak: 5,
    bestStreak: 12,
    bestHour: "2 PM",
    focusQuality: 35,
    recentMood: "tired"
)
// Expected: "You've done great today. Time for a break and recovery?"
```

---

## 📊 Feature #2: Smart Weekly Planner

### Quick Version (3-4 hours)

```swift
// In AIChatViewModel, add new function
func planWeek() async {
    // 1. Get past 4 weeks of data
    let pastSessions = progressStore.sessions.last(28)
    
    // 2. Send to AI with context
    let message = """
    Based on this data, create an optimal week plan:
    \(serializePastData(pastSessions))
    """
    
    // 3. AI returns suggested schedule
    // 4. Create all tasks automatically
}
```

### In System Prompt:
```
WEEKLY PLANNING:
When user asks "Plan my week" or "Suggest schedule":
1. Analyze past 4 weeks of productivity
2. Identify peak focus hours
3. Note energy patterns
4. Create balanced daily schedule
5. List all suggested tasks with times
6. ALWAYS ask user to confirm before creating
7. Once confirmed, create all tasks in batch
```

---

## 📊 Feature #3: Progress Insights

### Quick Implementation

```typescript
// supabase/functions/ai-insights/index.ts
// Similar to coaching but focused on analysis

const insightPrompt = `
Analyze this productivity data and provide insights:
${userDataSerialized}

Provide:
1. Trend (improving/stable/declining)
2. Best/worst days
3. Peak productivity hour
4. Task type performance
5. One actionable recommendation

Keep it SHORT and specific (max 150 words).
`
```

---

## 🎯 Implementation Checklist

### For Each New Feature:
- [ ] Create Supabase edge function
- [ ] Create Swift ViewModel
- [ ] Create SwiftUI View
- [ ] Add to main UI flow
- [ ] Update system prompt
- [ ] Write test cases
- [ ] Test with real data
- [ ] Deploy to backend
- [ ] Rebuild iOS app
- [ ] Test end-to-end

---

## ⚡ Performance Tips

1. **Cache Results**
   ```swift
   @Published var cachedMessage: String?
   var cacheTime: Date?
   
   func getCoaching() async {
       // Only fetch every 5 minutes
       if let cached = cachedMessage,
          let time = cacheTime,
          Date().timeIntervalSince(time) < 300 {
           return
       }
       // Fetch new message
   }
   ```

2. **Batch Requests**
   - Don't call coaching 10x per day
   - Call at natural moments (session start, break time, etc.)

3. **Optimize Tokens**
   - Use shorter, concise prompts
   - Cache user stats when possible

---

## 💡 Pro Tips

1. **Test with Real Data**
   - Use actual productivity stats
   - Try different moods/streaks
   - Verify responses make sense

2. **Iterate Based on Users**
   - Collect feedback on coaching messages
   - Update prompts based on what resonates
   - A/B test different styles

3. **Make It Feel Alive**
   - Vary messages (don't repeat)
   - Add personality
   - Reference specific achievements

4. **Consider Privacy**
   - Don't send personal data unless necessary
   - Anonymize user info if possible
   - Store coaching messages locally when possible

---

## 🚀 Next Steps

1. **Build Coaching Feature First** (4-5 hours)
   - Highest impact, lowest complexity
   - Users immediately feel difference
   
2. **Get User Feedback** (1 week)
   - Do users like the coaching?
   - Which messages resonate?
   - What could improve?
   
3. **Build Weekly Planner** (4-5 hours)
   - Second most impactful
   - Game-changing feature
   
4. **Add Progress Insights** (4-5 hours)
   - Users understand themselves better
   - Data-driven recommendations

5. **Roll Out More Features** (ongoing)
   - Habit formation
   - Break recommendations
   - Goal breakdown

---

**Ready to build? Start with the Productivity Coach - it's the quickest win and will immediately improve user experience!** 🚀
