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

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Export static site
npm run build  # Outputs to /out directory
```

Open [http://localhost:3000](http://localhost:3000) to view the site.

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

## 📤 Deployment

The site is configured for static export via AWS Amplify (`amplify.yml`).

Build output goes to the `/out` directory.
