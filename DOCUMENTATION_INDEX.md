# FocusFlow Documentation Index

**Complete documentation organized by topic**

---

## 📚 Documentation Files

### **1. [README.md](README.md)** - START HERE
- **Length**: ~500 lines | ~8,000 words
- **Topics**: 
  - Quick navigation guide
  - System architecture overview
  - Feature categories
  - Platform support
  - Core features breakdown
  - Data storage strategy
  - Project structure
  - Getting started for developers

**Read this first to understand FocusFlow at a high level.**

---

### **2. [ARCHITECTURE.md](ARCHITECTURE.md)** - Technical Deep Dive
- **Length**: ~600 lines | ~9,500 words
- **Topics**:
  - Complete architecture diagram
  - 5 design patterns used
  - Core components (10 detailed):
    - AuthManagerV2
    - SyncCoordinator
    - TasksStore
    - FocusTimerViewModel
    - JourneyManager
    - FlowService
    - ProGatingHelper
    - And more...
  - Sync architecture deep dive
  - AI architecture
  - Data layer breakdown
  - Performance optimizations
  - Testing strategy
  - Security checklist

**Read this to understand how everything works internally.**

---

### **3. [FEATURES.md](FEATURES.md)** - Feature Documentation
- **Length**: ~700 lines | ~10,500 words
- **Topics**:
  - 10 feature categories
  - Focus Timer (detailed)
  - Ambient Sounds (11 total with descriptions)
  - Ambient Backgrounds (14 total with descriptions)
  - Focus Presets
  - Task Management (creation, display, completion, deletion, reminders)
  - Progress Tracking (XP, Levels, Streaks, Journey)
  - Focus AI (Flow) - All capabilities
  - Cloud Sync (how it works)
  - Notifications (local + in-app)
  - Customization (themes, settings)
  - Onboarding flow
  - Widgets & Home Screen
  - Web Dashboard
  - Social/Sharing (future)

**Read this to understand every feature from a user perspective.**

---

### **4. [PRO_VS_FREE.md](PRO_VS_FREE.md)** - Pricing & Monetization
- **Length**: ~650 lines | ~9,800 words
- **Topics**:
  - Pricing overview
  - Free tier (comprehensive feature list)
  - Pro tier ($59.99/year) - all features
  - Feature limits comparison table
  - Cloud sync behavior (free vs pro)
  - Pro gating implementation
  - Paywall contexts (14 types)
  - Strategic monetization insights
  - Conversion triggers
  - Free to pro user journey
  - Testing checklist
  - Communication strategies
  - Subscription management

**Read this to understand monetization and how features are gated.**

---

### **5. [CLOUD_SYNC.md](CLOUD_SYNC.md)** - Sync System
- **Length**: ~550 lines | ~8,200 words
- **Topics**:
  - Architecture overview
  - 3 sync modes (no sync, one-time pull, full sync)
  - Sync coordination flow
  - 4 sync engines (detailed):
    - TasksSyncEngine
    - SessionsSyncEngine
    - PresetsSyncEngine
    - SettingsSyncEngine
  - Offline-safe sync queue
  - Conflict resolution strategy
  - Security & privacy
  - Performance benchmarks
  - Merge strategy for long offline
  - Testing sync
  - Common issues & solutions
  - Sync monitoring

**Read this to understand cloud synchronization in detail.**

---

### **6. [AI_FLOW.md](AI_FLOW.md)** - AI Assistant System
- **Length**: ~550 lines | ~8,000 words
- **Topics**:
  - What is Flow (introduction)
  - Complete architecture
  - Message flow (step-by-step)
  - FlowService API communication
  - FlowChatViewModel state management
  - Voice input system
  - Available actions (7 types)
  - Context building strategy
  - System prompt
  - Streaming responses
  - Proactive system (hints & nudges)
  - UI components
  - Security & privacy
  - Configuration
  - Testing Flow
  - Example conversations (3)
  - Common issues

**Read this to understand the AI assistant in depth.**

---

### **7. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Database Structure
- **Length**: ~400 lines | ~4,500 words
- **Topics**:
  - Tables overview
  - Table definitions (6 tables):
    - users
    - tasks
    - task_completions
    - focus_sessions
    - focus_presets
    - user_settings
  - Each table with:
    - SQL DDL
    - Column descriptions
    - Constraints
    - Indexes
    - RLS policies
  - Helper functions
  - Security policies summary
  - Optional views
  - Migrations info

**Read this to understand the database schema.**

---

### **8. [API_REFERENCE.md](API_REFERENCE.md)** - API Documentation
- **Length**: ~350 lines | ~3,500 words
- **Topics**:
  - API overview
  - Authentication (Bearer token)
  - REST API endpoints:
    - Tasks (CRUD)
    - Focus sessions (CRUD)
    - Focus presets (CRUD)
    - User settings (CRUD)
  - Edge functions:
    - Flow AI endpoint
    - Whisper transcription (future)
  - Query examples
  - Rate limiting
  - Error handling
  - Testing API (cURL & Swift)
  - SDK documentation links

**Read this to understand API usage.**

---

## 🗂️ Quick Reference by Role

### **For Product Managers**
1. Start: [README.md](README.md)
2. Then: [PRO_VS_FREE.md](PRO_VS_FREE.md)
3. Deep dive: [FEATURES.md](FEATURES.md)

### **For iOS Developers**
1. Start: [README.md](README.md)
2. Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
3. Features: [FEATURES.md](FEATURES.md)
4. Sync: [CLOUD_SYNC.md](CLOUD_SYNC.md)
5. AI: [AI_FLOW.md](AI_FLOW.md)
6. Database: [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)

### **For Backend Engineers**
1. Database: [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
2. API: [API_REFERENCE.md](API_REFERENCE.md)
3. Sync: [CLOUD_SYNC.md](CLOUD_SYNC.md)
4. Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)

### **For QA/Testers**
1. Features: [FEATURES.md](FEATURES.md)
2. Pro vs Free: [PRO_VS_FREE.md](PRO_VS_FREE.md)
3. Sync: [CLOUD_SYNC.md](CLOUD_SYNC.md)
4. Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) (for edge cases)

### **For New Team Members**
1. Start: [README.md](README.md)
2. Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
3. Features: [FEATURES.md](FEATURES.md)
4. Your role's section from above

---

## 📊 Documentation Statistics

```
Total Files: 8 markdown files
Total Words: ~54,000 words
Total Lines: ~4,500 lines
Total Size: ~150 KB

Breakdown:
├─ ARCHITECTURE.md      ~9,500 words
├─ FEATURES.md          ~10,500 words
├─ PRO_VS_FREE.md       ~9,800 words
├─ CLOUD_SYNC.md        ~8,200 words
├─ AI_FLOW.md           ~8,000 words
├─ README.md            ~8,000 words
├─ DATABASE_SCHEMA.md   ~4,500 words
└─ API_REFERENCE.md     ~3,500 words
```

---

## 🔍 Search by Topic

### **Authentication & Authorization**
- [ARCHITECTURE.md](ARCHITECTURE.md#authmanagerv2-authentication-state-machine) - AuthManagerV2
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md#-table-users) - Users table
- [CLOUD_SYNC.md](CLOUD_SYNC.md#authentication) - Auth in sync
- [API_REFERENCE.md](API_REFERENCE.md#-authentication) - API auth

### **Focus Timer & Sessions**
- [FEATURES.md](FEATURES.md#-core-focus-feature) - Focus timer details
- [FEATURES.md](FEATURES.md#-ambient-sounds) - Audio library
- [FEATURES.md](FEATURES.md#-ambient-visual-backgrounds) - Backgrounds
- [ARCHITECTURE.md](ARCHITECTURE.md#focustimerviewmodel-session-management) - Implementation

### **Task Management**
- [FEATURES.md](FEATURES.md#-task-management-feature) - Task features
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md#-table-tasks) - Tasks table
- [ARCHITECTURE.md](ARCHITECTURE.md#tasksstore-task-data-management) - TasksStore

### **Progress Tracking**
- [FEATURES.md](FEATURES.md#-progress-tracking-pro-only) - XP, levels, streaks
- [ARCHITECTURE.md](ARCHITECTURE.md#journeymanager-analytics--progress) - JourneyManager
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md#-table-user_settings) - Settings table

### **AI Assistant (Flow)**
- [AI_FLOW.md](AI_FLOW.md) - Complete AI documentation
- [FEATURES.md](FEATURES.md#-focus-ai-assistant-flow) - Feature overview
- [ARCHITECTURE.md](ARCHITECTURE.md#-ai-architecture-flow) - Architecture

### **Cloud Synchronization**
- [CLOUD_SYNC.md](CLOUD_SYNC.md) - Complete sync documentation
- [README.md](README.md#-cloud-sync-pro-only) - Sync overview
- [ARCHITECTURE.md](ARCHITECTURE.md#-sync-architecture-deep-dive) - Architecture

### **Monetization & Pro**
- [PRO_VS_FREE.md](PRO_VS_FREE.md) - Complete pricing guide
- [FEATURES.md](FEATURES.md#free-vs-pro) - Feature comparison tables

### **Database & API**
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Complete schema
- [API_REFERENCE.md](API_REFERENCE.md) - API docs

### **Widgets & Home Screen**
- [FEATURES.md](FEATURES.md#-widgets--home-screen) - Widget details
- [README.md](README.md#-widgets--home-screen) - Quick reference

### **Notifications**
- [FEATURES.md](FEATURES.md#-notifications-system) - Notification details
- [ARCHITECTURE.md](ARCHITECTURE.md#-notifications) - Architecture

### **Themes & Customization**
- [FEATURES.md](FEATURES.md#-customization) - Customization options
- [PRO_VS_FREE.md](PRO_VS_FREE.md#-10-total-themes-8-premium) - Theme list

---

## 🚀 Getting Started Paths

### **Path 1: "I want to understand the whole app" (2-3 hours)
1. [README.md](README.md) - Overview (30 min)
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Technical design (1 hour)
3. [FEATURES.md](FEATURES.md) - All features (45 min)
4. [PRO_VS_FREE.md](PRO_VS_FREE.md) - Monetization (30 min)

### **Path 2: "I need to implement a feature" (1-2 hours)
1. [FEATURES.md](FEATURES.md) - Feature details (30 min)
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Relevant components (30 min)
3. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Data model (20 min)
4. [API_REFERENCE.md](API_REFERENCE.md) - API if needed (15 min)

### **Path 3: "I need to fix a bug" (30-60 min)
1. [README.md](README.md#-system-architecture-at-a-glance) - Architecture diagram
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Relevant component
3. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) or [API_REFERENCE.md](API_REFERENCE.md) - Data if needed

### **Path 4: "I need to set up the backend" (1-2 hours)
1. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Create tables
2. [API_REFERENCE.md](API_REFERENCE.md) - API setup
3. [CLOUD_SYNC.md](CLOUD_SYNC.md) - Sync infrastructure
4. [AI_FLOW.md](AI_FLOW.md#-configuration) - AI setup

---

## ✅ Documentation Completeness

| Topic | Coverage | Status |
|-------|----------|--------|
| Architecture | 100% | ✅ Complete |
| Features | 100% | ✅ Complete |
| Pricing/Monetization | 100% | ✅ Complete |
| Cloud Sync | 100% | ✅ Complete |
| AI System | 100% | ✅ Complete |
| Database | 100% | ✅ Complete |
| API | 100% | ✅ Complete |
| Testing | 90% | ⚠️ Partial |
| Deployment | 0% | ❌ Not covered |
| Troubleshooting | 50% | ⚠️ Partial |

---

## 📝 Documentation Update Process

**When to update**:
- Feature added/changed
- Architecture modified
- API endpoint added
- Database schema changed
- Pro pricing changed
- Critical bug fix

**How to update**:
1. Find relevant .md file
2. Update section
3. Update table of contents if needed
4. Commit with clear message
5. Update this INDEX

---

## 🔗 External Resources

### **Official Documentation**
- [Supabase Docs](https://supabase.com/docs)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### **Helpful Guides**
- [App Store Connect](https://appstoreconnect.apple.com)
- [Xcode Help](https://help.apple.com/xcode)
- [Swift.org](https://swift.org)

---

## 🎯 Quick Navigation

**Just created an account?** → [README.md](README.md)  
**Need to implement a feature?** → [FEATURES.md](FEATURES.md)  
**Fixing a sync bug?** → [CLOUD_SYNC.md](CLOUD_SYNC.md)  
**Configuring the backend?** → [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)  
**Building the AI feature?** → [AI_FLOW.md](AI_FLOW.md)  
**Pricing questions?** → [PRO_VS_FREE.md](PRO_VS_FREE.md)  
**API integration?** → [API_REFERENCE.md](API_REFERENCE.md)  

---

**Last Updated**: January 7, 2026  
**Documentation Version**: 2.0  
**Status**: Complete & Current
