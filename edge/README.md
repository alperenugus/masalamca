# Masal Amca — Edge Proxy

Cloudflare Worker that acts as a **pure proxy** for **OpenAI** (story JSON) and **ElevenLabs** (TTS audio). API keys never ship in the iOS app.

The Worker does NOT build prompts or hold any story logic. The iOS app sends the complete `messages` array via `PromptOrchestrator`, and the Worker forwards it to OpenAI.

## Setup

```bash
cd edge
npm install
cp .env.example .env
# For local dev, use wrangler secret or .dev.vars (see Wrangler docs)
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put ELEVENLABS_API_KEY
npx wrangler secret put PROXY_AUTH_TOKEN
npx wrangler secret put ELEVENLABS_VOICE_ID
npx wrangler dev
```

## Deploy

Requires **Wrangler 4.36+** (`npm install` in this folder).

```bash
npx wrangler deploy
```

Set the worker URL in the iOS app **Info.plist** keys `ProxyBaseURL` (e.g. `https://masal-amca-proxy.youraccount.workers.dev`) and `ProxyAuthToken` (must match `PROXY_AUTH_TOKEN`).

## Architecture

```
iOS App                          Worker                        Providers
────────                         ──────                        ─────────
PromptOrchestrator               Auth + Rate Limit             OpenAI
├── buildSystemPrompt()   ──→    Forward messages[] ────→      GPT-4o-mini
├── buildUserMessage()           Parse JSON response            (json_object)
├── StorySeeds (places,          Join body[] → string
│   sideCharacters)              Return DTO
└── {messages: [sys, user]}
                                 TTS proxy                     ElevenLabs
text + voice_id          ──→     Forward to ElevenLabs ──→     Flash v2.5
                          ←──    Return audio/mpeg      ←──    (audio/mpeg)
```

## Endpoints

### `POST /v1/story`

**Request:** `{ messages: [{ role: "system", content: "..." }, { role: "user", content: "..." }] }`

**Processing:**
1. Validate `Authorization: Bearer <token>`
2. Rate limit check (Workers binding, per IP)
3. Forward `messages` to OpenAI `gpt-4o-mini` with `response_format: { type: "json_object" }`, `temperature: 0.7`
4. Parse response JSON `{ title, body, genre }`
5. If `body` is an array, join with `\n\n`
6. Return `{ title, body, genre, word_count, model }`

### `POST /v1/tts`

**Request:** `{ text, voice_id, output_format }`

**Processing:**
1. Validate auth
2. Rate limit check
3. Forward to ElevenLabs (`eleven_flash_v2_5` model, `language_code: tr`)
4. Return `audio/mpeg` binary

## Rate limiting

`wrangler.toml` defines `[[ratelimits]]` → `env.API_RATE_LIMITER`. Each successful auth check on **`POST /v1/story`** and **`POST /v1/tts`** calls `limit({ key })` once.

- **Key:** `CF-Connecting-IP` (client IP at the edge). One full "generate story" in the app uses **2** units (story + TTS).
- **Quota:** `40` requests per `60` seconds per IP **per Cloudflare PoP** (edge location), not a single global counter.
- **Response:** HTTP **429** with JSON `{ "error": "rate_limited", ... }` and `Retry-After: 60`.

## Configuration

| Secret | Purpose |
|--------|---------|
| `OPENAI_API_KEY` | OpenAI API key |
| `ELEVENLABS_API_KEY` | ElevenLabs API key |
| `ELEVENLABS_VOICE_ID` | Default Turkish voice UUID |
| `PROXY_AUTH_TOKEN` | Shared secret with iOS app |

## Models

| Provider | Model | Purpose |
|----------|-------|---------|
| OpenAI | `gpt-4o-mini` | Story text generation |
| ElevenLabs | `eleven_flash_v2_5` | TTS narration (Turkish) |
