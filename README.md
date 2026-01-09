# 🧘 FocusFlow - Be Present

<div align="center">

![FocusFlow Logo](FocusFlow/Resources/Focusflow_Logo.png)

**The beautifully crafted focus timer that helps you do deep work, track progress, and build better habits.**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![Next.js](https://img.shields.io/badge/Next.js-16.1-black.svg)](https://nextjs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![App Store](https://img.shields.io/badge/App%20Store-Rating%205.0-brightgreen.svg)](https://apps.apple.com/app/focusflow)

[Download on App Store](https://apps.apple.com/app/focusflow) • [Website](https://focusflowbepresent.com) • [Documentation](./docs/)

</div>

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Project Architecture](#-project-architecture)
3. [Features](#-features)
4. [Tech Stack](#-tech-stack)
5. [Project Structure](#-project-structure)
6. [Getting Started](#-getting-started)
7. [Documentation](#-documentation)
8. [Contributing](#-contributing)

---

## 🌟 Overview

FocusFlow is a comprehensive productivity ecosystem consisting of:

- **📱 iOS App** - Premium SwiftUI-based focus timer with AI assistant
- **🌐 Marketing Website** - Next.js 16 landing page and web app
- **📊 Home Screen Widgets** - WidgetKit widgets for quick access
- **🔄 Live Activities** - Dynamic Island support for active sessions
- **☁️ Cloud Backend** - Supabase for auth, sync, and AI services

### Mission Statement
> *"Your mind deserves focus."* - FocusFlow helps users achieve deep work, track their productivity journey, and build lasting habits through a beautifully designed, distraction-free experience.

---

## 🏗 Project Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FOCUSFLOW ECOSYSTEM                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         CLIENT LAYER                                   │ │
│  ├──────────────────┬───────────────────┬─────────────────────────────────┤ │
│  │                  │                   │                                 │ │
│  │  ┌────────────┐  │  ┌─────────────┐  │  ┌──────────────────────────┐   │ │
│  │  │  iOS App   │  │  │   Website   │  │  │       Widgets            │   │ │
│  │  │  (SwiftUI) │  │  │  (Next.js)  │  │  │  (WidgetKit + Live)      │   │ │
│  │  └─────┬──────┘  │  └──────┬──────┘  │  └────────────┬─────────────┘   │ │
│  │        │         │         │         │               │                 │ │
│  └────────┼─────────┴─────────┼─────────┴───────────────┼─────────────────┘ │
│           │                   │                         │                   │
│  ┌────────┴───────────────────┴─────────────────────────┴─────────────────┐ │
│  │                      INFRASTRUCTURE LAYER                              │ │
│  ├────────────────────────────────────────────────────────────────────────┤ │
│  │                                                                        │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐   │ │
│  │  │ Auth Manager│  │ Sync Engine │  │   StoreKit  │  │ App Groups   │   │ │
│  │  │ (AuthV2)    │  │ (Realtime)  │  │ (IAP/Subs)  │  │ (Shared Data)│   │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘   │ │
│  │         │                │                │                │           │ │
│  └─────────┴────────────────┴────────────────┴────────────────┴───────────┘ │
│                             │                                               │
│  ┌──────────────────────────┴─────────────────────────────────────────────┐ │
│  │                        BACKEND LAYER                                   │ │
│  ├────────────────────────────────────────────────────────────────────────┤ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │                    SUPABASE                                     │   │ │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐   │   │ │
│  │  │  │ PostgreSQL │  │    Auth    │  │   Edge     │  │ Storage  │   │   │ │
│  │  │  │  Database  │  │  (OAuth)   │  │ Functions  │  │  (Files) │   │   │ │
│  │  │  └────────────┘  └────────────┘  └────────────┘  └──────────┘   │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │                    OPENAI API                                   │   │ │
│  │  │              (Flow AI - GPT-4o Integration)                     │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

### 📱 iOS App Features

| Feature | Description | Status |
|---------|-------------|--------|
| **🎯 Focus Timer** | Beautiful countdown timer with ambient sounds and backgrounds | ✅ |
| **✅ Task Manager** | Full-featured task system with reminders and recurring tasks | ✅ |
| **📊 Progress Tracking** | XP system, streaks, badges, and detailed statistics | ✅ |
| **🤖 Flow AI** | ChatGPT-powered AI assistant for productivity coaching | ✅ Pro |
| **🎨 10 Premium Themes** | Forest, Neon, Peach, Cyber, Ocean, Sunrise, Amber, Mint, Royal, Slate | ✅ |
| **🔊 Focus Sounds** | Built-in ambient sounds (Rain, Ocean, Fire, etc.) | ✅ |
| **🎵 Music Integration** | Launch Spotify, Apple Music, or YouTube Music | ✅ |
| **📝 Focus Presets** | Customizable timer presets with theme/sound settings | ✅ |
| **☁️ Cloud Sync** | Cross-device sync for Pro users | ✅ Pro |
| **👤 Profiles** | Custom avatars, display names, and taglines | ✅ |
| **🔔 Smart Notifications** | Daily reminders, session alerts, goal tracking | ✅ |
| **🎮 Gamification** | Levels, XP, badges, and milestone celebrations | ✅ |

### 📊 Home Screen Widgets

| Widget | Size | Description |
|--------|------|-------------|
| **Quick Start** | Small | Start focus session with one tap |
| **Progress Widget** | Small/Medium | Today's focus time and goal progress |
| **Preset Selector** | Medium | Choose and start presets directly |
| **Live Activity** | Dynamic Island | Real-time session countdown |

### 🌐 Website Features

| Page | Description |
|------|-------------|
| **Landing Page** | Hero section, features, testimonials, download CTA |
| **Features Page** | Detailed feature breakdown with screenshots |
| **Pricing Page** | Free vs Pro comparison |
| **About Page** | Company and mission information |
| **Privacy/Terms** | Legal pages |
| **Support** | Contact and FAQ |
| **Web App** | Progressive web features (future) |

---

## 🛠 Tech Stack

### iOS App
```
┌────────────────────────────────────────────────────┐
│ Framework        │ Usage                           │
├─────────────────────────────────────────────────────┤
│ SwiftUI          │ UI Framework (100% SwiftUI)     │
│ Swift 5.9+       │ Language                        │
│ Combine          │ Reactive Programming            │
│ StoreKit 2       │ In-App Purchases               │
│ WidgetKit        │ Home Screen Widgets            │
│ ActivityKit      │ Live Activities/Dynamic Island │
│ AVFoundation     │ Audio Playback                 │
│ UserNotifications│ Local Notifications            │
│ Supabase Swift   │ Backend SDK                    │
│ Speech Framework │ Voice Input for Flow AI        │
└────────────────────────────────────────────────────┘
```

### Website
```
┌────────────────────────────────────────────────────┐
│ Technology       │ Usage                           │
├─────────────────────────────────────────────────────┤
│ Next.js 16.1     │ React Framework (App Router)   │
│ React 19         │ UI Library                     │
│ TypeScript 5     │ Language                       │
│ Tailwind CSS 4   │ Styling                        │
│ Supabase JS      │ Backend SDK                    │
│ Lucide React     │ Icons                          │
└────────────────────────────────────────────────────┘
```

### Backend (Supabase)
```
┌────────────────────────────────────────────────────┐
│ Service          │ Usage                           │
├─────────────────────────────────────────────────────┤
│ PostgreSQL       │ Database                       │
│ Auth             │ Email/OAuth Authentication     │
│ Edge Functions   │ Serverless AI Chat             │
│ Storage          │ Profile Images                 │
│ Realtime         │ Cross-device Sync              │
└────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
FocusFlow/
├── 📱 FocusFlow/                    # iOS App Source
│   ├── App/                         # App entry point & main views
│   ├── Core/                        # Core utilities & settings
│   ├── DesignSystem/                # UI components & theme
│   ├── Features/                    # Feature modules
│   │   ├── AI/                      # Flow AI assistant
│   │   ├── Account/                 # Auth & profile
│   │   ├── Focus/                   # Focus timer
│   │   ├── Tasks/                   # Task management
│   │   ├── Progress/                # Stats & tracking
│   │   ├── Presets/                 # Focus presets
│   │   ├── Journey/                 # Gamification journey
│   │   ├── Onboarding/              # First-time user flow
│   │   └── NotificationsCenter/     # In-app notifications
│   ├── Infrastructure/              # Cloud & networking
│   ├── Shared/                      # Widget bridge & shared code
│   ├── StoreKit/                    # In-app purchases
│   └── Resources/                   # Assets & sounds
│
├── 📊 FocusFlowWidgets/             # WidgetKit Extension
│   ├── FocusFlowWidget.swift        # Home Screen widgets
│   ├── FocusSessionLiveActivity.swift # Dynamic Island
│   └── WidgetDataProvider.swift     # App Group data bridge
│
├── 🌐 focusflow-site/               # Next.js Website
│   ├── app/                         # App Router pages
│   ├── components/                  # React components
│   ├── lib/                         # Utilities & constants
│   ├── contexts/                    # React contexts
│   └── hooks/                       # Custom hooks
│
├── ☁️ supabase/                     # Backend Configuration
│   ├── config.toml                  # Supabase config
│   └── functions/                   # Edge Functions
│       └── ai-chat/                 # Flow AI backend
│
├── 📄 docs/                         # Documentation
└── 🔧 FocusFlow.xcodeproj           # Xcode Project
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** (for iOS development)
- **Node.js 18+** (for website development)
- **Supabase CLI** (for backend)
- **iOS 17.0+ device/simulator**

### iOS App Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-org/focusflow.git
cd focusflow

# 2. Open in Xcode
open FocusFlow.xcodeproj

# 3. Add configuration
# Create Info.plist entries:
#   - SUPABASE_URL
#   - SUPABASE_ANON_KEY

# 4. Build and run
# Select target: FocusFlow
# Press Cmd+R
```

### Website Setup

```bash
# 1. Navigate to site directory
cd focusflow-site

# 2. Install dependencies
npm install

# 3. Create environment file
cp .env.example .env.local
# Add your Supabase credentials

# 4. Run development server
npm run dev

# 5. Open http://localhost:3000
```

### Supabase Setup

```bash
# 1. Install Supabase CLI
brew install supabase/tap/supabase

# 2. Navigate to supabase directory
cd supabase

# 3. Link to your project
supabase link --project-ref your-project-ref

# 4. Deploy Edge Functions
supabase functions deploy ai-chat

# 5. Set secrets
supabase secrets set OPENAI_API_KEY=sk-...
```

---

## 📚 Documentation

Detailed documentation is available in the `docs/` directory:

| Document | Description |
|----------|-------------|
| [iOS App Documentation](./docs/IOS_APP.md) | Complete iOS app architecture and features |
| [Website Documentation](./docs/Website.md) | Next.js website structure and deployment |
| [Widgets Documentation](./docs/WIDGETS.md) | WidgetKit and Live Activities guide |
| [Backend Documentation](./docs/Backend.md) | Supabase setup and Edge Functions |
| [Architecture](./docs/ARCHITECTURE.md) | System design and data flow diagrams |

---

## 🔐 Security

- All API keys stored in environment variables
- JWT-based authentication via Supabase
- PKCE OAuth flow for secure login
- No client-side API key exposure
- Pro gating for premium features

---

## 📜 License

Copyright © 2025 Soft Computers. All rights reserved.

---

## 🤝 Contributing

FocusFlow is a private project. For inquiries, contact support@focusflowbepresent.com.

---

<div align="center">

**Built with ❤️ for people who want to focus.**

[Website](https://focusflowbepresent.com) • [App Store](https://apps.apple.com/app/focusflow) • [Support](mailto:support@focusflowbepresent.com)

</div>
