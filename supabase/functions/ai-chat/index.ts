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

interface OpenAIMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authorization header exists (user must be authenticated)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('[ai-chat] Missing authorization header')
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('[ai-chat] Request from authenticated user')

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

    // Build messages array for OpenAI
    const messages: OpenAIMessage[] = [
      {
        role: 'system',
        content: context
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

    // Define functions for OpenAI function calling
    const functions = [
      {
        name: "create_task",
        description: "Create a new task in the user's task list",
        parameters: {
          type: "object",
          properties: {
            title: { type: "string", description: "Task title" },
            reminderDate: { type: "string", description: "Reminder date in YYYY-MM-DDTHH:MM:SS format (optional)" },
            durationMinutes: { type: "number", description: "Estimated duration in minutes (optional)" }
          },
          required: ["title"]
        }
      },
      {
        name: "update_task",
        description: "Update an existing task",
        parameters: {
          type: "object",
          properties: {
            taskID: { type: "string", description: "Task ID" },
            title: { type: "string", description: "New task title (optional)" },
            reminderDate: { type: "string", description: "New reminder date (optional)" },
            durationMinutes: { type: "number", description: "New duration in minutes (optional)" }
          },
          required: ["taskID"]
        }
      },
      {
        name: "delete_task",
        description: "Delete a task",
        parameters: {
          type: "object",
          properties: {
            taskID: { type: "string", description: "Task ID" }
          },
          required: ["taskID"]
        }
      },
      {
        name: "toggle_task_completion",
        description: "Toggle task completion status",
        parameters: {
          type: "object",
          properties: {
            taskID: { type: "string", description: "Task ID" }
          },
          required: ["taskID"]
        }
      },
      {
        name: "start_focus",
        description: "Start a focus session with optional duration",
        parameters: {
          type: "object",
          properties: {
            minutes: { type: "number", description: "Duration in minutes (default: 25)" },
            presetID: { type: "string", description: "Optional preset ID to use" },
            sessionName: { type: "string", description: "Optional name for the session" }
          }
        }
      },
      {
        name: "get_stats",
        description: "Get user's task statistics and productivity data",
        parameters: {
          type: "object",
          properties: {
            period: { type: "string", enum: ["today", "week", "month", "alltime"], description: "Time period for stats" }
          },
          required: ["period"]
        }
      },
      {
        name: "analyze_sessions",
        description: "Analyze user's productivity patterns and provide insights",
        parameters: {
          type: "object",
          properties: {}
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
        messages: messages,
        temperature: 0.7,
        max_tokens: 800,
        functions: functions,
        function_call: 'auto'
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

    // Handle function calls
    if (message.function_call) {
      const functionName = message.function_call.name
      const functionArgs = JSON.parse(message.function_call.arguments || '{}')
      
      return new Response(
        JSON.stringify({
          response: `Executing action: ${functionName}`,
          action: {
            type: functionName,
            params: functionArgs
          }
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Regular text response
    return new Response(
      JSON.stringify({
        response: message.content,
        action: null
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-chat] Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
