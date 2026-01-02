# FocusFlow

**Be Present** – The all-in-one iOS app for focused work.

FocusFlow is a premium focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work.

[![App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/app/focusflow-be-present/id6739000000)

---

## 📁 Project Structure

```
FocusFlow/
│
├── 📁 docs/                      # Documentation
│   ├── AUDIT_REVIEW.md           # Security & code audit notes
│   └── LAUNCH_GAME_PLAN.md       # Launch strategy & timeline
│
├── 📁 FocusFlow/                 # iOS App Source Code
│   ├── App/                      # App lifecycle & entry points
│   ├── Core/                     # Core functionality
│   │   ├── AppSettings/          # User preferences
│   │   ├── Logging/              # Debug logging & sync logs
│   │   ├── Notifications/        # Notification system
│   │   ├── UI/                   # Reusable UI components
│   │   └── Utilities/            # Helpers (haptics, network, etc.)
│   ├── Features/                 # Feature modules
│   │   ├── Auth/                 # Authentication flows
│   │   ├── Focus/                # Focus timer & ambient sounds
│   │   ├── Journey/              # Daily summary timeline
│   │   ├── NotificationsCenter/  # In-app notification center
│   │   ├── Onboarding/           # First-run experience
│   │   ├── Presets/              # Custom focus presets
│   │   ├── Profile/              # User profile & settings
│   │   ├── Progress/             # XP, levels & stats
│   │   └── Tasks/                # Task management
│   ├── Infrastructure/           # Backend & sync
│   │   └── Cloud/                # Supabase, auth, sync engines
│   ├── Resources/                # Assets, sounds, entitlements
│   ├── Shared/                   # Code shared with widgets
│   └── StoreKit/                 # In-app purchases & paywall
│
├── 📁 FocusFlowWidgets/          # Widget Extension
│   └── ...                       # Home screen & Live Activity widgets
│
├── 📁 FocusFlow.xcodeproj/       # Xcode Project
│
├── 📁 softcomputers-site/        # Marketing Website (Next.js)
│   ├── app/                      # Pages
│   ├── components/               # React components
│   ├── hooks/                    # Custom hooks
│   └── lib/                      # Utilities & constants
│
├── 📁 supabase/                  # Backend Functions
│   └── functions/
│       └── delete-user/          # Account deletion edge function
│
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 16+** (uses File System Synchronized Groups)
- **iOS 17.0+** deployment target
- **Node.js 18+** (for website development)

### iOS App

1. Open `FocusFlow.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on simulator or device

### Website

```bash
cd softcomputers-site
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 🎯 Key Features

| Feature | Description |
|---------|-------------|
| **Focus Timer** | Timed sessions with 14 ambient backgrounds |
| **Smart Tasks** | Recurring tasks with reminders & duration estimates |
| **XP & Levels** | 50 levels to unlock, earn XP for sessions & tasks |
| **10 Themes** | Beautiful customization options |
| **Cloud Sync** | Sync across devices with Supabase |
| **Guest Mode** | Use without an account (local only) |
| **Widgets** | Home screen widgets & Live Activity |
| **Privacy First** | No tracking, no ads |

---

## 🔧 Tech Stack

### iOS App
- **SwiftUI** – Modern declarative UI
- **Supabase** – Authentication & database
- **WidgetKit** – Home screen widgets
- **ActivityKit** – Live Activities

### Website
- **Next.js 14** – App Router, React Server Components
- **TypeScript** – Type safety
- **Tailwind CSS** – Styling
- **AWS Amplify** – Hosting

---

## 📄 License

Copyright © 2025 Soft Computers. All rights reserved.

---

## 📧 Contact

- **Email**: Info@softcomputers.ca
- **Website**: [softcomputers.ca](https://www.softcomputers.ca)

