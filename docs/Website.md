# 🌐 FocusFlow Website Documentation

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Pages](#pages)
5. [Components](#components)
6. [Styling](#styling)
7. [SEO & Metadata](#seo--metadata)
8. [Authentication](#authentication)
9. [Deployment](#deployment)
10. [Development](#development)

---

## Overview

The FocusFlow website is a modern, responsive marketing and web app built with Next.js 16 and React 19. It serves as the landing page, product information hub, and future web application platform.

### Key Features

- **Next.js 16 App Router** - Latest routing paradigm
- **React 19** - Latest React with Server Components
- **Tailwind CSS 4** - Utility-first styling
- **Dark Theme** - Premium dark aesthetic
- **SEO Optimized** - Full metadata and structured data
- **Responsive Design** - Mobile-first approach
- **Interactive Animations** - Smooth scroll and hover effects

---

## Technology Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                      WEBSITE TECH STACK                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Framework:        Next.js 16.1 (App Router)                   │
│  Language:         TypeScript 5                                 │
│  UI Library:       React 19.2                                   │
│  Styling:          Tailwind CSS 4                               │
│  Icons:            Lucide React                                 │
│  Backend:          Supabase (Auth, Database)                   │
│  Hosting:          AWS Amplify                                  │
│  Domain:           focusflowbepresent.com                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Dependencies

```json
{
  "dependencies": {
    "@supabase/ssr": "^0.8.0",
    "@supabase/supabase-js": "^2.89.0",
    "lucide-react": "^0.562.0",
    "next": "16.1.1",
    "react": "19.2.3",
    "react-dom": "19.2.3"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "eslint": "^9",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}
```

---

## Project Structure

```
focusflow-site/
├── app/                          # Next.js App Router
│   ├── layout.tsx               # Root layout
│   ├── page.tsx                 # Homepage
│   ├── globals.css              # Global styles
│   ├── HomeClient.tsx           # Homepage client component
│   │
│   ├── about/                   # About page
│   │   └── page.tsx
│   │
│   ├── features/                # Features page
│   │   ├── page.tsx
│   │   └── FeaturesClient.tsx
│   │
│   ├── pricing/                 # Pricing page
│   │   └── page.tsx
│   │
│   ├── privacy/                 # Privacy policy
│   │   └── page.tsx
│   │
│   ├── terms/                   # Terms of service
│   │   └── page.tsx
│   │
│   ├── support/                 # Support/contact
│   │   └── page.tsx
│   │
│   ├── signin/                  # Sign in page
│   │   └── page.tsx
│   │
│   ├── webapp/                  # Web app (future)
│   │   └── page.tsx
│   │
│   └── focusflow/               # Deep link handler
│       └── page.tsx
│
├── components/                   # React components
│   ├── index.ts                 # Barrel export
│   │
│   ├── common/                  # Shared components
│   │   ├── index.ts
│   │   ├── AnimatedBackground.tsx
│   │   ├── Container.tsx
│   │   ├── ScrollToTop.tsx
│   │   └── ThemeToggle.tsx
│   │
│   ├── features/                # Feature-specific
│   │   ├── index.ts
│   │   ├── phone/               # Phone simulator
│   │   └── pricing/             # Pricing cards
│   │
│   └── layout/                  # Layout components
│       ├── index.ts
│       ├── Header.tsx
│       └── Footer.tsx
│
├── contexts/                    # React contexts
│   └── AuthContext.tsx         # Auth state
│
├── hooks/                       # Custom hooks
│   ├── index.ts
│   ├── useTheme.ts
│   └── useThrottledMouse.ts
│
├── lib/                         # Utilities
│   ├── index.ts
│   ├── constants.ts            # App constants
│   ├── seo.ts                  # SEO helpers
│   └── supabase/               # Supabase client
│
├── public/                      # Static assets
│   ├── focusflow_app_icon.png
│   ├── favicon-32.png
│   ├── apple-touch-icon.png
│   └── manifest.json
│
├── next.config.ts              # Next.js config
├── tailwind.config.ts          # Tailwind config
├── tsconfig.json               # TypeScript config
├── package.json
└── .env.local                  # Environment variables
```

---

## Pages

### 1. Homepage (`/`)

**File:** `app/page.tsx` + `app/HomeClient.tsx`

The landing page featuring:

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOMEPAGE LAYOUT                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     HERO SECTION                          │  │
│  │  • Animated gradient orbs                                 │  │
│  │  • Floating particles                                     │  │
│  │  • "Your mind deserves focus" headline                    │  │
│  │  • App Store download CTA                                 │  │
│  │  • Phone simulator mockup                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   FEATURES GRID                           │  │
│  │  • Focus Timer                                            │  │
│  │  • Task Manager                                           │  │
│  │  • Progress Tracking                                      │  │
│  │  • Flow AI                                                │  │
│  │  • Cloud Sync                                             │  │
│  │  • Premium Themes                                         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   STATS SECTION                           │  │
│  │  • Animated counters                                      │  │
│  │  • Active users, focus hours, etc.                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  TESTIMONIALS                             │  │
│  │  • User reviews                                           │  │
│  │  • Star ratings                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   FINAL CTA                               │  │
│  │  • Download button                                        │  │
│  │  • "Start focusing today"                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Components:**
- `FloatingParticle` - Animated background particles
- `AnimatedCounter` - Number animation on scroll
- `FeatureCard` - Feature highlight card
- `PhoneSimulator` - iOS device mockup

### 2. Features Page (`/features`)

**File:** `app/features/page.tsx`

Detailed breakdown of app features with:
- Feature cards with icons
- Screenshot galleries
- Interactive demos
- Comparison tables

### 3. Pricing Page (`/pricing`)

**File:** `app/pricing/page.tsx`

Subscription comparison:

| Feature | Free | Pro |
|---------|------|-----|
| Focus Timer | ✓ | ✓ |
| Tasks | ✓ | ✓ |
| Progress | ✓ | ✓ |
| Flow AI | ✗ | ✓ |
| Cloud Sync | ✗ | ✓ |
| Themes | 3 | 10 |

**Pricing:**
- **Monthly:** $5.99 USD/month
- **Yearly:** $59.99 USD/year (17% savings)
- All pricing displayed in USD only
- 7-day free trial available
- Managed through Apple App Store subscriptions

### 4. About Page (`/about`)

**File:** `app/about/page.tsx`

Company information:
- Mission statement
- Team information
- Contact details

### 5. Legal Pages

**Privacy Policy:** `app/privacy/page.tsx`
**Terms of Service:** `app/terms/page.tsx`

### 6. Support Page (`/support`)

**File:** `app/support/page.tsx`

Support resources:
- FAQ sections
- Contact form
- Email support

### 7. Sign In Page (`/signin`)

**File:** `app/signin/page.tsx`

Web authentication for future web app features.

---

## Components

### Layout Components

#### Header (`components/layout/Header.tsx`)

```tsx
// Navigation structure
<Header>
  <Logo />
  <Navigation>
    <NavLink href="/">Home</NavLink>
    <NavLink href="/features">Features</NavLink>
    <NavLink href="/pricing">Pricing</NavLink>
    <NavLink href="/about">About</NavLink>
  </Navigation>
  <CTAButton href={APP_STORE_URL}>Download</CTAButton>
</Header>
```

Features:
- Sticky header
- Transparent to solid on scroll
- Mobile hamburger menu
- Smooth transitions

#### Footer (`components/layout/Footer.tsx`)

```tsx
<Footer>
  <FooterSection title="Product">
    <FooterLink href="/features">Features</FooterLink>
    <FooterLink href="/pricing">Pricing</FooterLink>
  </FooterSection>
  <FooterSection title="Company">
    <FooterLink href="/about">About</FooterLink>
    <FooterLink href="/support">Support</FooterLink>
  </FooterSection>
  <FooterSection title="Legal">
    <FooterLink href="/privacy">Privacy</FooterLink>
    <FooterLink href="/terms">Terms</FooterLink>
  </FooterSection>
  <SocialLinks />
  <Copyright />
</Footer>
```

### Common Components

#### Container (`components/common/Container.tsx`)

Responsive container wrapper:
```tsx
<Container className="custom-class">
  {children}
</Container>
```

#### AnimatedBackground (`components/common/AnimatedBackground.tsx`)

Gradient animated background used across pages.

#### ScrollToTop (`components/common/ScrollToTop.tsx`)

Floating button for scrolling to top.

### Feature Components

#### PhoneSimulator (`components/features/phone/`)

iOS device mockup displaying app screenshots:
- Realistic device frame
- Screen content slot
- Dynamic Island
- Responsive sizing

#### PricingCard (`components/features/pricing/`)

Subscription tier card:
- Tier name and price
- Feature list
- CTA button
- "Most Popular" badge

---

## Styling

### CSS Architecture

```css
/* app/globals.css */

/* CSS Custom Properties (Theme Variables) */
:root {
  --background: #0a0a0a;
  --background-elevated: #111111;
  --foreground: #f5f0e8;
  --foreground-muted: rgba(245, 240, 232, 0.7);
  --foreground-subtle: rgba(245, 240, 232, 0.4);
  
  --accent-primary: #8b5cf6;    /* Purple */
  --accent-secondary: #d4a853;  /* Gold */
  
  --border: rgba(245, 240, 232, 0.08);
  --border-strong: rgba(245, 240, 232, 0.15);
}

/* Animations */
@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  50% { transform: translateY(-20px) rotate(3deg); }
}

@keyframes slide-up {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes gradient-flow {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* Utility Classes */
.text-gradient {
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.bg-grid {
  background-image: 
    linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px);
  background-size: 50px 50px;
}

.glass {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
}
```

### Tailwind Configuration

```ts
// tailwind.config.ts
export default {
  content: [
    './app/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        background: 'var(--background)',
        foreground: 'var(--foreground)',
        accent: {
          primary: 'var(--accent-primary)',
          secondary: 'var(--accent-secondary)',
        },
      },
      fontFamily: {
        clash: ['var(--font-clash)'],
        cabinet: ['var(--font-cabinet)'],
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'slide-up': 'slide-up 0.6s ease-out',
        'fade-in': 'fade-in 0.5s ease-out',
      },
    },
  },
}
```

### Typography

```tsx
// app/layout.tsx
import { Inter, Inter_Tight } from 'next/font/google';

// Display font (headings)
const interTight = Inter_Tight({
  variable: '--font-clash',
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
});

// Body font (paragraphs/UI)
const inter = Inter({
  variable: '--font-cabinet',
  subsets: ['latin'],
  weight: ['400', '500', '600'],
});
```

---

## SEO & Metadata

### Metadata Configuration

```tsx
// app/layout.tsx
export const metadata: Metadata = {
  metadataBase: new URL('https://focusflowbepresent.com'),
  title: {
    default: 'FocusFlow - Be Present | Focus Timer & Productivity App',
    template: '%s | FocusFlow',
  },
  description: 'FocusFlow is the all-in-one focus timer, task manager, and progress tracker.',
  keywords: [
    'focus timer', 'productivity app', 'task management',
    'iOS app', 'pomodoro timer', 'habit tracker',
  ],
  openGraph: {
    title: 'FocusFlow - Be Present',
    description: '...',
    url: 'https://focusflowbepresent.com',
    images: [{ url: '/focusflow_app_icon.png' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'FocusFlow - Be Present',
    images: ['/focusflow_app_icon.png'],
  },
  robots: {
    index: true,
    follow: true,
  },
};
```

### Structured Data

```tsx
// Organization Schema
const organizationSchema = {
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "FocusFlow",
  "url": "https://focusflowbepresent.com",
  "logo": "https://focusflowbepresent.com/focusflow_app_icon.png",
};

// Software Application Schema
const softwareSchema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "FocusFlow",
  "operatingSystem": "iOS",
  "applicationCategory": "ProductivityApplication",
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "5.0",
    "ratingCount": "500"
  }
};
```

### SEO Helpers

```ts
// lib/seo.ts
export function generatePageMetadata(page: string): Metadata {
  return {
    title: pageTitle,
    description: pageDescription,
    alternates: {
      canonical: `https://focusflowbepresent.com/${page}`,
    },
  };
}

export function generateBreadcrumbSchema(items: BreadcrumbItem[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": items.map((item, index) => ({
      "@type": "ListItem",
      "position": index + 1,
      "name": item.name,
      "item": `https://focusflowbepresent.com${item.url}`,
    })),
  };
}
```

---

## Authentication

### Supabase Auth Setup

```tsx
// contexts/AuthContext.tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { User, Session } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  
  const supabase = createClient();
  
  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });
    
    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
      }
    );
    
    return () => subscription.unsubscribe();
  }, []);
  
  return (
    <AuthContext.Provider value={{ user, session, loading, ... }}>
      {children}
    </AuthContext.Provider>
  );
}
```

### Supabase Client

```ts
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

---

## Deployment

### AWS Amplify Configuration

```yaml
# amplify.yml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - cd focusflow-site
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: focusflow-site/.next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
      - focusflow-site/node_modules/**/*
```

### Environment Variables

Required in Amplify console:
```
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
NEXT_PUBLIC_APP_STORE_URL=https://apps.apple.com/app/focusflow
```

### Build Commands

```bash
# Development
npm run dev          # Start dev server on port 3000

# Production
npm run build        # Build for production
npm run start        # Start production server

# Static Export
npm run build:static # Export static HTML
```

---

## Development

### Getting Started

```bash
# 1. Navigate to website directory
cd focusflow-site

# 2. Install dependencies
npm install

# 3. Create environment file
cp .env.example .env.local

# 4. Add your Supabase credentials
NEXT_PUBLIC_SUPABASE_URL=your-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-key

# 5. Start development server
npm run dev

# 6. Open http://localhost:3000
```

### Project Constants

```ts
// lib/constants.ts
export const SITE_URL = 'https://focusflowbepresent.com';
export const SITE_NAME = 'FocusFlow';
export const SITE_DESCRIPTION = 'The all-in-one focus timer...';

export const APP_STORE_URL = 'https://apps.apple.com/app/focusflow';
export const CONTACT_EMAIL = 'support@focusflowbepresent.com';

export const SOCIAL_LINKS = {
  twitter: 'https://twitter.com/focusflow',
  instagram: 'https://instagram.com/focusflow',
};
```

### File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Pages | lowercase | `page.tsx` |
| Components | PascalCase | `FeatureCard.tsx` |
| Hooks | camelCase | `useTheme.ts` |
| Utilities | camelCase | `constants.ts` |
| Client Components | suffix | `HomeClient.tsx` |

### Code Style

- ESLint with Next.js config
- TypeScript strict mode
- Prettier formatting
- Import sorting

---

## Performance Optimizations

1. **Image Optimization:** Next.js Image component with priority loading
2. **Font Loading:** `next/font` with display swap
3. **Code Splitting:** Automatic per-page bundles
4. **Static Generation:** Pre-rendered pages where possible
5. **Lazy Loading:** Intersection Observer for animations
6. **CSS:** Tailwind CSS purging unused styles

---

## Future Roadmap

- [ ] Web app timer functionality
- [ ] User dashboard
- [ ] Data visualization
- [ ] PWA support
- [ ] Internationalization

---

*Last Updated: January 2026*
