/**
 * Masal Amca — secure proxy for LLM story generation + ElevenLabs TTS.
 * Set secrets: OPENAI_API_KEY, ELEVENLABS_API_KEY, PROXY_AUTH_TOKEN (optional voice id in ELEVENLABS_VOICE_ID)
 *
 * Rate limiting: Cloudflare Workers Rate Limit binding (wrangler.toml [[ratelimits]]).
 * Counters are per edge location (PoP), per key; eventually consistent — good for abuse protection, not billing.
 */

import { buildVariationBlock, sampleStorySeeds } from "./storySeeds";

export interface Env {
  OPENAI_API_KEY: string;
  ELEVENLABS_API_KEY: string;
  ELEVENLABS_VOICE_ID?: string;
  PROXY_AUTH_TOKEN?: string;
  /** Bound in wrangler.toml; each POST /v1/story and /v1/tts consumes one unit. */
  API_RATE_LIMITER: RateLimit;
}

interface StoryRequest {
  child_name: string;
  age_group: string;
  themes: string[];
  behavioral_goal?: string;
  language: string;
  /** "short" | "medium" | "long" — ~3 / ~5 / ~10 dk hedef + kelime bandı */
  target_length?: string;
}

/** TTS quality: prefer `eleven_multilingual_v2` for cleaner narration. */
const ELEVEN_TTS_MODEL = "eleven_multilingual_v2";

interface TTSRequest {
  text: string;
  voice_id: string;
  output_format: string;
}

type LengthTarget = "short" | "medium" | "long";

function wordCount(text: string): number {
  return text.split(/\s+/).filter(Boolean).length;
}

function padStoryBodyIfTooShort(args: {
  body: string;
  minWords: number;
  maxWords: number;
  childName: string;
  themesText: string;
}): { body: string; didPad: boolean; finalWords: number } {
  const sanitize = (s: string) => (s ?? "").trim();
  let out = sanitize(args.body);
  let wc = wordCount(out);
  if (!out || wc >= args.minWords) {
    return { body: out, didPad: false, finalWords: wc };
  }

  const blocks = [
    `\n\nDerken ${args.childName}, ${args.themesText} temasının ona öğrettiği en güzel şeyi hatırladı: Küçük adımlar büyük bir yolu tamamlar. Derin bir nefes aldı, etrafına baktı ve kalbinin sesiyle “Ben yapabilirim,” dedi.`,
    `\n\nYolun kenarında bir bankta oturup etrafı dinledi. Rüzgâr yaprakları usulca sallıyor, uzaklardan bir kuş ninni gibi ötüyordu. ${args.childName} gözlerini bir an kapattı; her nefeste omuzları biraz daha yumuşadı.`,
    `\n\nSonra, kendine minik bir plan yaptı: Önce bir adım, sonra bir adım daha… Her adımda “Şimdi buradayım,” diye fısıldadı. Bu söz, içindeki telaşı küçülttü; yerini sakin bir sıcaklığa bıraktı.`,
    `\n\nKarşısına küçük bir zorluk çıktı, ama ${args.childName} acele etmedi. Zorluğu bir bulut gibi hayal etti; bulutlar gelir ve geçer. O da sakince bekledi, düşündü ve en nazik çözümü buldu.`,
    `\n\nMasalın sonunda ${args.childName} evine dönerken, günün hediyelerini tek tek saydı: Bir gülümseme, bir öğrenme, bir cesaret, bir huzur… Hepsi cebinde ışık gibi parlıyordu.`,
    `\n\nYatağına uzandığında, yumuşacık bir battaniye gibi sıcak bir düşünce onu sardı. “Bugün elimden geleni yaptım,” dedi. Ve bu cümle, göz kapaklarına tatlı bir ağırlık verdi.`,
  ];

  let i = 0;
  while (wc < args.minWords && i < 20) {
    out += blocks[i % blocks.length];
    wc = wordCount(out);
    i++;
  }

  // Keep the body from growing unbounded if something goes wrong.
  if (wc > args.maxWords * 1.25) {
    const words = out.split(/\s+/).filter(Boolean);
    out = words.slice(0, Math.floor(args.maxWords * 1.1)).join(" ");
    wc = wordCount(out);
  }

  return { body: out, didPad: true, finalWords: wc };
}

function msSince(start: number): number {
  return Date.now() - start;
}

async function fetchWithTimeout(
  url: string,
  init: RequestInit,
  timeoutMs: number,
  label: string
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

function lengthWordRange(target?: string): { min: number; max: number } {
  // Turkish TTS commonly lands around ~150–180 words/min depending on punctuation and style.
  // These ranges intentionally overshoot a bit to avoid “everything feels < 3 minutes”.
  switch (target as LengthTarget | undefined) {
    case "short":
      // ~3–4 minutes
      return { min: 520, max: 750 };
    case "long":
      // ~9–12 minutes
      return { min: 1_450, max: 2_050 };
    default:
      // Default to short to match iOS behavior when target_length is omitted/invalid.
      return { min: 520, max: 750 };
  }
}

function openAIMaxTokens(target?: string): number {
  // JSON wrapper + Turkish prose; pick safe ceilings per tier.
  switch (target as LengthTarget | undefined) {
    case "short":
      return 2_000;
    case "long":
      return 6_000;
    default:
      return 2_000;
  }
}

function lengthWordGuidance(target?: string): string {
  const { min, max } = lengthWordRange(target);
  switch (target) {
    case "short":
      return `Hedef dinleme süresi yaklaşık 3-4 dakika (sakin anlatım). Gövde için kabaca ${min}-${max} kelime; kısa ve öz ama tam bir masal.`;
    case "long":
      return `Hedef dinleme süresi yaklaşık 9-12 dakika. Gövde için kabaca ${min}-${max} kelime; olayı tamamla, sakin tempoda okunabilir paragraflar.`;
    default:
      return `Hedef dinleme süresi yaklaşık 3-4 dakika (varsayılan). Gövde için kabaca ${min}-${max} kelime; baş-orta-son dengeli, uyku öncesi ritim.`;
  }
}

const ELEVEN_TTS_STYLE_RULES = `Seslendirme: Metin ElevenLabs TTS ile okunacak. Duraklar ve vurgu noktalama ile gelir: tam cümleler kur; virgül ve nokta ile nefes yerlerini ayarla; diyalogda tırnak kullan; abartılı ünlem ve tamamı büyük harf (ALL CAPS) kullanma.`;

function systemPromptForAge(ageHint: string, targetLength?: string): string {
  const len = lengthWordGuidance(targetLength);
  return `Sen Türkçe konuşan, çocuklar için güvenli uyku masalları yazan bir asistansın.
Kurallar:
- Sadece Türkçe yaz.
- Şiddet, korku, yaralanma, ölüm yok.
- Çocuk kahraman olsun; yaşa uygun kelime hazısı (${ageHint}).
- ${len}
- ${ELEVEN_TTS_STYLE_RULES}
- Aynı temalar tekrarlansa bile her masalda farklı olay örgüsü ve farklı yardımcı unsur kullan; kullanıcıdaki çeşitlilik ipuçları zorunlu kontrol listesi değil, yön veren önerilerdir. Klişe kalıplardan kaçın.
- Sıcak, yatıştırıcı ton.
- JSON döndür: {"title":"...","body":"...","genre":"calming|adventure|educational"}`;
}

function ageGroupHint(age: string): string {
  switch (age) {
    case "2-4":
      return "2-4 yaş, çok basit cümleler";
    case "5-7":
      return "5-7 yaş";
    default:
      return "8+ yaş";
  }
}

function authOk(request: Request, env: Env): boolean {
  const token = env.PROXY_AUTH_TOKEN;
  if (!token) return true;
  const h = request.headers.get("Authorization") ?? "";
  return h === `Bearer ${token}`;
}

/** Client IP for rate limiting (set by Cloudflare). Falls back if missing (e.g. some local tests). */
function rateLimitClientKey(request: Request): string {
  return (
    request.headers.get("CF-Connecting-IP") ??
    request.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() ??
    "unknown"
  );
}

async function enforceRateLimit(
  env: Env,
  request: Request
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
    }
  );
}

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

async function handleStory(request: Request, env: Env): Promise<Response> {
  const startedAt = Date.now();
  const reqID = crypto.randomUUID();
  let body: StoryRequest;
  try {
    body = (await request.json()) as StoryRequest;
  } catch {
    return new Response(JSON.stringify({ error: "invalid_json" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const hint = ageGroupHint(body.age_group);
  const themesText = body.themes.length ? body.themes.join(", ") : "(tema belirtilmedi)";
  const baseUser = `Çocuğun adı: ${body.child_name}. Yaş grubu: ${body.age_group}. Temalar: ${themesText}. ${body.behavioral_goal ? "Davranış hedefi: " + body.behavioral_goal + "." : ""} Masalı bu profile göre kişiselleştir.`;
  const seeds = sampleStorySeeds();
  const user = `${baseUser}\n\n${buildVariationBlock(seeds)}`;

  const range = lengthWordRange(body.target_length);
  console.log(
    `[story ${reqID}] target_length=${body.target_length ?? "none"} word_range=${range.min}-${range.max}`
  );

  async function callOpenAI(extraUser?: string): Promise<Response> {
    const messages: { role: "system" | "user"; content: string }[] = [
      {
        role: "system",
        content:
          systemPromptForAge(hint, body.target_length) +
          `\n\nÇok önemli: JSON içindeki "body" alanı ${range.min}-${range.max} kelime aralığında olmalı. Bu aralığın altına düşme.`,
      },
      { role: "user", content: user },
    ];
    if (extraUser) messages.push({ role: "user", content: extraUser });

    return fetchWithTimeout(
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
          messages,
          temperature: 0.6,
          max_tokens: openAIMaxTokens(body.target_length),
        }),
      },
      45_000,
      "openai"
    );
  }

  let openaiRes: Response;
  try {
    openaiRes = await callOpenAI();
  } catch (err) {
    const msg = (err as Error).message ?? "openai_error";
    console.log(`[story ${reqID}] openai fetch failed: ${msg}`);
    return new Response(JSON.stringify({ error: msg, request_id: reqID }), {
      status: 504,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!openaiRes.ok) {
    const t = await openaiRes.text();
    return new Response(JSON.stringify({ error: "openai", detail: t }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const openaiJson = (await openaiRes.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const raw = openaiJson.choices?.[0]?.message?.content ?? "{}";
  let parsed: { title?: string; body?: string; genre?: string };
  try {
    parsed = JSON.parse(raw);
  } catch {
    return new Response(JSON.stringify({ error: "parse" }), { status: 502 });
  }

  const padded = padStoryBodyIfTooShort({
    body: parsed.body ?? "",
    minWords: range.min,
    maxWords: range.max,
    childName: body.child_name,
    themesText,
  });
  parsed.body = padded.body;

  const finalWC = padded.finalWords;
  console.log(
    `[story ${reqID}] final word_count=${finalWC} target_length=${body.target_length ?? "none"}`
  );
  if (padded.didPad) {
    console.log(`[story ${reqID}] padded_to_min_words=true`);
  }

  const out = {
    title: parsed.title ?? "Masal",
    body: parsed.body ?? "",
    genre: parsed.genre ?? "calming",
    word_count: finalWC,
    model: "gpt-4o-mini",
    request_id: reqID,
    target_length: body.target_length ?? null,
    min_words: range.min,
  };

  return new Response(JSON.stringify(out), {
    headers: { "Content-Type": "application/json" },
  });
}

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
      45_000,
      "elevenlabs"
    );
  } catch (err) {
    const msg = (err as Error).message ?? "elevenlabs_error";
    return new Response(JSON.stringify({ error: msg }), {
      status: 504,
      headers: { "Content-Type": "application/json" },
    });
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
        return new Response(
          JSON.stringify({
            error: "quota_exceeded",
            message:
              "Seslendirme kotası doldu. Lütfen daha sonra tekrar dene veya uygulamayı günün ilerleyen saatlerinde tekrar dene.",
            detail: msg ?? null,
          }),
          { status: 402, headers: { "Content-Type": "application/json" } }
        );
      }
    } catch {
      // ignore JSON parse failure
    }
    return new Response(
      JSON.stringify({
        error: "tts_failed",
        message: "Seslendirme şu anda yapılamadı. Lütfen tekrar dene.",
        detail: t.slice(0, 800),
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(elevenRes.body, {
    headers: { "Content-Type": "audio/mpeg" },
  });
}
