/**
 * Masal Amca — secure proxy for LLM story generation + ElevenLabs TTS.
 * Set secrets: OPENAI_API_KEY, ELEVENLABS_API_KEY, PROXY_AUTH_TOKEN (optional voice id in ELEVENLABS_VOICE_ID)
 */

import { buildVariationBlock, sampleStorySeeds } from "./storySeeds";

export interface Env {
  OPENAI_API_KEY: string;
  ELEVENLABS_API_KEY: string;
  ELEVENLABS_VOICE_ID?: string;
  PROXY_AUTH_TOKEN?: string;
  RATE_LIMIT?: KVNamespace;
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

/** Lansman: düşük birim maliyet; kalite için `eleven_multilingual_v2`ye dönülebilir. */
const ELEVEN_TTS_MODEL = "eleven_flash_v2_5";

interface TTSRequest {
  text: string;
  voice_id: string;
  output_format: string;
}

function lengthWordGuidance(target?: string): string {
  switch (target) {
    case "short":
      return "Hedef dinleme süresi yaklaşık 3 dakika (sakin anlatım). Gövde için kabaca 250-350 kelime; kısa ve öz ama tam bir masal.";
    case "long":
      return "Hedef dinleme süresi yaklaşık 10 dakika. Gövde için kabaca 650-950 kelime; olayı tamamla, sakin tempoda okunabilir paragraflar.";
    default:
      return "Hedef dinleme süresi yaklaşık 5 dakika. Gövde için kabaca 400-650 kelime; baş-orta-son dengeli, uyku öncesi ritim.";
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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (!authOk(request, env)) {
      return new Response("Unauthorized", { status: 401 });
    }

    if (request.method === "POST" && url.pathname.endsWith("/v1/story")) {
      return handleStory(request, env);
    }
    if (request.method === "POST" && url.pathname.endsWith("/v1/tts")) {
      return handleTTS(request, env);
    }
    return new Response("Masal Amca proxy", { status: 200 });
  },
};

async function handleStory(request: Request, env: Env): Promise<Response> {
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

  const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: systemPromptForAge(hint, body.target_length),
        },
        { role: "user", content: user },
      ],
      temperature: 0.7,
    }),
  });

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

  const out = {
    title: parsed.title ?? "Masal",
    body: parsed.body ?? "",
    genre: parsed.genre ?? "calming",
    word_count: parsed.body?.split(/\s+/).filter(Boolean).length ?? 0,
    model: "gpt-4o-mini",
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

  const elevenRes = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voice)}`,
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
    }
  );

  if (!elevenRes.ok) {
    const t = await elevenRes.text();
    return new Response(t, { status: 502 });
  }

  return new Response(elevenRes.body, {
    headers: { "Content-Type": "audio/mpeg" },
  });
}
