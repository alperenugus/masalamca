# Masal Amca — Progress Ledger

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
