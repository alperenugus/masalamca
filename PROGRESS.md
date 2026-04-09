# Masal Amca — Progress Ledger

## 2026-04-09 — v1.3 Prompt Logic Migration to Worker

### Architecture changes
- **Worker-owned prompts**: All prompt logic (system prompt, user prompt template, story seeds, theme hints) moved from iOS to the Cloudflare Worker. iOS sends structured `{ child_name, age_group, themes }` instead of full `messages` arrays. Prompts can be iterated via `wrangler deploy` without App Store release.
- **New worker source files**: `edge/src/prompts.ts` (system + user prompts), `edge/src/themes.ts` (24 theme definitions with hints), `edge/src/storySeeds.ts` (~40 places, ~40 characters, 18 plot hooks, 18 family threads, 18 objects).
- **Simplified iOS**: `PromptOrchestrator` reduced to a thin DTO builder (`StoryRequestDTO`). Prompt builder methods, `StoryGenerateRequestDTO.Message` type removed.
- **Removed versioning**: `X-Client-Version` header and ElevenLabs fallback removed. Single TTS path (Google Gemini Flash TTS).
- **Richer story variety**: Worker seeds include plot hooks, family threads, and objects beyond the original iOS places/characters — woven into user prompt via variation block.

### Documentation
- Updated all docs to reflect worker-owned prompt architecture.
- Updated `AGENTS.md` rule 8, `ARCHITECTURE.md`, `DEVELOPER_SETUP.md`, `MasalAmca.md`, `Project Wiki`, `API_USAGE_REPORT.md`, `edge/README.md`.

---

## 2026-04-09 — v1.2 TTS Migration & Documentation Update

### Architecture changes (superseded by v1.3 migration above)
- **TTS migration**: Migrated from ElevenLabs Flash v2.5 to **Google Gemini Flash TTS** (`gemini-2.5-flash-tts`) — ~75% cost reduction with style-prompted narration and Turkish GA support.
- **Theme category system**: 24 themes organized into 5 categories (`StoryThemeCategory`).
- **Expanded content variety**: Story seeds expanded.

### Bug fixes
- **Story/audio mismatch after generation**: Fixed audio from previous story playing when new story opens. `StoryPlayerView` now verifies both story ID and title match before skipping audio reload.
- **Conditional post-generation behavior**: If user stays on home tab during generation, story auto-plays. If user switches tabs, only a toast is shown — no unwanted tab navigation.
- **White noise premium skip**: Next/previous buttons in `WhiteNoisePlayerView` now automatically skip past premium sounds for free users instead of showing parental gate.

### New features
- **9 value education themes**: Dürüstlük, Doğruluk, Sevgi, Çalışkanlık, Saygı, Cömertlik, Adalet, Sorumluluk, Yardımseverlik.
- **Category-based theme UI**: Expandable accordion with per-category "select all" and theme count badges.

### Documentation
- Created `MasalAmca.md` — business overview, features, architecture summary.
- Created `docs/FINANCIAL_ANALYSIS.md` — detailed cost model, break-even analysis, plan comparison.
- Updated `AGENTS.md` — new rules for prompt ownership, post-generation behavior, premium skip.
- Updated `ARCHITECTURE.md` — full story generation flow diagram, theme system, cost model reference.
- Updated `DEVELOPER_SETUP.md` — pure proxy setup, Flash v2.5 model, 24 themes.
- Updated `edge/README.md` — pure proxy architecture, messages-based API, endpoint docs.
- Updated `docs/API_USAGE_REPORT.md` — corrected architecture, Flash v2.5 pricing.
- Updated `Project Wiki: Masal Amca.md` — current feature set and financials.

---

## 2026-04-08 — v1.1 Release

### Bug fixes
- **iOS 17 deployment target** for all targets (was 26.0). iOS-only (removed macOS/visionOS).
- **Audio session**: Removed `.mixWithOthers` — lock screen Now Playing card now appears for both stories and white noise.
- **Singleton audio services**: `AudioPlayerService` and `MixerEngine` moved to app-level `@State` in `MasalAmcaApp`. Survive tab switches and navigation.
- **Story player navigation**: Matches `StorySettingsView` pattern — standard NavigationStack push with `.navigationTitle`, `.toolbarBackground`, system back button and interactive swipe-back gesture.
- **Story read view**: Same navigation pattern — pushed via `.navigationDestination`, no more `fullScreenCover`.
- **Tab switching preserves audio**: Opacity-based tab system keeps all NavigationStacks alive. Switching tabs never stops playback.
- **Story continues after dismiss**: Navigating back from player keeps audio playing. Lock screen controls stay active with next/prev.
- **White noise single-tap**: Tapping a sound in the playlist now immediately starts it (was requiring two taps).
- **White noise stops story**: Starting solo white noise properly stops any active story narration.
- **Same-story re-open**: Tapping an already-playing story shows the player at current position instead of restarting.
- **Volume toast deduplication**: Single canonical call site prevents double banners.
- **Audio interruption handling**: Properly pauses on interruption began, resumes on ended with shouldResume.
- **Failed audio load retry**: `loadedStoryID` only set on success so `.task(id:)` retries on next appear.

### New features
- **Global mini player**: Floating bar above tab bar shows when audio is playing but full player is not visible. Story mode (title, time, skip) and white noise mode (sound name, skip). Tap to navigate to full player. Persists after pause.
- **Lock screen next/prev**: Story player wires playlist-based skip to `MPRemoteCommandCenter`. White noise player cycles through sounds with subscription checks.
- **App Store review prompt**: `SKStoreReviewController` at milestones 3, 10, 25 stories generated.
- **15 story themes**: Expanded from 10. Added Hayvanlar, Müzik, Mevsimler, Korsanlar, Prenses & Şövalye, Sihirli Orman. Removed "Masal" (redundant). Richer API hints (3 per theme). 30% cross-theme blending.
- **Version bumped to 1.1**.

### Architecture changes
- Player presentation state owned by `MainTabView`, passed as `@Binding` to Home/Library.
- Cleanup on player dismiss only clears view-specific callbacks (not audio).
- `AudioPlayerService` owns playlist and skip logic (survives view dismissal).
- `MixerEngine` owns `focusedSound`, `orderedPlaylist`, skip logic, and `subscriptionManager` reference.
- `MixerEngine.solo()` stops `AudioPlayerService` when taking over.

---

## 2026-03-27 — Initial implementation

- **Epic 1–8 (initial implementation):** Dreamscape theme, components, tab shell, SwiftData models, CloudKit-first ModelContainer with local fallback, onboarding + paywall UI, home / library / settings, story player + mixer, `StoryService` + proxy contract, `SubscriptionManager` (StoreKit 2 + free tier quota), WAV loops, variable fonts, edge Worker.
- **Build:** SUCCEEDED.
- **Tests:** `MasalAmcaTests` + `MasalAmcaUITests` targets added.
- **Manual QA:** See `MANUAL_TESTING.md`.
