# Masal Amca — Edge proxy

Cloudflare Worker that proxies **OpenAI** (story JSON) and **ElevenLabs** (TTS audio). API keys never ship in the iOS app.

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

## Rate limiting (Option A — Workers binding)

`wrangler.toml` defines `[[ratelimits]]` → `env.API_RATE_LIMITER`. Each successful auth check on **`POST /v1/story`** and **`POST /v1/tts`** calls `limit({ key })` once.

- **Key:** `CF-Connecting-IP` (client IP at the edge). One full “generate story” in the app uses **2** units (story + TTS).
- **Quota:** `40` requests per `60` seconds per IP **per Cloudflare PoP** (edge location), not a single global counter. Tweak `limit` / `period` in `wrangler.toml` if needed (`period` must be `10` or `60`).
- **Response:** HTTP **429** with JSON `{ "error": "rate_limited", ... }` and `Retry-After: 60`.

## Endpoints

- `POST /v1/story` — JSON body per app `StoryGenerateRequestDTO`
- `POST /v1/tts` — JSON body per app `TTSRequestDTO`; returns `audio/mpeg`
