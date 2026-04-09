/**
 * Masal Amca — pure proxy for OpenAI + TTS.
 *
 * The iOS app builds the complete prompt (system + user messages).
 * This worker only handles auth, rate limiting, and forwarding.
 *
 * Client versioning: the iOS app sends `X-Client-Version: 2` (or higher)
 * to use Google Gemini TTS. Old clients without the header (or version < 2)
 * fall back to ElevenLabs. This lets us deploy one worker that serves both
 * the current production app and future releases.
 *
 * Secrets: OPENAI_API_KEY, PROXY_AUTH_TOKEN,
 *   GOOGLE_SERVICE_ACCOUNT_JSON (for Gemini TTS, version >= 2),
 *   ELEVENLABS_API_KEY (legacy, version < 2)
 * Rate limiting: Cloudflare Workers Rate Limit binding (wrangler.toml [[ratelimits]]).
 */

import { getGoogleAccessToken } from "./googleAuth";

export interface Env {
  OPENAI_API_KEY: string;
  /** Legacy: ElevenLabs key for old clients (X-Client-Version < 2). */
  ELEVENLABS_API_KEY?: string;
  ELEVENLABS_VOICE_ID?: string;
  /** Google service account JSON for Gemini TTS (X-Client-Version >= 2). */
  GOOGLE_SERVICE_ACCOUNT_JSON?: string;
  PROXY_AUTH_TOKEN?: string;
  API_RATE_LIMITER: RateLimit;
  /** Gemini-TTS fallback speaker when client sends voice_id=default. */
  GOOGLE_TTS_VOICE_NAME?: string;
}

interface StoryRequest {
  messages: { role: string; content: string }[];
}

interface TTSRequest {
  text: string;
  voice_id: string;
  output_format?: string;
}

// ─── Constants ───────────────────────────────────────────────────────

const ELEVEN_TTS_MODEL = "eleven_flash_v2_5";
const GOOGLE_TTS_LANG = "tr-TR";
const GEMINI_TTS_MODEL = "gemini-2.5-flash-tts";

/**
 * Minimum client version that uses Google Gemini TTS.
 * Clients below this version use ElevenLabs (legacy).
 */
const MIN_GEMINI_VERSION = 2;

const GEMINI_TTS_STYLE_PROMPT = `Read the following text as a comforting, wise, and engaging storyteller for children. Your voice should be incredibly warm, gentle, and deeply soothing. Speak with a patient, melodic tone, as if reading a bedtime story to help a child feel completely safe and relaxed.

Keep the pacing slow and deliberate. Use natural, hushed pauses to build a sense of gentle wonder. When emphasizing descriptive words, do it with warmth and a subtle smile in your voice rather than dramatic volume. The overall emotion must be pure coziness, safety, and affectionate care.

The entire passage is a story in Turkish (Türkçe). Read it from start to finish as continuous narration only. Do not speak any English, stage directions, or meta-instructions — there should be none in the text; if you ever see English words, skip them and continue with the Turkish story.`;

// ─── Utilities ───────────────────────────────────────────────────────

function clientVersion(request: Request): number {
  const raw = request.headers.get("X-Client-Version") ?? "1";
  const n = parseInt(raw, 10);
  return Number.isFinite(n) ? n : 1;
}

function resolveGeminiVoice(voiceId: string | undefined, env: Env): string {
  const id = (voiceId ?? "").trim();
  if (id && id !== "default") return id;
  return env.GOOGLE_TTS_VOICE_NAME?.trim() || "Achernar";
}

function wordCount(text: string): number {
  return text.split(/\s+/).filter(Boolean).length;
}

function msSince(start: number): number {
  return Date.now() - start;
}

async function fetchWithTimeout(
  url: string,
  init: RequestInit,
  timeoutMs: number,
  label: string,
): Promise<Response> {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (err) {
    if ((err as { name?: string } | undefined)?.name === "AbortError") {
      throw new Error(`${label}_timeout`);
    }
    throw err;
  } finally {
    clearTimeout(t);
  }
}

function authOk(request: Request, env: Env): boolean {
  const token = env.PROXY_AUTH_TOKEN;
  if (!token) return true;
  const h = request.headers.get("Authorization") ?? "";
  return h === `Bearer ${token}`;
}

function rateLimitClientKey(request: Request): string {
  return (
    request.headers.get("CF-Connecting-IP") ??
    request.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() ??
    "unknown"
  );
}

async function enforceRateLimit(
  env: Env,
  request: Request,
): Promise<Response | null> {
  const { success } = await env.API_RATE_LIMITER.limit({
    key: rateLimitClientKey(request),
  });
  if (success) return null;
  return new Response(
    JSON.stringify({
      error: "rate_limited",
      message: "Çok fazla istek. Bir dakika sonra tekrar dene.",
    }),
    {
      status: 429,
      headers: {
        "Content-Type": "application/json",
        "Retry-After": "60",
      },
    },
  );
}

function jsonResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Router ──────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const ver = clientVersion(request);
    console.log(`[req] ${request.method} ${url.pathname} client_v=${ver}`);

    if (!authOk(request, env)) {
      return new Response("Unauthorized", { status: 401 });
    }

    if (request.method === "POST" && url.pathname.endsWith("/v1/story")) {
      const limited = await enforceRateLimit(env, request);
      if (limited) return limited;
      return handleStory(request, env);
    }
    if (request.method === "POST" && url.pathname.endsWith("/v1/tts")) {
      const limited = await enforceRateLimit(env, request);
      if (limited) return limited;
      return handleTTS(request, env, ver);
    }
    return new Response("Masal Amca proxy", { status: 200 });
  },
};

// ─── Story (pure proxy to OpenAI) ───────────────────────────────────

async function handleStory(request: Request, env: Env): Promise<Response> {
  const startedAt = Date.now();
  const reqID = crypto.randomUUID();

  let body: StoryRequest;
  try {
    body = (await request.json()) as StoryRequest;
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  if (!body.messages || !Array.isArray(body.messages) || body.messages.length === 0) {
    return jsonResponse({ error: "missing_messages" }, 400);
  }

  console.log(`[story ${reqID}] messages=${body.messages.length} started`);

  let openaiRes: Response;
  try {
    openaiRes = await fetchWithTimeout(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          response_format: { type: "json_object" },
          messages: body.messages,
          temperature: 0.9,
          max_tokens: 6000,
        }),
      },
      60_000,
      "openai",
    );
  } catch (err) {
    const msg = (err as Error).message ?? "openai_error";
    console.log(`[story ${reqID}] openai fetch failed: ${msg}`);
    return jsonResponse({ error: msg, request_id: reqID }, 504);
  }

  if (!openaiRes.ok) {
    const t = await openaiRes.text();
    return jsonResponse({ error: "openai", detail: t }, 502);
  }

  const openaiJson = (await openaiRes.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const raw = openaiJson.choices?.[0]?.message?.content ?? "{}";

  let parsed: { title?: string; body?: string | string[]; genre?: string };
  try {
    parsed = JSON.parse(raw);
  } catch {
    return jsonResponse({ error: "parse", raw: raw.slice(0, 500) }, 502);
  }

  let storyBody: string;
  if (Array.isArray(parsed.body)) {
    storyBody = parsed.body.join("\n\n");
  } else {
    storyBody = (parsed.body ?? "").trim();
  }

  const finalWC = wordCount(storyBody);
  console.log(
    `[story ${reqID}] word_count=${finalWC} elapsed_ms=${msSince(startedAt)}`,
  );

  return jsonResponse({
    title: parsed.title ?? "Masal",
    body: storyBody,
    genre: parsed.genre ?? "calming",
    word_count: finalWC,
    model: "gpt-4o-mini",
    request_id: reqID,
  });
}

// ─── TTS Router ─────────────────────────────────────────────────────

async function handleTTS(
  request: Request,
  env: Env,
  ver: number,
): Promise<Response> {
  let body: TTSRequest;
  try {
    body = (await request.json()) as TTSRequest;
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  if (!body.text?.trim()) {
    return jsonResponse({ error: "missing_text" }, 400);
  }

  if (ver >= MIN_GEMINI_VERSION) {
    return handleTTSGemini(body, env);
  }
  return handleTTSElevenLabs(body, env);
}

// ─── TTS: Google Gemini Flash TTS (version >= 2) ────────────────────

async function handleTTSGemini(
  body: TTSRequest,
  env: Env,
): Promise<Response> {
  if (!env.GOOGLE_SERVICE_ACCOUNT_JSON?.trim()) {
    return jsonResponse(
      { error: "google_tts_not_configured", message: "GOOGLE_SERVICE_ACCOUNT_JSON eksik." },
      500,
    );
  }

  const speakerName = resolveGeminiVoice(body.voice_id, env);

  let accessToken: string;
  let projectId: string;
  try {
    const tok = await getGoogleAccessToken(env.GOOGLE_SERVICE_ACCOUNT_JSON);
    accessToken = tok.accessToken;
    projectId = tok.projectId;
  } catch (err) {
    const msg = (err as Error).message ?? "google_auth_error";
    console.log(`[tts gemini] auth failed: ${msg}`);
    return jsonResponse(
      {
        error: "google_auth_failed",
        message: "Google kimlik doğrulaması başarısız.",
        detail: msg.slice(0, 500),
      },
      502,
    );
  }

  const synthBody = {
    input: {
      text: body.text,
      prompt: GEMINI_TTS_STYLE_PROMPT,
    },
    voice: {
      languageCode: GOOGLE_TTS_LANG,
      name: speakerName,
      model_name: GEMINI_TTS_MODEL,
    },
    audioConfig: {
      audioEncoding: "MP3",
      sampleRateHertz: 24000,
    },
  };

  let gRes: Response;
  try {
    gRes = await fetchWithTimeout(
      "https://texttospeech.googleapis.com/v1/text:synthesize",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "x-goog-user-project": projectId,
        },
        body: JSON.stringify(synthBody),
      },
      180_000,
      "google_tts",
    );
  } catch (err) {
    const msg = (err as Error).message ?? "google_tts_fetch_error";
    return jsonResponse({ error: msg }, 504);
  }

  const raw = await gRes.text();
  if (!gRes.ok) {
    console.log(`[tts gemini] ${gRes.status} ${raw.slice(0, 600)}`);
    return jsonResponse(
      {
        error: "tts_failed",
        message: "Seslendirme şu anda yapılamadı. Lütfen tekrar dene.",
        detail: raw.slice(0, 800),
      },
      gRes.status >= 400 && gRes.status < 600 ? gRes.status : 502,
    );
  }

  let parsed: { audioContent?: string };
  try {
    parsed = JSON.parse(raw) as { audioContent?: string };
  } catch {
    return jsonResponse({ error: "google_tts_bad_json", detail: raw.slice(0, 200) }, 502);
  }

  if (!parsed.audioContent) {
    return jsonResponse({ error: "google_tts_empty_audio" }, 502);
  }

  let binary: Uint8Array;
  try {
    binary = Uint8Array.from(atob(parsed.audioContent), (c) => c.charCodeAt(0));
  } catch {
    return jsonResponse({ error: "google_tts_base64_decode_failed" }, 502);
  }

  return new Response(binary, {
    headers: { "Content-Type": "audio/mpeg" },
  });
}

// ─── TTS: ElevenLabs (legacy, version < 2) ──────────────────────────

async function handleTTSElevenLabs(
  body: TTSRequest,
  env: Env,
): Promise<Response> {
  if (!env.ELEVENLABS_API_KEY?.trim()) {
    return jsonResponse(
      { error: "elevenlabs_not_configured", message: "ELEVENLABS_API_KEY eksik." },
      500,
    );
  }

  const voice =
    body.voice_id && body.voice_id !== "default"
      ? body.voice_id
      : env.ELEVENLABS_VOICE_ID ?? "";
  const outputFormat = body.output_format?.trim() || "mp3_44100_128";

  let elevenRes: Response;
  try {
    elevenRes = await fetchWithTimeout(
      `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voice)}?output_format=${encodeURIComponent(outputFormat)}`,
      {
        method: "POST",
        headers: {
          "xi-api-key": env.ELEVENLABS_API_KEY!,
          "Content-Type": "application/json",
          Accept: "audio/mpeg",
        },
        body: JSON.stringify({
          text: body.text,
          model_id: ELEVEN_TTS_MODEL,
          language_code: "tr",
        }),
      },
      180_000,
      "elevenlabs",
    );
  } catch (err) {
    const msg = (err as Error).message ?? "elevenlabs_error";
    return jsonResponse({ error: msg }, 504);
  }

  if (!elevenRes.ok) {
    const t = await elevenRes.text();
    try {
      const j = JSON.parse(t) as {
        detail?: { status?: string; message?: string } | string;
      };
      const status =
        typeof j.detail === "object" && j.detail ? j.detail.status : undefined;
      const msg =
        typeof j.detail === "object" && j.detail ? j.detail.message : undefined;
      if (status === "quota_exceeded") {
        return jsonResponse(
          {
            error: "quota_exceeded",
            message: "Seslendirme kotası doldu. Lütfen daha sonra tekrar dene.",
            detail: msg ?? null,
          },
          402,
        );
      }
    } catch {
      // fall through
    }
    return jsonResponse(
      {
        error: "tts_failed",
        message: "Seslendirme şu anda yapılamadı. Lütfen tekrar dene.",
        detail: t.slice(0, 800),
      },
      502,
    );
  }

  return new Response(elevenRes.body, {
    headers: { "Content-Type": "audio/mpeg" },
  });
}
