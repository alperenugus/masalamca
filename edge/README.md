# Masal Amca — Edge Proxy

Cloudflare Worker that acts as a **pure proxy** for **OpenAI** (story JSON) and **TTS** (narration audio). API keys never ship in the iOS app.

The Worker does NOT build prompts or hold any story logic. The iOS app sends the complete `messages` array via `PromptOrchestrator`, and the Worker forwards it to OpenAI.

## Client versioning

The Worker supports multiple iOS app versions simultaneously via the `X-Client-Version` header:

| Header value | TTS provider | Voice ID format |
|-------------|--------------|-----------------|
| `2` (or higher) | **Google Gemini Flash TTS** | Gemini speaker name (e.g. `Achernar`) |
| `1` (or missing) | **ElevenLabs Flash v2.5** (legacy) | ElevenLabs voice UUID |

This lets you deploy one Worker that serves both the current production app and new releases. When all users have upgraded, the ElevenLabs fallback can be removed.

## Setup

```bash
cd edge
npm install
cp .env.example .env
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put PROXY_AUTH_TOKEN
npx wrangler secret put GOOGLE_SERVICE_ACCOUNT_JSON
# Keep for old app versions:
npx wrangler secret put ELEVENLABS_API_KEY
npx wrangler secret put ELEVENLABS_VOICE_ID
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

## Testing `/v1/tts` locally

1. Create `edge/.dev.vars` with the same keys as production (including `PROXY_AUTH_TOKEN` and `GOOGLE_SERVICE_ACCOUNT_JSON`).
2. Run `npx wrangler dev` (or `npx wrangler dev --remote` to use secrets from Cloudflare without pasting JSON locally).
3. Call with the same `Authorization` header the app uses:

```bash
curl -sS -X POST "http://localhost:8787/v1/tts" \
  -H "Authorization: Bearer YOUR_PROXY_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Merhaba, bu bir test.","voice_id":"Achernar","output_format":"mp3_44100_128"}' \
  -o /tmp/out.mp3 && file /tmp/out.mp3
```

Expect **`MPEG`** / **audio** for success; JSON with `error` for failures.

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
                                 TTS proxy                     Google Cloud
text + voice_id          ──→     Forward to Gemini TTS  ──→   Gemini 2.5 Flash TTS
                          ←──    Return audio/mpeg      ←──    (base64 → binary)
```

## Endpoints

### `POST /v1/story`

**Request:** `{ messages: [{ role: "system", content: "..." }, { role: "user", content: "..." }] }`

**Processing:**
1. Validate `Authorization: Bearer <token>`
2. Rate limit check (Workers binding, per IP)
3. Forward `messages` to OpenAI `gpt-4o-mini` with `response_format: { type: "json_object" }`, `temperature: 0.9`
4. Parse response JSON `{ title, body, genre }`
5. If `body` is an array, join with `\n\n`
6. Return `{ title, body, genre, word_count, model }`

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
| `ELEVENLABS_API_KEY` | (legacy) ElevenLabs key for old app versions |
| `ELEVENLABS_VOICE_ID` | (legacy) Default voice UUID for old app versions |

## Models

| Provider | Model | Purpose |
|----------|-------|---------|
| OpenAI | `gpt-4o-mini` | Story text generation |
| Google | `gemini-2.5-flash-tts` | TTS narration (Turkish) — `X-Client-Version >= 2` |
| ElevenLabs | `eleven_flash_v2_5` | TTS narration (Turkish, legacy) — `X-Client-Version < 2` |
