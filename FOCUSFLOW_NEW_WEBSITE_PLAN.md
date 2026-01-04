# FocusFlow Brand New Website Plan

## Overview
Creating a **brand new website** for FocusFlow at `focusflowbepresent.com`, completely separate from the existing Soft Computers site. The Soft Computers site (`softcomputers-site/`) will remain untouched.

---

## Project Structure

**New Directory:**
```
focusflow-site/          (NEW - FocusFlow website)
├── app/
├── components/
├── lib/
├── public/
└── package.json

softcomputers-site/      (KEEP AS-IS - Soft Computers website)
└── ... (untouched)
```

**Deployment:**
- `softcomputers.ca` → `softcomputers-site/` (existing, unchanged)
- `focusflowbepresent.com` → `focusflow-site/` (new)

---

## New Website Structure

### Pages
1. **Homepage** (`/`) - High-level overview, highlights only
2. **Features** (`/features`) - Detailed feature breakdown
3. **Pricing** (`/pricing`) - Free vs Pro comparison
4. **About** (`/about`) - FocusFlow story, team, Soft Computers mention
5. **Sign In** (`/signin`) - Authentication page
6. **Privacy** (`/privacy`) - Privacy policy
7. **Terms** (`/terms`) - Terms of service
8. **Support** (`/support`) - Help & contact

### Future Pages
- `/app` - Web application (when ready)
- `/app/auth/callback` - OAuth callback handler

---

## Implementation Approach

### Option 1: Copy & Redesign (Recommended)
**Steps:**
1. Copy `softcomputers-site/` → `focusflow-site/`
2. Remove company-focused content
3. Redesign for FocusFlow product-first
4. Update all domain/email references
5. Create new pages (Features, Sign In)

**Pros:**
- Reuse existing components, styles, structure
- Faster development
- Consistent design system

**Cons:**
- Need to clean up company references

### Option 2: Build from Scratch
**Steps:**
1. Create new Next.js project
2. Copy over reusable components
3. Build new pages from scratch

**Pros:**
- Clean slate
- No legacy code

**Cons:**
- More time-consuming
- Need to rebuild everything

**Recommendation:** Option 1 (Copy & Redesign) - faster and we can reuse the beautiful design system

---

## Detailed Page Plans

### 1. Homepage (`/`) - High-Level Overview

**Hero Section:**
- FocusFlow app icon (large, prominent)
- "FocusFlow" headline
- "Be Present" tagline
- Subheadline: "The all-in-one app for focused work"
- CTAs:
  - "Download on App Store" (primary)
  - "Sign In" (secondary)
  - "Explore Features" (tertiary)
- Platform badges: "Available on iOS • Web Coming Soon"

**What is FocusFlow Section:**
- Brief overview: "Timer, tasks, and progress tracking in one beautiful app"
- Key highlights (3-4 bullet points):
  - Focus timer with ambient backgrounds
  - Smart task management
  - Progress tracking with XP & levels
  - Beautiful themes & personalization
- Visual: Single phone mockup or app icon grid

**Core Features Preview:**
- 4 feature cards (high-level only):
  - ⏱️ Focus Timer
  - ✅ Tasks
  - 📈 Progress
  - 🎨 Personalization
- Each card: Icon, title, one-line description
- "Learn More" link to Features page

**Web App Preview Section:**
- "Use FocusFlow anywhere"
- Description: "Sign in to access FocusFlow on the web. Same account, same data, syncs across all your devices."
- "Sign In" CTA
- Browser mockup visual (placeholder)

**Testimonials:**
- 2-3 App Store reviews (brief quotes)
- 5-star rating display

**Final CTA:**
- "Ready to build better focus habits?"
- Download + Sign In + Explore Features buttons

---

### 4. About Page (`/about`)

**Hero:**
- "About FocusFlow" headline
- "Why we built this app"

**The Story:**
- Why FocusFlow was created
- The problem it solves
- Personal, touchy narrative
- Mission statement

**The Team:**
- Who built FocusFlow
- General team description (no names/photos)
- Values and approach

**About Soft Computers:**
- Brief section: "FocusFlow is built by Soft Computers"
- What Soft Computers is (small team, premium software)
- Keep it minimal and effective

**What's Next:**
- Future plans (web app, macOS)
- Community involvement

**Tone:** Personal, authentic, touchy but effective

---

### 2. Features Page (`/features`) - Detailed Breakdown

**Hero:**
- "Everything you need to focus"
- Subheadline: "Deep dive into FocusFlow's features"

**Feature Categories (Tabbed Interface):**
1. **Focus Timer**
   - Ambient backgrounds (14 total, 3 free)
   - Focus sounds (11 total, 3 free)
   - Music integration (Spotify, Apple Music, YouTube Music)
   - Live Activity support
   - Session intentions
   - Phone mockups with screenshots

2. **Tasks**
   - Recurring tasks (daily, weekly, monthly, custom)
   - Duration estimates & tracking
   - Smart reminders
   - Task limits (3 free, unlimited Pro)
   - Phone mockups with screenshots

3. **Progress Tracking**
   - XP & 50 levels system
   - Achievement badges
   - Journey view (daily summaries, weekly reviews)
   - Progress history
   - Streak tracking
   - Phone mockups with screenshots

4. **Personalization**
   - 10 beautiful themes (2 free, 8 Pro)
   - 50+ symbol avatars
   - Custom focus presets (3 free, unlimited Pro)
   - Cloud sync (Pro)
   - Interactive widgets (Pro)
   - Phone mockups with screenshots

**Platform Availability:**
- iOS (available now)
- Web (coming soon / available)
- macOS (coming soon)
- Cross-platform sync explanation

**Feature Highlights:**
- Visual feature grid
- Icons and descriptions
- Free vs Pro indicators

---

### 3. Pricing Page (`/pricing`)

**Hero:**
- "Choose your plan"
- Subheadline: "Start free, upgrade when you're ready"

**Pricing Cards:**
1. **Free Plan**
   - $0 forever
   - Feature list (limited)
   - "Current Plan" badge (if applicable)

2. **Pro Yearly** (Featured)
   - $44.99 USD / $59.99 CAD per year
   - "Best Value" badge
   - Save amount highlighted
   - Full feature list
   - "Start Free Trial" CTA

3. **Pro Monthly**
   - $3.99 USD / $5.99 CAD per month
   - Full feature list
   - "Start Free Trial" CTA

**Currency Selector:**
- Toggle between USD and CAD
- Update prices dynamically

**Feature Comparison Table:**
- Side-by-side comparison
- Free vs Pro features
- Checkmarks and indicators

**FAQ Section:**
- Common pricing questions
- Trial information
- Cancellation policy

**Final CTA:**
- "Ready to unlock Pro?"
- App Store download link

---

### 5. Sign In Page (`/signin`)

**Hero:**
- "Sign in to FocusFlow"
- "Access your account on any device"

**Auth Options:**
- Email/Password form
- Google Sign In button
- Apple Sign In button
- "Don't have an account? Sign up" link

**After Sign In Logic:**
- If web app ready: Redirect to `/app`
- If not ready: Show "Web app coming soon" with link to iOS app

**Implementation:**
- Supabase Auth JS client
- Handle OAuth callbacks
- Store session in cookies/localStorage
- Redirect logic

---

## Component Structure

### Reusable Components (Copy from softcomputers-site):
- `Container` - Layout wrapper
- `PhoneSimulator` - Phone mockup component
- `ThemeToggle` - Dark/light mode
- Card components (glass, glow effects)
- Button components

### New Components Needed:
- `AuthForm` - Sign in/sign up form
- `FeatureCard` - Feature showcase cards
- `PlatformBadge` - Platform availability badges
- `PricingCard` - Pricing comparison cards

---

## Design System

**Colors:** (Reuse from softcomputers-site)
- Accent primary: Violet/Purple
- Accent secondary: Amber/Orange
- Background: Dark theme
- Glass morphism effects

**Typography:**
- Headings: Sora font (premium, geometric)
- Body: Inter font (clean, readable)

**Branding:**
- Logo: FocusFlow app icon
- Header: "FocusFlow" text logo
- Footer: "Made by Soft Computers" (subtle)

---

## Domain & Configuration

### Constants (`lib/constants.ts`):
```typescript
export const SITE_URL = 'https://focusflowbepresent.com';
export const SITE_NAME = 'FocusFlow';
export const CONTACT_EMAIL = 'info@focusflowbepresent.com';
export const APP_STORE_URL = 'https://apps.apple.com/app/focusflow-be-present/id6739000000';
```

### Metadata (`app/layout.tsx`):
- Title: "FocusFlow - Be Present"
- Description: "The all-in-one focus timer, task manager, and progress tracker"
- Domain: `focusflowbepresent.com`

### Supabase Configuration:
- Add redirect URL: `https://focusflowbepresent.com/auth/callback`
- Keep iOS redirect: `ca.softcomputers.FocusFlow://login-callback`

---

## Implementation Steps

### Phase 1: Setup (1 hour)
1. Create `focusflow-site/` directory
2. Copy base structure from `softcomputers-site/`
3. Update `package.json` (name, scripts)
4. Install dependencies
5. Set up Next.js config

### Phase 2: Core Pages (5-6 hours)
1. **Homepage** (`app/page.tsx`)
   - Hero section (high-level overview)
   - What is FocusFlow section (brief highlights)
   - Core features preview (4 cards, high-level)
   - Web app preview section
   - Testimonials
   - Final CTA

2. **Features Page** (`app/features/page.tsx`)
   - Tabbed interface (Timer, Tasks, Progress, Personalization)
   - Detailed feature breakdowns
   - Phone mockups for each feature
   - Platform availability section

3. **Pricing Page** (`app/pricing/page.tsx`)
   - Pricing cards (Free, Pro Yearly, Pro Monthly)
   - Currency selector
   - Feature comparison table
   - FAQ section

4. **About Page** (`app/about/page.tsx`)
   - Write FocusFlow story
   - Add team section
   - Add Soft Computers mention

5. **Sign In Page** (`app/signin/page.tsx`)
   - Create auth form
   - Set up Supabase Auth
   - Handle redirects

### Phase 3: Components & Layout (2 hours)
1. Update `Header.tsx`
   - Change logo to "FocusFlow"
   - Navigation: Home, About, Features, Sign In
   - Add Sign In button

2. Update `Footer.tsx`
   - FocusFlow branding
   - "Made by Soft Computers" mention
   - Update email links

3. Create new components
   - AuthForm
   - PlatformBadge
   - FeatureCard

### Phase 4: Configuration (1 hour)
1. Update `lib/constants.ts`
2. Update `app/layout.tsx` metadata
3. Update domain references
4. Update sitemap.xml, robots.txt
5. Update manifest.json

### Phase 5: Assets & Content (1 hour)
1. Copy app icons/images
2. Update screenshots
3. Write About page content
4. Update all email references

### Phase 6: Testing & Polish (1 hour)
1. Test all pages
2. Test navigation
3. Test responsive design
4. Test Sign In flow
5. Fix any issues

**Total Estimated Time: ~11-13 hours**

---

## File Structure

```
focusflow-site/
├── app/
│   ├── layout.tsx              (Metadata, fonts)
│   ├── page.tsx                 (Homepage - high-level overview)
│   ├── features/
│   │   └── page.tsx             (Detailed feature breakdown)
│   ├── pricing/
│   │   └── page.tsx             (Pricing plans & comparison)
│   ├── about/
│   │   └── page.tsx             (FocusFlow story, team)
│   ├── signin/
│   │   └── page.tsx             (Authentication)
│   ├── privacy/
│   │   └── page.tsx             (Privacy policy)
│   ├── terms/
│   │   └── page.tsx             (Terms of service)
│   ├── support/
│   │   └── page.tsx             (Help & contact)
│   └── globals.css              (Styles)
├── components/
│   ├── layout/
│   │   ├── Header.tsx           (FocusFlow logo, nav)
│   │   └── Footer.tsx           (FocusFlow branding)
│   ├── common/
│   │   ├── Container.tsx        (Reuse)
│   │   ├── ThemeToggle.tsx      (Reuse)
│   │   └── PhoneSimulator.tsx   (Reuse)
│   ├── features/
│   │   ├── FeatureCard.tsx      (New)
│   │   └── PlatformBadge.tsx   (New)
│   └── auth/
│       └── AuthForm.tsx         (New)
├── lib/
│   ├── constants.ts             (FocusFlow config)
│   └── supabase.ts              (Supabase client)
├── public/
│   ├── focusflow_app_icon.jpg   (App icon)
│   ├── images/                  (Screenshots)
│   └── ...                      (Other assets)
├── package.json
├── next.config.ts
└── tsconfig.json
```

---

## Content to Write

### Homepage:
- Hero copy (high-level)
- What is FocusFlow overview
- Core features preview (brief)
- Web app preview copy
- Testimonials

### Features Page:
- Detailed feature descriptions for each category
- Platform availability explanation
- Feature highlights

### Pricing Page:
- Pricing plan descriptions
- Feature comparison content
- FAQ content

### About Page:
- FocusFlow story (why it was created)
- Team description
- Soft Computers mention
- Future plans

---

## Supabase Setup

### Required Changes:
1. **Dashboard → Authentication → URL Configuration**
   - Add: `https://focusflowbepresent.com/auth/callback`
   - Keep: `ca.softcomputers.FocusFlow://login-callback`

2. **Site URL:**
   - Set to: `https://focusflowbepresent.com`

### Code Setup:
- Install `@supabase/supabase-js`
- Create `lib/supabase.ts` client
- Set up auth helpers
- Handle OAuth callbacks

---

## Deployment

### Environment Variables:
```env
NEXT_PUBLIC_SITE_URL=https://focusflowbepresent.com
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key
```

### Deployment Options:
- Vercel (recommended for Next.js)
- AWS Amplify
- Netlify

### DNS:
- Point `focusflowbepresent.com` to hosting
- Set up SSL certificate

---

## Next Steps

1. ✅ Review this plan
2. ✅ Confirm approach (Copy & Redesign)
3. 🚀 Start Phase 1: Create `focusflow-site/` directory
4. 🚀 Copy base structure
5. 🚀 Begin homepage redesign

---

## Questions Resolved

✅ **Logo in Header:** FocusFlow only
✅ **About Page Team:** Keep general (no names/photos)
✅ **Web App Section:** After pricing on homepage
✅ **Soft Computers Site:** Keep untouched
✅ **New Website:** Create `focusflow-site/` directory

---

Ready to start! 🚀

