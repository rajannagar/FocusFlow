# Soft Computers Website

The official website for Soft Computers, featuring our flagship product **FocusFlow**.

Built with [Next.js 14](https://nextjs.org) (App Router), TypeScript, and Tailwind CSS.

## 🏗️ Project Structure

```
softcomputers-site/
├── app/                          # Next.js App Router (Pages)
│   ├── about/                    # About page
│   ├── focusflow/                # FocusFlow product page
│   ├── privacy/                  # Privacy policy
│   ├── support/                  # Support & contact
│   ├── terms/                    # Terms of service
│   ├── globals.css               # Global styles & CSS variables
│   ├── layout.tsx                # Root layout (header, footer)
│   └── page.tsx                  # Homepage
│
├── components/                   # React components
│   ├── common/                   # Shared/reusable components
│   │   ├── AnimatedBackground.tsx
│   │   ├── Container.tsx
│   │   └── ScrollToTop.tsx
│   ├── features/                 # Feature-specific components
│   │   ├── phone/                # iPhone simulator
│   │   │   └── PhoneSimulator.tsx
│   │   └── pricing/              # Pricing components
│   │       └── CurrencySelector.tsx
│   └── layout/                   # Site-wide layout elements
│       ├── Footer.tsx
│       └── Header.tsx
│
├── hooks/                        # Custom React hooks
│   └── useThrottledMouse.ts      # Mouse position hook for parallax effects
│
├── lib/                          # Utilities & constants
│   └── constants.ts              # Site configuration, URLs, pricing
│
└── public/                       # Static assets
    ├── images/                   # App screenshots
    ├── focusflow_app_icon.*      # App icons
    └── ...                       # Favicons, manifest, etc.
```

## 🚀 Getting Started

### Development Server Setup

1. **Install dependencies:**
```bash
npm install
```

2. **Set up environment variables:**
Create a `.env.local` file in the root directory with the following variables:
```env
# Site Configuration
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Supabase Configuration (get these from your Supabase project settings)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. **Start the development server:**
```bash
npm run dev
```

The dev server will start on [http://localhost:3000](http://localhost:3000) with hot reload enabled.

**Available scripts:**
- `npm run dev` - Start dev server on port 3000
- `npm run dev:port` - Start dev server on custom port (prompts for port)
- `npm run build` - Build for production (static export)
- `npm run build:static` - Explicitly build static export
- `npm run start` - Start production server (after build)
- `npm run lint` - Run ESLint

## 📦 Import Patterns

Components and hooks use path aliases for clean imports:

```typescript
// Import components
import { Container, Header, PhoneSimulator } from '@/components';

// Import hooks
import { useThrottledMouse } from '@/hooks';

// Import constants
import { SITE_URL, APP_STORE_URL, PRICING } from '@/lib/constants';
```

## 🎨 Styling

- **Tailwind CSS** for utility-first styling
- **CSS Variables** defined in `globals.css` for theming
- Dark theme by default with premium purple/gold accents

## 📱 Pages

| Path | Description |
|------|-------------|
| `/` | Homepage - Company intro & FocusFlow preview |
| `/focusflow` | FocusFlow product page with features & pricing |
| `/about` | About Soft Computers - mission & values |
| `/support` | Support page with FAQs & contact |
| `/privacy` | Privacy policy |
| `/terms` | Terms of service |

## 🔧 Configuration

Site-wide configuration is centralized in `lib/constants.ts`:

- Site URL & metadata
- Contact information
- App Store links
- Pricing tiers

## 🔧 Development vs Production

The Next.js configuration automatically switches between development and production modes:

- **Development** (`npm run dev`): Full Next.js dev server with hot reload, API routes, and dynamic features
- **Production** (`npm run build`): Static export for AWS Amplify deployment (outputs to `/out` directory)

The static export is only enabled in production builds, allowing you to use all Next.js features during development.

## 📤 Deployment

The site is configured for static export via AWS Amplify (`amplify.yml`).

Build output goes to the `/out` directory.
