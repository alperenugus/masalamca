# Masal Amca — Architecture

## Overview

- **Client:** SwiftUI + SwiftData (+ CloudKit when container is provisioned). iOS-first; Xcode project may list other Apple platforms.
- **Secrets:** Cloudflare Worker (`edge/`) holds OpenAI + ElevenLabs keys. App sends `Authorization: Bearer` when `ProxyAuthToken` is set.
- **Audio:** Story playback via `AVAudioPlayer` + Now Playing; white noise via one `AVAudioPlayer` per `MixerSound` (looped WAV in bundle under `Resources/Audio/`).
- **Monetization:** StoreKit 2; `SubscriptionManager` tracks entitlements and `storiesGeneratedCount` for freemium (2 stories / 3 sounds).

## Module map

| Area | Path |
|------|------|
| App entry | `MasalAmca/MasalAmca/App/MasalAmcaApp.swift` |
| Root / tabs | `Views/Root/` |
| Theme | `Theme/` |
| Models | `Models/`, `Models/Enums/` |
| Data | `Data/ChildProfileManager.swift`, `Data/SwiftDataRepository.swift` |
| Services | `Services/` |
| Screens | `Views/Dashboard`, `Library`, `Player`, `Mixer`, `Onboarding`, `Settings`, `Components` |

## Environment injection

- `masalThemeManager` — `ThemeManager` (Dreamscape midnight palette).
- `masalChildProfileManager` — active child profile selection.
- `subscriptionManager` / `mixerEngine` — passed as `@Bindable` from `RootView` / `MainTabView` and also exposed via `.environment(...)` on `WindowGroup` where needed.

## API DTOs

Swift types mirror the Worker contract in `Services/PromptOrchestrator.swift` (`StoryGenerateRequestDTO`, `StoryGenerateResponseDTO`, `TTSRequestDTO`).
