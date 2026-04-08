# Masal Amca — Developer Setup Checklist

Use this when configuring a new machine or shipping a build.

## Apple Developer & Xcode

1. **Apple ID / team**
   Open the project in Xcode → **Signing & Capabilities** → select your **Team** for targets: `MasalAmca`, `MasalAmcaWidget`, `MasalAmcaTests`, `MasalAmcaUITests`.

2. **Deployment target**
   All targets: **iOS 17.0**. iPhone and iPad only (`TARGETED_DEVICE_FAMILY = 1,2`).

3. **App Group (required for Home Screen widget)**
   - [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) → **Identifiers** → **App Groups** → create `group.alperenugus.MasalAmca`.
   - In Xcode, for **MasalAmca** and **MasalAmcaWidget**, add capability **App Groups** and tick the same group ID.
   - Entitlements files already list `group.alperenugus.MasalAmca`; they must match the portal.

4. **Live Activities**
   - `Info.plist` includes `NSSupportsLiveActivities`.
   - Infrastructure exists but is intentionally not wired during playback — lock screen uses native Now Playing instead.

5. **CloudKit** (optional / premium)
   - Create an **iCloud** container in the developer portal.
   - Add the container ID to `MasalAmca.entitlements` under `com.apple.developer.icloud-container-identifiers`.
   - App falls back to local-only SwiftData if CloudKit fails (current default: `cloudKitDatabase: .none`).

6. **StoreKit**
   - In [App Store Connect](https://appstoreconnect.apple.com), create subscription products:
     - `alperenugus.MasalAmca.premium.monthly`
     - `alperenugus.MasalAmca.premium.yearly`
   - **Introductory offer / trial:** Paywall copy is driven from `Product.subscription?.introductoryOffer`. Configure in App Store Connect.
   - **Local testing:** Create a StoreKit Configuration File (`.storekit`) in Xcode with the same product IDs. Set the scheme's **Run → Options → StoreKit Configuration** to that file.
   - **Sandbox:** Sign in with a sandbox Apple ID under **Settings → Developer**.

7. **Subscription model**
   | Tier | Limit | Gates |
   |------|-------|-------|
   | Free | 2 stories lifetime | 3 white noise sounds, 2 narrators |
   | Premium | 2 stories/day | All 15 themes, 6 sounds, 8 narrators, background music |

8. **Legal links**
   Set in `Info.plist`: `TermsOfUseURL`, `PrivacyPolicyURL`. Paywall shows tappable links per Guideline 3.1.2(c).

9. **Bedtime reminders**
   Uses `UserNotifications` with `UNCalendarNotificationTrigger`. No remote push needed. Only the active child's reminder is scheduled.

---

## Edge Proxy (Cloudflare Worker)

1. **Install tooling**
   ```bash
   cd edge && npm install
   npm i -g wrangler   # or use npx wrangler
   ```

2. **Provider API keys (never in the iOS app)**
   - **OpenAI**: API key with billing enabled (GPT-4o-mini)
   - **ElevenLabs**: API key + Turkish voice IDs (multilingual_v2 model)

3. **Worker secrets**
   ```bash
   wrangler secret put OPENAI_API_KEY
   wrangler secret put ELEVENLABS_API_KEY
   wrangler secret put ELEVENLABS_VOICE_ID    # default voice
   wrangler secret put PROXY_AUTH_TOKEN        # shared with iOS app
   ```

4. **Deploy**
   ```bash
   wrangler deploy
   ```

5. **Story generation pipeline**
   - System prompt: age-appropriate Turkish, TTS-optimized punctuation, JSON output
   - `storySeeds.ts`: random place, side character, plot hook, family thread, object — injected each request for variety
   - Word count enforcement: `lengthWordRange()` per target length, padding if LLM undershoots
   - Model: `gpt-4o-mini` with `temperature: 0.6`

---

## iOS App Configuration (`Info.plist`)

| Key | Purpose |
|-----|---------|
| `ProxyBaseURL` | HTTPS base URL of deployed Worker |
| `ProxyAuthToken` | Shared secret with Worker |
| `ElevenLabsVoiceID` | Default voice UUID for TTS |
| `TermsOfUseURL` | EULA link for paywall |
| `PrivacyPolicyURL` | Privacy policy link for paywall |

**Security:** Move secrets to `.xcconfig` per configuration (Debug/Release) so keys are not in the plist in git.

---

## Audio Architecture

- **Audio session**: `.playback` category, no `.mixWithOthers` (enables lock screen Now Playing card). Multiple AVAudioPlayers in the same process play concurrently regardless.
- **AudioPlayerService**: Singleton at app level. Owns story playback, Now Playing metadata, remote commands (play/pause/next/prev), playlist tracking. Survives navigation and tab switches.
- **MixerEngine**: Singleton at app level. Owns white noise playback, focused sound tracking, skip logic with subscription checks. Takes over Now Playing when no story is active. `solo()` stops story playback.

---

## Build Verification

```bash
cd MasalAmca

# Debug (device)
xcodebuild build -scheme MasalAmca -destination 'generic/platform=iOS'

# Release (device)
xcodebuild build -scheme MasalAmca -destination 'generic/platform=iOS' -configuration Release

# Simulator
xcodebuild build -scheme MasalAmca -destination 'platform=iOS Simulator,id=<UDID>'
```

```bash
cd edge && npx wrangler dev   # local proxy testing
```
