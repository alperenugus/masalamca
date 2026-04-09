# Masal Amca

**AI-powered personalized Turkish bedtime stories for children — zero screen time, pure imagination.**

## What is Masal Amca?

Masal Amca generates safe, unique Turkish bedtime stories tailored to each child. Parents create a child profile (name, age, favorite themes), tap "Masal Üret," and AI writes and narrates a one-of-a-kind story. The child listens with eyes closed — no screen required.

## Key Features

### Story Generation
- **Personalized AI stories**: Each story features the child as the hero, with age-appropriate language and themes
- **24 themes in 5 categories**: Macera & Keşif, Doğa & Hayvanlar, Hayal Dünyası, Günlük Hayat, Değerler Eğitimi
- **8 AI narrator voices** via Google Gemini Flash TTS (2 free, 6 premium)
- **Content safety**: Strict prompt guardrails — no violence, fear, death, or inappropriate content
- **Variety engine**: ~40 randomized places, ~40 side characters, plus plot hooks, family threads, objects, and theme-based hints ensure no two stories are alike (managed server-side for instant updates)

### Audio & Sleep
- **Background playback**: Stories continue playing when the phone is locked
- **Lock screen controls**: Full Now Playing card with play/pause/skip
- **6 white noise sounds**: Rain, ocean, wind, fireplace, shush, fan — playable standalone or mixed with stories
- **Background white noise**: Optional low-volume white noise layered under story narration
- **Mini player**: Global floating bar when audio is active but full player is not visible

### Subscription Model
| | Free | Premium |
|--|------|---------|
| Stories | 2 lifetime | 2 per day |
| Themes | 9 | 24 (5 categories) |
| Narrators | 2 | 8 |
| White noise | 3 | 6 |
| Background music | No | Yes |
| **Price** | $0 | $9.99/mo or $99.99/yr |
| **Free trial** | — | 3 days |

### Platform
- **iOS 17+**, iPhone and iPad
- Swift 5, SwiftUI, SwiftData
- Cloudflare Worker proxy (API keys never on device)
- StoreKit 2 subscriptions with Apple Small Business Program (15% commission)

## Architecture (High Level)

```
iOS App                          Cloudflare Worker              Providers
┌─────────────────┐             ┌──────────────┐             ┌──────────┐
│ PromptOrchestrator│─structured─▶│ Prompt builder│──messages──▶│  OpenAI  │
│ (child_name,    │             │ + auth/rate   │             │ GPT-4o-  │
│  age_group,     │             │ Seeds, themes │             │  mini    │
│  themes)        │             │               │             └──────────┘
└────────┬────────┘             └──────┬───────┘
         │                             │                      ┌──────────┐
         │──text+voice_id─────────────▶│──────forward────────▶│ Google   │
         │                             │                      │Gemini TTS│
         │◀────────audio/mpeg──────────│◀─────audio/mpeg──────│          │
         │                             │                      └──────────┘
```

The Cloudflare Worker owns all prompt logic (system prompt, themes, story seeds). The iOS app sends structured data; prompts can be updated via `wrangler deploy` without an App Store release.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | SwiftUI + SwiftData, iOS 17+ |
| Story text | OpenAI GPT-4o-mini |
| Story audio | Google Gemini Flash TTS (Turkish, `gemini-2.5-flash-tts`) |
| Proxy | Cloudflare Workers + rate limiting |
| Subscriptions | StoreKit 2 (Apple) |
| Data sync | SwiftData (local-first, optional CloudKit) |

## Business Model

- **Revenue**: App Store subscriptions ($9.99/mo, $99.99/yr)
- **Apple commission**: 15% (Small Business Program)
- **Net revenue**: $8.49/mo (monthly), $7.08/mo (yearly)
- **Primary cost**: Google Gemini Flash TTS (~$0.10–0.12/story)
- **Break-even**: Substantially lower with ~75% TTS cost reduction vs previous ElevenLabs stack
- **Target**: 50+ paying subscribers for sustainable profitability

See [docs/FINANCIAL_ANALYSIS.md](docs/FINANCIAL_ANALYSIS.md) for detailed cost modeling and break-even analysis.

## Repository Structure

```
masalamca/
├── MasalAmca/                  # Xcode project
│   └── MasalAmca/
│       ├── App/                # Entry point, audio session
│       ├── Views/              # SwiftUI screens
│       │   ├── Root/           # RootView, MainTabView
│       │   ├── Dashboard/      # Home screen
│       │   ├── Library/        # Story library
│       │   ├── Player/         # Story player, white noise
│       │   ├── Settings/       # Settings, story settings
│       │   ├── Onboarding/     # Multi-page onboarding
│       │   └── Components/     # Reusable UI (mini player, tab bar, etc.)
│       ├── Models/             # SwiftData models, enums
│       ├── Services/           # Audio, networking, subscriptions
│       └── Theme/              # Design tokens, palette, typography
├── edge/                       # Cloudflare Worker (prompt builder + auth + TTS)
│   └── src/
│       ├── index.ts            # Router, story handler, TTS handler
│       ├── prompts.ts          # System prompt, user prompt template
│       ├── themes.ts           # 24 theme definitions with hints
│       ├── storySeeds.ts       # Places, characters, plot hooks, etc.
│       └── googleAuth.ts       # Google Cloud OAuth2
├── docs/                       # Financial analysis, API report, privacy
├── DesignProposal/             # UI design references
└── *.md                        # Architecture, setup, progress docs
```

## Links

- **App Store**: [Masal Amca](https://apps.apple.com/app/id6761391879)
- **Terms of Use**: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
