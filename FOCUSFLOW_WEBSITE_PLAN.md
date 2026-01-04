# FocusFlow Website Redesign Plan

## Overview
Redesigning website from company-first to product-first, merging `/focusflow` content into homepage, and preparing for web app launch.

---

## Navigation Structure

**New Navigation:**
- **Home** (`/`) - FocusFlow product landing (merged from `/focusflow`)
- **About Us** (`/about`) - FocusFlow story, team, Soft Computers mention
- **Features** (`/features`) - Detailed feature breakdown (extracted from homepage)
- **Sign In** (`/signin`) - Authentication page (new)

**Removed:**
- `/focusflow` page (content merged into homepage)

---

## Page-by-Page Plan

### 1. Homepage (`/`) - Product Landing

**Structure:**
1. **Hero Section**
   - FocusFlow app icon (large, prominent)
   - "FocusFlow - Be Present" headline
   - Tagline: "The all-in-one app for focused work"
   - CTAs:
     - "Download on App Store" (primary)
     - "Sign In" (secondary, for web app)
     - "Explore Features" (tertiary)
   - Platform badges: "Available on iOS • Web Coming Soon"

2. **Features Section** (from current `/focusflow` page)
   - Tabbed interface: Timer, Tasks, Progress, Profile
   - Phone mockups with screenshots
   - Feature highlights for each category

3. **Pricing Section** (from current `/focusflow` page)
   - Free vs Pro comparison
   - Currency selector
   - App Store CTA

4. **Web App Preview Section** (NEW)
   - "Use FocusFlow anywhere"
   - Brief description: "Sign in to access FocusFlow on the web. Same account, same data, syncs across all your devices."
   - "Sign In" CTA button
   - Visual: Browser mockup or screenshot placeholder

5. **Testimonials / Social Proof**
   - App Store reviews
   - User quotes

6. **Final CTA**
   - "Ready to build better focus habits?"
   - Download + Sign In buttons

**Content Source:** Merge current `/focusflow/page.tsx` content into homepage

---

### 2. About Us (`/about`) - FocusFlow Story

**Structure:**

1. **Hero Section**
   - "About FocusFlow" headline
   - Subheadline: "Why we built this app"

2. **The Story Section**
   - Why FocusFlow was created
   - The problem it solves
   - Personal, touchy narrative
   - Mission: "Help people do meaningful work, calmly and consistently"

3. **The Team Section**
   - Who built FocusFlow
   - Team members (if applicable)
   - Values and approach

4. **About Soft Computers Section**
   - Brief mention: "FocusFlow is built by Soft Computers"
   - What Soft Computers is
   - Link to company site (if separate) or keep minimal
   - "We're a small team dedicated to building premium software"

5. **What's Next**
   - Future plans
   - Web app, macOS app
   - Community involvement

**Tone:** Personal, authentic, touchy but effective

---

### 3. Features (`/features`) - Detailed Breakdown

**Structure:**

1. **Hero**
   - "Everything you need to focus"

2. **Feature Categories** (from current `/focusflow` page)
   - Focus Timer
   - Tasks
   - Progress Tracking
   - Personalization

3. **Platform Availability**
   - iOS (available now)
   - Web (coming soon / available)
   - macOS (coming soon)
   - Sync across all platforms

4. **Feature Comparison**
   - Free vs Pro features
   - Visual comparison table

**Content Source:** Extract detailed features from current `/focusflow` page

---

### 4. Sign In (`/signin`) - Authentication

**Structure:**

1. **Hero Section**
   - "Sign in to FocusFlow"
   - "Access your account on any device"

2. **Auth Options**
   - Email/Password
   - Google Sign In
   - Apple Sign In
   - "Don't have an account? Sign up"

3. **After Sign In**
   - If web app ready: Redirect to `/app`
   - If not ready: Show "Web app coming soon" with link to iOS app

**Implementation:**
- Use Supabase Auth
- Handle OAuth callbacks
- Store session
- Redirect to `/app` when ready

---

## Web Version Showcase Strategy

### Option 1: Homepage Section (Recommended)
**Add "Web App" section on homepage:**
- Position: After pricing, before testimonials
- Content: "Use FocusFlow on any device"
- Visual: Browser mockup or screenshot
- CTA: "Sign In to Use Web App"
- Benefits: "Same account, syncs across devices"

### Option 2: Features Page Mention
- Add "Platforms" section
- Show iOS, Web, macOS (with status badges)
- Explain cross-platform sync

### Option 3: Separate "Web App" Page (Future)
- Only if web app is fully ready
- Dedicated page with screenshots, features
- Sign in CTA

**Recommendation:** Use Option 1 (Homepage section) + Option 2 (Features page mention)

---

## Implementation Steps

### Step 1: Update Navigation & Header
1. Update `Header.tsx`:
   - Change logo: "Soft Computers" → "FocusFlow" (or keep both)
   - Navigation: Home, About, Features, Sign In
   - Remove `/focusflow` link
   - Add "Sign In" button in header

### Step 2: Redesign Homepage
1. Merge `/focusflow` content into `app/page.tsx`
2. Transform hero from company → product
3. Add web app preview section
4. Update CTAs

### Step 3: Redesign About Page
1. Rewrite `app/about/page.tsx`
2. Focus on FocusFlow story
3. Add team section
4. Add Soft Computers mention (small section)

### Step 4: Create Features Page
1. Create `app/features/page.tsx`
2. Extract detailed features from current `/focusflow`
3. Add platform availability section

### Step 5: Create Sign In Page
1. Create `app/signin/page.tsx`
2. Set up Supabase Auth UI
3. Handle redirects

### Step 6: Update Domain References
1. Update all `softcomputers.ca` → `focusflowbepresent.com`
2. Update all emails → `info@focusflowbepresent.com`
3. Update constants, metadata, sitemap

### Step 7: Update Footer
1. Change branding: "FocusFlow" or "Made by Soft Computers"
2. Update email links
3. Update navigation links

---

## File Changes Summary

### Files to Create:
- `app/features/page.tsx` (new)
- `app/signin/page.tsx` (new)
- `app/app/page.tsx` (future web app)

### Files to Modify:
- `app/page.tsx` - Complete redesign (merge `/focusflow` content)
- `app/about/page.tsx` - Rewrite for FocusFlow story
- `components/layout/Header.tsx` - Update navigation
- `components/layout/Footer.tsx` - Update branding/links
- `lib/constants.ts` - Update domain, email, site name
- `app/layout.tsx` - Update metadata
- All pages with email references

### Files to Remove:
- `app/focusflow/page.tsx` (content merged into homepage)

---

## Web App Integration Points

### Current State (Before Web App Ready):
- Sign In button → `/signin` page
- After sign in → "Web app coming soon" message
- Link to iOS app download

### Future State (When Web App Ready):
- Sign In button → `/signin` page
- After sign in → Redirect to `/app` (web app)
- Web app accessible at `focusflowbepresent.com/app`

### Supabase Configuration:
- Add redirect URL: `https://focusflowbepresent.com/auth/callback`
- Keep iOS redirect: `ca.softcomputers.FocusFlow://login-callback`

---

## Content Guidelines

### Homepage:
- Product-focused, not company-focused
- Lead with FocusFlow benefits
- Clear CTAs: Download, Sign In, Explore

### About Page:
- Personal story about why FocusFlow exists
- Team behind it
- Soft Computers mention (small, at end)
- Touchy but effective tone

### Features Page:
- Detailed feature breakdown
- Platform availability
- Free vs Pro comparison

### Sign In Page:
- Clear authentication options
- Link to sign up
- Redirect logic for web app

---

## Timeline Estimate

- **Step 1** (Navigation): 30 minutes
- **Step 2** (Homepage redesign): 2-3 hours
- **Step 3** (About page): 1-2 hours
- **Step 4** (Features page): 1 hour
- **Step 5** (Sign In page): 1-2 hours
- **Step 6** (Domain updates): 1 hour
- **Step 7** (Footer): 30 minutes
- **Testing**: 1 hour

**Total**: ~8-10 hours

---

## Questions to Confirm

1. **Logo in Header**: "FocusFlow" or "Soft Computers" or both?
2. **Web App Section**: Exact placement on homepage?
3. **About Page Team**: Include names/photos or keep general?
4. **Features Page**: Extract all from `/focusflow` or create new content?

---

## Next Steps

1. Review this plan
2. Confirm logo/branding in header
3. Confirm web app showcase approach
4. I'll start implementing Step 1 (Navigation) and Step 2 (Homepage)

