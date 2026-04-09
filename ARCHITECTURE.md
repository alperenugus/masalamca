# Masal Amca — Architecture

## Overview

- **Client:** SwiftUI + SwiftData, iOS 17+. iPhone and iPad only.
- **Prompt logic:** Owned by the Cloudflare Worker (`edge/src/prompts.ts`, `themes.ts`, `storySeeds.ts`). The iOS app sends structured data (child name, age group, selected themes); the worker builds prompts, samples seeds, and forwards to OpenAI.
- **Edge worker:** Cloudflare Worker (`edge/`) handles auth, rate limiting, prompt construction, and AI provider forwarding. API keys never leave the worker.
- **Audio:** Story playback via singleton `AudioPlayerService` (`AVAudioPlayer` + `MPNowPlayingInfoCenter`); white noise via singleton `MixerEngine` (one looped `AVAudioPlayer` per `MixerSound`). Both survive navigation and tab switches.
- **Monetization:** StoreKit 2 auto-renewable subscriptions (monthly/yearly). `SubscriptionManager` tracks entitlements and `storiesGeneratedCount` for freemium gating.
- **Version:** 1.2 (deployment target iOS 17.0)

## Module map

| Area | Path | Key types |
|------|------|-----------|
| App entry | `App/MasalAmcaApp.swift` | Singleton services, AVAudioSession, ModelContainer |
| Root / tabs | `Views/Root/` | `RootView`, `MainTabView` (opacity-based tabs), `MiniPlayerBar` |
| Theme | `Theme/` | `ThemeManager`, `DreamscapePalette`, `DesignTokens`, `Typography` |
| Models | `Models/`, `Models/Enums/` | `Story`, `ChildProfile`, `AppSyncState`, `StoryBentoTheme`, `StoryThemeCategory`, `StoryGenre` |
| Data | `Data/` | `ChildProfileManager`, `AppSyncPersistence`, `SwiftDataRepository` |
| Services | `Services/` | `AudioPlayerService`, `MixerEngine`, `SubscriptionManager`, `StoryService`, `PromptOrchestrator` |
| Live Activity | `Services/LiveActivity/` | `PlaybackSessionSync`, `PlaybackLiveActivityManager`, `PlaybackWidgetStore` |
| Screens | `Views/Dashboard`, `Library`, `Player`, `Mixer`, `Onboarding`, `Settings`, `Components` | |
| Widget | `MasalAmcaWidget/` | `NowPlayingWidget`, `StoryPlaybackLiveActivityWidget` |
| Edge worker | `edge/` | Cloudflare Worker: auth, rate limiting, prompt builder, OpenAI + Gemini TTS |

## Story generation flow

```
┌─ iOS App ──────────────────────────────────────────────────────────────┐
│                                                                        │
│  1. User taps "Masal Üret" → HomeView.generateStory()                 │
│  2. PromptOrchestrator.storyRequest(from: profile)                     │
│     ├── StoryPreferences.load(for: profile) → bentoThemes              │
│     ├── Map theme rawValues                                            │
│     └── Map age group string                                           │
│  3. StoryRequestDTO { child_name, age_group, themes }                  │
│  4. StoryService → POST /v1/story (structured data)                    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ Cloudflare Worker (prompt builder + proxy) ─────────────────────────┐
│                                                                        │
│  5. Validate auth (Bearer token)                                       │
│  6. Rate limit check (CF Workers binding, per IP)                      │
│  7. Pick one random theme from themes[] (themes.ts)                    │
│  8. Sample story seeds: place, character, plot, family, object         │
│     └── ~40 places, ~40 characters, 18 plots, 18 family, 18 objects   │
│  9. Build system prompt (safety, format, diversity rules) (prompts.ts) │
│ 10. Build user message (child name, age, theme, seeds)                 │
│ 11. Forward built messages[] to OpenAI GPT-4o-mini                     │
│     └── response_format: json_object, temperature: 0.9                 │
│ 12. Parse response: { title, body (string or array), genre }           │
│ 13. Join body[] with "\n\n" → single string                            │
│ 14. Return { title, body, genre, word_count, model, request_id }       │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ iOS App (continued) ─────────────────────────────────────────────────┐
│                                                                        │
│ 15. StoryService → POST /v1/tts (text + voice_id)                     │
│     └── Worker forwards to Google Gemini Flash TTS → audio/mpeg       │
│ 16. Story saved to SwiftData, audio cached to Documents                │
│ 17. If user on home tab → auto-open player, stop white noise           │
│     If user on other tab → show toast "Masal hazır!"                   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Audio architecture

```
MasalAmcaApp (@State)
├── AudioPlayerService (singleton)
│   ├── AVAudioPlayer (story narration)
│   ├── MPNowPlayingInfoCenter (lock screen)
│   ├── MPRemoteCommandCenter (play/pause/next/prev)
│   ├── Playlist tracking (survives view dismissal)
│   ├── Skip logic (self-contained)
│   └── Audio-story identity verification (title + ID match)
├── MixerEngine (singleton)
│   ├── AVAudioPlayer × 6 (white noise loops)
│   ├── MPNowPlayingInfoCenter (when no story active)
│   ├── MPRemoteCommandCenter (play/pause/next/prev)
│   ├── focusedSound + orderedPlaylist (survives view dismissal)
│   ├── Skip logic: auto-skips premium sounds for free users
│   └── storyIsActive flag (yields Now Playing to story)
└── Coordination
    ├── MainTabView.onChange(audioPlayer.hasActiveTrack) → mixer.storyIsActive
    └── MixerEngine.solo() stops AudioPlayerService when taking over
```

## Navigation architecture

- **Tabs:** `MainTabView` uses opacity-based `ZStack` (not SwiftUI `TabView`). All 4 tabs stay alive simultaneously — preserves `NavigationStack` state across switches.
- **Story player:** Pushed via `.navigationDestination(item:)` from Home/Library `NavigationStack`. Uses same pattern as StorySettingsView: `.navigationTitle` + `.navigationBarTitleDisplayMode(.inline)` + `.toolbarBackground`. System back button and interactive pop gesture.
- **Story read view:** Pushed via `.navigationDestination(isPresented:)` from StoryPlayerView.
- **Mini player:** Global `MiniPlayerBar` in `MainTabView`, sits above `DreamscapeTabBar`. Shows when audio is active but full player is not on screen.
- **Player presentation:** Single `@State` in `MainTabView`, passed as `@Binding` to Home/Library. Mini player tap also sets this binding.

## Theme system

24 themes organized into 5 categories (`StoryThemeCategory`):

| Category | Key | Themes |
|----------|-----|--------|
| Macera & Keşif | `.adventureExploration` | adventure, space, pirates, ocean |
| Doğa & Hayvanlar | `.natureAnimals` | nature, animals, seasons, magicForest |
| Hayal Dünyası | `.fantasyWorld` | dreams, princesKnight, robots, dinosaurs |
| Günlük Hayat | `.dailyLife` | friendship, music, vehicles |
| Değerler Eğitimi | `.valuesEducation` | durustluk, dogruluk, sevgi, caliskanlik, saygi, comertlik, adalet, sorumluluk, yardimseverlik |

`ThemeCategoryPicker` (reusable accordion view) is used in both Onboarding and Story Settings.

Theme `rawValue` strings are the shared contract between iOS (UI, premium gating) and the worker (prompt building, hint selection). For generation, the worker picks ONE random theme from the app's selected set. The LLM receives a single theme — never multiple.

## Environment injection

| Key | Type | Purpose |
|-----|------|---------|
| `masalThemeManager` | `ThemeManager` | Dreamscape midnight palette |
| `masalChildProfileManager` | `ChildProfileManager` | Active child profile selection |
| `masalToastCenter` | `ToastCenter` | In-app toast notifications |
| `masalVolumeMonitor` | `VolumeMonitor` | System volume warning |
| `masalMixerPinStore` | `MixerPinStore` | Pinned white noise sounds |
| `masalAudioPlayer` | `AudioPlayerService` | Singleton audio player |
| `SubscriptionManager` | via `.environment()` | StoreKit 2 entitlements |
| `MixerEngine` | via `.environment()` | White noise engine |

## API DTOs

Swift types in `Services/PromptOrchestrator.swift`:

```swift
struct StoryRequestDTO: Codable, Sendable {
    var childName: String    // "child_name"
    var ageGroup: String     // "age_group"
    var themes: [String]     // theme rawValues
}
```

The Worker receives `{ child_name, age_group, themes }`, builds prompts, calls OpenAI, and returns `{ title, body, genre, word_count, model, request_id }`. Response: `StoryGenerateResponseDTO` with `title`, `body`, `genre`, `wordCount`, `model`.

## Subscription model

| Tier | Limit | Premium features |
|------|-------|-----------------|
| Free | 2 stories lifetime | 3 white noise sounds, 2 narrators, 9 themes |
| Premium | 2 stories/day | All 24 themes (5 categories), 6 white noise sounds, 8 narrators, background music during story |
| Trial | 3 days free | Full premium access |

## Cost model

See [docs/FINANCIAL_ANALYSIS.md](docs/FINANCIAL_ANALYSIS.md) for detailed analysis.

- **OpenAI**: ~$0.001/story (negligible)
- **Google Gemini Flash TTS**: ~$0.10–0.12/story (Cloud TTS HD pricing)
- See [docs/FINANCIAL_ANALYSIS.md](docs/FINANCIAL_ANALYSIS.md) for detailed analysis
