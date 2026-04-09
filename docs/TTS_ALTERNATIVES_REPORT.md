# Masal Amca — TTS Provider Alternatives Report

**Purpose:** Compare TTS options for **Turkish** bedtime-story narration with **clear pronunciation** and **natural, emotional delivery** (warm, expressive—not flat or robotic). **Voice cloning is not a requirement** for now; **stock / preset voices** are fine if they sound good in Turkish.

**Last updated:** April 2026

**Disclaimer:** Vendor pricing, models, and language lists change frequently. Treat dollar figures as **order-of-magnitude planning estimates**. Confirm on each vendor’s official pricing and docs before committing.

---

## 1. Product priorities (current scope)

| Priority | What to validate |
|----------|-------------------|
| **Turkish** | Correct language code, natural sentence melody, acceptable handling of suffixes and proper nouns |
| **Pronunciation** | Clear consonants/vowels; minimal “foreign accent” artifacts on Turkish text |
| **Emotional / expressive speech** | Warm, calming bedtime tone; variation (not monotone); supports long-form listening without fatigue |
| **API + predictable cost** | Fits Cloudflare Worker or backend proxy; per-character or clear quota |

**Out of scope for now:** Custom voice cloning, brand-owned voice training, or per-user voice upload.

**Engineering note:** “Emotional” quality is partly **model + voice preset**, partly **prompting**: short sentences, commas for pauses, SSML where supported (Polly, Azure, Google).

---

## 2. Baseline: ElevenLabs (current stack)

| Aspect | Notes |
|--------|--------|
| **Why it’s strong here** | Neural voices often score well on **expressiveness** and **prosody** for long Turkish passages—good fit for “masal” narration |
| **Models** | e.g. Flash v2.5 (cost/quality balance), Multilingual v2 (often richer; higher cost) |
| **Turkish** | Use multilingual / Flash model cards; pick Turkish-capable presets |
| **Rough cost** | ~**$0.42 per story** at ~3,500 characters on Flash-class overage (see [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md)) |
| **Trade-off** | **COGS** is high vs hyperscalers; you pay partly for **expressiveness** without cloning |

---

## 3. Short list by goal (preset voices only)

### 3.1 Best candidate to **match** “emotional + Turkish” (listen first)

| Provider | Why try it |
|----------|------------|
| **ElevenLabs** (keep) | Strong default for **warm, non-monotone** long-form; you already integrated |
| **Google Cloud TTS** (**Chirp / HD** class) | Often strong **neural** quality and languages; verify **Turkish** voice names and “Studio”/HD tier for expressiveness |
| **Cartesia Sonic** (multilingual, `tr`) | Modern models; good for **natural** delivery; evaluate Turkish samples for bedtime tone |
| **Amazon Polly** | Neural **Burcu** for Turkish—**very cheap**; emotion range may be **narrower** than EL; worth A/B testing |

### 3.2 Best candidate to **cut cost** (accept possible quality trade-off)

| Provider | Notes |
|----------|--------|
| **Amazon Polly** (neural **Burcu**) | Among the lowest $/character; test **pronunciation + warmth** on real masal scripts |
| **OpenAI TTS** (`tts-1` / `tts-1-hd`) | Low $/char; **Turkish** quality and **emotion** must be validated—often more “neutral” than ElevenLabs for storytelling |

### 3.3 Usually **less relevant** without cloning

| Provider | Note |
|----------|------|
| **Resemble / Fish** (clone-first positioning) | Fine if they expose **preset** Turkish voices with good API pricing—only pursue if listening tests beat Polly/OpenAI |

---

## 4. Comparison table (preset / stock voices; no cloning)

Rough **variable cost** at ~**3,500 characters** per story (see [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md)). **Expressiveness** is subjective—**listen** before switching.

| Provider | Turkish (preset) | Expressiveness (typical) | Rough $/story* |
|----------|------------------|---------------------------|----------------|
| **ElevenLabs** | Yes | **High** (industry benchmark for “AI narrator”) | **~$0.35–0.45** (Flash-class) |
| **Google Chirp / HD-class** | Yes (verify voice) | **High–very high** (tier-dependent) | **~$0.10–0.12** (list HD band) |
| **Cartesia Sonic** (`tr`) | Yes | **High** (often natural) | Plan/credit-dependent |
| **Amazon Polly neural (Burcu)** | Yes | **Medium** (clear; less “actorly” than EL) | **~$0.05–0.06** |
| **OpenAI TTS** | Verify latest | **Medium** (often flatter than EL for long Turkish) | **~$0.05** (`tts-1`) |
| **Deepgram Aura** | Check `tr` | Varies | ~**$0.10** band (reported PAYG) |

\* Order-of-magnitude; confirm current pricing.

---

## 5. Evaluation protocol (pronunciation + emotion)

Use **the same** 3–5 Turkish scripts (bedtime story excerpts, 300–800 characters each):

1. **Blind listen** (parents): warmth, calm, “storyteller” vs “GPS voice,” fatigue after 2–3 minutes  
2. **Pronunciation**: proper nouns, dialogue in quotes, numbers—any systematic errors?  
3. **SSML / punctuation**: try comma-heavy vs short sentences; see if the voice **breathes** naturally  
4. **Cost**: measure **characters billed** per story in the provider dashboard  

**Pass bar:** Good enough that you would ship to families without apology; **fail** if it sounds robotic or mispronounces common Turkish in ways parents would notice.

---

## 6. Cost scenario (illustrative, preset voices)

| Scenario | ElevenLabs Flash-class | AWS Polly neural (Burcu) | OpenAI `tts-1` (indicative) |
|----------|------------------------|--------------------------|-----------------------------|
| **1 story (~3.5k chars)** | ~$0.42 | ~$0.056 | ~$0.053 |
| **1,000 stories/mo** | ~$420 | ~$56 | ~$53 |

**Insight:** You can cut **TTS COGS by ~5–8×** moving to Polly or OpenAI **if** listening tests pass for **Turkish + emotional** requirements. If not, **Google HD/Chirp** or staying on **ElevenLabs** may be the better product trade-off.

---

## 7. Practical recommendation (no cloning)

| Situation | Suggestion |
|-----------|------------|
| **Quality first; budget secondary** | Keep **ElevenLabs** (Flash or step up model if needed) or pilot **Google Chirp/HD** + **Cartesia** in parallel listening tests |
| **Budget first; willing to iterate on prompts/SSML** | Pilot **Amazon Polly Burcu**; tune text (short sentences, pauses) to maximize warmth |
| **Single-vendor simplicity** | **OpenAI** for both LLM + TTS only if Turkish samples are **clearly** acceptable—do not assume |

---

## 8. Migration checklist (preset voices)

1. **Language:** Turkish on the **exact** model/voice ID in production  
2. **Metering:** Characters vs bytes vs seconds—align Worker logs with invoice  
3. **Latency & limits:** Max request size for full masal text  
4. **Acceptance:** Parent/stakeholder sign-off on **pronunciation + emotional tone** (not only WER)  
5. **Fallback:** Abstract TTS behind one interface in the Worker so you can revert or A/B providers  

---

## 9. References (verify live)

- [Amazon Polly pricing](https://aws.amazon.com/polly/pricing/) · [Voices](https://docs.aws.amazon.com/polly/latest/dg/available-voices.html)  
- [Google Cloud Text-to-Speech pricing](https://cloud.google.com/text-to-speech/pricing)  
- [Azure AI Speech pricing](https://azure.microsoft.com/pricing/details/cognitive-services/speech-services/)  
- [OpenAI pricing](https://openai.com/pricing)  
- [Cartesia docs](https://docs.cartesia.ai/)  
- [ElevenLabs API pricing](https://elevenlabs.io/pricing/api)  

---

*This report supports product and engineering planning only; it is not financial or legal advice.*
