# FocusFlow Domain Migration & Web App Plan

## Overview
Migrating from `softcomputers.ca` (company site) to `focusflowbepresent.com` (product-first site) with support for future web app where users can sign in directly on the website.

---

## Phase 1: Website Redesign & Domain Migration

### 1.1 Website Structure Changes
**Current:** Company site showcasing FocusFlow as a product
**New:** Product-first site with minimal company branding

**New Structure:**
- **Homepage (`/`)**: FocusFlow hero, features, benefits (product-focused)
- **Features (`/features`)**: Detailed feature showcase (merge current `/focusflow` content)
- **Pricing (`/pricing`)**: Pro subscription details
- **About (`/about`)**: Brief company story, but FocusFlow-focused
- **Support (`/support`)**: Help & contact
- **Privacy/Terms**: Legal pages
- **Web App (`/app`)**: Future web application entry point

**Company Branding:**
- Footer: "Made by Soft Computers" (subtle)
- About page: Small section with company story, but FocusFlow-focused
- Email: `info@focusflowbepresent.com`

### 1.2 Domain References to Update
**Files to update (32+ occurrences):**
- `lib/constants.ts` - Site URL, email, company name
- `app/layout.tsx` - Metadata, structured data
- `app/page.tsx` - Homepage content
- `app/about/page.tsx` - Company references
- `app/privacy/page.tsx` - Email references
- `app/terms/page.tsx` - Email references
- `app/support/page.tsx` - Email references
- `components/layout/Footer.tsx` - Email links
- `public/sitemap.xml` - Domain URLs
- `public/robots.txt` - Sitemap URL
- `public/manifest.json` - Site name
- `package.json` - Package name (optional)

**New Domain:**
- `https://focusflowbepresent.com` (or `www.focusflowbepresent.com`)

---

## Phase 2: OAuth & Authentication Setup

### 2.1 Multi-Platform OAuth Strategy

**Current Setup:**
- iOS: `ca.softcomputers.FocusFlow://login-callback` (custom URL scheme)
- Supabase configured for this redirect

**New Multi-Platform Setup:**

#### iOS (Keep Current)
- **Bundle ID**: `ca.softcomputers.FocusFlow` (keep as-is)
- **Redirect URL**: `ca.softcomputers.FocusFlow://login-callback`
- **No changes needed** - works perfectly

#### macOS (Future)
- **Bundle ID**: `ca.softcomputers.FocusFlow` (can reuse)
- **Redirect URL**: `ca.softcomputers.FocusFlow://login-callback` (same as iOS)
- **OR**: Use web redirect: `https://focusflowbepresent.com/auth/callback`

#### Web App (New)
- **Domain**: `focusflowbepresent.com`
- **Redirect URL**: `https://focusflowbepresent.com/auth/callback`
- **Sign-in flow**: Users sign in directly on website, redirect back to `/app`

### 2.2 Supabase Configuration

**Required Supabase Dashboard Changes:**
1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Add new redirect URL: `https://focusflowbepresent.com/auth/callback`
3. Keep existing: `ca.softcomputers.FocusFlow://login-callback` (for iOS/macOS)
4. Set site URL: `https://focusflowbepresent.com`

**Redirect URLs to Configure:**
```
ca.softcomputers.FocusFlow://login-callback          (iOS/macOS)
https://focusflowbepresent.com/auth/callback         (Web)
```

### 2.3 Web App Authentication Flow

**User Journey:**
1. User visits `focusflowbepresent.com`
2. Clicks "Sign In" or "Use Web App"
3. Redirected to Supabase Auth (email/password, Google, Apple, etc.)
4. After auth, redirected to `https://focusflowbepresent.com/auth/callback`
5. Callback page extracts session token, stores it
6. Redirects to `/app` (web application)

**Implementation:**
- Create `/app/auth/callback/page.tsx` - Handles OAuth callback
- Create `/app/page.tsx` - Main web app interface
- Use Supabase JS client for web (different from Swift SDK)

---

## Phase 3: Bundle ID Strategy

### 3.1 Keep Current Bundle IDs
**Decision:** Keep `ca.softcomputers.FocusFlow` for iOS/macOS

**Why:**
- Avoids App Store disruption
- Bundle IDs don't need to match domain
- OAuth redirects work independently
- Users won't notice the difference

**Files with Bundle ID (no changes needed):**
- `project.pbxproj` - Bundle identifiers
- `Info.plist` - URL scheme
- `SupabaseManager.swift` - Redirect scheme
- `FocusFlow.entitlements` - App group

**Note:** Bundle ID can stay as `ca.softcomputers.FocusFlow` even though domain is `focusflowbepresent.com`. They're independent.

---

## Phase 4: Implementation Steps

### Step 1: Update Website Domain References
1. Update `lib/constants.ts`:
   - `SITE_URL`: `https://focusflowbepresent.com`
   - `CONTACT_EMAIL`: `info@focusflowbepresent.com` (or keep softcomputers.ca)
   - `SITE_NAME`: `FocusFlow` (or `FocusFlow - Be Present`)

2. Update all page files with domain/email references
3. Update sitemap.xml and robots.txt
4. Update manifest.json

### Step 2: Redesign Homepage
1. Transform homepage from company showcase to product landing
2. Use content from `/focusflow` page as base
3. Add "Sign In" / "Use Web App" CTA (for future)
4. Keep company mention minimal (footer only)

### Step 3: Configure Supabase
1. Add web redirect URL in Supabase dashboard
2. Test OAuth flow with new domain
3. Verify iOS redirect still works

### Step 4: Prepare Web App Structure (Future)
1. Create `/app` directory structure
2. Set up Supabase JS client
3. Create auth callback handler
4. Build web app UI (when ready)

### Step 5: DNS & Deployment
1. Point `focusflowbepresent.com` to hosting (Vercel/Amplify)
2. Update environment variables
3. Deploy and test
4. No redirect needed (company site separate)

---

## Phase 5: Future Web App Architecture

### 5.1 Web App Structure
```
/app
  /auth
    /callback          # OAuth callback handler
    /signin            # Sign in page
    /signup            # Sign up page
  /dashboard           # Main app interface
  /timer               # Focus timer
  /tasks               # Task management
  /progress            # Progress tracking
  /settings            # Settings
```

### 5.2 Technology Stack
- **Frontend**: Next.js (already using)
- **Auth**: Supabase Auth (JS client)
- **Database**: Supabase (same as iOS)
- **State**: React Context / Zustand
- **Styling**: Tailwind CSS (already using)

### 5.3 Data Sync
- Same Supabase database as iOS
- Users sign in with same account
- Data syncs automatically across platforms
- Real-time updates via Supabase Realtime

---

## Summary of Changes

### ✅ What Changes:
1. **Website domain**: `softcomputers.ca` → `focusflowbepresent.com`
2. **Website content**: Company-first → Product-first
3. **Email addresses**: Update to new domain (or keep softcomputers.ca)
4. **Supabase redirects**: Add web redirect URL
5. **Website structure**: Redesign for product focus

### ❌ What Stays the Same:
1. **Bundle IDs**: Keep `ca.softcomputers.FocusFlow`
2. **iOS OAuth**: Keep current redirect scheme
3. **Supabase database**: No changes
4. **App Store listing**: No changes
5. **Existing users**: No impact

---

## Timeline Estimate

- **Phase 1** (Website Redesign): 2-3 hours
- **Phase 2** (OAuth Setup): 1 hour (Supabase config)
- **Phase 3** (Domain Migration): 30 minutes (DNS + deploy)
- **Phase 4** (Testing): 1 hour
- **Total**: ~5-6 hours

---

## Confirmed Decisions ✅

1. **Email**: `info@focusflowbepresent.com` ✅
2. **Company Branding**: Small "About" section (not just footer) ✅
3. **Old Domain**: No redirect needed (company site will be redesigned separately) ✅
4. **Web App Timeline**: Future (structure prepared now)

---

## Next Steps

1. Review this plan
2. Confirm email strategy
3. Confirm company branding level
4. I'll start implementing Phase 1 (Website Redesign)

