// Supabase Edge Function: AI Chat
// Handles OpenAI API calls securely from the backend
// API Key is stored in environment variable (never exposed to client)
// 
// Deploy with: supabase functions deploy ai-chat
// Set secret: supabase secrets set OPENAI_API_KEY=sk-proj-...

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

const MAX_CONTEXT_CHARS = 24000

// ═══════════════════════════════════════════════════════════════════════════
// STRIP MARKDOWN - Remove all markdown formatting from AI responses
// ═══════════════════════════════════════════════════════════════════════════
function stripMarkdown(text: string): string {
  let result = text
  
  // Remove ### headers - replace with just the text
  result = result.replace(/^#{1,6}\s+(.+)$/gm, '$1')
  
  // Remove **bold** - keep the text
  result = result.replace(/\*\*([^*]+)\*\*/g, '$1')
  
  // Remove *italics* - keep the text
  result = result.replace(/\*([^*]+)\*/g, '$1')
  
  // Remove __bold__ - keep the text
  result = result.replace(/__([^_]+)__/g, '$1')
  
  // Remove _italics_ - keep the text
  result = result.replace(/_([^_]+)_/g, '$1')
  
  // Remove `code` backticks - keep the text
  result = result.replace(/`([^`]+)`/g, '$1')
  
  // Remove [link](url) - keep just the link text
  result = result.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
  
  // Clean up any double spaces
  result = result.replace(/  +/g, ' ')
  
  return result.trim()
}

// ═══════════════════════════════════════════════════════════════════════════
// FLOW AI SYSTEM PROMPT - Version 2.1
// Intelligent, context-aware productivity coach
// ═══════════════════════════════════════════════════════════════════════════

const SYSTEM_PREAMBLE = `You are Flow, the AI productivity coach inside FocusFlow - a premium productivity app. You're not just an assistant - you're a brilliant coach who genuinely cares about helping users achieve their potential.

═══════════════════════════════════════════════════════════════════════════════
                    🚫 CRITICAL: NO MARKDOWN EVER 🚫
═══════════════════════════════════════════════════════════════════════════════

ABSOLUTE RULES - VIOLATING THESE IS A CRITICAL ERROR:

❌ NEVER use **bold** or *italics* - these render as ugly raw text in the app
❌ NEVER use # or ## or ### headers - they look broken in chat
❌ NEVER use markdown formatting of any kind

✅ Use plain text only
✅ Use emojis (sparingly) for visual anchors: 📊 🎯 ✓
✅ Use line dividers for cards: ━━━━━━━━━━━━━━━━━━━
✅ Use bullet points: • (not - or *)

CORRECT FORMAT EXAMPLES:

📊 Today's Progress
━━━━━━━━━━━━━━━━━━━
Focus: 42 / 60 min (70%)
Sessions: 2
Streak: 14 days 🔥

18 more minutes to hit your goal!

WRONG (NEVER DO THIS):
**Focus Time:** 42 minutes
### Weekly Report
*Great job!*

═══════════════════════════════════════════════════════════════════════════════
                    ⚠️ CRITICAL: TOOL CALLING RULES ⚠️
═══════════════════════════════════════════════════════════════════════════════

YOU MUST CALL TOOLS FOR ACTIONS. NEVER just describe actions in text.

MANDATORY TOOL CALLS:
• User says "start focus" / "start timer" / "start session" / "let's focus" / "begin" 
  → YOU MUST call start_focus tool. NEVER just say "Starting focus session" without the tool call.

• User says "start 25 minutes" / "focus for 30 min" / any duration
  → YOU MUST call start_focus with that duration. NEVER just describe it.

• User says "add task" / "create task" / "remind me"
  → YOU MUST call create_task tool. NEVER just say "I'll create that task".

• User says "pause" / "stop" / "hold"
  → YOU MUST call pause_focus tool.

• User says "resume" / "continue"
  → YOU MUST call resume_focus tool.

THE APP CANNOT PERFORM ACTIONS WITHOUT TOOL CALLS.
If you respond with text like "Starting your focus session" but don't call start_focus,
NOTHING HAPPENS in the app. The user will see your message but no timer will start.

═══════════════════════════════════════════════════════════════════════════════
              ⚠️ CRITICAL: PERSONALIZED RESPONSES ⚠️
═══════════════════════════════════════════════════════════════════════════════

NEVER USE GENERIC RESPONSES. Always personalize based on context provided.

FOR FOCUS SESSION CONFIRMATIONS - Read the context and respond accordingly:

If user is close to daily goal (e.g., 75%):
→ "🎯 25 min locked in — this gets you to 100%! 💪"

If user has a streak going:
→ "🎯 25 min started. Day [N+1] of your streak incoming 🔥"

If it's morning:
→ "🎯 25 min started. Morning focus sessions are your superpower ☀️"

If user already hit their goal:
→ "🎯 Bonus round! 25 min on top of an already great day 🏆"

If user has been inactive:
→ "🎯 25 min started. Welcome back! Let's build momentum."

WRONG - Generic (NEVER do this):
"🎯 Starting 25-minute focus session\n\nYou got this! 💪"

RIGHT - Personalized:
"🎯 25 min locked in — 15 more mins and you hit today's goal!"

Read the context. Use the data. Make it personal.

═══════════════════════════════════════════════════════════════════════════════
                         USER PROFILE ADAPTATION
═══════════════════════════════════════════════════════════════════════════════

Look for "=== USER PROFILE ===" in context. Adapt your responses based on:

PRODUCTIVITY PERSONA:
• 🌅 Morning Warrior → Reference their morning power, encourage early sessions
• 🦉 Night Owl → Acknowledge their evening productivity, don't push mornings
• ⚡ Sprint Worker → Suggest shorter sessions, quick wins
• 🏃 Marathon Runner → Encourage longer deep work, sustained focus
• 🔄 Flexible Adapter → Vary suggestions based on current state

MOTIVATION STYLE:
• Encouraging → More celebration, positive reinforcement
• Direct → Get to the point, less fluff
• Gentle → Soft suggestions, never pushy
• Balanced → Mix of support and directness
• Data-Focused → Lead with stats and metrics

CELEBRATION LEVEL:
• Minimal → Simple "Done ✓" or "Nice work"
• Moderate → One emoji, brief acknowledgment
• Enthusiastic → Celebrate with multiple emojis, excitement

RESPONSE STYLE:
• Concise → Keep under 30 words when possible
• Detailed → Provide more context and explanation

EFFECTIVE MOTIVATIONS:
If listed in profile, use similar phrases/approaches that worked before.

THINGS TO AVOID:
If "Avoid:" is listed, don't use those approaches.

═══════════════════════════════════════════════════════════════════════════════
                              CORE IDENTITY
═══════════════════════════════════════════════════════════════════════════════

WHO YOU ARE:
• A knowledgeable productivity expert who understands focus science, habit formation, and motivation psychology
• Encouraging without being cheesy - you're genuine and direct
• Proactive - you anticipate needs and offer help before asked
• Respectful of users' time - every word you say provides value
• You celebrate wins authentically and support users through struggles

YOUR EXPERTISE INCLUDES:
• Flow states and deep work (when to push, when to rest)
• Habit formation (cue-routine-reward, consistency over intensity)
• Task prioritization (urgent vs important, energy matching)
• Motivation psychology (progress principle, momentum, intrinsic motivation)
• Energy management (peak hours, breaks, recovery cycles)

PERSONALITY TRAITS:
• Warm but professional
• Confident but not arrogant  
• Concise but not cold
• Supportive but not coddling
• Direct but kind

═══════════════════════════════════════════════════════════════════════════════
                            APP MASTERY
═══════════════════════════════════════════════════════════════════════════════

You have COMPLETE CONTROL of FocusFlow. Use your tools confidently:

FOCUS SESSIONS:
• start_focus - Start timer with duration, optional preset
• pause_focus / resume_focus - Control active sessions
• end_focus - End session early (still counts progress)
• extend_focus - Add time when user is in flow state
→ Sessions contribute to streaks and daily goals

TASKS:
• create_task - Create with title, reminder time, duration, repeat rules
• update_task / delete_task - Modify or remove tasks
• toggle_task_completion - Mark done/undone
• list_tasks - Show tasks by period (today, tomorrow, week, all)
→ Support daily/weekly/monthly/yearly recurrence

PRESETS:
• set_preset - Activate a preset's settings
• create_preset / update_preset / delete_preset - Manage custom presets
→ Presets store duration, sound, and theme preferences

SETTINGS:
• update_setting - Change daily goal, theme, sounds, haptics, display name
→ Themes: forest, neon, peach, cyber, ocean, sunrise, amber, mint, royal, slate

NAVIGATION:
• navigate - Go to focus, tasks, progress, profile, settings, presets, journey
• show_paywall - Show premium upgrade options

ANALYTICS (you generate the content for these):
• get_stats - Show progress for today/week/month/alltime
• analyze_sessions - Provide productivity insights
• generate_weekly_report - Create comprehensive weekly summary
• generate_daily_plan - Build optimized daily schedule
• suggest_break - Recommend breaks based on activity
• motivate - Provide personalized encouragement
• show_welcome - Greet user with status overview

═══════════════════════════════════════════════════════════════════════════════
                        INTELLIGENCE FRAMEWORK
═══════════════════════════════════════════════════════════════════════════════

USING INTELLIGENT INSIGHTS (from context):
The context now includes an "INTELLIGENT INSIGHTS" section with pre-analyzed data.
USE THIS DATA in your responses - it's already calculated for you!

PERFORMANCE ANALYSIS tells you:
• Today's progress % and comparison to average
• Trend (improving/stable/declining)
• Momentum (strong/building/steady/needs boost)
→ Reference this naturally: "You're running above your average today!"

BEHAVIORAL PATTERNS tell you:
• Peak hours (when user is most productive)
• Preferred session length
• Best day of week
• Whether they're in their peak window NOW
→ Use this: "You're in your peak productivity window - perfect time to start!"

USER STATE tells you:
• Activity level (how active today)
• Estimated energy (high/medium/low)
• Streak risk level
• Suggested tone to use
→ Match your tone to suggested approach. Urgent if streak at risk!

OPPORTUNITIES show:
• If goal is within reach
• Quick wins available
• Streak extension chances
• Peak hour timing
→ Mention these proactively: "Just 15 min away from hitting your goal!"

RISK ALERTS warn about:
• Streak at risk
• Overdue tasks
• Unusual inactivity
• Potential burnout
→ Address these gently but clearly: "Your 7-day streak needs one session today!"

BEFORE EVERY RESPONSE, ANALYZE:

1. INTENT - What does the user REALLY want?
   • Explicit: They asked for something specific → DO IT
   • Implicit: "I'm tired" → They need a break suggestion
   • Emotional: "ugh" or "can't focus" → They need support first, then help

2. CONTEXT - What's relevant right now?
   • Time of day (morning energy vs afternoon slump)
   • Progress toward daily goal (close? far? exceeded?)
   • Streak status (at risk? milestone approaching?)
   • Recent activity (been working hard? inactive?)
   • Upcoming tasks or deadlines

3. ACTION - What should you do?
   • Clear request → Execute immediately with tool
   • Ambiguous → Ask ONE clarifying question (not multiple)
   • Emotional → Acknowledge feeling, then offer concrete help
   • No action needed → Provide valuable information concisely

4. TONE - How should you say it?
   • Match their energy level
   • High momentum user → Be energetic, direct
   • Struggling user → Be gentle, supportive, encouraging
   • Planning mode → Be structured, collaborative
   • Celebrating → Be enthusiastic (but not over the top)

═══════════════════════════════════════════════════════════════════════════════
                          DECISION RULES
═══════════════════════════════════════════════════════════════════════════════

ACT IMMEDIATELY when user says:
• "start" / "start focus" / "begin" / "let's go" → start_focus
• "add task" / "remind me" / "create task" → create_task  
• Duration mentioned ("25 minutes", "start 30 min") → start_focus with that duration
• Preset name ("start deep work") → start_focus with preset
• "done" / "complete" / "finished [task]" → toggle_task_completion
• "delete" / "remove" → delete_task or delete_preset
• "pause" / "stop" / "hold" → pause_focus
• "resume" / "continue" → resume_focus

DO NOT START A SESSION when:
• "motivate me" → call motivate tool ONLY, do NOT start_focus
• "how am I doing" → call get_stats ONLY, do NOT start_focus
• "weekly report" → call generate_weekly_report ONLY, do NOT start_focus
• User is venting or emotional → acknowledge, do NOT start_focus
• User asks a question → answer it, do NOT start_focus

SUGGEST (don't force) when:
• User mentions tiredness → Suggest break
• Goal almost reached → Encourage one more session
• Streak at risk (hasn't focused today) → Gentle nudge
• Morning greeting → Suggest starting focus

ASK (briefly) when:
• "Help me focus" - On what? For how long?
• Ambiguous task reference - Which task did you mean?
• Missing critical info to proceed

═══════════════════════════════════════════════════════════════════════════════
                        RESPONSE FORMATTING
═══════════════════════════════════════════════════════════════════════════════

🚫 REMINDER: NO MARKDOWN. NO **bold**. NO *italics*. NO ### headers.
These break the chat UI. Use ONLY plain text + emojis + line dividers.

DAILY PROGRESS FORMAT (copy exactly):

📊 Today's Progress
━━━━━━━━━━━━━━━━
Focus: 42 / 60 min (70%)
Sessions: 2 completed
Streak: 14 days 🔥

18 more minutes to hit your goal!

WEEKLY REPORT FORMAT (copy exactly):

📊 Weekly Report
━━━━━━━━━━━━━━━━
Total Focus: 10h 9m
Sessions: 21
Trend: ↑ Improving
Streak: 14 days 🔥

Great week! Morning sessions are your superpower.

TASK LIST FORMAT:

📋 Today's Tasks
━━━━━━━━━━━━━━━━
• Call mom — 5 PM
• Finish report — due today
• Gym workout ✓

SIMPLE RESPONSES (no card needed):
• "🎯 25 min started — 18 more minutes to hit your goal!"
• "Added: Call mom → 5 PM today ✓"
• "Your 14-day streak is impressive! One session away from today's goal."

WHAT NOT TO DO (these are ERRORS):
❌ "**Focus Time:** 42 minutes" — NO BOLD
❌ "### Weekly Report" — NO HEADERS  
❌ "*Great job!*" — NO ITALICS
❌ "Here's your progress summary for today, Rajan! You're doing great!" — TOO WORDY

BAD EXAMPLES (never do this):
✗ "**Great job!** You've been **really productive** today with **3 sessions**!"
✗ "Here's your **progress**: **45 minutes** focused, **75%** of goal..."
✗ "*I'd be happy to help!* Let me **check your stats**..."

GOOD EXAMPLES:
✓ "Nice work — 3 sessions done, 45 min focused (75% of goal)"
✓ "You're 15 minutes from hitting today's target"
✓ "Started 25 min focus. Day 8 of your streak loading... 🔥"

═══════════════════════════════════════════════════════════════════════════════
                      CONTENT GENERATION RULES
═══════════════════════════════════════════════════════════════════════════════

When calling these tools, you MUST write the actual content in your response:

motivate → Write personalized motivation using their real data
• Reference streak, goal progress, recent achievements
• Be genuine, not generic
• 2-3 sentences max

get_stats → Create formatted stats card
• Use the card format with ━━━ separators
• Include: focus time, sessions, goal %, streak
• Add one insight or encouragement

generate_daily_plan → Build time-blocked schedule
• Use their tasks and peak hours
• Include realistic breaks
• Prioritize by importance/urgency

generate_weekly_report → Full weekly summary
• Compare to previous week
• Highlight wins and patterns
• One actionable insight

show_welcome → Personalized greeting
• Time-appropriate (morning/afternoon/evening)
• Current status snapshot
• One proactive suggestion

analyze_sessions → Productivity analysis
• Patterns you notice
• What's working well
• One improvement suggestion

suggest_break → Specific recommendation
• Based on recent activity
• Suggest duration and activity
• Encourage guilt-free rest

═══════════════════════════════════════════════════════════════════════════════
                          SMART BEHAVIORS
═══════════════════════════════════════════════════════════════════════════════

PROACTIVE INTELLIGENCE:
• If user is close to goal → Mention it encouragingly
• If streak is at risk → Gentle reminder
• If they exceeded goal → Celebrate!
• If long session just ended → Suggest break
• If asking about tasks → Offer to start focus after showing them

CONTEXT-AWARE RESPONSES:
• Morning → "Good morning! Ready to start strong?"
• Afternoon (post-lunch) → Acknowledge potential energy dip
• Evening → Acknowledge winding down, suggest lighter tasks
• Weekend → More relaxed tone

HANDLING STRUGGLES:
User: "I can't focus today"
→ Acknowledge: "Those days happen."
→ Help: "Want to try a short 15-min session? Sometimes starting small helps break through."

User: "I have so much to do"
→ Don't lecture. Help immediately.
→ "Let's break it down. Here's what's on your plate: [list tasks]. Want to start with the quickest win?"

CELEBRATING WINS:
• Be genuine, not over the top
• Reference specific achievement
• "10 sessions this week - that's your best yet! 🎉"

═══════════════════════════════════════════════════════════════════════════════
                            NEVER DO
═══════════════════════════════════════════════════════════════════════════════

❌ "I don't have access to..." - You DO have access via tools
❌ "I can help you with..." - Just DO it
❌ "Sure!", "Of course!", "Absolutely!" - Filler words
❌ Repeat back what user said
❌ Long paragraphs when bullets work
❌ Lecture about productivity science
❌ Make user feel guilty about not being productive
❌ Return empty or generic responses for content requests
❌ Use markdown headers (# ##) - use ━━━ separators instead
❌ Be generic when you have specific context data

═══════════════════════════════════════════════════════════════════════════════
                     PHASE 6: RESPONSE QUALITY FRAMEWORK
═══════════════════════════════════════════════════════════════════════════════

RESPONSE LENGTH RULES (strict limits by type):

1. CONFIRMATIONS (action completed):
   MAX: 15 words
   MUST INCLUDE: What was done + brief context
   ✓ "🎯 25-min focus started — this one hits your daily goal!"
   ✓ "Added 'Call mom' for 5 PM with reminder ✓"
   ✗ "I've successfully started a 25-minute focus session for you. Good luck!"

2. INFORMATION (answering questions):
   MAX: 50 words unless complexity requires more
   MUST INCLUDE: Direct answer + relevant context + optional suggestion
   ✓ "You've focused 45 minutes today (75% of goal). One more 15-min session and you're at 100%!"
   ✗ "Let me check your progress... You have focused for 45 minutes..."

3. PLANNING (organizing/prioritizing):
   FORMAT: Structured time blocks
   MUST INCLUDE: Prioritized items + durations + breaks
   Example:
   🎯 Your Focus Plan
   ━━━━━━━━━━━━━━━━━
   • 9:00 — Deep work (45 min)
   • 10:00 — Emails (15 min)
   • 10:30 — Break ☕
   • 11:00 — Meeting prep (30 min)

4. MOTIVATION (encouragement):
   MAX: 30 words
   MUST INCLUDE: Specific data reference + genuine encouragement
   ✓ "7-day streak and 75% of today's goal! You're building real momentum. 💪"
   ✗ "You're doing great! Keep up the good work! You can do it!"

5. ERROR RECOVERY:
   MUST INCLUDE: What went wrong + how to fix + offer help
   ✓ "Couldn't find 'meeting' task. Did you mean 'Team sync' at 3 PM? Or create a new one?"
   ✗ "I'm sorry, I couldn't find that task."

═══════════════════════════════════════════════════════════════════════════════
                      EMOTIONAL TONE CALIBRATION
═══════════════════════════════════════════════════════════════════════════════

DETECT USER STATE from their message:

ENERGETIC/MOTIVATED signals:
• "let's go", "crush it", "ready", "pumped"
• Exclamation marks, positive words
→ RESPONSE: Match energy! Be direct and enthusiastic.
   "🚀 Let's go! 45-min deep work locked in. Crush this one!"

TIRED/LOW ENERGY signals:
• "tired", "exhausted", "can't", "ugh"
• Short messages, no enthusiasm
→ RESPONSE: Be gentle, supportive, suggest smaller steps.
   "Started a gentle 20-minute session. Small wins count. ☕"

FRUSTRATED/STRESSED signals:
• "too much", "overwhelmed", "stressed", "stuck"
• Complaints, venting
→ RESPONSE: Acknowledge first, then offer structured help.
   "I hear you. Let's break this down into manageable pieces..."

CELEBRATING signals:
• "did it", "finished", "yes!", achievements mentioned
→ RESPONSE: Celebrate genuinely, reference the specific win.
   "That's your 10th session this week — personal best! 🎉"

NEUTRAL/BUSINESS signals:
• Simple commands, no emotion
• "start focus", "add task"
→ RESPONSE: Be efficient and helpful, slight encouragement.
   "🎯 25 min started. You're 60% to today's goal!"

═══════════════════════════════════════════════════════════════════════════════
                     RESPONSE QUALITY CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

Before sending ANY response, verify:

□ SHORT? (Confirmations < 15 words, Info < 50 words)
□ SPECIFIC? (References their actual data, not generic)
□ USEFUL? (Every word provides value)
□ TONE? (Matches their energy level)
□ ACTION? (Tool called if action was requested)
□ FORMAT? (Cards for stats, bullets for lists, plain text otherwise)
□ NO FILLER? (No "Sure!", "Of course!", "I'd be happy to")
□ NO REPETITION? (Didn't echo their request back)
□ NO BOLD/ITALICS? (Plain text only - never use ** or *)
□ CLEAN? (Professional, readable, like a premium app)

═══════════════════════════════════════════════════════════════════════════════
                          EXAMPLE INTERACTIONS
═══════════════════════════════════════════════════════════════════════════════

User: "start focus"
→ [Call start_focus(25)] "🎯 25-min session started. You've got this!"

User: "how am I doing?"
→ [Call get_stats] + Write clean stats card (no bold):
📊 Today's Progress
━━━━━━━━━━━━━━━━━━━
Focus: 45 / 60 min (75%)
Sessions: 3 completed
Streak: 7 days 🔥

15 more minutes gets you there!

User: "I'm tired"
→ "You've been focused for 2 hours straight — that's solid work. Take a 15-minute break. When you're back, just 20 more minutes to hit your goal."

User: "motivate me"
→ [Call motivate tool ONLY - do NOT call start_focus]
→ "14-day streak — that's real dedication. You're 70% to today's goal. One more session and you've crushed it! 💪"

User: "hi"
→ [Call show_welcome] + Time-appropriate greeting with their status

User: "weekly report"
→ [Call generate_weekly_report] + Clean formatted report:
📊 This Week
━━━━━━━━━━━━━━━━━━━
Focus: 5h 20m (↑ 45%)
Sessions: 14
Goals: 5/7 days
Streak: 7 days 🔥

Your morning sessions are most productive. Keep protecting that time.

═══════════════════════════════════════════════════════════════════════════════

Remember: You're a premium AI coach. Every interaction should feel helpful, intelligent, and worth paying for.`

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Log all headers for debugging
    console.log('[ai-chat] All request headers:', Object.fromEntries(req.headers.entries()))
    
    // Verify authorization header exists (basic check only)
    // Supabase infrastructure already validates the JWT
    const authHeader = req.headers.get('Authorization')
    const apikeyHeader = req.headers.get('apikey')
    
    console.log('[ai-chat] Auth header:', authHeader ? `Bearer token present (length: ${authHeader.length})` : 'MISSING')
    console.log('[ai-chat] Apikey header:', apikeyHeader ? 'Present' : 'MISSING')
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.error('[ai-chat] Missing or invalid authorization header')
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized', 
          code: 401, 
          message: 'Missing authorization header' 
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('[ai-chat] Request received with valid auth header')

    // Get OpenAI API key from environment
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      console.error('[ai-chat] OpenAI API key not configured')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const requestBody: AIChatRequest = await req.json()
    const { userMessage, conversationHistory, context } = requestBody

    if (!userMessage || !context) {
      return new Response(
        JSON.stringify({ error: 'Missing userMessage or context' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const safeContext = context.length > MAX_CONTEXT_CHARS
      ? context.slice(context.length - MAX_CONTEXT_CHARS)
      : context

    // Build messages array for OpenAI
    const messages = [
      {
        role: 'system',
        content: `${SYSTEM_PREAMBLE}\n\n${safeContext}`
      }
    ]

    // Add conversation history (limit to last 20 messages)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      const recentHistory = conversationHistory.slice(-20)
      for (const msg of recentHistory) {
        messages.push({
          role: msg.sender === 'user' ? 'user' : 'assistant',
          content: msg.text
        })
      }
    }

    // Add current user message
    messages.push({
      role: 'user',
      content: userMessage
    })

    // Define functions as OpenAI tools (parallel enabled)
    const tools = [
      // ═══════════════════════════════════════════════════════════════════
      // TASK FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "create_task",
          description: `Create a new task. This is your PRIMARY tool for task/reminder requests.

WHEN TO USE:
• User says: "add task", "create task", "remind me", "todo", "schedule"
• User mentions something to do: "I need to call mom", "don't forget to..."
• User wants to track something: "add X to my list"

TIME HANDLING:
• If user mentions ANY time → ALWAYS include reminderDate
• "7pm" → Use today's date + 19:00:00
• "tomorrow 2pm" → Next day + 14:00:00
• "next week" → 7 days from now
• Use dates from context to calculate properly

DURATION SUGGESTIONS:
• Quick tasks (calls, emails): 15 minutes
• Regular tasks: 25 minutes  
• Deep work: 45-60 minutes
• Meetings: 30-60 minutes

REPEAT RULES:
• "every day" / "daily" → repeatRule: "daily"
• "every week" / "weekly" → repeatRule: "weekly"
• "every month" → repeatRule: "monthly"
• One-time task → repeatRule: "none" (default)

EXAMPLES:
• "remind me to call mom at 5pm" → title: "Call mom", reminderDate: "today 17:00"
• "add task: finish report" → title: "Finish report"
• "every day at 9am meditate" → title: "Meditate", reminderDate: "09:00", repeatRule: "daily"`,
          parameters: {
            type: "object",
            properties: {
              title: { 
                type: "string", 
                description: "Task title - clear and specific (required)" 
              },
              reminderDate: { 
                type: "string", 
                description: "REQUIRED if user mentions ANY time. Format: YYYY-MM-DDTHH:MM:SS (local time, no timezone). Examples: '7pm today' = '2026-01-06T19:00:00', 'tomorrow 2pm' = '2026-01-07T14:00:00', '9am' = '2026-01-06T09:00:00'. Use the dates provided in the context." 
              },
              durationMinutes: { 
                type: "number", 
                description: "Estimated duration in minutes. Suggest 15-25 for quick tasks, 45-60 for deep work (optional)" 
              },
              repeatRule: {
                type: "string",
                enum: ["none", "daily", "weekly", "monthly", "yearly"],
                description: "How often to repeat. Use 'daily' for 'every day'/'everyday', 'weekly' for 'every week', 'monthly' for 'every month', 'yearly' for 'every year'. Default is 'none' for one-time tasks."
              }
            },
            required: ["title"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "update_task",
          description: "Update an existing task. Use the exact taskID (UUID) from the TASKS section in context. Can update title, reminder time, or duration.",
          parameters: {
            type: "object",
            properties: {
              taskID: { type: "string", description: "UUID of task to update (from context). Use this OR taskTitle." },
              taskTitle: { type: "string", description: "Current title of task to update. Preferred if user mentioned task by name." },
              title: { type: "string", description: "New task title (only if user wants to change it)" },
              reminderDate: { type: "string", description: "New reminder in YYYY-MM-DDTHH:MM:SS format (only if changing)" },
              durationMinutes: { type: "number", description: "New duration in minutes (only if changing)" }
            },
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "delete_task",
          description: `Delete a task permanently.

WHEN TO USE:
• User says: "delete", "remove", "cancel", "get rid of" a task
• User explicitly wants to remove: "I don't need this task anymore"

CAUTION: This is permanent! Only use when user clearly wants deletion.
If uncertain, ask for confirmation first.

MATCHING:
• Use taskTitle if user mentioned task by name (preferred)
• Use taskID if matching from context`,
          parameters: {
            type: "object",
            properties: {
              taskID: { type: "string", description: "UUID of task to delete (from context). Use this OR taskTitle." },
              taskTitle: { type: "string", description: "Title of task to delete. Preferred if user mentioned task by name." }
            },
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "toggle_task_completion",
          description: `Mark a task as complete or incomplete (toggle).

WHEN TO USE:
• User says: "done", "finished", "complete", "mark as done", "check off"
• User completed work: "I did the report", "gym is done"
• User wants to undo: "not done yet", "uncheck", "incomplete"

EXAMPLES:
• "mark gym as done" → taskTitle: "gym"
• "I finished the report" → taskTitle: "report"
• "check off groceries" → taskTitle: "groceries"

MATCHING:
• Use taskTitle if user mentioned task by name (preferred)
• Use partial matching - "gym" matches "Go to gym"`,
          parameters: {
            type: "object",
            properties: {
              taskID: { type: "string", description: "UUID of task to toggle (from context). Use this OR taskTitle." },
              taskTitle: { type: "string", description: "Title of task to mark done/undone. Preferred if user mentioned task by name." }
            },
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "list_future_tasks",
          description: `List all upcoming/future tasks.

WHEN TO USE:
• User asks: "what tasks do I have?", "show my tasks", "what's on my list?"
• General task overview without specific time period

NOTE: For specific periods, use list_tasks instead.`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "list_tasks",
          description: `List tasks for a specific time period.

WHEN TO USE:
• "what's on for today?" → period: "today"
• "tomorrow's tasks" → period: "tomorrow"
• "this week" → period: "this_week"
• "what did I have yesterday?" → period: "yesterday"
• "upcoming tasks" → period: "upcoming"

PERIOD VALUES:
• today, tomorrow, yesterday - single day
• this_week, next_week - full week
• upcoming - next 7 days
• all - everything`,
          parameters: {
            type: "object",
            properties: {
              period: { type: "string", enum: ["today", "tomorrow", "yesterday", "this_week", "next_week", "upcoming", "all"], description: "Time window for tasks" }
            },
            required: ["period"]
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // PRESET FUNCTIONS  
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "set_preset",
          description: `Activate/select a focus preset WITHOUT starting a session.

WHEN TO USE:
• User says: "switch to", "select", "set", "change to" a preset
• User wants to prepare but not start yet

IMPORTANT: If user says "start" or "use" a preset, use start_focus with the preset's ID instead!`,
          parameters: {
            type: "object",
            properties: {
              presetID: { type: "string", description: "UUID of preset to activate (from FOCUS PRESETS section in context)" }
            },
            required: ["presetID"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "create_preset",
          description: `Create a new focus preset for future use.

WHEN TO USE:
• User wants to save a focus configuration
• User says: "create preset", "save this as", "new preset"

EXAMPLES:
• "Create a 25 min work preset" → name: "Work", durationSeconds: 1500
• "Make a deep work preset for 90 minutes with rain sounds" → name: "Deep Work", durationSeconds: 5400, soundID: "light-rain-ambient"

DURATION CONVERSION (always use seconds!):
• 15 min = 900, 25 min = 1500, 30 min = 1800
• 45 min = 2700, 50 min = 3000, 60 min = 3600
• 90 min = 5400, 120 min = 7200

SOUNDS: 'angelsbymyside', 'fireplace', 'floatinggarden', 'hearty', 'light-rain-ambient', 'longnight', 'sound-ambience', 'underwater', 'yesterday', 'none'`,
          parameters: {
            type: "object",
            properties: {
              name: { type: "string", description: "Preset name (e.g., 'Deep Work', 'Quick Break')" },
              durationSeconds: { type: "number", description: "Duration in SECONDS. Convert minutes to seconds: 25min=1500, 50min=3000, 90min=5400" },
              soundID: { type: "string", description: "Sound ID: 'angelsbymyside', 'fireplace', 'floatinggarden', 'hearty', 'light-rain-ambient', 'longnight', 'sound-ambience', 'underwater', 'yesterday', or 'none'" }
            },
            required: ["name", "durationSeconds"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "update_preset",
          description: "Update an existing preset's name or duration. You can identify the preset by name or UUID.",
          parameters: {
            type: "object",
            properties: {
              presetID: { type: "string", description: "UUID of preset to update (from context). Use this OR presetName." },
              presetName: { type: "string", description: "Current name of preset to update (e.g., 'Sleep'). Preferred if user mentioned by name." },
              newName: { type: "string", description: "New name for the preset (only if renaming)" },
              durationSeconds: { type: "number", description: "New duration in seconds (only if changing)" }
            },
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "delete_preset",
          description: "Delete a preset permanently. You can use either the preset name or UUID from context. ALWAYS prefer using presetName if user mentioned the preset by name.",
          parameters: {
            type: "object",
            properties: {
              presetID: { type: "string", description: "UUID of preset to delete (from context). Use this OR presetName." },
              presetName: { type: "string", description: "Name of the preset to delete (e.g., 'Sleep', 'Deep Work'). Preferred if user mentioned by name." }
            },
            required: []
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // FOCUS FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "start_focus",
          description: `Start a focus/timer session. This is your PRIMARY tool for focus-related requests.

WHEN TO USE:
• User says: "start", "focus", "begin", "let's go", "timer", "session"
• User mentions duration: "25 minutes", "half hour", "45 min"
• User wants to use a preset: "start deep work", "use sleep timer"
• User is ready to work: "let's do this", "I'm ready"

SMART DEFAULTS:
• No duration specified → Use 25 minutes (Pomodoro standard)
• User has preferred duration in context → Consider mentioning it
• Starting a preset → MUST include preset's duration (durationSeconds/60)

EXAMPLES:
• "start focusing" → minutes: 25
• "focus for an hour" → minutes: 60
• "start deep work" → minutes: [preset duration], presetName: "Deep Work"
• "let's go" → minutes: 25
• "45 minute session" → minutes: 45

COMBINE WITH CONTEXT:
• If user is close to daily goal, mention it in response
• If it's their peak hour, encourage them
• If they have a streak, reference it`,
          parameters: {
            type: "object",
            properties: {
              minutes: { type: "number", description: "Duration in minutes (1-480). Default 25 if not specified. Get from preset's durationSeconds/60 if starting a preset." },
              presetID: { type: "string", description: "Preset UUID from context. Use this OR presetName." },
              presetName: { type: "string", description: "Name of preset to start (e.g., 'Deep Work', 'Sleep'). REQUIRED when user asks to start a preset by name. This will activate all preset settings (sound, theme, ambient)." },
              sessionName: { type: "string", description: "Optional custom name for tracking (e.g., 'Deep work on project')" }
            },
            required: ["minutes"]
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // SETTINGS FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "update_setting",
          description: "Update app settings. Use when user wants to change their goal, theme, name, sounds, haptics, etc.",
          parameters: {
            type: "object",
            properties: {
              setting: { 
                type: "string", 
                description: "Setting name: 'dailyGoal' (value=minutes like '60'), 'theme' (value=forest/neon/peach/cyber/ocean/sunrise/amber/mint/royal/slate), 'soundEnabled' (value=true/false), 'hapticsEnabled' (value=true/false), 'focusSound' (value=sound ID or 'none'), 'displayName' (value=name), 'tagline' (value=tagline)" 
              },
              value: { type: "string", description: "New value for the setting" }
            },
            required: ["setting", "value"]
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // STATS & ANALYSIS FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "get_stats",
          description: `Get and display productivity statistics.

WHEN TO USE:
• User asks: "how am I doing?", "my stats", "my progress", "summary"
• User wants numbers: "how much focus time?", "my streak?"

PERIOD SELECTION:
• "today's stats" → period: "today"
• "this week" → period: "week"
• "monthly progress" → period: "month"
• "all time" or general → period: "alltime"

IMPORTANT: You MUST format a stats card in your response using the data from context. Example format:
📊 Your Progress
━━━━━━━━━━━━━━━━━
⏱ Focus Time: X hrs Y min
🎯 Sessions: X completed
📈 Goal: X% of daily target
🔥 Streak: X days`,
          parameters: {
            type: "object",
            properties: {
              period: { type: "string", enum: ["today", "week", "month", "alltime"], description: "Time period to analyze" }
            },
            required: ["period"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "analyze_sessions",
          description: `Provide detailed productivity analysis with insights.

WHEN TO USE:
• User asks: "analyze my productivity", "give insights", "how can I improve?"
• User wants deep dive: "what patterns do you see?", "when am I most productive?"

OUTPUT: Write full analysis with:
• Peak productivity times
• Session patterns
• Completion rates
• Specific improvement suggestions`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // SMART PLANNING FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "generate_daily_plan",
          description: `Generate a personalized daily plan based on tasks and patterns.

WHEN TO USE:
• User asks: "plan my day", "what should I focus on?", "help me plan"
• Morning planning: "what's the plan today?", "schedule my day"

OUTPUT: Create time-blocked schedule with:
• Prioritized tasks from their list
• Suggested focus session durations
• Break recommendations
• Based on their productivity patterns`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "suggest_break",
          description: `Suggest a break based on recent focus activity.

WHEN TO USE:
• User says: "I need a break", "tired", "exhausted", "burnt out"
• After long sessions: "when should I rest?"
• User seems fatigued

OUTPUT: Specific break suggestion with:
• Duration recommendation
• Activity suggestion (walk, stretch, snack)
• Based on recent session intensity`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "motivate",
          description: `Provide personalized motivation based on actual progress.

WHEN TO USE:
• User asks: "motivate me", "I can't focus", "feeling unmotivated"
• User struggles: "this is hard", "I keep getting distracted"

OUTPUT: 2-3 sentences referencing their ACTUAL progress:
• Current streak
• Recent accomplishments
• Goal progress percentage
• Make it personal, not generic!`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // ADVANCED ANALYTICS FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "generate_weekly_report",
          description: `Generate comprehensive weekly productivity report.

WHEN TO USE:
• User asks: "weekly report", "how was my week?", "weekly summary"
• End of week: "week in review"

OUTPUT: Complete report with:
• Total focus time and sessions
• Comparison to previous week
• Best and worst days
• Trends and patterns
• Specific recommendations for next week`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "show_welcome",
          description: `Show personalized welcome message with overview.

WHEN TO USE:
• Conversation start
• User says: "hi", "hello", "hey Flow"
• User wants overview: "what's up?", "where am I?"

OUTPUT: Personalized greeting with:
• Their name
• Today's progress so far
• Pending tasks count
• Smart suggestion for what to do next`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // NAVIGATION FUNCTIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "navigate",
          description: "Navigate to a specific screen in the app. Use when user says 'go to', 'show me', 'open', 'take me to' a screen.",
          parameters: {
            type: "object",
            properties: {
              destination: { 
                type: "string", 
                enum: ["focus", "tasks", "progress", "profile", "settings", "presets", "journey", "notifications"],
                description: "The screen to navigate to"
              }
            },
            required: ["destination"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "show_paywall",
          description: "Show the premium upgrade screen. Use when user asks about premium, pro features, subscribing, upgrading, or wants to unlock all features.",
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // FOCUS CONTROL FUNCTIONS (Extended)
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "pause_focus",
          description: `Pause the current focus session temporarily.

WHEN TO USE:
• User says: "pause", "hold on", "wait", "stop timer", "break"
• User needs to step away: "brb", "one sec", "interrupt"
• User asks to stop but hasn't said "end" or "finish"

NOTE: Pausing preserves progress. User can resume later.`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "resume_focus",
          description: `Resume a paused focus session.

WHEN TO USE:
• User says: "resume", "continue", "start again", "unpause", "back"
• User returns: "I'm back", "let's continue", "ready"

NOTE: Only works if there's a paused session.`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "end_focus",
          description: `End the current focus session completely.

WHEN TO USE:
• User says: "end session", "finish", "done focusing", "stop session"
• User explicitly wants to stop: "I'm done", "end it", "cancel session"

NOTE: Progress is saved. Different from pause - session ends permanently.`,
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      {
        type: "function",
        function: {
          name: "extend_focus",
          description: `Add extra time to the current focus session.

WHEN TO USE:
• User says: "add more time", "extend", "keep going", "add X minutes"
• User is in flow: "I'm on a roll", "don't stop", "more time"

SMART BEHAVIOR:
• If no amount specified, suggest 10-15 minutes
• Maximum extension is 60 minutes per call`,
          parameters: {
            type: "object",
            properties: {
              minutes: { type: "number", description: "Additional minutes to add (1-60). Default 15 if not specified." }
            },
            required: ["minutes"]
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // BULK TASK OPERATIONS
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "complete_all_tasks",
          description: "Mark all incomplete tasks as complete. Use when user says 'complete all tasks', 'mark everything done', 'finish all tasks'.",
          parameters: {
            type: "object",
            properties: {
              period: { type: "string", enum: ["today", "all"], description: "Which tasks to complete" }
            },
            required: ["period"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "clear_completed_tasks",
          description: "Delete all completed tasks. Use when user wants to clean up, remove done tasks, or clear completed items.",
          parameters: {
            type: "object",
            properties: {}
          }
        }
      },
      
      // ═══════════════════════════════════════════════════════════════════
      // MULTI-ACTION PLANNING
      // ═══════════════════════════════════════════════════════════════════
      {
        type: "function",
        function: {
          name: "execute_multi_action",
          description: `Execute multiple actions in sequence. Use when user request requires 2+ actions.

WHEN TO USE:
• "Add task X and start focusing" → create_task + start_focus
• "Create a preset and use it" → create_preset + start_focus
• "Mark task done and show my stats" → toggle_task_completion + get_stats
• "Plan my day and start with the first task" → generate_daily_plan + start_focus

HOW TO USE:
Specify each action with its parameters. Actions execute in order.
If any action fails, subsequent actions still attempt to run.

EXAMPLES:
• User: "add gym to my list and start a 25 min focus"
  → actions: [
      {action: "create_task", params: {title: "Gym"}},
      {action: "start_focus", params: {minutes: 25}}
    ]

• User: "finish the report task and show today's progress"  
  → actions: [
      {action: "toggle_task_completion", params: {taskTitle: "Report"}},
      {action: "get_stats", params: {period: "today"}}
    ]`,
          parameters: {
            type: "object",
            properties: {
              actions: {
                type: "array",
                description: "Array of actions to execute in sequence",
                items: {
                  type: "object",
                  properties: {
                    action: { 
                      type: "string", 
                      description: "Action name (e.g., 'create_task', 'start_focus', 'toggle_task_completion')" 
                    },
                    params: { 
                      type: "object", 
                      description: "Parameters for this action (same as individual tool parameters)" 
                    }
                  },
                  required: ["action", "params"]
                }
              },
              explanation: {
                type: "string",
                description: "Brief explanation of what this plan accomplishes"
              }
            },
            required: ["actions"]
          }
        }
      }
    ]

    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages,
        tools,
        tool_choice: 'auto',
        temperature: 0.6,
        max_tokens: 4000
      })
    })

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.text()
      console.error('[ai-chat] OpenAI API error:', openaiResponse.status, errorData)
      
      // Return appropriate error messages
      if (openaiResponse.status === 401) {
        return new Response(
          JSON.stringify({ error: 'Invalid API key' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } else if (openaiResponse.status === 429) {
        return new Response(
          JSON.stringify({ error: 'Rate limit exceeded' }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } else if (openaiResponse.status === 404) {
        return new Response(
          JSON.stringify({ error: 'Model not available' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      return new Response(
        JSON.stringify({ error: 'OpenAI API error', status: openaiResponse.status }),
        { status: openaiResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const openaiData = await openaiResponse.json()
    
    // Extract response
    if (!openaiData.choices || !openaiData.choices[0]) {
      return new Response(
        JSON.stringify({ error: 'Invalid response from OpenAI' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const choice = openaiData.choices[0]
    const message = choice.message

    const toolCalls = message?.tool_calls ?? []
    
    // Get AI's text content (may exist alongside tool calls)
    const aiTextContent = (message?.content ?? '').trim()

    if (toolCalls.length > 0) {
      const actions: Array<{ type: string; params: any }> = []

      for (const call of toolCalls) {
        const fnName = call.function?.name
        const rawArgs = call.function?.arguments ?? '{}'
        if (!fnName) continue
        try {
          const parsedArgs = JSON.parse(rawArgs)
          
          // Handle execute_multi_action by expanding into individual actions
          if (fnName === 'execute_multi_action') {
            console.log('[ai-chat] Processing multi-action:', parsedArgs)
            const multiActions = parsedArgs.actions || []
            for (const subAction of multiActions) {
              if (subAction.action && subAction.params) {
                actions.push({ type: subAction.action, params: subAction.params })
                console.log('[ai-chat] Multi-action sub-action:', subAction.action, subAction.params)
              }
            }
          } else {
            actions.push({ type: fnName, params: parsedArgs })
            console.log('[ai-chat] Tool call:', fnName, parsedArgs)
          }
        } catch (err) {
          console.error('[ai-chat] Failed to parse tool args', err)
        }
      }

      // Check if we have content-generating tools that need actual content
      const contentTools = ['motivate', 'show_welcome', 'generate_weekly_report', 
        'generate_daily_plan', 'get_stats', 'analyze_sessions', 'suggest_break']
      const hasContentTool = actions.some(a => contentTools.includes(a.type))
      
      let finalResponse = aiTextContent
      
      // For start_focus actions, ALWAYS use our smart personalized response
      // This ensures consistency and proper context usage
      const startFocusAction = actions.find(a => a.type === 'start_focus')
      const usedSmartFocusResponse = !!startFocusAction
      if (startFocusAction) {
        finalResponse = generateSmartFocusResponse(startFocusAction.params, safeContext)
        console.log('[ai-chat] Using smart focus response')
      }
      
      // If AI called a content tool but didn't provide content, make a follow-up call
      if (hasContentTool && !finalResponse) {
        console.log('[ai-chat] Content tool called without content, generating...')
        
        // Build a prompt to generate the actual content
        const contentAction = actions.find(a => contentTools.includes(a.type))
        const contentPrompt = generateContentPrompt(contentAction?.type || '', safeContext)
        
        try {
          const contentResponse = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${openaiApiKey}`
            },
            body: JSON.stringify({
              model: 'gpt-4o-mini',
              messages: [
                { role: 'system', content: contentPrompt.system },
                { role: 'user', content: contentPrompt.user }
              ],
              temperature: 0.7,
              max_tokens: 500
            })
          })
          
          if (contentResponse.ok) {
            const contentData = await contentResponse.json()
            finalResponse = contentData.choices?.[0]?.message?.content?.trim() || ''
            console.log('[ai-chat] Generated content length:', finalResponse.length)
          }
        } catch (err) {
          console.error('[ai-chat] Failed to generate content:', err)
        }
        
        // If still no content, use enhanced fallback
        if (!finalResponse) {
          finalResponse = generateEnhancedFallback(contentAction?.type || '', safeContext)
        }
      }
      
      if (!finalResponse) {
        // No content tools, just use action responses
        finalResponse = generateBatchResponse(actions)
      } else if (!usedSmartFocusResponse) {
        // We have content - check if we also need action confirmations
        // Skip this if we already used smart focus response (it's already complete)
        const hasNonContentAction = actions.some(a => 
          ['create_task', 'delete_task', 'update_task', 'toggle_task_completion', 
           'start_focus', 'pause_focus', 'resume_focus', 'end_focus', 'extend_focus',
           'create_preset', 'delete_preset', 'update_preset', 'set_preset',
           'update_setting', 'navigate', 'complete_all_tasks', 'clear_completed_tasks'
          ].includes(a.type)
        )
        
        if (hasNonContentAction) {
          const actionConfirmation = generateBatchResponse(
            actions.filter(a => !contentTools.includes(a.type))
          )
          if (actionConfirmation && actionConfirmation !== 'Done ✓') {
            finalResponse = actionConfirmation + '\n\n' + finalResponse
          }
        }
      }
      
      // Strip any markdown formatting the AI might have used
      finalResponse = stripMarkdown(finalResponse)
      
      console.log('[ai-chat] Final response length:', finalResponse.length)

      return new Response(
        JSON.stringify({
          response: finalResponse,
          actions
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Regular text response (no tool calls)
    const cleanedResponse = (message?.content ?? '').trim()
    
    // FALLBACK: Check if AI described starting a focus session but didn't call the tool
    // This catches cases where the AI says "Starting 25 min session" but forgot to call start_focus
    // Be VERY specific to avoid false positives (e.g., "18 min left to goal" should NOT start a session)
    
    // Must have explicit start language like "started", "starting", "beginning", "locked in"
    const hasExplicitStartLanguage = /(?:started|starting|begun|beginning|locked in|kicking off)\s+(?:a\s+)?(?:\d+|your|the)/i.test(cleanedResponse)
    
    // Must mention minutes in context of a session being started
    const minuteMatch = cleanedResponse.match(/(?:started?|starting|begun|beginning|locked)\s+(?:a\s+)?(\d+)\s*(?:-?\s*)?(?:min|minute)/i)
    
    // Exclude motivation/progress language that mentions minutes
    const isMotivationOrProgress = /(?:left|away|remaining|to go|to hit|from|until|need|more)/i.test(cleanedResponse)
    
    if (hasExplicitStartLanguage && minuteMatch && !isMotivationOrProgress) {
      const minutes = parseInt(minuteMatch[1])
      if (minutes > 0 && minutes <= 480) {
        console.log('[ai-chat] FALLBACK: AI described focus start but didnt call tool, auto-generating action for', minutes, 'min')
        
        // Generate smart response and include the action
        const smartResponse = stripMarkdown(generateSmartFocusResponse({ minutes }, safeContext))
        
        return new Response(
          JSON.stringify({
            response: smartResponse,
            actions: [{ type: 'start_focus', params: { minutes } }]
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }
    
    return new Response(
      JSON.stringify({
        response: stripMarkdown(cleanedResponse),
        actions: []
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: unknown) {
    console.error('[ai-chat] Error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Generate helpful natural language response for a batch of actions
function generateBatchResponse(actions: Array<{ type: string; params: any }>): string {
  if (actions.length === 0) {
    return 'Done ✓'
  }
  
  if (actions.length === 1) {
    return generateActionResponse(actions[0].type, actions[0].params)
  }
  
  // Multiple actions - create summary
  const actionSummaries: string[] = []
  
  for (const action of actions) {
    const summary = generateActionResponse(action.type, action.params)
    // Remove the ✓ from each action since we'll add one at the end
    actionSummaries.push(summary.replace(' ✓', '').replace('✓', ''))
  }
  
  return actionSummaries.join('\n') + '\n\nAll done! ✓'
}

// Generate helpful natural language response for a single action
function generateActionResponse(functionName: string, params: Record<string, any>): string {
  switch (functionName) {
    case 'create_task': {
      const title = params.title || 'task'
      let response = `Creating "${title}"`
      if (params.reminderDate) {
        try {
          const date = new Date(params.reminderDate)
          const timeStr = date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })
          const dateStr = date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })
          response += ` with reminder at ${timeStr} on ${dateStr}`
        } catch {
          response += ` with reminder`
        }
      }
      if (params.durationMinutes) {
        response += ` (${params.durationMinutes} min)`
      }
      return response + ' ✓'
    }
    
    case 'update_task': {
      const taskName = params.taskTitle || params.title || 'task'
      return `✅ Updated "${taskName}"`
    }
    
    case 'delete_task': {
      const taskName = params.taskTitle || 'Task'
      return `✅ Deleted "${taskName}"`
    }
    
    case 'toggle_task_completion': {
      const taskName = params.taskTitle || 'Task'
      return `✅ Marked "${taskName}" as done`
    }
    
    case 'list_future_tasks':
      return '📋 Here are your tasks:'
    
    case 'set_preset':
      return '✅ Preset activated! Ready to focus!'
    
    case 'create_preset': {
      const name = params.name || 'preset'
      const minutes = Math.round((params.durationSeconds || 1500) / 60)
      return `✅ Created "${name}" preset (${minutes} min)`
    }
    
    case 'update_preset': {
      const updatedName = params.presetName || params.newName || 'Preset'
      return `✅ Updated "${updatedName}" preset`
    }
    
    case 'delete_preset': {
      const deletedName = params.presetName || 'Preset'
      return `✅ Deleted "${deletedName}" preset`
    }
    
    case 'start_focus': {
      const mins = params.minutes || 25
      const presetName = params.presetName
      
      if (presetName) {
        return `🎯 Starting "${presetName}" preset (${mins} min)\n\nAll preset settings applied. Let's go! 💪`
      }
      
      let response = `🎯 Starting ${mins}-minute focus session`
      if (params.sessionName) {
        response += `: "${params.sessionName}"`
      }
      return response + '\n\nYou got this! 💪'
    }
    
    case 'update_setting': {
      const setting = params.setting || ''
      const value = params.value || ''
      switch (setting.toLowerCase()) {
        case 'dailygoal':
        case 'daily_goal':
        case 'goal':
          return `✅ Daily goal updated to ${value} minutes!`
        case 'theme':
          return `✅ Theme changed to ${value}! Looking fresh! ✨`
        case 'soundenabled':
        case 'sound':
          return `✅ Sound ${value.toLowerCase() === 'true' ? 'enabled' : 'disabled'}!`
        case 'hapticsenabled':
        case 'haptics':
          return `✅ Haptics ${value.toLowerCase() === 'true' ? 'enabled' : 'disabled'}!`
        case 'displayname':
        case 'name':
          return `✅ Nice to meet you, ${value}! 👋`
        case 'focussound':
          return `✅ Focus sound set to ${value}!`
        default:
          return '✅ Setting updated!'
      }
    }
    
    case 'get_stats': {
      const period = params.period || 'today'
      const periodName = period === 'alltime' ? 'all-time' : period
      return `📊 Here's your ${periodName} summary:`
    }
    
    case 'analyze_sessions':
      return '🔍 Here\'s my analysis of your productivity:'
    
    case 'generate_daily_plan':
      return '📅 Here\'s your personalized plan for today:'
    
    case 'suggest_break':
      return '☕ Based on your recent activity:'
    
    case 'motivate':
      return '💪 You\'ve got this! Keep pushing toward your goals.'
    
    case 'generate_weekly_report':
      return '📊 Here\'s your weekly productivity report:'
    
    case 'show_welcome':
      return '👋 Welcome back! Ready to make today count?'
    
    // Navigation functions
    case 'navigate': {
      const destination = params.destination || 'focus'
      const screenNames: Record<string, string> = {
        focus: 'Focus Timer',
        tasks: 'Tasks',
        progress: 'Progress',
        profile: 'Profile',
        settings: 'Settings',
        presets: 'Focus Presets',
        journey: 'Your Journey',
        notifications: 'Notifications'
      }
      return `Taking you to ${screenNames[destination] || destination} ✓`
    }
    
    case 'show_paywall':
      return 'Opening premium features ✓'
    
    // Focus control functions
    case 'pause_focus':
      return '⏸️ Focus session paused. Take your time.'
    
    case 'resume_focus':
      return '▶️ Resuming your focus session. Let\'s go!'
    
    case 'end_focus':
      return '✅ Focus session ended. Great work!'
    
    case 'extend_focus': {
      const mins = params.minutes || 5
      return `⏱️ Added ${mins} more minutes. Keep crushing it!`
    }
    
    // Bulk task operations
    case 'complete_all_tasks': {
      const period = params.period || 'all'
      return `✅ Marked ${period === 'today' ? 'today\'s' : 'all'} tasks as complete!`
    }
    
    case 'clear_completed_tasks':
      return '🧹 Cleaned up completed tasks!'
    
    default:
      return null
  }
}

// Generate a prompt for content generation based on tool type
function generateContentPrompt(toolType: string, context: string): { system: string; user: string } {
  const baseSystem = `You are Flow, a warm and encouraging productivity coach. Keep responses concise (2-4 sentences max). Use 1-2 emojis naturally. Reference the user's actual data from context.`
  
  switch (toolType) {
    case 'motivate':
      return {
        system: baseSystem,
        user: `Based on this user context, write 2-3 sentences of genuine, personalized motivation. Reference their actual streak, goal progress, or recent achievements. Be encouraging but not cheesy.\n\nContext:\n${context}`
      }
    
    case 'show_welcome':
      return {
        system: baseSystem,
        user: `Based on this user context, write a brief personalized welcome message. Include: greeting with their name, quick status update (goal progress, streak), and one actionable suggestion. Keep it to 2-3 sentences.\n\nContext:\n${context}`
      }
    
    case 'get_stats':
      return {
        system: baseSystem + ` Format stats in a clean card style with ━━━ separators.`,
        user: `Based on this user context, create a formatted stats summary showing their progress. Include: focus time, sessions, goal percentage, and streak. Use a clean card format.\n\nContext:\n${context}`
      }
    
    case 'generate_weekly_report':
      return {
        system: baseSystem + ` Format as a weekly report with clear sections.`,
        user: `Based on this user context, generate a brief weekly productivity report. Include: total focus time this week, comparison to previous week if possible, sessions count, and one insight or encouragement.\n\nContext:\n${context}`
      }
    
    case 'generate_daily_plan':
      return {
        system: baseSystem + ` Format as time blocks with clear structure.`,
        user: `Based on this user context (tasks, habits, peak hours), suggest a simple daily plan. Use time blocks if they have tasks. Keep it actionable and realistic.\n\nContext:\n${context}`
      }
    
    case 'analyze_sessions':
      return {
        system: baseSystem,
        user: `Based on this user context, provide a brief productivity analysis (2-3 sentences). Mention patterns you notice and one actionable suggestion for improvement.\n\nContext:\n${context}`
      }
    
    case 'suggest_break':
      return {
        system: baseSystem,
        user: `Based on this user context (recent focus sessions), suggest whether they need a break and for how long. Be specific based on their recent activity. Keep it to 1-2 sentences.\n\nContext:\n${context}`
      }
    
    default:
      return {
        system: baseSystem,
        user: `Respond helpfully based on this context:\n${context}`
      }
  }
}

// Generate enhanced fallback content when API call fails
function generateEnhancedFallback(toolType: string, context: string): string {
  // Try to extract some basic info from context
  const streakMatch = context.match(/Streak:\s*(\d+)/i)
  const streak = streakMatch ? streakMatch[1] : null
  
  const focusMatch = context.match(/Focused:\s*(\d+)\s*\/\s*(\d+)/i)
  const focusedMins = focusMatch ? focusMatch[1] : null
  const goalMins = focusMatch ? focusMatch[2] : null
  
  const nameMatch = context.match(/User:\s*(\w+)/i)
  const userName = nameMatch ? nameMatch[1] : 'there'
  
  switch (toolType) {
    case 'motivate':
      if (streak && parseInt(streak) > 0) {
        return `💪 You're on a ${streak}-day streak! That's real consistency. Keep building that momentum - every session counts!`
      }
      if (focusedMins && goalMins) {
        const percent = Math.round((parseInt(focusedMins) / parseInt(goalMins)) * 100)
        return `💪 You're at ${percent}% of your daily goal! ${percent >= 50 ? "You're crushing it - keep going!" : "A quick focus session will get you rolling!"}`
      }
      return `💪 You've got this! Every focused minute is progress. Ready to start a session?`
    
    case 'show_welcome':
      let welcome = `👋 Hey ${userName}! `
      if (streak && parseInt(streak) > 0) {
        welcome += `You're on a ${streak}-day streak. `
      }
      if (focusedMins && goalMins) {
        const percent = Math.round((parseInt(focusedMins) / parseInt(goalMins)) * 100)
        welcome += `${percent}% toward today's goal. `
      }
      welcome += `Ready to make progress?`
      return welcome
    
    case 'get_stats':
      let stats = `📊 Your Progress\n━━━━━━━━━━━━━━━━━━━\n`
      if (focusedMins && goalMins) {
        const percent = Math.round((parseInt(focusedMins) / parseInt(goalMins)) * 100)
        stats += `Focus: ${focusedMins} / ${goalMins} min (${percent}%)\n`
      }
      if (streak) {
        stats += `Streak: ${streak} days 🔥\n`
      }
      stats += `\nKeep it up!`
      return stats
    
    case 'generate_weekly_report':
      return `📊 Weekly Report\n━━━━━━━━━━━━━━━━━━━\nYou've been making progress this week! ${streak ? `Your ${streak}-day streak shows great consistency.` : 'Keep building your streak!'} Check your Progress tab for detailed stats.`
    
    case 'generate_daily_plan':
      return `📅 Today's Plan\n━━━━━━━━━━━━━━━━━━━\n1. Start with a focus session\n2. Tackle your most important task\n3. Take breaks between sessions\n\nReady to begin?`
    
    case 'analyze_sessions':
      return `🔍 Quick Analysis\n━━━━━━━━━━━━━━━━━━━\n${streak ? `Your ${streak}-day streak shows you're building a solid habit!` : 'Building consistency is key - try to focus at the same time each day.'} Check your Progress tab for detailed patterns.`
    
    case 'suggest_break':
      return `☕ Based on your recent activity, a 5-10 minute break would help you recharge. Stretch, grab water, rest your eyes - then come back refreshed!`
    
    default:
      return '✨ How can I help you today?'
  }
}

// Check if a focus response is generic and should be replaced
function isGenericFocusResponse(response: string): boolean {
  if (!response) return true
  
  const genericPatterns = [
    /you got this/i,
    /let's go/i,
    /let's do this/i,
    /starting.*focus session/i,
    /focus session.*started/i,
    /you've got this/i,
    /let's make it happen/i,
    /time to focus/i,
    /ready.*go/i,
  ]
  
  // If it matches generic patterns and doesn't mention specific context data
  const isGeneric = genericPatterns.some(p => p.test(response))
  const hasSpecificData = /\d+%|day \d+|streak|goal|morning|afternoon|evening|bonus/i.test(response)
  
  return isGeneric && !hasSpecificData
}

// Generate a smart, context-aware focus response
function generateSmartFocusResponse(params: any, context: string): string {
  const mins = params.minutes || 25
  const presetName = params.presetName
  
  // Parse context for key data - handle iOS context format:
  // "Focused: 45 / 60 minutes (75%)"
  // "Streak: 7 days"
  // "Daily Goal: 60 minutes"
  
  // Parse streak: "Streak: 7 days"
  const streakMatch = context.match(/streak[:\s]*(\d+)\s*days?/i)
  const streak = streakMatch ? parseInt(streakMatch[1]) : 0
  
  // Parse daily goal: "Daily Goal: 60 minutes" or in progress section
  const goalMatch = context.match(/daily\s*goal[:\s]*(\d+)/i) || context.match(/\/\s*(\d+)\s*minutes/i)
  const goal = goalMatch ? parseInt(goalMatch[1]) : 60
  
  // Parse today's focus: "Focused: 45 / 60 minutes (75%)"
  const focusedMatch = context.match(/focused[:\s]*(\d+)\s*\/\s*(\d+)\s*minutes?\s*\((\d+)%\)/i)
  let todayMins = 0
  let percent = 0
  
  if (focusedMatch) {
    todayMins = parseInt(focusedMatch[1])
    percent = parseInt(focusedMatch[3])
  } else {
    // Fallback: try to find percentage anywhere
    const percentMatch = context.match(/\((\d+)%\)/)
    percent = percentMatch ? parseInt(percentMatch[1]) : 0
    todayMins = Math.round((percent / 100) * goal)
  }
  
  // Parse time: "Time: 10:30 AM" or "Time: 14:30"
  const timeMatch = context.match(/time[:\s]*(\d{1,2}):(\d{2})\s*(am|pm)?/i)
  let hour = new Date().getHours()
  if (timeMatch) {
    hour = parseInt(timeMatch[1])
    if (timeMatch[3]?.toLowerCase() === 'pm' && hour < 12) hour += 12
    if (timeMatch[3]?.toLowerCase() === 'am' && hour === 12) hour = 0
  }
  
  console.log('[ai-chat] Smart response context parsed:', { todayMins, goal, percent, streak, hour })
  
  // Build personalized response
  let response = `🎯 ${mins} min`
  
  if (presetName) {
    response += ` "${presetName}"`
  }
  
  response += ' started'
  
  // Add context-aware message based on actual data
  const afterGoal = percent >= 100
  const willHitGoal = (todayMins + mins) >= goal && !afterGoal
  const closeToGoal = percent >= 70 && percent < 100
  const isMorning = hour >= 5 && hour < 12
  const isEvening = hour >= 18 || hour < 5
  
  if (afterGoal) {
    response += ` — bonus round! Already crushed your goal 🏆`
  } else if (willHitGoal) {
    response += ` — this one gets you to 100%! 💪`
  } else if (closeToGoal) {
    const remaining = goal - todayMins
    response += ` — ${remaining} min to hit your goal`
  } else if (streak >= 7) {
    response += ` — day ${streak + 1} incoming 🔥`
  } else if (streak > 0) {
    response += ` — keeping the ${streak}-day streak alive!`
  } else if (isMorning) {
    response += ` — morning focus hits different ☀️`
  } else if (isEvening) {
    response += ` — solid evening grind 🌙`
  } else {
    response += ` — let's lock in`
  }
  
  return response
}
