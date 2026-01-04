# FocusFlow Web App

The web application for FocusFlow, accessible at `webapp.focusflowbepresent.com`.

## Overview

This is a separate Next.js application that handles all authentication and app functionality, independent from the main marketing site.

## Features

- **Authentication**: Sign in, sign up, and password reset
- **Dashboard**: User dashboard with stats and feature previews
- **Profile**: User profile and account management
- **Shared Database**: Uses the same Supabase project as the iOS app

## Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Environment Variables**
   Create a `.env.local` file with:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://grcelvuzlayxrrokojpg.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
   ```

3. **Development**
   ```bash
   npm run dev
   ```
   The app will run on `http://localhost:3001` (port 3001 to avoid conflict with main site on port 3000)

4. **Build**
   ```bash
   npm run build
   ```

## Deployment

This app is deployed to AWS Amplify using the `amplify-webapp.yml` configuration file at the repository root.

### AWS Amplify Setup

1. Go to AWS Amplify Console
2. Create new app: `focusflow-webapp`
3. Connect to GitHub repository: `rajannagar/FocusFlow`
4. Select branch: `main`
5. Configure build settings to use `amplify-webapp.yml`
6. Add environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
7. Deploy

### DNS Configuration

After deployment:
1. In Amplify Console → Domain management
2. Add custom domain: `webapp.focusflowbepresent.com`
3. Get CloudFront URL from Amplify
4. Add CNAME record in GoDaddy:
   - Name: `webapp`
   - Value: `[CloudFront URL from Amplify]`
   - TTL: 1 Hour
5. Wait for DNS propagation and SSL certificate provisioning

## Project Structure

```
focusflow-webapp/
├── app/
│   ├── layout.tsx          # Root layout with AuthProvider
│   ├── page.tsx            # Home (redirects to signin/dashboard)
│   ├── signin/             # Sign in page
│   ├── signup/             # Sign up page
│   ├── dashboard/          # Dashboard (protected)
│   └── profile/            # User profile (protected)
├── components/
│   ├── auth/               # Authentication components
│   ├── dashboard/          # Dashboard components
│   └── layout/             # Layout components
├── contexts/
│   └── AuthContext.tsx     # Authentication context
├── lib/
│   └── supabase/           # Supabase client utilities
└── middleware.ts           # Route middleware (placeholder)
```

## Authentication Flow

- Unauthenticated users are redirected to `/signin`
- Authenticated users can access `/dashboard` and `/profile`
- All auth state is managed client-side (static export)

## Design System

Uses the same design system as the main marketing site:
- Dark luxury theme
- Sora font for headings
- Inter font for body text
- CSS custom properties for theming

## Notes

- Static export is used for AWS Amplify deployment
- Authentication is handled client-side
- Same Supabase project as iOS app (shared user database)
- No server-side rendering (static export)
