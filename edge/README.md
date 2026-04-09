# Masal Amca — Edge Worker

Cloudflare Worker that handles **auth**, **rate limiting**, **prompt construction**, and **AI provider forwarding** for story generation (OpenAI) and narration (Google Gemini TTS). API keys never ship in the iOS app.

The Worker owns all prompt logic: system prompt, user prompt template, story seeds, and theme definitions. The iOS app sends only structured data (`child_name`, `age_group`, `themes`). To iterate on prompts, update the worker files and run `wrangler deploy` — no App Store release needed.

## Setup

```bash
cd edge
npm install
cp .env.example .env
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put PROXY_AUTH_TOKEN
npx wrangler secret put GOOGLE_SERVICE_ACCOUNT_JSON
npx wrangler dev
```

## TTS — Google Gemini Flash TTS

The Worker uses **Gemini 2.5 Flash TTS** via the Cloud Text-to-Speech API. The iOS app sends the Gemini speaker short name (e.g. `Achernar`, `Algieba`) directly as `voice_id`.

The secret **`GOOGLE_SERVICE_ACCOUNT_JSON`** must contain the full service account JSON. The GCP project must have the **Cloud Text-to-Speech API** enabled.

## Deploy

Requires **Wrangler 4.36+** (`npm install` in this folder).

```bash
npx wrangler deploy
```

Set the worker URL in the iOS app **Info.plist** keys `ProxyBaseURL` (e.g. `https://masal-amca-proxy.youraccount.workers.dev`) and `ProxyAuthToken` (must match `PROXY_AUTH_TOKEN`).

## Worker source files

| File | Purpose |
|------|---------|
| `src/index.ts` | Router, story handler, TTS handler, auth, rate limiting |
| `src/prompts.ts` | System prompt, user prompt template, age group text mapping |
| `src/themes.ts` | 24 theme definitions with Turkish hints (mirrors iOS `StoryBentoTheme` rawValues) |
| `src/storySeeds.ts` | ~40 places, ~40 characters, plot hooks, family threads, objects |
| `src/googleAuth.ts` | Google Cloud service account OAuth2 (JWT → access token) |

## Architecture

```
iOS App                          Worker                        Providers
────────                         ──────                        ─────────
PromptOrchestrator               Auth + Rate Limit             OpenAI
├── profile.name          ──→    Pick theme from themes[]      GPT-4o-mini
├── profile.ageGroup             Sample story seeds             (json_object)
├── themes: [rawValue...]        Build system + user prompts
└── {child_name,                 Forward messages to OpenAI
     age_group,                  Parse JSON response
     themes: [...]}              Return DTO

                                 TTS                           Google Cloud
text + voice_id          ──→     Style prompt + Gemini TTS ──→ Gemini 2.5 Flash TTS
                          ←──    Return audio/mpeg       ←──   (base64 → binary)
```

## Endpoints

### `POST /v1/story`

**Request:**

```json
{
  "child_name": "Ali",
  "age_group": "five_to_seven",
  "themes": ["adventure", "space"]
}
```

- `child_name` — hero of the story
- `age_group` — one of `two_to_four`, `five_to_seven`, `eight_plus`
- `themes` — array of theme rawValues; worker picks one randomly

**Processing:**
1. Validate `Authorization: Bearer <token>`
2. Rate limit check (Workers binding, per IP)
3. Pick one theme, sample seeds, build system + user prompts
4. Forward built messages to OpenAI `gpt-4o-mini` with `response_format: { type: "json_object" }`, `temperature: 0.9`
5. Parse response JSON `{ title, body, genre }`
6. If `body` is an array, join with `\n\n`
7. Return `{ title, body, genre, word_count, model, request_id }`

### `POST /v1/tts`

**Request:** `{ text, voice_id, output_format }`

**Processing:**
1. Validate auth
2. Rate limit check
3. OAuth2 token from service account → `POST texttospeech.googleapis.com/v1/text:synthesize`
4. Gemini Flash TTS with style prompt, speaker name from `voice_id`, Turkish (`tr-TR`), MP3 output
5. Decode base64 `audioContent` from response
6. Return `audio/mpeg` binary

## Rate limiting

`wrangler.toml` defines `[[ratelimits]]` → `env.API_RATE_LIMITER`. Each successful auth check on **`POST /v1/story`** and **`POST /v1/tts`** calls `limit({ key })` once.

- **Key:** `CF-Connecting-IP` (client IP at the edge). One full "generate story" in the app uses **2** units (story + TTS).
- **Quota:** `40` requests per `60` seconds per IP **per Cloudflare PoP** (edge location), not a single global counter.
- **Response:** HTTP **429** with JSON `{ "error": "rate_limited", ... }` and `Retry-After: 60`.

## Configuration

| Secret / var | Purpose |
|--------------|---------|
| `OPENAI_API_KEY` | OpenAI API key |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Full JSON for Google Gemini Flash TTS |
| `PROXY_AUTH_TOKEN` | Shared secret with iOS app |
| `GOOGLE_TTS_VOICE_NAME` | (optional) Fallback speaker name when `voice_id=default` |

## Models

| Provider | Model | Purpose |
|----------|-------|---------|
| OpenAI | `gpt-4o-mini` | Story text generation |
| Google | `gemini-2.5-flash-tts` | TTS narration (Turkish, Gemini Flash TTS via Cloud TTS API) |
