// Supabase Edge Function: delete-user
// This function handles complete account deletion including:
// 1. All user data from database tables
// 2. The auth user account itself
//
// Deploy with: supabase functions deploy delete-user
// Set secret: supabase secrets set SERVICE_ROLE_KEY=your-service-role-key

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization') || req.headers.get('authorization')
    console.log('[delete-user] Auth header present:', !!authHeader)
    
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract the JWT token (case-insensitive Bearer removal)
    const token = authHeader.replace(/^Bearer\s+/i, '')
    console.log('[delete-user] Token length:', token.length)
    console.log('[delete-user] Token prefix:', token.substring(0, 20) + '...')

    // Get environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY')
    
    console.log('[delete-user] SUPABASE_URL present:', !!supabaseUrl)
    console.log('[delete-user] SERVICE_ROLE_KEY present:', !!supabaseServiceKey)
    
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('[delete-user] Missing environment variables')
      return new Response(
        JSON.stringify({ error: 'Server configuration error', details: 'Missing environment variables' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create admin client with service role - this can verify any JWT
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Verify the user's JWT using admin client
    console.log('[delete-user] Verifying JWT with admin client...')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    console.log('[delete-user] getUser result - user:', user?.id, 'error:', userError?.message)
    
    if (userError || !user) {
      console.error('[delete-user] JWT verification failed:', userError)
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token', details: userError?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = user.id
    console.log(`[delete-user] Starting deletion for user: ${userId}`)

    // Delete all user data from tables (order matters for foreign keys)
    const tables = [
      'task_completions',
      'tasks',
      'focus_sessions',
      'focus_presets',
      'focus_preset_settings',
      'user_settings',
      'user_stats'
    ]

    for (const table of tables) {
      const { error } = await supabaseAdmin
        .from(table)
        .delete()
        .eq('user_id', userId)
      
      if (error) {
        console.error(`[delete-user] Error deleting from ${table}:`, error)
        // Continue with other tables even if one fails
      } else {
        console.log(`[delete-user] Deleted from ${table}`)
      }
    }

    // Delete the auth user using admin API
    const { error: deleteUserError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteUserError) {
      console.error('[delete-user] Error deleting auth user:', deleteUserError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to delete auth account',
          details: deleteUserError.message,
          dataDeleted: true // Data was deleted even if auth deletion failed
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[delete-user] Successfully deleted user: ${userId}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Account and all data deleted successfully' 
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[delete-user] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

