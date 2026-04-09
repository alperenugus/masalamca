# TODO: Remove legacy worker compatibility (story + TTS)

After the **new app version** (structured story request + Gemini `voice_id` only)
has shipped and essentially all users have upgraded, remove the backward-compat
code below and deploy the worker.

---

## 1. Legacy `/v1/story` — `messages` array

### What

The Cloudflare Worker (`edge/src/index.ts`) currently supports **two** request
formats on `POST /v1/story`:

| Format | App version | Detection |
|--------|-------------|-----------|
| **New (v2)** — `{ child_name, age_group, themes }` | v1.3+ | Has `child_name` field |
| **Legacy** — `{ messages: [...] }` | v1.2 and earlier | Has `messages` array |

The auto-detection lives in `handleStory()`. If the payload contains a
`messages` array, it routes to `handleStoryLegacy()` which forwards the
pre-built messages to OpenAI as-is (pure proxy). Otherwise it routes to
`handleStoryV2()` which builds prompts server-side.

### Why it exists

To avoid breaking existing v1.2 users while the v1.3 update rolls out through
App Store review and user upgrades.

### How to remove

1. In `edge/src/index.ts`:
   - Delete the `LegacyStoryRequest` interface.
   - Delete the `handleStoryLegacy()` function.
   - Simplify `handleStory()` to directly call `handleStoryV2()` logic
     (or inline it).
   - Remove the `messages` array detection branch.

---

## 2. Legacy `/v1/tts` — ElevenLabs `voice_id` → Gemini mapping

### What

Old App Store builds send **ElevenLabs voice IDs** (e.g. from `Info.plist` or
`NarratorChoice` constants) as `voice_id`. Google Gemini TTS expects **speaker
names** (`Achernar`, `Algieba`, …). The worker maps known legacy IDs via
`LEGACY_ELEVENLABS_TO_GEMINI` and uses `GEMINI_SPEAKER_NAMES` to pass through
names the new app already sends.

### Why it exists

So production users on the pre–Gemini app keep working after the worker switched
to Google TTS.

### How to remove

1. In `edge/src/index.ts`:
   - Delete `LEGACY_ELEVENLABS_TO_GEMINI` and the comment block above it.
   - Delete `GEMINI_SPEAKER_NAMES` if you no longer need pass-through
     validation (or keep a minimal check if you want).
   - Simplify `resolveGeminiVoice()` to only handle `default`/empty and real
     Gemini speaker names (same behavior as the current iOS app).

---

## When to remove (both sections)

Once you are confident the vast majority of users are on the **new** app
(structured story + Gemini voices). A reasonable timeline is **4–6 weeks after
that release**, or when App Store analytics show negligible use of old builds.

## Final step

1. Deploy the worker with `wrangler deploy`.
2. Delete this file (`TODO_REMOVE_LEGACY_STORY_PATH.md`).
