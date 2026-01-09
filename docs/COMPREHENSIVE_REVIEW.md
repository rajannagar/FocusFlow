# FocusFlow Comprehensive Review and App Store Readiness

Last Updated: January 9, 2026
Scope: Full codebase (iOS app, widgets, Supabase backend, marketing site), documentation, policies, and release readiness.

---

## Executive Summary

FocusFlow is a well-architected SwiftUI iOS app with a modern Supabase V2 sync stack, StoreKit subscriptions, polished UI/UX, widgets, and a Next.js marketing site. Core wiring looks consistent and intentional. Most documentation is current. A few critical items require attention before App Store submission:

- Secrets committed in the app bundle: Supabase URL and anon key in [FocusFlow/Info.plist](FocusFlow/Info.plist#L1-L200). Move to secure config.
- Supabase Edge `ai-chat` function JWT verification disabled in [supabase/config.toml](supabase/config.toml). Enable verification to prevent public misuse.
- Remote stats update in [SessionsSyncEngine](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift#L160-L220) still has TODOs for `currentStreak`, `totalXp`, `currentLevel`.
- Terminal environment broken on this Mac due to `.zprofile` referencing Homebrew path; local build/verify currently blocked.
- App Store URL on the website is placeholder in [focusflow-site/lib/constants.ts](focusflow-site/lib/constants.ts#L1-L80); update when live.
- Privacy Policy/Terms are strong and accurate; minor improvements suggested below (static "Last updated" date, clearer data categories for App Privacy).

---

## Architecture & Wiring

- App entry: [FocusFlow/App/FocusFlowApp.swift](FocusFlow/App/FocusFlowApp.swift) initializes Supabase, Auth, Sync Coordinator, and local managers. Deep link handling supports `focusflow://` and `ca.softcomputers.FocusFlow://`.
- Launch flow and root switcher: [FocusFlow/App/FocusFlowApp.swift](FocusFlow/App/FocusFlowApp.swift#L1-L120) + `RootView` toggles onboarding vs main content; integrates a branded launch screen ([FocusFlow/App/FocusFlowLaunchView.swift](FocusFlow/App/FocusFlowLaunchView.swift)).
- Main tabs and auth gating: [FocusFlow/App/ContentView.swift](FocusFlow/App/ContentView.swift). Uses `AuthManagerV2` state machine (`.guest`, `.signedIn`, `.signedOut`). Contains robust guest→account migration (persist guest data, show migration sheet).
- Global sync signaling: [FocusFlow/App/AppSyncManager.swift](FocusFlow/App/AppSyncManager.swift) publishes refresh triggers, session completion events, level-up checks, streak updates.
- StoreKit Pro entitlement: [FocusFlow/StoreKit/ProEntitlementManager.swift](FocusFlow/StoreKit/ProEntitlementManager.swift) handles product loading, purchase, restore, manage subscriptions.
- Notifications & widget sync: [FocusFlow/App/AppDelegate.swift](FocusFlow/App/AppDelegate.swift) delegates UNUserNotificationCenter, clears completion notifications, triggers widget sync.
- Premium visual system: [FocusFlow/App/PremiumAppBackground.swift](FocusFlow/App/PremiumAppBackground.swift) offers consistent themed background used across premium surfaces.

Observations: Initialization order is clear; managers and stores are warmed early, and notification reconciliation is handled on launch. Deep link routing posts events to `NotificationCenterManager.navigateToDestination` which is consumed in `ContentView`. Good separation between local/state and cloud sync.

---

## iOS App Review

- Entry & startup: [FocusFlow/App/FocusFlowApp.swift](FocusFlow/App/FocusFlowApp.swift) — clean initialization, good use of `@UIApplicationDelegateAdaptor`, environment objects, and async reconciliation of notifications.
- Deep link handling: Auth links routed to Supabase, widget links map to navigation and actions (start/pause/resume/preset selection). See [FocusFlow/App/FocusFlowApp.swift](FocusFlow/App/FocusFlowApp.swift#L60-L220).
- Auth state and migration: [FocusFlow/App/ContentView.swift](FocusFlow/App/ContentView.swift#L1-L200) tracks guest→signedIn transitions and persist guest data directly to guest keys to avoid races; shows [DataMigrationSheet] when needed. Solid.
- Global sync/XP/streak: [FocusFlow/App/AppSyncManager.swift](FocusFlow/App/AppSyncManager.swift) computes XP and levels; triggers UI refreshes; posts notifications for components.
- Info.plist: [FocusFlow/Info.plist](FocusFlow/Info.plist) contains URL schemes (app + Google), Spotify/YoutubeMusic queries, microphone and speech usage strings, background modes (audio/fetch). Contains Supabase URL and anon key — should be removed from the repo and injected via build configs.
- Theming & visuals: Background system and section styles provide coherent premium feel, used by launch, profile, paywall.
- Gating & Pro tiers: As documented in [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md), features are gated per Free vs Pro. UX triggers for paywall contexts are wired.

Potential gaps:
- Stats upsert TODOs: See [FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift#L160-L220) for `currentStreak`, `totalXp`, `currentLevel`. These can read from `AppSyncManager` or `ProgressStore` to keep remote in sync.
- Secrets management: `SUPABASE_URL` and `SUPABASE_ANON_KEY` in [FocusFlow/Info.plist](FocusFlow/Info.plist) must be externalized.

---

## Widgets & Live Activity

- WidgetKit bundle: [FocusFlowWidgets/FocusFlowWidgetsBundle.swift](FocusFlowWidgets/FocusFlowWidgetsBundle.swift) (bundle entry) and views in [FocusFlowWidgets/FocusFlowWidget.swift](FocusFlowWidgets/FocusFlowWidget.swift) implement small/medium tiles with timer ring, streak, preset controls, and deep links via `focusflow://`.
- Widget data provider: [FocusFlowWidgets/WidgetDataProvider.swift](FocusFlowWidgets/WidgetDataProvider.swift) syncs shared defaults and exposes session/preset info to widgets.
- Live Activity: [FocusFlowWidgets/FocusSessionLiveActivity.swift](FocusFlowWidgets/FocusSessionLiveActivity.swift) integrates with Lock Screen / Dynamic Island.
- Intents: [FocusFlowWidgets/StartFocusIntent.swift](FocusFlowWidgets/StartFocusIntent.swift), [FocusFlowWidgets/AppIntent.swift](FocusFlowWidgets/AppIntent.swift) map invokeable actions.

Observations: The widget design is consistent; refresh intervals adapt based on session status; deep links map back to navigation and start/resume/pause actions.

---

## Cloud Sync (Supabase V2)

- Engines & coordinator: `SessionsSyncEngine`, `TasksSyncEngine`, `PresetsSyncEngine`, `SettingsSyncEngine` orchestrated by `SyncCoordinator` with a `SyncQueue` and timestamp merges. See Infrastructure paths under `FocusFlow/Infrastructure/Cloud/`.
- Stats upsert: [FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift#L160-L220) updates `user_stats` but has 3 TODO placeholders.
- Account deletion: Edge function [supabase/functions/delete-user/index.ts](supabase/functions/delete-user/index.ts) verifies JWT with service role and deletes data from all key tables, then deletes auth user. CORS handled.
- AI Chat: Edge function [supabase/functions/ai-chat/index.ts](supabase/functions/ai-chat/index.ts) proxies OpenAI requests. Reads `OPENAI_API_KEY` from environment. Designed to require Authorization header.
- Function config: [supabase/config.toml](supabase/config.toml) sets `verify_jwt = false` for `ai-chat` — security risk (publicly callable if endpoint exposed). Should be `true` or the function should perform robust JWT validation.

Observations: Sync gating aligns with Pro status. Merge strategies documented in [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md). Edge functions are well-structured with proper error handling.

---

## StoreKit & Monetization

- Entitlements: [FocusFlow/StoreKit/ProEntitlementManager.swift](FocusFlow/StoreKit/ProEntitlementManager.swift) uses StoreKit 2 to load products, verify entitlements, and restore.
- Product IDs: `com.softcomputers.focusflow.pro.monthly` and `com.softcomputers.focusflow.pro.yearly` defined in code; ensure they match App Store Connect.
- Paywall & contexts: Implemented per plan. Check that all gated surfaces call the paywall with context (theme, sound, ambiance, presets, tasks, history, XP/levels, journey, widgets, live activity, external music, cloud sync).

---

## Website (Next.js) Review

- Stack: Next.js 16, React 19, Tailwind CSS v4 classes. See [focusflow-site/package.json](focusflow-site/package.json).
- Privacy Policy: [focusflow-site/app/privacy/page.tsx](focusflow-site/app/privacy/page.tsx) + [focusflow-site/app/privacy/PrivacyClient.tsx](focusflow-site/app/privacy/PrivacyClient.tsx).
  - Content accurately describes Guest vs Signed-in, data categories, sharing, rights, account deletion steps, children’s privacy, changes.
  - Suggest changing dynamic "Last updated" to a fixed ISO date per release for auditability.
  - Consider adding a brief “Data Collected” mapping aligned with Apple App Privacy categories.
- Terms of Service: [focusflow-site/app/terms/page.tsx](focusflow-site/app/terms/page.tsx) + [focusflow-site/app/terms/TermsClient.tsx](focusflow-site/app/terms/TermsClient.tsx).
  - Content is comprehensive: service description, accounts, Pro subscription terms (billing, trial, renewal, cancellation, refunds), acceptable use, IP, user content, privacy, deletion, disclaimers, liability, governing law, contact.
  - Matches product capabilities stated across docs.
- SEO utility: [focusflow-site/lib/seo.ts](focusflow-site/lib/seo.ts); constants: [focusflow-site/lib/constants.ts](focusflow-site/lib/constants.ts). Update `APP_STORE_URL` when live.

---

## Documentation Audit

- Index & summaries: [README.md](README.md), [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md), [COMPLETE_SUMMARY.md](COMPLETE_SUMMARY.md) — broadly current; dates show Jan 7, 2026.
- Technical docs: [ARCHITECTURE.md](ARCHITECTURE.md), [CLOUD_SYNC.md](CLOUD_SYNC.md), [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md), [API_REFERENCE.md](API_REFERENCE.md) — align with the Supabase V2 approach.
- Feature breakdowns: [FEATURES.md](FEATURES.md), [PRO_VS_FREE.md](PRO_VS_FREE.md), onboarding plans: [ONBOARDING_IMPLEMENTATION_SUMMARY.md](ONBOARDING_IMPLEMENTATION_SUMMARY.md), [ONBOARDING_REDESIGN_PLAN.md](ONBOARDING_REDESIGN_PLAN.md).
- AI flow: [AI_FLOW.md](AI_FLOW.md) describes assistant behavior and tooling.

Observations: Docs are thorough and mostly up-to-date. Keep the dates consistent across docs for release cadence. Ensure App Store metadata mirrors claims (e.g., numbers of sounds/backgrounds/themes).

---

## Security & Compliance

- Secrets exposure:
  - `SUPABASE_URL` and `SUPABASE_ANON_KEY` in [FocusFlow/Info.plist](FocusFlow/Info.plist). Move to `XCConfig` with environment-driven injection per scheme/config or use a runtime config service; avoid committing keys to source.
  - OpenAI key is in Supabase secrets (good) — ensure `ai-chat` verifies JWT. Update [supabase/config.toml](supabase/config.toml) to `verify_jwt = true` for `ai-chat`.
- Apple App Privacy: Match data categories with what’s stored (focus sessions, tasks, presets, settings). You declare Microphone/Speech usage in [FocusFlow/Info.plist](FocusFlow/Info.plist#L1-L200) — ensure feature references (voice input) exist and are Pro-gated appropriately.
- LSApplicationQueriesSchemes: Spotify and YouTube Music listed in [FocusFlow/Info.plist](FocusFlow/Info.plist). If integrating Apple Music, ensure compliance with entitlement requirements. Ensure schemes only include necessary apps.
- Notifications: Foreground suppression of completion banners handled in [FocusFlow/App/AppDelegate.swift](FocusFlow/App/AppDelegate.swift#L1-L200). Ensure recommended UX for in-app overlays meets App Store guidelines.

---

## Bugs, Risks, and Gaps

- Stats TODOs: Remote stats upsert needs integration with local computed values — see [SessionsSyncEngine](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift#L160-L220).
- JWT verification off for `ai-chat`: [supabase/config.toml](supabase/config.toml) — risk of public invocation. Fix before launch.
- Secrets in repo: Supabase URL/anon key in [FocusFlow/Info.plist](FocusFlow/Info.plist). Remove and inject per build.
- Terminal environment: Local zsh retries failing due to `.zprofile` pointing to `/opt/homebrew/bin/brew`; macOS environment broken. Fix developer machine to verify builds.
- App Store URL placeholder: [focusflow-site/lib/constants.ts](focusflow-site/lib/constants.ts#L1-L80) — replace when approved/live.

---

## Improvements & Feature Add‑Ons

- Stats sync completeness: Wire `currentStreak`, `totalXp`, `currentLevel` using `AppSyncManager` / `ProgressStore`, and upsert to `user_stats`.
- Secrets & config hygiene: Move Supabase keys to `XCConfig` or use a secure config provider. Optionally add `FirebaseAppCheck` or supabase RLS hardened policies for additional protection.
- App Privacy section (website): Add an explicit “Data Collected” grid aligned to Apple categories (Contact Info, Identifiers, Usage Data) and state retention and linkage (not linked to identity where appropriate).
- Accessibility: Verify Dynamic Type, VoiceOver labels, contrasts in premium backgrounds. Add `UIAccessibility` labels on key controls.
- Crash resilience: Add lightweight error reporting (e.g., privacy-preserving telemetry or Sentry with opted-in capture) — ensure no PII and that policies disclose it.
- Marketing site: Add an FAQs page and a “Support” page linking to the email in [focusflow-site/lib/constants.ts](focusflow-site/lib/constants.ts).
- Onboarding: If voice input is described, ensure clear opt-in and privacy messaging.

---

## App Store Readiness Checklist

- Bundle & identifiers:
  - Confirm URL schemes in [FocusFlow/Info.plist](FocusFlow/Info.plist) (app, Google) and LSApplicationQueriesSchemes are minimal.
  - Ensure `ITSAppUsesNonExemptEncryption` is accurately set (currently `false`).
- Permissions & usage strings:
  - Microphone: [FocusFlow/Info.plist](FocusFlow/Info.plist) — string present.
  - Speech Recognition: [FocusFlow/Info.plist](FocusFlow/Info.plist) — string present.
  - Notifications: Categories registered in [FocusFlow/App/AppDelegate.swift](FocusFlow/App/AppDelegate.swift).
- StoreKit:
  - Product IDs in [ProEntitlementManager.swift](FocusFlow/StoreKit/ProEntitlementManager.swift) match App Store Connect.
  - Paywall and purchase flows tested on Sandbox.
- Supabase:
  - RLS policies enforced for all tables; JWT verification enabled for all functions. Update [supabase/config.toml](supabase/config.toml).
  - `delete-user` function deployed and hooked to in-app settings.
- Widgets & Live Activity:
  - Verify functionality across iOS versions and small/medium families ([FocusFlowWidgets](FocusFlowWidgets)).
- Website:
  - Privacy Policy and Terms pages complete ([focusflow-site/app/privacy](focusflow-site/app/privacy), [focusflow-site/app/terms](focusflow-site/app/terms)).
  - Update `APP_STORE_URL` when live and ensure SEO metadata reflects production domain.
- App Privacy (App Store Connect):
  - Map stored data types and categories; declare data usage, retention, and linkage.
- QA:
  - Device testing across iPhone/iPad sizes, light/dark mode, background audio, phone calls interruptions.
  - Guest→Sign-in migration flows; Pro gating correctness.

---

## Action Items (Prioritized)

1. Secrets hygiene: Remove Supabase URL/anon key from [FocusFlow/Info.plist](FocusFlow/Info.plist) and inject via `XCConfig`/build settings.
2. Security: Set `verify_jwt = true` for `ai-chat` in [supabase/config.toml](supabase/config.toml) and ensure functions validate JWT robustly.
3. Stats completeness: Implement `currentStreak`, `totalXp`, `currentLevel` in [FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift#L160-L220) using `ProgressStore` and `AppSyncManager` utilities.
4. Website: Replace placeholder App Store URL in [focusflow-site/lib/constants.ts](focusflow-site/lib/constants.ts#L1-L80) upon approval.
5. App Privacy: Add a “Data Collected” mapping section to Privacy Policy and prepare App Store Connect privacy answers accordingly.
6. Dev environment: Fix local `.zprofile` Homebrew path; install Homebrew or correct the path to enable terminal builds.
7. Final QA: Run through subscription flows, migration, widgets, and deep links on devices.

---

## Notable Files

- App entry & routing: [FocusFlow/App/FocusFlowApp.swift](FocusFlow/App/FocusFlowApp.swift), [FocusFlow/App/AppDelegate.swift](FocusFlow/App/AppDelegate.swift), [FocusFlow/App/ContentView.swift](FocusFlow/App/ContentView.swift)
- Sync & stats: [FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift](FocusFlow/Infrastructure/Cloud/Engines/SessionsSyncEngine.swift)
- StoreKit: [FocusFlow/StoreKit/ProEntitlementManager.swift](FocusFlow/StoreKit/ProEntitlementManager.swift)
- Widgets: [FocusFlowWidgets/FocusFlowWidget.swift](FocusFlowWidgets/FocusFlowWidget.swift), [FocusFlowWidgets/WidgetDataProvider.swift](FocusFlowWidgets/WidgetDataProvider.swift)
- Site policies: [focusflow-site/app/privacy/PrivacyClient.tsx](focusflow-site/app/privacy/PrivacyClient.tsx), [focusflow-site/app/terms/TermsClient.tsx](focusflow-site/app/terms/TermsClient.tsx)
- Edge functions: [supabase/functions/delete-user/index.ts](supabase/functions/delete-user/index.ts), [supabase/functions/ai-chat/index.ts](supabase/functions/ai-chat/index.ts)

---

If you want, I can implement the stats upsert fix, add secure config scaffolding for Supabase keys, and update Supabase function config now.
