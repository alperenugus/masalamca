# Masal Amca — Agent Guidelines

## Project overview

Masal Amca is a Turkish bedtime story app for children. It generates personalized stories using AI (OpenAI GPT-4o-mini via a Cloudflare Worker proxy) and narrates them with ElevenLabs TTS. The app also provides white noise playback for sleep.

- **Platform:** iOS 17+, iPhone and iPad
- **Language:** Swift 5, SwiftUI, SwiftData
- **Architecture:** Single Xcode project with 4 targets (app, widget, tests, UI tests)
- **Version:** 1.1

## Critical rules

1. **Audio must never stop unexpectedly.** `AudioPlayerService` and `MixerEngine` are singletons at the app level. Never create new instances. Never call `stop()` or `pause()` from `onDisappear` — use `onChange` of state bindings instead.

2. **Navigation pattern.** All pushed views must use the same structure as `StorySettingsView`:
   ```swift
   .navigationTitle("Title")
   .navigationBarTitleDisplayMode(.inline)
   .toolbarBackground(c.surface, for: .navigationBar)
   ```
   Never use `.toolbar(.hidden, for: .navigationBar)` — it disables the interactive pop gesture.
   Never use `.navigationBarBackButtonHidden(true)` unless absolutely necessary.

3. **Tab system.** `MainTabView` uses opacity-based `ZStack`, not SwiftUI `TabView` or `switch`. All 4 tabs are always alive. Never change this — it preserves NavigationStack state across tab switches.

4. **Player presentation.** `playerPresentation: PresentedStory?` is a single `@State` owned by `MainTabView`, passed as `@Binding` to `HomeView` and `LibraryView`. The mini player also reads/writes this binding. Never create separate local player presentation state in child views.

5. **Subscription gating.** All premium content must check `subscription.canUseSound()` / `subscription.canUseNarrator()`. Lock screen skip commands must also respect these checks (see `MixerEngine.skipToNextSound()`).

6. **Turkish language.** All user-facing strings are in Turkish. The app does not use localization files — strings are inline. Keep this consistent.

7. **Audio session.** Configured once in `MasalAmcaApp.init()` as `.playback` without `.mixWithOthers`. Do not change this — `.mixWithOthers` prevents the lock screen Now Playing card from appearing.

## File organization

| Directory | Purpose |
|-----------|---------|
| `App/` | App entry point, audio session setup |
| `Views/Root/` | `RootView`, `MainTabView` |
| `Views/Dashboard/` | Home screen |
| `Views/Library/` | Story library |
| `Views/Player/` | Story player, story read view, white noise player |
| `Views/Mixer/` | White noise mixer panel |
| `Views/Settings/` | Settings, story settings, child profile editor |
| `Views/Onboarding/` | Onboarding flow |
| `Views/Components/` | Reusable UI: tab bar, mini player, cards, buttons, etc. |
| `Models/` | SwiftData models and enums |
| `Services/` | Audio, networking, subscriptions, notifications |
| `Services/LiveActivity/` | Live Activity infrastructure (currently not wired) |
| `Theme/` | Design tokens, palette, typography |
| `Data/` | Profile manager, sync persistence |
| `Utilities/` | Helpers (PresentedStory, Color+Hex) |
| `Content/` | Daily tips |

## Key singletons (all @State on MasalAmcaApp)

- `AudioPlayerService` — story narration, Now Playing, remote commands, playlist
- `MixerEngine` — white noise, focused sound, skip logic, subscription checks
- `SubscriptionManager` — StoreKit 2 entitlements, generation limits
- `ThemeManager` — Dreamscape midnight palette
- `ChildProfileManager` — active profile selection
- `ToastCenter` — in-app toast banners
- `VolumeMonitor` — system volume warning
- `MixerPinStore` — pinned white noise sounds

## Testing

- Unit tests: `MasalAmcaTests` target
- UI tests: `MasalAmcaUITests` target
- Manual QA checklist: `MANUAL_TESTING.md`
- Build command: `xcodebuild build -scheme MasalAmca -destination 'generic/platform=iOS'`
