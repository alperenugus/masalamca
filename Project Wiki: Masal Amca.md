# Masal Amca — Project Wiki

**AI-Powered Personalized Turkish Bedtime Stories & White Noise Companion**

> While this documentation is in English, all app UI, onboarding, and generated AI content (text & audio) are 100% in Turkish.

## 1. Executive Summary

**Vision:** A premium iOS app that generates personalized, safe bedtime stories in Turkish for children, combined with a white noise mixer for healthy sleep routines.

**Target audience:** Turkish-speaking parents with children aged 2–9 who want engaging, screen-free bedtime routines.

**Core value proposition:** Zero screen time required — AI creates a unique story where the child is the hero, narrated with natural-sounding voices. No static audiobooks, no repeated content.

## 2. Technical Architecture

| Layer | Technology | Role |
|-------|-----------|------|
| **iOS app** | SwiftUI + SwiftData, iOS 17+ | UI, audio playback, profile management, local storage |
| **Edge worker** | Cloudflare Workers | Auth, rate limiting, prompt construction, story seeds, AI provider forwarding |
| **Story text** | OpenAI GPT-4o-mini | Generates personalized Turkish story in JSON format |
| **Story audio** | Google Gemini Flash TTS (`gemini-2.5-flash-tts`) | TTS narration with Turkish voice models |
| **Subscriptions** | StoreKit 2 | Monthly/yearly auto-renewable via Apple |
| **Data sync** | SwiftData (local-first) | Optional CloudKit for cross-device sync |

**Key architectural decisions:**
- Cloudflare Worker owns all prompt logic (`prompts.ts`, `themes.ts`, `storySeeds.ts`). iOS sends structured data (`child_name`, `age_group`, `themes`). Prompts updatable via `wrangler deploy`.
- Audio singletons (`AudioPlayerService`, `MixerEngine`) survive navigation and tab switches.
- Opacity-based tab system preserves all NavigationStack states.
- Generated audio cached locally — replays cost $0.

## 3. Core Features

### Story Generation Engine
- Worker builds system + user prompts from structured iOS input (`edge/src/prompts.ts`)
- 24 themes in 5 categories (9 free, 15 premium), theme hints in `edge/src/themes.ts`
- ~40 randomized places, ~40 side characters, plus plot hooks, family threads, objects (`edge/src/storySeeds.ts`)
- One theme randomly selected per story by the worker — keeps prompts focused
- Age-appropriate language calibration (2–4, 5–7, 8+)
- Prompts updatable via `wrangler deploy` without App Store release

### Audio & Sleep
- 8 AI narrator voices (2 free, 6 premium) via Google Gemini Flash TTS
- 6 white noise sounds: rain, ocean, wind, fireplace, shush, fan
- Background playback with lock screen Now Playing controls
- Mini player bar for persistent audio access
- Optional low-volume white noise layered under story narration
- Sleep timer (15/30 min)

### Safety
- No violence, fear, death, or inappropriate content (enforced in worker system prompt, `edge/src/prompts.ts`)
- Content-safe at every moment — Turkish children's standards
- Parental gate for premium purchases
- API keys never on device

## 4. Market Position

**Global context:** Apps like Oscar and Bedtime AI prove demand for personalized AI stories. Sleep apps like White Noise Baby have massive downloads for audio loops.

**Turkish market gap:** Existing Turkish apps (Masalcı etc.) offer static, pre-recorded audio. No dominant local app combines AI personalization + high-quality Turkish narration + white noise mixer in one iOS experience.

**Differentiators:**
- Zero screen time (audio-only consumption)
- Child is the hero of every story
- Turkish-first (not a translation)
- White noise + story in one app

## 5. Subscription Model

| | Free | Premium |
|--|------|---------|
| Stories | 2 lifetime | 2/day |
| Themes | 9 | 24 (5 categories) |
| Narrators | 2 | 8 |
| White noise | 3 | 6 |
| Background music | No | Yes |
| **Price** | $0 | $9.99/mo or $99.99/yr |
| **Free trial** | — | 3 days |

Revenue after Apple 15% commission: $8.49/mo (monthly), $7.08/mo (yearly).

## 6. Financial Model

### Per-Story Cost (Gemini Flash TTS)
- OpenAI: ~$0.001
- Google Gemini Flash TTS: ~$0.10–0.12
- **Total: ~$0.10–0.12/story**

### Break-Even
- Per-user: substantially more headroom than previous ElevenLabs stack (~75% TTS cost reduction)
- Subscriber count: much lower break-even due to reduced COGS

### Projection (50 subscribers, average usage)
- Revenue: $424.50/mo
- Costs: $276/mo
- **Net profit: ~$148.50/mo ($1,782/yr)**

Full analysis: [docs/FINANCIAL_ANALYSIS.md](docs/FINANCIAL_ANALYSIS.md)

## 7. App Store

- **App Store URL:** https://apps.apple.com/app/id6761391879
- **Terms:** https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- **Keywords:** masal,uyku masalı,çocuk,ebeveyn,uyku,hikaye,beyaz gürültü,yağmur,rutin,bebek,rüya
- **Version:** 1.2
