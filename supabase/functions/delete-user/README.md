# Delete User Edge Function

This Supabase Edge Function handles complete account deletion for FocusFlow users.

## What it does

1. Verifies the user's JWT token
2. Deletes all user data from database tables:
   - `task_completions`
   - `tasks`
   - `focus_sessions`
   - `focus_presets`
   - `focus_preset_settings`
   - `user_settings`
   - `user_stats`
3. Deletes the user's Supabase Auth account

## Prerequisites

1. [Supabase CLI](https://supabase.com/docs/guides/cli) installed
2. Logged in to Supabase CLI: `supabase login`
3. Project linked: `supabase link --project-ref your-project-ref`

## Deployment

### 1. Set the Service Role Key Secret

The function needs the service role key to delete auth users. Get it from your Supabase dashboard under Project Settings > API.

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 2. Deploy the Function

```bash
cd /path/to/FocusFlow
supabase functions deploy delete-user
```

### 3. Verify Deployment

Check that the function is deployed:

```bash
supabase functions list
```

## Testing

You can test the function with curl (replace with your values):

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/delete-user' \
  -H 'Authorization: Bearer YOUR_USER_JWT_TOKEN' \
  -H 'Content-Type: application/json'
```

## Security

- The function only accepts requests with a valid JWT
- Users can only delete their own account
- The service role key is stored as a secret (never in code)
- All operations are logged for debugging

## Response

**Success (200):**
```json
{
  "success": true,
  "message": "Account and all data deleted successfully"
}
```

**Error (401):**
```json
{
  "error": "Missing authorization header"
}
```

**Error (500):**
```json
{
  "error": "Failed to delete auth account",
  "details": "Error message",
  "dataDeleted": true
}
```

Note: If `dataDeleted` is `true`, the user's data was deleted but the auth account deletion failed. The app handles this gracefully by still signing the user out.

