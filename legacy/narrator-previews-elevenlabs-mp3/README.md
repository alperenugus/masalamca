# Legacy ElevenLabs Narrator Previews (MP3)

This folder holds legacy ElevenLabs narrator preview MP3 files, now replaced by Gemini TTS WAV previews.

## Historical convention

Bundled narrator previews were named `{elevenlabs_voice_id}.mp3` under `MasalAmca/Resources/Audio/`. Each file was a short TTS sample keyed by the ElevenLabs voice UUID.

## Current convention (v1.3+)

Narrator previews use **Gemini speaker short names** with WAV format:
- `Achernar.wav`, `Algieba.wav`, `Alnilam.wav`, `Aoede.wav`, `Erinome.wav`, `Fenrir.wav`, `Iapetus.wav`, `Sulafat.wav`
- These live in `MasalAmca/MasalAmca/Resources/Audio/` and are referenced via `NarratorChoice.voiceName`.

## ElevenLabs voice ID mapping (for reference)

| Narrator | ElevenLabs Voice ID | Gemini Voice Name |
|----------|--------------------|--------------------|
| Yumuşak Bulut | `oPC5I9GKjMReiaM29gjY` (Gökçe Deniz) | Achernar |
| Bilge Dede | `NfwyWIJnRR1RrYnStGUG` (Serdar Sağlam) | Algieba |
| Yakamoz | `mF7tIc9VLrznhGooGjaT` | Alnilam |
| Ihlamur | `LYfSi2g3Frvxg50fRl91` | Aoede |
| Çam Fısıltısı | `LCHGt3rsPMP50Vs28amI` | Iapetus |
| Lavanta | `ywzrmJ3AgYiLqAeZAGrq` | Erinome |
| Rüzgar | `j9K9HnBcmgA6xNWqjlX0` | Fenrir |
| Gelincik | `bqaNYmxFgK1TN7CL95PZ` | Sulafat |

## ElevenLabs configuration (removed in v1.3)

The following were removed from the codebase:

### Info.plist keys
- `ElevenLabsVoiceID` — default female voice UUID
- `ProxyTTSEngine` — provider switch (`google` / `elevenlabs`)

### Worker secrets (no longer needed)
- `ELEVENLABS_API_KEY`
- `ELEVENLABS_VOICE_ID`
- `TTS_PROVIDER` env var

### Worker code
- `handleTTSElevenLabs()` function
- `ELEVEN_TTS_MODEL` constant (`eleven_flash_v2_5`)
- Dual-mode `ttsProvider()` routing

### iOS code
- `NarratorChoice.elevenLabsVoiceIdentifier()` method
- `NarratorChoice.defaultFemaleVoiceID()` method
- All `static let *VoiceID` constants
- `AppConfiguration.ProxyTTSEngine` enum
- `AppConfiguration.proxyTTSEngine` computed property

If you still have the old MP3 files locally, move them here. Nothing in this directory is referenced by the Xcode project.
