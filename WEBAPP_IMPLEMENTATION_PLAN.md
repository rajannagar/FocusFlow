# FocusFlow Web App Implementation Plan

## Overview

Create a completely separate web application at `webapp.focusflowbepresent.com` that is independent from the main marketing site at `focusflowbepresent.com`.

---

## Architecture - Option 3: Separate Deployments

### Current Structure
- **Main Site**: `focusflow-site/` → `focusflowbepresent.com` (marketing site)
  - **AWS Amplify App**: `focusflow-website` (existing)
  - **Deployment**: Independent
  
- **Web App**: `focusflow-webapp/` → `webapp.focusflowbepresent.com` (application) ← **NEW**
  - **AWS Amplify App**: `focusflow-webapp` (new)
  - **Deployment**: Independent
  - **Subdomain**: Free (no additional cost)

### Separation of Concerns
- **Main Site**: Marketing, features, pricing, about pages
  - **No authentication pages** - just a "Sign In" button that links to webapp
- **Web App**: Authentication, dashboard, app functionality, user data
  - **All sign in/sign up pages** live here
  - **All app functionality** lives here

### Benefits of Option 3
- ✅ Complete independence (deploy separately)
- ✅ Clean separation (different subdomain)
- ✅ Professional appearance
- ✅ No domain cost (subdomain is free)
- ✅ Free SSL from Amplify
- ✅ Easy to scale independently

---

## Implementation Steps

### Phase 1: Create New Web App Project

1. **Initialize Next.js App**
   ```bash
   cd /Users/rajannagar/Rajan\ Nagar/FocusFlow
   npx create-next-app@latest focusflow-webapp --typescript --tailwind --app --no-src-dir
   ```

2. **Install Dependencies**
   - `@supabase/supabase-js`
   - `@supabase/ssr`
   - `lucide-react` (for icons)
   - Any other required packages

3. **Set Up Project Structure**
   ```
   focusflow-webapp/
   ├── app/
   │   ├── layout.tsx          # Root layout with AuthProvider
   │   ├── page.tsx            # Dashboard/Home (protected)
   │   ├── signin/
   │   │   └── page.tsx        # Sign in page
   │   ├── signup/
   │   │   └── page.tsx        # Sign up page (optional)
   │   └── (protected)/       # Protected routes
   │       ├── dashboard/
   │       ├── tasks/
   │       ├── focus/
   │       └── progress/
   ├── components/
   │   ├── auth/
   │   ├── dashboard/
   │   └── layout/
   ├── contexts/
   │   └── AuthContext.tsx
   ├── lib/
   │   ├── supabase/
   │   │   ├── client.ts
   │   │   └── server.ts
   │   └── constants.ts
   ├── .env.local              # Supabase credentials
   └── package.json
   ```

### Phase 2: Authentication Setup

1. **Copy Supabase Configuration**
   - Use same Supabase project as iOS app
   - URL: `https://grcelvuzlayxrrokojpg.supabase.co`
   - Anon Key: (from Info.plist)

2. **Create Auth Context**
   - Similar to what we started in main site
   - Sign up, sign in, sign out, password reset
   - OAuth (Apple, Google) support

3. **Create Sign In/Sign Up Pages**
   - Clean, focused design
   - Match FocusFlow branding
   - Error handling

4. **Protected Routes**
   - Middleware or HOC to protect routes
   - Redirect to signin if not authenticated

### Phase 3: Basic Dashboard

1. **Create Dashboard Layout**
   - Header with user info and sign out
   - Navigation sidebar (optional)
   - Main content area

2. **Dashboard Home Page**
   - Welcome message
   - Quick stats (if available)
   - "Coming Soon" sections for:
     - Focus Timer
     - Tasks
     - Progress
   - Link to download iOS app

3. **User Profile**
   - Display user email
   - Account settings
   - Sign out button

### Phase 4: Update Main Site

1. **Update Header Component**
   - Change Sign In button to link to `https://webapp.focusflowbepresent.com`
   - Open in new tab: `target="_blank" rel="noopener noreferrer"`
   - File: `focusflow-site/components/layout/Header.tsx`

2. **Remove Sign In Page from Marketing Site**
   - Remove `/signin` route entirely from `focusflow-site/`
   - Or keep as simple redirect page that immediately redirects to webapp
   - **Key Point**: Marketing site has NO authentication - it's all on webapp subdomain

### Phase 5: Deployment Setup

1. **Create Amplify Config**
   - New file: `amplify-webapp.yml` at repository root
   - Similar structure to main site's `amplify.yml`
   - Point to `focusflow-webapp/` directory
   - Use `appRoot: focusflow-webapp`

2. **AWS Amplify Setup (New App)**
   - Go to AWS Amplify Console
   - Click "New app" → "Host web app"
   - Connect to GitHub repository: `rajannagar/FocusFlow`
   - Select branch: `main`
   - App name: `focusflow-webapp`
   - Build settings: Use `amplify-webapp.yml` (auto-detected or manual)
   - Configure environment variables in Amplify Console:
     - `NEXT_PUBLIC_SUPABASE_URL` = `https://grcelvuzlayxrrokojpg.supabase.co`
     - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = `[from Info.plist]`
   - Deploy and wait for build to complete

3. **DNS Configuration (GoDaddy)**
   - After Amplify deployment, go to Domain management
   - Add custom domain: `webapp.focusflowbepresent.com`
   - Amplify will provide DNS records
   - Add CNAME record in GoDaddy:
     - Name: `webapp`
     - Value: `[CloudFront URL from Amplify]` (e.g., `dxxxxx.cloudfront.net`)
   - Wait for DNS propagation (5-15 minutes)
   - SSL certificate will be automatically provisioned by Amplify

### Phase 6: Styling & Branding

1. **Match FocusFlow Design**
   - Use same color scheme
   - Same fonts (Sora, Inter)
   - Same design tokens
   - Copy `globals.css` theme variables

2. **Responsive Design**
   - Mobile-friendly
   - Tablet optimized
   - Desktop experience

---

## Technical Details

### Environment Variables

**`.env.local`** (in `focusflow-webapp/`):
```env
NEXT_PUBLIC_SUPABASE_URL=https://grcelvuzlayxrrokojpg.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyY2VsdnV6bGF5eHJyb2tvanBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3OTI4NzAsImV4cCI6MjA4MjM2ODg3MH0.Ibjy2icZOIEZFq9mIe7y8C7twbq4fSXpMTh1JPqMHdw
```

### Amplify Configuration

**`amplify-webapp.yml`** (at repository root):
```yaml
version: 1
applications:
  -
    appRoot: focusflow-webapp
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: out
        files:
          - '**/*'
      cache:
        paths:
          - 'node_modules/**/*'
```

### Next.js Configuration

**`next.config.ts`** (in `focusflow-webapp/`):
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export', // Static export for Amplify
  images: {
    unoptimized: true, // Required for static export
  },
};

export default nextConfig;
```

---

## File Structure (Detailed)

```
FocusFlow/
├── focusflow-site/                    # Main marketing site
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── features/
│   │   ├── pricing/
│   │   ├── about/
│   │   └── signin/                   # Update to redirect/link
│   ├── components/
│   │   └── layout/
│   │       └── Header.tsx             # Update Sign In button
│   └── ...
│
├── focusflow-webapp/                  # NEW: Web application
│   ├── app/
│   │   ├── layout.tsx                 # Root layout with AuthProvider
│   │   ├── page.tsx                   # Dashboard (protected)
│   │   ├── signin/
│   │   │   └── page.tsx               # Sign in page
│   │   ├── signup/
│   │   │   └── page.tsx               # Sign up page (optional)
│   │   └── (protected)/               # Protected route group
│   │       ├── dashboard/
│   │       │   └── page.tsx            # Main dashboard
│   │       ├── profile/
│   │       │   └── page.tsx           # User profile
│   │       └── ...
│   ├── components/
│   │   ├── auth/
│   │   │   ├── SignInForm.tsx
│   │   │   └── SignUpForm.tsx
│   │   ├── dashboard/
│   │   │   ├── DashboardHeader.tsx
│   │   │   ├── StatsCard.tsx
│   │   │   └── QuickActions.tsx
│   │   └── layout/
│   │       ├── AppHeader.tsx          # Web app header
│   │       └── AppSidebar.tsx         # Optional sidebar
│   ├── contexts/
│   │   └── AuthContext.tsx           # Authentication context
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts              # Browser client
│   │   │   └── server.ts              # Server client (if needed)
│   │   ├── constants.ts               # App constants
│   │   └── utils.ts                   # Utility functions
│   ├── middleware.ts                  # Route protection
│   ├── .env.local                     # Environment variables
│   ├── next.config.ts                 # Next.js config
│   ├── package.json
│   └── ...
│
├── amplify.yml                        # Main site deployment
├── amplify-webapp.yml                 # NEW: Web app deployment
└── ...
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] Create `focusflow-webapp/` directory
- [ ] Initialize Next.js app
- [ ] Set up authentication
- [ ] Create dashboard
- [ ] Test locally
- [ ] Update main site header

### AWS Amplify Setup (New App)
- [ ] Go to AWS Amplify Console
- [ ] Create new Amplify app: `focusflow-webapp`
- [ ] Connect to GitHub repository: `rajannagar/FocusFlow`
- [ ] Select branch: `main`
- [ ] Configure build settings (use `amplify-webapp.yml`)
- [ ] Add environment variables in Amplify Console:
  - [ ] `NEXT_PUBLIC_SUPABASE_URL`
  - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] Deploy and test build
- [ ] Verify build succeeds

### DNS Configuration
- [ ] In Amplify Console → Domain management
- [ ] Add custom domain: `webapp.focusflowbepresent.com`
- [ ] Get CloudFront URL from Amplify
- [ ] Go to GoDaddy DNS management
- [ ] Add CNAME record:
  - [ ] Name: `webapp`
  - [ ] Value: `[CloudFront URL from Amplify]`
  - [ ] TTL: 1 Hour
- [ ] Wait for DNS propagation (5-15 minutes)
- [ ] Wait for SSL certificate provisioning
- [ ] Test `https://webapp.focusflowbepresent.com`

### Post-Deployment
- [ ] Test authentication flow
- [ ] Test protected routes
- [ ] Verify redirects work
- [ ] Test on mobile devices
- [ ] Update main site Sign In button

---

## Key Decisions

1. **Static Export**: Use `output: 'export'` for static hosting (simpler, faster)
2. **Authentication**: Same Supabase project as iOS app (shared user database)
3. **Styling**: Match main site design system
4. **Routing**: Use Next.js App Router
5. **Protected Routes**: Use middleware or route groups
6. **Sign In Flow**: 
   - Marketing site button → redirects to `webapp.focusflowbepresent.com`
   - All sign in/sign up pages are on webapp subdomain
   - Marketing site has NO authentication functionality

---

## Future Enhancements (Post-MVP)

1. **Full App Features**
   - Focus Timer interface
   - Task management
   - Progress tracking
   - Sync with iOS app

2. **Additional Features**
   - Settings page
   - Profile customization
   - Subscription management
   - Data export

3. **Performance**
   - Optimize bundle size
   - Add caching strategies
   - Implement service worker (PWA)

---

## Notes

- The web app will share the same Supabase database as the iOS app
- Users can sign in with the same credentials across platforms
- The main site remains purely marketing-focused
- Each deployment is independent and can be updated separately

---

## User Flow

### Marketing Site → Web App
1. User visits `focusflowbepresent.com` (marketing site)
2. User clicks "Sign In" button in header
3. Opens `webapp.focusflowbepresent.com` in new tab
4. User sees sign in page on webapp
5. After sign in, user is on webapp dashboard

### Web App Routes
- `webapp.focusflowbepresent.com/` → Redirects to `/signin` if not authenticated, or `/dashboard` if authenticated
- `webapp.focusflowbepresent.com/signin` → Sign in page (all authentication here)
- `webapp.focusflowbepresent.com/signup` → Sign up page (optional)
- `webapp.focusflowbepresent.com/dashboard` → User dashboard (protected)

### Marketing Site
- `focusflowbepresent.com/` → Home page
- `focusflowbepresent.com/features` → Features page
- `focusflowbepresent.com/pricing` → Pricing page
- `focusflowbepresent.com/about` → About page
- **NO `/signin` route** - Sign In button just links to webapp

## Questions to Consider

1. Should sign up be on a separate page or same as sign in?
2. What should the dashboard show initially? (Coming soon sections?)
3. Should we implement OAuth (Apple/Google) immediately or later?
4. Do we need a "Forgot Password" flow?
5. Should webapp root (`/`) redirect to `/signin` or show a landing page?

---

## Next Steps

1. Start new agent chat
2. Reference this plan
3. Begin with Phase 1: Create new web app project
4. Work through phases sequentially
5. Test each phase before moving to next

---

**Created**: 2026-01-04
**Status**: Planning Complete - Ready for Implementation

