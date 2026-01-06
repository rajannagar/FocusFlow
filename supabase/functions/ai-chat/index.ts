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
const SYSTEM_PREAMBLE = `You are Focus AI, the in-app assistant for FocusFlow. Rules:
- Accuracy first: never invent data; use only context and tool results.
- Relevance: answer ONLY what the user asked; skip unrelated extras.
- Tone: friendly, professional, concise; minimal filler.
- Formatting: short sentences; use bullets when they improve clarity; emojis are okay but sparing (0–2) and only if they fit naturally.
- Actions: if something should be done, call the tool instead of describing it.`

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
          description: "Create a new task. ALWAYS use this when user wants to add a task, reminder, todo, or schedule something. If user mentions ANY time (7pm, tomorrow, next week), ALWAYS include reminderDate. Be proactive - 'remind me to call mom' = create task with reminder.",
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
                description: "Estimated duration in minutes. Suggest 25 for quick tasks, 50 for deep work (optional)" 
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
              taskID: { type: "string", description: "UUID of task to update (from context, e.g., '12345678-1234-1234-1234-123456789abc')" },
              title: { type: "string", description: "New task title (only if user wants to change it)" },
              reminderDate: { type: "string", description: "New reminder in YYYY-MM-DDTHH:MM:SS format (only if changing)" },
              durationMinutes: { type: "number", description: "New duration in minutes (only if changing)" }
            },
            required: ["taskID"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "delete_task",
          description: "Delete a task permanently. Only use when user explicitly asks to delete, remove, or cancel a task.",
          parameters: {
            type: "object",
            properties: {
              taskID: { type: "string", description: "UUID of task to delete (from context)" }
            },
            required: ["taskID"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "toggle_task_completion",
          description: "Mark a task as complete or incomplete. Use when user says 'done', 'complete', 'finished', 'mark as done', 'check off', etc.",
          parameters: {
            type: "object",
            properties: {
              taskID: { type: "string", description: "UUID of task to toggle (from context)" }
            },
            required: ["taskID"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "list_future_tasks",
          description: "List all upcoming/future tasks. Use when user asks 'what tasks do I have?', 'show my tasks', 'upcoming tasks', 'what's on my list?'",
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
          description: "List tasks for a specific period. Use when user asks for today, tomorrow, yesterday, this week, next week, or upcoming tasks.",
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
          description: "Activate/select a focus preset. Use when user wants to 'use', 'set', 'switch to', or 'activate' a specific preset.",
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
          description: "Create a new focus preset. Use when user wants to create, add, or make a new preset.",
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
          description: "Update an existing preset's name or duration.",
          parameters: {
            type: "object",
            properties: {
              presetID: { type: "string", description: "UUID of preset to update (from context)" },
              name: { type: "string", description: "New name (only if changing)" },
              durationSeconds: { type: "number", description: "New duration in seconds (only if changing)" }
            },
            required: ["presetID"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "delete_preset",
          description: "Delete a preset permanently.",
          parameters: {
            type: "object",
            properties: {
              presetID: { type: "string", description: "UUID of preset to delete (from context)" }
            },
            required: ["presetID"]
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
          description: "Start a focus/timer session. Use when user says 'start focus', 'let's focus', 'start timer', 'focus for X minutes', 'begin session'.",
          parameters: {
            type: "object",
            properties: {
              minutes: { type: "number", description: "Duration in minutes (1-480). Default 25 for Pomodoro, 50 for deep work." },
              presetID: { type: "string", description: "Optional preset ID to use (from context)" },
              sessionName: { type: "string", description: "Optional name for tracking (e.g., 'Deep work on project')" }
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
          description: "Get productivity statistics. Use when user asks 'how am I doing?', 'show my stats', 'my progress', 'summary'.",
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
          description: "Provide detailed productivity analysis and personalized recommendations. Use for 'analyze my productivity', 'give insights', 'how can I improve?'",
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
          description: "Generate a personalized daily plan based on user's tasks, goals, and productivity patterns. Use when user asks 'plan my day', 'what should I focus on?', 'help me plan', 'daily schedule', 'what's my plan?', or at the start of a conversation.",
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
          description: "Suggest a break based on recent focus activity. Use when user says 'I need a break', 'tired', 'exhausted', 'when should I rest?', 'break time?', or after extended focus periods.",
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
          description: "Provide personalized motivation and encouragement based on user's progress. Use when user seems discouraged, asks for motivation, says 'motivate me', 'I can't focus', 'help me stay motivated', or needs encouragement.",
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
          description: "Generate a comprehensive weekly productivity report with stats, trends, and insights. Use when user asks 'weekly report', 'how was my week?', 'weekly summary', 'week in review', 'last 7 days', or wants to see their weekly performance.",
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
          description: "Show a personalized welcome message with today's status, pending tasks, and suggestions. Use at the start of conversations, when user says 'hi', 'hello', 'hey', 'what's up', or when they want a quick overview of their day.",
          parameters: {
            type: "object",
            properties: {}
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
        model: 'gpt-4o',
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

    if (toolCalls.length > 0) {
      const actions: Array<{ type: string; params: any }> = []

      for (const call of toolCalls) {
        const fnName = call.function?.name
        const rawArgs = call.function?.arguments ?? '{}'
        if (!fnName) continue
        try {
          const parsedArgs = JSON.parse(rawArgs)
          actions.push({ type: fnName, params: parsedArgs })
          console.log('[ai-chat] Tool call:', fnName, parsedArgs)
        } catch (err) {
          console.error('[ai-chat] Failed to parse tool args', err)
        }
      }

      const actionResponse = generateBatchResponse(actions)

      return new Response(
        JSON.stringify({
          response: actionResponse,
          actions
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Regular text response (keep bullets/formatting)
    const cleanedResponse = (message?.content ?? '').trim()
    
    return new Response(
      JSON.stringify({
        response: cleanedResponse,
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
    
    case 'update_task':
      return 'Updating your task ✓'
    
    case 'delete_task':
      return 'Task deleted ✓'
    
    case 'toggle_task_completion':
      return '✅ Task completion toggled!'
    
    case 'list_future_tasks':
      return '📋 Here are your tasks:'
    
    case 'set_preset':
      return '✅ Preset activated! Ready to focus!'
    
    case 'create_preset': {
      const name = params.name || 'preset'
      const minutes = Math.round((params.durationSeconds || 1500) / 60)
      return `✅ Created "${name}" preset (${minutes} min)`
    }
    
    case 'update_preset':
      return '✅ Preset updated!'
    
    case 'delete_preset':
      return '✅ Preset deleted!'
    
    case 'start_focus': {
      const mins = params.minutes || 25
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
      return ''  // Let the action handler provide the full motivation message
    
    case 'generate_weekly_report':
      return ''  // Let the action handler provide the full report
    
    case 'show_welcome':
      return ''  // Let the action handler provide the full welcome
    
    default:
      return '✅ Done!'
  }
}
