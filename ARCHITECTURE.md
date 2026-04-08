# Masal Amca — Architecture

## Overview

- **Client:** SwiftUI + SwiftData, iOS 17+. iPhone and iPad only.
- **Secrets:** Cloudflare Worker (`edge/`) holds OpenAI + ElevenLabs keys. App sends `Authorization: Bearer` when `ProxyAuthToken` is set in Info.plist.
- **Audio:** Story playback via singleton `AudioPlayerService` (`AVAudioPlayer` + `MPNowPlayingInfoCenter`); white noise via singleton `MixerEngine` (one looped `AVAudioPlayer` per `MixerSound`). Both survive navigation and tab switches.
- **Monetization:** StoreKit 2 auto-renewable subscriptions (monthly/yearly). `SubscriptionManager` tracks entitlements and `storiesGeneratedCount` for freemium gating.
- **Version:** 1.1 (deployment target iOS 17.0)

## Module map

| Area | Path | Key types |
|------|------|-----------|
| App entry | `App/MasalAmcaApp.swift` | Singleton services, AVAudioSession, ModelContainer |
| Root / tabs | `Views/Root/` | `RootView`, `MainTabView` (opacity-based tabs), `MiniPlayerBar` |
| Theme | `Theme/` | `ThemeManager`, `DreamscapePalette`, `DesignTokens`, `Typography` |
| Models | `Models/`, `Models/Enums/` | `Story`, `ChildProfile`, `AppSyncState`, `StoryBentoTheme`, `StoryGenre` |
| Data | `Data/` | `ChildProfileManager`, `AppSyncPersistence`, `SwiftDataRepository` |
| Services | `Services/` | `AudioPlayerService`, `MixerEngine`, `SubscriptionManager`, `StoryService`, `PromptOrchestrator` |
| Live Activity | `Services/LiveActivity/` | `PlaybackSessionSync`, `PlaybackLiveActivityManager`, `PlaybackWidgetStore` |
| Screens | `Views/Dashboard`, `Library`, `Player`, `Mixer`, `Onboarding`, `Settings`, `Components` | |
| Widget | `MasalAmcaWidget/` | `NowPlayingWidget`, `StoryPlaybackLiveActivityWidget` |
| Edge proxy | `edge/` | Cloudflare Worker: OpenAI + ElevenLabs proxy with rate limiting |

## Audio architecture

```
MasalAmcaApp (@State)
├── AudioPlayerService (singleton)
│   ├── AVAudioPlayer (story narration)
│   ├── MPNowPlayingInfoCenter (lock screen)
│   ├── MPRemoteCommandCenter (play/pause/next/prev)
│   ├── Playlist tracking (survives view dismissal)
│   └── Skip logic (self-contained)
├── MixerEngine (singleton)
│   ├── AVAudioPlayer × 6 (white noise loops)
│   ├── MPNowPlayingInfoCenter (when no story active)
│   ├── MPRemoteCommandCenter (play/pause/next/prev)
│   ├── focusedSound + orderedPlaylist (survives view dismissal)
│   ├── Skip logic with subscription checks
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

## Story generation flow

1. User taps "Masal Üret" → `HomeView.generateStory()`
2. `PromptOrchestrator.storyRequest()` builds DTO with `StoryBentoTheme.generateHints()` (30% chance of cross-theme blend)
3. `StoryService.generateStoryAndAudio()` → POST `/v1/story` to edge proxy
4. Edge proxy: system prompt (age-appropriate, TTS-optimized) + `storySeeds` (random place/character/plot/family/object) + user themes
5. OpenAI GPT-4o-mini generates JSON → proxy pads if too short → returns story
6. App calls POST `/v1/tts` for ElevenLabs narration
7. Story saved to SwiftData + audio cached to Documents
8. Player presented via `playerPresentation` binding

## API DTOs

Swift types in `Services/PromptOrchestrator.swift` mirror the Worker contract: `StoryGenerateRequestDTO`, `StoryGenerateResponseDTO`, `TTSRequestDTO`.

## Subscription model

| Tier | Limit | Premium features |
|------|-------|-----------------|
| Free | 2 stories lifetime | 3 white noise sounds, 2 narrators |
| Premium | 2 stories/day | All 15 themes, 6 white noise sounds, 8 narrators, background music during story |
