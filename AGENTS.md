# Masal Amca — Agent Guidelines

## Project overview

Masal Amca is a Turkish bedtime story app for children. It generates personalized stories using AI (OpenAI GPT-4o-mini) and narrates them with ElevenLabs Flash v2.5 TTS. A Cloudflare Worker acts as a pure proxy (auth + rate limiting). The app also provides white noise playback for sleep.

- **Platform:** iOS 17+, iPhone and iPad
- **Language:** Swift 5, SwiftUI, SwiftData
- **Architecture:** Single Xcode project with 4 targets (app, widget, tests, UI tests)
- **Version:** 1.2

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

5. **Subscription gating.** All premium content must check `subscription.canUseSound()` / `subscription.canUseNarrator()`. Lock screen and in-app skip buttons must automatically skip past premium content for free users (never show a paywall from skip).

6. **Turkish language.** All user-facing strings are in Turkish. The app does not use localization files — strings are inline. Keep this consistent.

7. **Audio session.** Configured once in `MasalAmcaApp.init()` as `.playback` without `.mixWithOthers`. Do not change this — `.mixWithOthers` prevents the lock screen Now Playing card from appearing.

8. **Story generation flow.** The iOS app owns ALL prompt logic. `PromptOrchestrator` builds the full `messages` array (system + user), `StorySeeds` provides randomized places/characters, and the Worker is a pure proxy. Never add prompt logic to the Worker.

9. **Post-generation behavior.** After story generation: if the user is still on the home tab, auto-open the player. If the user switched tabs, only show a toast — never auto-navigate across tabs.

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
| `Views/Onboarding/` | Onboarding flow (multi-page TabView) |
| `Views/Components/` | Reusable UI: tab bar, mini player, cards, buttons, ThemeCategoryPicker |
| `Models/` | SwiftData models, enums, StoryThemeCategory, StoryBentoTheme |
| `Services/` | Audio, networking, subscriptions, notifications, StorySeeds, PromptOrchestrator |
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

## Story generation architecture

```
iOS (PromptOrchestrator)           Worker (pure proxy)           Providers
├── Pick 1 random theme            ├── Validate messages          ├── OpenAI GPT-4o-mini
├── Pick 1-2 random places         ├── Forward to OpenAI          ├── ElevenLabs Flash v2.5
├── Pick 1-2 random characters     ├── Join body[] → string       │
├── Build system prompt            ├── Return {title,body,genre}  │
├── Build user message             │                              │
└── Send {messages: [...]}         └── TTS: forward text+voice    │
```

## Theme system

24 themes organized into 5 categories via `StoryThemeCategory`:

| Category | Themes | Premium |
|----------|--------|---------|
| Macera & Keşif | Macera, Uzay, Korsanlar, Deniz | Mixed |
| Doğa & Hayvanlar | Doğa, Hayvanlar, Mevsimler, Sihirli Orman | Mixed |
| Hayal Dünyası | Rüya, Prenses & Şövalye, Robot, Dinozor | Mixed |
| Günlük Hayat | Arkadaşlık, Müzik, Araçlar | Mixed |
| Değerler Eğitimi | Dürüstlük, Doğruluk, Sevgi, Çalışkanlık, Saygı, Cömertlik, Adalet, Sorumluluk, Yardımseverlik | Mixed |

UI: `ThemeCategoryPicker` — reusable accordion component used in both Onboarding (page 2) and Story Settings.

## Testing

- Unit tests: `MasalAmcaTests` target
- UI tests: `MasalAmcaUITests` target
- Manual QA checklist: `MANUAL_TESTING.md`
- Build command: `xcodebuild build -scheme MasalAmca -destination 'generic/platform=iOS'`
