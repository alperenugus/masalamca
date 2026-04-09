/**
 * Masal Amca — pure proxy for OpenAI + ElevenLabs TTS.
 *
 * The iOS app builds the complete prompt (system + user messages).
 * This worker only handles auth, rate limiting, and forwarding.
 *
 * Secrets: OPENAI_API_KEY, ELEVENLABS_API_KEY, PROXY_AUTH_TOKEN, ELEVENLABS_VOICE_ID (optional default)
 * Rate limiting: Cloudflare Workers Rate Limit binding (wrangler.toml [[ratelimits]]).
 */

export interface Env {
  OPENAI_API_KEY: string;
  ELEVENLABS_API_KEY: string;
  ELEVENLABS_VOICE_ID?: string;
  PROXY_AUTH_TOKEN?: string;
  API_RATE_LIMITER: RateLimit;
}

// iOS sends the full messages array — the worker just forwards it.
interface StoryRequest {
  messages: { role: string; content: string }[];
}

interface TTSRequest {
  text: string;
  voice_id: string;
  output_format: string;
}

const ELEVEN_TTS_MODEL = "eleven_flash_v2_5";

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

// ─── Router ──────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    console.log(`[req] ${request.method} ${url.pathname}`);
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
      return handleTTS(request, env);
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
          max_tokens: 2500,
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

  // body may be a string or an array of paragraphs — normalize to string
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

// ─── TTS (pure proxy to ElevenLabs) ─────────────────────────────────

async function handleTTS(request: Request, env: Env): Promise<Response> {
  let body: TTSRequest;
  try {
    body = (await request.json()) as TTSRequest;
  } catch {
    return new Response("invalid_json", { status: 400 });
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
          "xi-api-key": env.ELEVENLABS_API_KEY,
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
      // JSON parse failure — fall through
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

// ─── Helpers ─────────────────────────────────────────────────────────

function jsonResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
