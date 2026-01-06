# FocusFlow AI Backend - Production Deployment Guide

## Overview

Your app now has a **production-ready AI system** with the API key stored securely on the backend instead of in the app binary.

**Architecture:**
```
iOS App → Supabase Edge Function (ai-chat) → OpenAI API
```

- ✅ API key never exposed in app
- ✅ Secure authentication via Supabase
- ✅ Serverless backend (free tier available)
- ✅ App Store compliant

---

## Files Created/Modified

### 1. **Supabase Edge Function** (NEW)
**Location:** `supabase/functions/ai-chat/index.ts`

This is your backend handler that:
- Receives encrypted requests from the app
- Calls OpenAI API securely (key stored on server)
- Returns responses to the app
- Handles function calling

### 2. **AIService.swift** (MODIFIED)
**Changes:**
- Now calls `/supabase/functions/v1/ai-chat` instead of OpenAI directly
- Uses Supabase auth token instead of API key
- Simpler response parsing (backend handles complexity)

### 3. **SupabaseManager.swift** (MODIFIED)
**Added:**
- `currentUserToken()` method to get auth token for API calls

---

## Deployment Steps

### Step 1: Set OpenAI API Key in Supabase

1. Go to Supabase Dashboard: https://app.supabase.com
2. Select your FocusFlow project
3. **Settings → Secrets** (or Project Settings → API Secrets)
4. Click **New Secret**
5. Add:
   - **Name:** `OPENAI_API_KEY`
   - **Value:** `sk-proj-...` (your OpenAI key)
6. Save

### Step 2: Deploy the Edge Function

In terminal, run:
```bash
cd /Users/rajannagar/Rajan\ Nagar/FocusFlow
supabase functions deploy ai-chat
```

If you don't have Supabase CLI installed:
```bash
brew install supabase/tap/supabase
```

Verify deployment:
```bash
supabase functions list
```

You should see `ai-chat` as deployed.

### Step 3: Update iOS App

No code changes needed! The app already calls the new backend endpoint.

Just rebuild and test:
1. Close Xcode completely
2. Reopen the project
3. Build and run (Cmd+R)

### Step 4: Test

1. Go to AI Chat in the app
2. Send a test message
3. Should work without API key setup screen

---

## Supabase Function Details

**Endpoint:** `https://grcelvuzlayxrrokojpg.supabase.co/functions/v1/ai-chat`

**Request:**
```json
{
  "userMessage": "Create a task to study for exam",
  "conversationHistory": [
    { "sender": "user", "text": "..." },
    { "sender": "assistant", "text": "..." }
  ],
  "context": "You are a helpful AI..."
}
```

**Response:**
```json
{
  "response": "I've created a task to study for exam",
  "action": {
    "type": "create_task",
    "params": { "title": "Study for exam" }
  }
}
```

---

## Security Checklist

- ✅ API key stored only in Supabase (server-side)
- ✅ App authenticates with Supabase JWT token
- ✅ Function validates auth header
- ✅ CORS configured for cross-origin requests
- ✅ No API key in app binary or version control
- ✅ Function can be deployed privately if needed

---

## Troubleshooting

### "Unauthorized" error
**Solution:** User not logged in. Check auth flow.

### Function not found (404)
**Solution:** Run `supabase functions deploy ai-chat` again

### "Invalid API key" (from OpenAI)
**Solution:** Check Supabase secret is set correctly

### CORS errors
**Solution:** Already handled in function, but if issues persist, check Supabase function CORS settings

---

## Going to App Store

Your app is now **ready for App Store submission**:
- ✅ No hardcoded API keys
- ✅ Backend handles secrets
- ✅ App-side auth verification
- ✅ Scalable architecture
- ✅ Usage tracking possible (Supabase logs)

**App Store Review Notes:**
> "AI features powered by OpenAI API through secure backend service."

---

## Cost Considerations

**Supabase (Free Tier):**
- 50,000 monthly function invocations
- Sufficient for small-medium apps

**OpenAI API:**
- Pay per token used
- gpt-4o-mini is ~$0.00015 per 1K input tokens
- Example: 1,000 daily users = ~$4-5/month

---

## Future Enhancements

1. **Usage Analytics:** Log AI calls to Supabase for analytics
2. **Rate Limiting:** Limit calls per user per day
3. **Caching:** Cache common responses
4. **Custom Models:** Switch between GPT models based on tier
5. **Pro Feature:** Gate AI behind subscription

---

## Support

If deployment fails:
1. Check Supabase CLI is installed (`supabase --version`)
2. Verify secret is set: `supabase secrets list`
3. Check function syntax: `supabase functions list`
4. View logs: `supabase functions logs ai-chat`

