# 🎯 FocusFlow Onboarding Redesign - Ultra-Premium Experience

**Created:** January 7, 2026  
**Status:** Planning Phase  
**Goal:** Transform first-run experience into a premium, value-driven onboarding that showcases flagship features

---

## 📊 COMPLETE APP OVERVIEW

### Current App Architecture

**Platform:** iOS 18.6+, SwiftUI, Native + Web companion  
**Monetization:** Freemium with Pro subscription ($4.99/month, $9.99/year)  
**Authentication:** Guest mode, Email/Password, Google Sign-In, Apple Sign-In  
**Backend:** Supabase (auth, database, edge functions), OpenAI GPT-4o  
**Sync:** Cloud sync (Pro + SignedIn only)

### Core Features Inventory

#### 1. **Focus Timer & Sessions** ⏱️
- **What it does:** Pomodoro-style timer with ambient sounds and backgrounds
- **Highlights:**
  - 14 ambient backgrounds (aurora, rain, ocean, forest, stars, cosmic, etc.)
  - 11 focus sounds (light rain, fireplace, soft ambience, lofi, nature, etc.)
  - Live Activity support (Dynamic Island integration) **[PRO]**
  - External music integration (Spotify, Apple Music, YouTube Music) **[PRO]**
  - Session tracking with duration, XP earning
- **Free tier:** 3 backgrounds (Minimal, Stars, Forest), 3 sounds (Light Rain, Fireplace, Soft Ambience)
- **Pro tier:** All 14 backgrounds, all 11 sounds, Live Activity, external music

#### 2. **Custom Presets** 🎛️
- **What it does:** Save personalized focus setups (duration, sound, background, intention)
- **System defaults:** Deep Work (90min), Study (45min), Writing (60min)
- **Highlights:**
  - Quick-launch from widgets
  - Customizable duration, sound pairing, background theme
  - Intention/goal tagging
- **Free tier:** Use 3 default presets only (Deep Work, Study, Writing)
- **Pro tier:** Create unlimited custom presets

#### 3. **Smart Task Management** ✅
- **What it does:** Priority-based task list with reminders, duration estimates, recurring tasks
- **Highlights:**
  - Task tagging and categorization
  - Reminder scheduling
  - Recurring task support
  - Completion tracking → earns XP
  - Due dates and priority levels
- **Free tier:** 3 active tasks maximum
- **Pro tier:** Unlimited tasks

#### 4. **Flow AI Copilot** 🤖 **[PRO ONLY]**
- **What it does:** GPT-4o powered conversational AI for productivity coaching
- **Capabilities:**
  - Natural language task creation ("Add task: finish proposal by Friday 5pm")
  - Daily planning assistance ("Plan my day")
  - Progress insights ("How am I doing this week?")
  - Focus session control ("Start deep work preset")
  - Adaptive suggestions ("What should I work on next?")
  - Motivational coaching
  - Voice input support
  - Multi-turn conversational context
- **Function calling:** Creates tasks, starts sessions, adjusts settings, generates analytics
- **Free tier:** Locked with paywall prompt
- **Pro tier:** Full access to AI copilot

#### 5. **Progress & Gamification** 📊 **[PRO ONLY]**
- **What it does:** XP system, levels (1-50), achievement badges, streaks
- **Highlights:**
  - Earn XP from sessions (10 XP per 25 min) and completed tasks (5-20 XP)
  - 50 levels with milestone celebrations
  - Daily streak tracking (flame icon)
  - Achievement badges for milestones
  - Progress history with charts
- **Free tier:** Progress tracking visible for last 3 days only, XP/levels hidden
- **Pro tier:** Full history, XP/levels system, badges

#### 6. **Journey View** 🗓️ **[PRO ONLY]**
- **What it does:** Timeline of daily summaries with personalized insights
- **Highlights:**
  - Daily cards showing: focus time, sessions, tasks completed, XP earned, streak status
  - Weekly summaries with patterns and recommendations
  - Milestone highlights (level-ups, streak milestones)
  - Emoji-based mood/motivation messages
- **Free tier:** Locked with paywall
- **Pro tier:** Full journey timeline

#### 7. **10 Premium Themes** 🎨
- **Themes:** Forest, Neon Glow, Soft Peach, Cyber Violet, Ocean Mist, Sunrise Coral, Solar Amber, Mint Aura, Royal Indigo, Cosmic Slate
- **What it does:** Dynamic gradient backgrounds with accent colors throughout app
- **Free tier:** 2 themes (Forest, Neon Glow)
- **Pro tier:** All 10 themes

#### 8. **Widgets & Live Activities** 📱
- **What it does:** Home screen widgets, Dynamic Island integration
- **Widget types:**
  - Session timer widget
  - Today's progress
  - Quick-start preset buttons
- **Free tier:** View-only widgets (no interactions)
- **Pro tier:** Full interactive widgets + Live Activity in Dynamic Island

#### 9. **Cloud Sync** ☁️ **[PRO + SIGNED IN]**
- **What it does:** Real-time sync across iOS app and web app
- **Syncs:** Tasks, presets, sessions, progress, settings
- **Requirements:** Must have Pro subscription AND be signed in (not guest)
- **Free tier:** Local-only storage
- **Guest users with Pro:** Must sign in to activate sync
- **Pro + Signed In:** Full cross-device sync

#### 10. **Web Companion App** 🌐
- **URL:** focusflow.app/app
- **Features:** Focus timer, task management, progress tracking (synced)
- **Requires:** Sign-in (no guest mode on web)

---

## 🚨 CURRENT ONBOARDING ANALYSIS

### What Exists Today (6 Pages)

1. **Welcome Page:** Logo, tagline ("A calmer way to get serious work done"), Get Started button
2. **Focus Page:** Animated timer ring demo, description of focus sessions
3. **Habits Page:** Week dots visualization, streak counter, XP bar demo
4. **Personalize Page:** Name input, daily goal selector (15-120 min), theme grid picker
5. **Notifications Page:** Bell icon animation, 3 feature rows (reminders, streaks, tasks), Enable/Maybe Later
6. **Ready Page:** Success checkmark, welcome message, auth options (Apple/Google/Email), "Continue as guest"

### Strengths ✅
- Beautiful liquid glass aesthetic with floating particles
- Theme-aware dynamic backgrounds
- Smooth animations and haptic feedback
- Optional skip functionality
- Guest mode option (no forced sign-up)
- Collects basic personalization (name, goal, theme)

### Critical Gaps ❌

#### **1. Missing Flagship Features**
- **No AI showcase:** Flow AI Copilot is a HUGE differentiator but completely absent
- **No presets mention:** Custom presets are a core workflow but never explained
- **No sync value:** Cloud sync + web app never mentioned (major Pro value prop)
- **No widgets tease:** Home screen widgets and Live Activity not shown
- **No journey preview:** Timeline/summary view is hidden

#### **2. Generic Positioning**
- Tagline is vague ("calmer way to get serious work done")
- Doesn't establish **who it's for** (knowledge workers, students, creators?)
- Doesn't communicate **what makes it different** (AI-first? Premium design? Sync everywhere?)
- No personality or voice

#### **3. Weak Value Ladder**
- Free vs Pro distinction is unclear
- No preview of what Pro unlocks
- Auth choice on final page feels arbitrary (why sign in?)
- Guest mode doesn't explain limitations

#### **4. Generic Personalization**
- Name field is optional but not used anywhere meaningful
- Daily goal (15-120 min) doesn't seed intelligent defaults
- Theme selection happens before seeing the app
- No intent discovery (What do you want to focus on? Why are you here?)

#### **5. Linear, Non-Adaptive Flow**
- Every user sees same 6 pages regardless of needs
- Can't skip to what matters to them
- No branching based on use case (focus-only vs tasks vs AI planning)

---

## 🎯 REDESIGN STRATEGY

### Design Principles

1. **Value First, Not Features:** Show outcomes (productivity, calm, achievement) not specs
2. **Adaptive Journey:** Branch based on user intent (focus enthusiast vs task warrior vs AI seeker)
3. **Progressive Disclosure:** Reveal complexity gradually, don't overwhelm
4. **Premium Throughout:** Liquid glass, motion design, delightful interactions
5. **Transparent Tiers:** Be upfront about Free vs Pro, build aspiration not resentment
6. **Guest-Friendly:** Don't force sign-in, but make value crystal clear

### Target User Archetypes

We'll design for 3 primary personas:

1. **The Deep Worker** → Loves long focus blocks, ambient sounds, minimal distractions
2. **The Task Orchestrator** → Needs to juggle many tasks, wants smart organization
3. **The AI Augmenter** → Excited by AI planning, wants intelligent assistant

### New Onboarding Flow (4-5 Steps)

#### **Step 1: Hero Moment** 🌟
**Goal:** Establish premium positioning and emotional hook  
**Duration:** ~5 seconds

**Visual:**
- Full-screen dynamic theme background (auto-cycles through 3-4 themes)
- Parallax logo animation
- Headline: **"Your day, orchestrated."**
- Subheadline: **"AI planning • Deep focus • Sync everywhere"**
- Single CTA: **"Begin →"**
- Tiny skip link in corner

**Key Elements:**
- No form fields, just pure atmosphere
- Liquid glass card with subtle float animation
- Particles tied to selected theme
- Micro-copy about premium experience ("Designed for iOS 26")

---

#### **Step 2: Intent Discovery** 🎯
**Goal:** Branch experience based on what they care about  
**Duration:** ~10 seconds

**Visual:**
- Headline: **"What brings you to FocusFlow?"**
- 4 intent cards in 2x2 grid:

1. **🎯 Deep Focus**  
   "Long sessions, zero distractions"  
   → Seeds 90min default, ambience-heavy presets

2. **✅ Smart Tasks**  
   "Organize, prioritize, accomplish"  
   → Seeds task-first workflow, reminder preferences

3. **🤖 AI Planning**  
   "Let AI orchestrate your day"  
   → Highlights Flow AI immediately, creates sample plan

4. **🎵 Ambient Study**  
   "Soundscapes for concentration"  
   → Emphasizes sound library, creates chill presets

**Interaction:**
- Tap to select (single choice, but can change later)
- Each card briefly animates its icon on hover
- Haptic feedback on selection

---

#### **Step 3: Smart Setup Stack** 🛠️
**Goal:** Collect meaningful personalization to seed intelligent defaults  
**Duration:** ~30 seconds

**Visual:**
- Animated card stack (cards appear/dismiss with physics)
- 4 cards total, progress indicator at top ("2 of 4")

**Card 1: Identity**
```
"What should we call you?"
[Text field: "Your name"]
Skip button: "I'll do this later"
```

**Card 2: Daily Rhythm**
```
"How much focus time feels right?"
[Segmented picker with smart suggestions]
• Light (30 min/day) → 1 session
• Balanced (60 min/day) → 2 sessions ✨ Recommended
• Deep (90 min/day) → 3+ sessions
• Custom → Slider (15-180 min)
```

**Card 3: Vibe Selection**
```
"Choose your atmosphere"
[Horizontal scroll of theme previews]
• Each shows: theme name, gradient preview, live background sample
• Tapping theme immediately updates page background
• Shows "🔒 Pro" badge on locked themes (but still tappable to preview)
```

**Card 4: Notification Style**
```
"How should we nudge you?"
• 🔔 Gentle reminders (focus start times only)
• ⚡ Keep me on track (focus + tasks + streaks) ✨ Recommended
• 🤫 Silent mode (no notifications)
```

**Key Feature:**
- Auto-advances after each card completes (or user taps "Next")
- Can go back with swipe or back button
- Each choice immediately influences app setup

---

#### **Step 4: Feature Spotlight Carousel** ✨
**Goal:** Showcase flagship capabilities with value-first messaging  
**Duration:** ~20 seconds (skippable)

**Visual:**
- Horizontal page carousel (like App Store feature pages)
- 4 spotlight cards (user can swipe or auto-advances after 5s each)
- Each card: Full-screen visual + headline + 1-sentence value prop

**Spotlight 1: Flow AI**
```
[Visual: Animated chat bubbles showing AI interaction]
Headline: "Your AI productivity copilot"
Subtext: "Natural language planning • Smart suggestions • Voice input"
Example shown: "Plan my next 2 hours" → AI generates task list
Badge: "PRO" in corner
```

**Spotlight 2: Sync Everywhere**
```
[Visual: Phone → Cloud → Laptop animation]
Headline: "Start here, finish anywhere"
Subtext: "Cloud sync • Web app • Cross-device"
Shows: focusflow.app URL, "Pick up where you left off"
Badge: "PRO + SIGN IN"
```

**Spotlight 3: Journey Timeline**
```
[Visual: Scrolling daily summary cards]
Headline: "Your productivity story"
Subtext: "Daily summaries • Weekly insights • Streak tracking"
Shows: Sample day card with XP, sessions, tasks
Badge: "PRO"
```

**Spotlight 4: Widgets & Live Activity**
```
[Visual: Home screen mockup with widgets + Dynamic Island]
Headline: "Focus without opening the app"
Subtext: "Home screen widgets • Dynamic Island timer"
Shows: Interactive widget, Live Activity in Dynamic Island
Badge: "PRO"
```

**Interaction:**
- Horizontal swipe to navigate
- Dots indicator at bottom
- "Skip tour" button always visible
- Each card has subtle parallax effect

---

#### **Step 5: Launch Decision** 🚀
**Goal:** Clear choice between guest, sign-in, or Pro trial  
**Duration:** ~15 seconds

**Visual:**
- Headline: **"Ready to focus?"**
- Subheadline: **"Here's what you've chosen:"**

**Recap Chips (editable):**
```
[Name chip]      [60 min/day chip]     [Forest theme chip]     [Notify: Balanced chip]
(Each tappable to quick-edit)
```

**Primary CTA:**
```
[Large gradient button]
"Start with my setup ✨"
→ Goes to main app (applies all settings, creates sample preset/task if relevant)
```

**Secondary Options:**
```
[Glass card with 3 options]

1. "Sign in to unlock Pro trial" 
   → Shows: "7 days free • Then $4.99/mo • Cancel anytime"
   → Opens auth sheet (Apple/Google/Email)

2. "Sign in to sync & unlock Pro"
   → Same auth sheet, highlights sync value

3. "Continue as guest"
   → Shows: "Local only • Limited features • Upgrade anytime"
   → Proceeds to app as guest
```

**Smart Copy:**
- If they selected "AI Planning" intent → Emphasize "Try Flow AI free for 7 days"
- If they selected "Smart Tasks" intent → Emphasize "Unlimited tasks with Pro"
- If they selected "Deep Focus" intent → Emphasize "All sounds & themes with Pro"

---

## 📐 VISUAL & INTERACTION DESIGN

### Design System Alignment

**Use existing liquid glass components:**
- `FFGlassCard` for all cards
- `FFButton` with theme gradients
- `PremiumAppBackground` for dynamic theming
- Floating particles throughout
- Consistent padding: 20pt horizontal (DS.Spacing.xl)
- Corner radii: 20pt for cards (DS.Radius.lg)
- Typography: System font, SF Pro Rounded for headlines

### Motion Design

**Transitions:**
- Page-to-page: Horizontal slide with subtle scale (0.97 → 1.0)
- Card appearance: Fade + slide from bottom with spring (response: 0.5, damping: 0.8)
- Theme preview: Cross-dissolve with 0.3s duration
- Button presses: Scale down to 0.97 with haptic

**Animations:**
- Logo entrance: Scale + fade + slight rotation
- Intent cards: Staggered entrance (0.1s delay between each)
- Setup cards: Physics-based swipe dismiss
- Spotlight pages: Parallax scroll with 0.2 damping

**Haptics:**
- Light impact on card tap
- Medium impact on intent selection
- Selection feedback on segmented picker
- Success notification on final "Start" button

### Accessibility

- All text meets WCAG AA contrast (4.5:1 minimum)
- VoiceOver labels for all interactive elements
- Semantic labels: "Step 2 of 5", "Intent selector", etc.
- Reduce motion support (disable particles, simplified transitions)
- Dynamic Type support for all text
- Keyboard navigation support (though iOS primarily touch)

---

## 🛠️ IMPLEMENTATION PLAN

### Phase 1: Data Model Updates (2 hours)

**File: `OnboardingManager.swift`**

```swift
// Add new fields to OnboardingData
struct OnboardingData {
    // Existing
    var displayName: String = ""
    var dailyGoalMinutes: Int = 60
    var selectedTheme: AppTheme = .forest
    
    // NEW
    var selectedIntent: OnboardingIntent? = nil
    var notificationStyle: NotificationStyle = .balanced
    var notificationWindowStart: Int = 9 // 9 AM
    var notificationWindowEnd: Int = 21   // 9 PM
    var firstPriorityTask: String = ""     // If provided, create this task
    var preferredPresetStyle: PresetStyle? = nil
}

enum OnboardingIntent: String, Codable, CaseIterable {
    case deepFocus = "Deep Focus"
    case smartTasks = "Smart Tasks"
    case aiPlanning = "AI Planning"
    case ambientStudy = "Ambient Study"
    
    var icon: String {
        switch self {
        case .deepFocus: return "target"
        case .smartTasks: return "checklist"
        case .aiPlanning: return "sparkles"
        case .ambientStudy: return "music.note.list"
        }
    }
    
    var description: String {
        switch self {
        case .deepFocus: return "Long sessions, zero distractions"
        case .smartTasks: return "Organize, prioritize, accomplish"
        case .aiPlanning: return "Let AI orchestrate your day"
        case .ambientStudy: return "Soundscapes for concentration"
        }
    }
    
    // Seed defaults based on intent
    func suggestedDefaults() -> (goalMinutes: Int, preset: FocusPreset?, sound: FocusSound?, ambiance: AmbientMode?) {
        switch self {
        case .deepFocus:
            return (90, FocusPreset.deepWork, .lightRainAmbient, .forest)
        case .smartTasks:
            return (45, FocusPreset.study, .soundAmbience, .minimal)
        case .aiPlanning:
            return (60, nil, .fireplace, .cosmic)
        case .ambientStudy:
            return (60, nil, .lofiBeats, .stars)
        }
    }
}

enum NotificationStyle: String, Codable, CaseIterable {
    case gentle = "Gentle reminders"
    case balanced = "Keep me on track"
    case silent = "Silent mode"
    
    var icon: String {
        switch self {
        case .gentle: return "bell"
        case .balanced: return "bolt"
        case .silent: return "bell.slash"
        }
    }
}

enum PresetStyle: String, Codable {
    case deepWork
    case quickSprints
    case relaxedFlow
}
```

**Update `OnboardingManager`:**
- Bump `currentOnboardingVersion` to 2
- Increase `totalPages` from 6 to 5 (we're condensing)
- Add methods: `selectIntent()`, `setNotificationStyle()`, `setFirstTask()`

---

### Phase 2: New Page Components (8 hours)

Create new Swift files in `Features/Onboarding/`:

#### **File: `OnboardingHeroPage.swift`**
```swift
struct OnboardingHeroPage: View {
    let theme: AppTheme
    @State private var logoScale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var cycleIndex: Int = 0
    
    // Auto-cycle through 3 themes for preview
    private let previewThemes: [AppTheme] = [.forest, .cyber, .ocean]
    
    var body: some View {
        VStack {
            Spacer()
            
            // Logo + Headline
            VStack(spacing: 24) {
                Image("Focusflow_Logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .scaleEffect(logoScale)
                    .opacity(opacity)
                
                VStack(spacing: 12) {
                    Text("Your day, orchestrated.")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("AI planning • Deep focus • Sync everywhere")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(opacity)
            }
            
            Spacer()
            
            // CTA
            Button(action: {
                Haptics.impact(.medium)
                // Navigate to next page
            }) {
                HStack(spacing: 12) {
                    Text("Begin")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: theme.accentPrimary.opacity(0.4), radius: 16, y: 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
            .opacity(opacity)
        }
        .onAppear {
            animateIn()
            startThemeCycle()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            logoScale = 1.0
            opacity = 1.0
        }
    }
    
    private func startThemeCycle() {
        // Auto-cycle themes every 3 seconds for visual interest
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                cycleIndex = (cycleIndex + 1) % previewThemes.count
            }
        }
    }
}
```

#### **File: `OnboardingIntentPage.swift`**
```swift
struct OnboardingIntentPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var cardsVisible: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("What brings you to FocusFlow?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll personalize your experience")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Intent grid (2x2)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Array(OnboardingIntent.allCases.enumerated()), id: \.offset) { index, intent in
                    IntentCard(
                        intent: intent,
                        isSelected: manager.onboardingData.selectedIntent == intent,
                        theme: theme
                    ) {
                        manager.selectIntent(intent)
                        Haptics.impact(.medium)
                        
                        // Auto-advance after 0.5s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            manager.nextPage()
                        }
                    }
                    .opacity(cardsVisible[index] ? 1 : 0)
                    .offset(y: cardsVisible[index] ? 0 : 20)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            // Staggered animation
            for i in 0..<4 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(i) * 0.1)) {
                    cardsVisible[i] = true
                }
            }
        }
    }
}

struct IntentCard: View {
    let intent: OnboardingIntent
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: intent.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? theme.accentPrimary : .white)
                
                Text(intent.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(intent.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? theme.accentPrimary : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(FFPressButtonStyle())
    }
}
```

#### **File: `OnboardingSetupStackPage.swift`**
```swift
struct OnboardingSetupStackPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var currentCardIndex: Int = 0
    @FocusState private var nameFieldFocused: Bool
    
    private let totalCards = 4
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalCards, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentCardIndex ? theme.accentPrimary : Color.white.opacity(0.2))
                        .frame(width: index == currentCardIndex ? 32 : 8, height: 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentCardIndex)
                }
            }
            .padding(.top, 20)
            
            // Card stack
            ZStack {
                switch currentCardIndex {
                case 0:
                    NameCard(theme: theme, manager: manager, nameFieldFocused: $nameFieldFocused) {
                        advanceCard()
                    }
                case 1:
                    DailyGoalCard(theme: theme, manager: manager) {
                        advanceCard()
                    }
                case 2:
                    ThemeCard(theme: theme, manager: manager) {
                        advanceCard()
                    }
                case 3:
                    NotificationCard(theme: theme, manager: manager) {
                        advanceCard()
                    }
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func advanceCard() {
        if currentCardIndex < totalCards - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentCardIndex += 1
            }
        } else {
            manager.nextPage()
        }
    }
}

// Individual card components (NameCard, DailyGoalCard, etc.)
// ... implement each with similar glass card styling
```

#### **File: `OnboardingSpotlightPage.swift`**
```swift
struct OnboardingSpotlightPage: View {
    let theme: AppTheme
    @State private var currentSpotlight: Int = 0
    
    private let spotlights = [
        SpotlightContent(
            visual: "ai_chat_preview",
            headline: "Your AI productivity copilot",
            subtext: "Natural language planning • Smart suggestions • Voice input",
            badge: "PRO"
        ),
        SpotlightContent(
            visual: "sync_animation",
            headline: "Start here, finish anywhere",
            subtext: "Cloud sync • Web app • Cross-device",
            badge: "PRO + SIGN IN"
        ),
        SpotlightContent(
            visual: "journey_cards",
            headline: "Your productivity story",
            subtext: "Daily summaries • Weekly insights • Streak tracking",
            badge: "PRO"
        ),
        SpotlightContent(
            visual: "widgets_mockup",
            headline: "Focus without opening the app",
            subtext: "Home screen widgets • Dynamic Island timer",
            badge: "PRO"
        )
    ]
    
    var body: some View {
        VStack {
            // Skip button
            HStack {
                Spacer()
                Button("Skip tour") {
                    // Jump to final page
                }
                .foregroundColor(.white.opacity(0.5))
                .padding()
            }
            
            // Spotlight carousel
            TabView(selection: $currentSpotlight) {
                ForEach(0..<spotlights.count, id: \.self) { index in
                    SpotlightCard(spotlight: spotlights[index], theme: theme)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            // Auto-advance timer (5s per card)
            .onAppear {
                startAutoAdvance()
            }
        }
    }
    
    private func startAutoAdvance() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentSpotlight = (currentSpotlight + 1) % spotlights.count
            }
        }
    }
}

struct SpotlightContent {
    let visual: String  // Image or animation name
    let headline: String
    let subtext: String
    let badge: String
}

struct SpotlightCard: View {
    let spotlight: SpotlightContent
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Visual (mockup image or Lottie animation)
            Image(spotlight.visual)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: theme.accentPrimary.opacity(0.3), radius: 20)
            
            VStack(spacing: 12) {
                // Badge
                Text(spotlight.badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.accentPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.accentPrimary.opacity(0.15))
                    )
                
                // Headline
                Text(spotlight.headline)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Subtext
                Text(spotlight.subtext)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}
```

#### **File: `OnboardingFinishPage.swift`**
```swift
struct OnboardingFinishPage: View {
    let theme: AppTheme
    let displayName: String
    @ObservedObject var manager: OnboardingManager
    @ObservedObject private var authManager = AuthManagerV2.shared
    
    @State private var showAuthSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Ready to focus?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            Text("Here's what you've chosen:")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            // Recap chips
            RecapChipsView(manager: manager, theme: theme)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Primary CTA
            Button(action: {
                applySettingsAndLaunch()
            }) {
                HStack(spacing: 12) {
                    Text("Start with my setup")
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: theme.accentPrimary.opacity(0.5), radius: 20, y: 10)
            }
            .padding(.horizontal, 32)
            
            // Secondary options
            VStack(spacing: 16) {
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                    Text("or")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
                
                // Sign in option (with smart copy based on intent)
                Button(action: {
                    showAuthSheet = true
                }) {
                    VStack(spacing: 8) {
                        Text(signInCopy)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("7 days free • Then $4.99/mo • Cancel anytime")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Guest option
                Button(action: {
                    manager.completeOnboarding()
                }) {
                    VStack(spacing: 4) {
                        Text("Continue as guest")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Local only • Limited features")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthLandingView()
        }
    }
    
    private var signInCopy: String {
        guard let intent = manager.onboardingData.selectedIntent else {
            return "Sign in to unlock Pro trial"
        }
        
        switch intent {
        case .aiPlanning:
            return "Try Flow AI free for 7 days"
        case .smartTasks:
            return "Unlock unlimited tasks with Pro"
        case .deepFocus:
            return "Get all sounds & themes with Pro"
        case .ambientStudy:
            return "Access full sound library with Pro"
        }
    }
    
    private func applySettingsAndLaunch() {
        // Apply all onboarding choices
        let settings = AppSettings.shared
        
        // 1. Basic personalization
        if !manager.onboardingData.displayName.isEmpty {
            settings.displayName = manager.onboardingData.displayName
        }
        settings.dailyGoalMinutes = manager.onboardingData.dailyGoalMinutes
        settings.selectedTheme = manager.onboardingData.selectedTheme
        settings.profileTheme = manager.onboardingData.selectedTheme
        
        // 2. Apply intent-based defaults
        if let intent = manager.onboardingData.selectedIntent {
            let defaults = intent.suggestedDefaults()
            
            // Seed default preset
            if let preset = defaults.preset {
                // Store as preferred preset in AppSettings
            }
            
            // Seed default sound/ambiance
            if let sound = defaults.sound {
                FocusSoundManager.shared.setDefaultSound(sound)
            }
            if let ambiance = defaults.ambiance {
                // Store default ambiance
            }
        }
        
        // 3. Create first task if provided
        if !manager.onboardingData.firstPriorityTask.isEmpty {
            TasksStore.shared.createSampleTask(
                title: manager.onboardingData.firstPriorityTask
            )
        }
        
        // 4. Set notification preferences
        // Apply notification style to NotificationPreferencesStore
        
        // 5. Complete onboarding
        manager.completeOnboarding()
        
        // Success haptic
        Haptics.notification(.success)
    }
}

struct RecapChipsView: View {
    @ObservedObject var manager: OnboardingManager
    let theme: AppTheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if !manager.onboardingData.displayName.isEmpty {
                    RecapChip(
                        icon: "person.fill",
                        text: manager.onboardingData.displayName,
                        theme: theme
                    ) {
                        // Edit name
                    }
                }
                
                RecapChip(
                    icon: "clock.fill",
                    text: "\(manager.onboardingData.dailyGoalMinutes) min/day",
                    theme: theme
                ) {
                    // Edit goal
                }
                
                RecapChip(
                    icon: "paintpalette.fill",
                    text: manager.onboardingData.selectedTheme.displayName,
                    theme: theme
                ) {
                    // Edit theme
                }
                
                if let intent = manager.onboardingData.selectedIntent {
                    RecapChip(
                        icon: intent.icon,
                        text: intent.rawValue,
                        theme: theme
                    ) {
                        // Edit intent
                    }
                }
            }
        }
    }
}

struct RecapChip: View {
    let icon: String
    let text: String
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
```

---

### Phase 3: Update OnboardingView Container (2 hours)

**File: `OnboardingView.swift`**

Update the main container to orchestrate new pages:

```swift
TabView(selection: $manager.currentPage) {
    OnboardingHeroPage(theme: manager.onboardingData.selectedTheme)
        .tag(0)
    
    OnboardingIntentPage(theme: manager.onboardingData.selectedTheme, manager: manager)
        .tag(1)
    
    OnboardingSetupStackPage(theme: manager.onboardingData.selectedTheme, manager: manager)
        .tag(2)
    
    OnboardingSpotlightPage(theme: manager.onboardingData.selectedTheme)
        .tag(3)
    
    OnboardingFinishPage(
        theme: manager.onboardingData.selectedTheme,
        displayName: manager.onboardingData.displayName,
        manager: manager
    )
    .tag(4)
}
.tabViewStyle(.page(indexDisplayMode: .never))
```

---

### Phase 4: Apply Settings Logic (2 hours)

**File: `OnboardingManager.swift`**

Add completion logic that seeds intelligent defaults:

```swift
func completeOnboarding() {
    // 1. Apply basic personalization (existing)
    // ...
    
    // 2. NEW: Apply intent-based seeds
    if let intent = onboardingData.selectedIntent {
        seedIntentDefaults(intent)
    }
    
    // 3. NEW: Create first task if provided
    if !onboardingData.firstPriorityTask.isEmpty {
        createFirstTask()
    }
    
    // 4. NEW: Apply notification preferences
    applyNotificationStyle()
    
    // 5. Mark complete and navigate
    // ...
}

private func seedIntentDefaults(_ intent: OnboardingIntent) {
    let defaults = intent.suggestedDefaults()
    
    // Adjust settings based on intent
    switch intent {
    case .deepFocus:
        // Seed a 90-min deep work preset
        FocusPresetStore.shared.createDefaultDeepWorkPreset(
            duration: defaults.goalMinutes * 60,
            sound: defaults.sound ?? .lightRainAmbient,
            ambiance: defaults.ambiance ?? .forest
        )
        
    case .smartTasks:
        // Create 2 sample tasks to demonstrate
        TasksStore.shared.createSampleTask(title: "Review today's priorities")
        TasksStore.shared.createSampleTask(title: "Plan tomorrow")
        
    case .aiPlanning:
        // Set AI as default tab? Or show AI welcome tip?
        break
        
    case .ambientStudy:
        // Seed multiple preset variations with different sounds
        break
    }
}

private func createFirstTask() {
    TasksStore.shared.createTask(
        title: onboardingData.firstPriorityTask,
        priority: .high,
        dueDate: Date().addingTimeInterval(86400 * 2) // 2 days from now
    )
}

private func applyNotificationStyle() {
    let prefs = NotificationPreferencesStore.shared
    
    switch onboardingData.notificationStyle {
    case .gentle:
        prefs.enableFocusReminders = true
        prefs.enableStreakAlerts = false
        prefs.enableTaskReminders = false
        
    case .balanced:
        prefs.enableFocusReminders = true
        prefs.enableStreakAlerts = true
        prefs.enableTaskReminders = true
        
    case .silent:
        prefs.enableFocusReminders = false
        prefs.enableStreakAlerts = false
        prefs.enableTaskReminders = false
    }
    
    // Set notification window
    prefs.notificationWindowStart = onboardingData.notificationWindowStart
    prefs.notificationWindowEnd = onboardingData.notificationWindowEnd
}
```

---

### Phase 5: Polish & Testing (4 hours)

1. **Accessibility audit:**
   - VoiceOver labels on all interactive elements
   - Dynamic Type support
   - Reduce Motion respects
   - Semantic grouping

2. **Edge cases:**
   - Rapid tapping on cards (debounce)
   - Backgrounding mid-onboarding (state persistence)
   - Skipping entire flow (still applies defaults)
   - Going back from final page (allow edits)

3. **Analytics instrumentation:**
   - Track which intent selected
   - Track completion rate per page
   - Track auth choice (guest vs sign-in)
   - Track time spent in onboarding

4. **Performance:**
   - Preload next page assets
   - Lazy-load spotlight visuals
   - Optimize particle animations

---

## 📊 SUCCESS METRICS

### Quantitative KPIs
- **Completion rate:** % who finish onboarding (target: >85%)
- **Auth conversion:** % who sign in vs guest (target: >30% sign-in)
- **Pro trial starts:** % who start 7-day trial (target: >15%)
- **Time to value:** Median time from install to first session (target: <2 minutes)
- **Intent distribution:** Which intents are most popular
- **Feature discovery:** % who view all spotlights vs skip

### Qualitative Goals
- Users understand what makes FocusFlow different (AI, sync, premium)
- Users feel confident they've customized the app for their needs
- Users understand Free vs Pro distinction without feeling locked out
- Users trust the premium quality and design polish

---

## 🎨 VISUAL ASSETS NEEDED

### Illustrations & Mockups
1. **AI chat preview:** Animated chat bubbles showing sample AI interaction
2. **Sync animation:** Device-to-cloud-to-device flow visualization
3. **Journey cards:** Sample daily summary cards scrolling
4. **Widgets mockup:** iPhone home screen with FocusFlow widgets + Dynamic Island

### Icons
- All existing system SF Symbols are sufficient
- Potentially custom icons for intent cards (optional enhancement)

### Animations
- Consider Lottie animations for spotlights (optional)
- SVG animations for hero page theme cycling

---

## ⚙️ CONFIGURATION & FLAGS

### Feature Flags (for staged rollout)
```swift
enum OnboardingVersion {
    case legacy  // Current 6-page flow
    case v2      // New adaptive flow
}

struct OnboardingConfig {
    static var currentVersion: OnboardingVersion = .v2
    static var enableIntentBranching: Bool = true
    static var enableSpotlightCarousel: Bool = true
    static var autoAdvanceSpotlights: Bool = true
    static var spotlightDuration: TimeInterval = 5.0
}
```

### A/B Test Variants
- **Control:** Legacy onboarding
- **Variant A:** New onboarding with 4 intents
- **Variant B:** New onboarding with 3 intents (remove "Ambient Study")
- **Variant C:** New onboarding, skip spotlights by default

---

## 📅 ROLLOUT PLAN

### Week 1: Development
- Days 1-2: Data model + OnboardingManager updates
- Days 3-4: Hero, Intent, Setup Stack pages
- Day 5: Spotlight + Finish pages

### Week 2: Polish & Testing
- Days 1-2: Accessibility, animations, edge cases
- Days 3-4: Internal testing, bug fixes
- Day 5: Beta build to TestFlight

### Week 3: Beta Testing
- Small group (50 users) tests new onboarding
- Collect feedback on clarity, time-to-value
- Monitor completion rates and auth conversion

### Week 4: Iteration
- Address feedback
- Polish animations
- Finalize copy

### Week 5: Phased Rollout
- 10% of new installs get v2
- Monitor metrics vs control
- Ramp to 50%, then 100% if metrics improve

---

## 🚀 FUTURE ENHANCEMENTS (Post-Launch)

### Phase 2 Features
1. **Sample AI plan generation:** If user selects "AI Planning" intent, generate a real sample plan via Supabase function (offline-safe fallback)
2. **Preset templates library:** During setup, show gallery of popular preset templates based on intent
3. **Onboarding replay:** Allow users to re-run onboarding from settings to update preferences
4. **Personalized tips:** Show contextual tips in first session based on intent (e.g., "Try voice input in Flow AI")

### Advanced Personalization
- **Time-of-day preferences:** "When do you usually focus?" → Seeds notification window
- **Work style quiz:** "Do you prefer long sprints or short bursts?" → Adjusts preset durations
- **Integration hints:** "Do you use Notion/Todoist/etc?" → Suggest integration (future feature)

---

## 📝 COPY DECK

### Hero Page
**Headline:** Your day, orchestrated.  
**Subheadline:** AI planning • Deep focus • Sync everywhere  
**CTA:** Begin →

### Intent Page
**Headline:** What brings you to FocusFlow?  
**Subheadline:** We'll personalize your experience  

**Intent 1: Deep Focus**  
_Long sessions, zero distractions_

**Intent 2: Smart Tasks**  
_Organize, prioritize, accomplish_

**Intent 3: AI Planning**  
_Let AI orchestrate your day_

**Intent 4: Ambient Study**  
_Soundscapes for concentration_

### Setup Stack
**Card 1:** What should we call you?  
**Card 2:** How much focus time feels right?  
**Card 3:** Choose your atmosphere  
**Card 4:** How should we nudge you?

### Spotlight Carousel
**Spotlight 1:**  
Headline: Your AI productivity copilot  
Subtext: Natural language planning • Smart suggestions • Voice input  
Badge: PRO

**Spotlight 2:**  
Headline: Start here, finish anywhere  
Subtext: Cloud sync • Web app • Cross-device  
Badge: PRO + SIGN IN

**Spotlight 3:**  
Headline: Your productivity story  
Subtext: Daily summaries • Weekly insights • Streak tracking  
Badge: PRO

**Spotlight 4:**  
Headline: Focus without opening the app  
Subtext: Home screen widgets • Dynamic Island timer  
Badge: PRO

### Finish Page
**Headline:** Ready to focus?  
**Subheadline:** Here's what you've chosen:  
**Primary CTA:** Start with my setup ✨  
**Secondary CTA (AI intent):** Try Flow AI free for 7 days  
**Secondary CTA (Tasks intent):** Unlock unlimited tasks with Pro  
**Secondary CTA (Deep Focus intent):** Get all sounds & themes with Pro  
**Guest option:** Continue as guest  
_Local only • Limited features_

---

## ✅ FINAL CHECKLIST

**Data Model:**
- [ ] Add OnboardingIntent enum
- [ ] Add NotificationStyle enum
- [ ] Expand OnboardingData struct
- [ ] Add intent selection methods to OnboardingManager
- [ ] Bump onboardingVersion to 2

**Page Components:**
- [ ] OnboardingHeroPage.swift
- [ ] OnboardingIntentPage.swift
- [ ] OnboardingSetupStackPage.swift (with 4 card types)
- [ ] OnboardingSpotlightPage.swift
- [ ] OnboardingFinishPage.swift

**Logic:**
- [ ] seedIntentDefaults() method
- [ ] createFirstTask() method
- [ ] applyNotificationStyle() method
- [ ] Update completeOnboarding() flow

**Polish:**
- [ ] All animations implemented
- [ ] Haptic feedback on key interactions
- [ ] VoiceOver labels
- [ ] Reduce Motion support
- [ ] Loading states for async operations
- [ ] Error handling (e.g., AI plan generation timeout)

**Testing:**
- [ ] Test all 4 intent paths
- [ ] Test skip functionality
- [ ] Test back navigation
- [ ] Test with VoiceOver
- [ ] Test on various device sizes
- [ ] Test guest vs sign-in paths
- [ ] Test notification permission flow

**Assets:**
- [ ] Spotlight visuals (4 images/animations)
- [ ] Optional: Custom intent icons
- [ ] Optional: Lottie animations

**Analytics:**
- [ ] Track intent selection
- [ ] Track page completion rates
- [ ] Track auth conversion
- [ ] Track Pro trial starts
- [ ] Track time in onboarding

---

## 🎯 SUMMARY

This redesign transforms onboarding from a generic walkthrough into a **value-driven, adaptive experience** that:

1. **Establishes premium positioning** from first frame
2. **Discovers user intent** and personalizes accordingly
3. **Showcases flagship features** (AI, sync, widgets, journey)
4. **Seeds intelligent defaults** based on user choices
5. **Makes Free vs Pro transparent** without being pushy
6. **Reduces time-to-first-value** with smart setup

**Key Innovation:** Intent-based branching means every user gets a customized experience that matches their goals, making the app feel purpose-built for them from day one.

**Expected Impact:**
- 🔺 +15-20% completion rate
- 🔺 +10-15% auth conversion
- 🔺 +5-10% Pro trial starts
- 🔺 Significantly improved feature discovery
- 🔺 Clearer value communication → better retention

---

**Status:** Ready for development approval ✅  
**Next Step:** Review with team, then begin Phase 1 implementation
