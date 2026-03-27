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

```bash
npx wrangler deploy
```

Set the worker URL in the iOS app **Info.plist** keys `ProxyBaseURL` (e.g. `https://masal-amca-proxy.youraccount.workers.dev`) and `ProxyAuthToken` (must match `PROXY_AUTH_TOKEN`).

## Endpoints

- `POST /v1/story` — JSON body per app `StoryGenerateRequestDTO`
- `POST /v1/tts` — JSON body per app `TTSRequestDTO`; returns `audio/mpeg`
