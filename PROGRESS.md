# Masal Amca — Progress ledger

## 2026-03-27

- **Epic 1–8 (initial implementation):** Dreamscape theme (`masalThemeManager` / `masalChildProfileManager` env keys), components, tab shell, SwiftData `ChildProfile` + `Story`, CloudKit-first ModelContainer with local fallback, onboarding + paywall UI, home / library / settings, story player + mixer, `StoryService` + proxy contract, `SubscriptionManager` (StoreKit 2 + free tier quota), placeholder WAV loops, variable fonts, edge Worker (`edge/`).
- **Build:** `xcodebuild -scheme MasalAmca -destination 'platform=iOS Simulator,name=iPhone 17' build` — **SUCCEEDED**.
- **Tests:** `MasalAmcaTests` + `MasalAmcaUITests` targets added; shared scheme `MasalAmca.xcscheme` runs both. `xcodebuild build-for-testing -scheme MasalAmca -destination 'platform=iOS Simulator,name=iPhone 17'` — **SUCCEEDED**. Run `xcodebuild test` when the simulator can boot (host resource limits may block automated runs).
- **Manual QA:** See root `MANUAL_TESTING.md` (200+ checklist items).

### Blockers / next

- Configure App Store Connect products with IDs matching `AppConfiguration.ProductID`.
- Set `ProxyBaseURL`, `ProxyAuthToken`, `ElevenLabsVoiceID` in **Info.plist** (or XCConfig) for real API runs.
- Provision CloudKit container in Apple Developer portal when enabling sync for premium.
