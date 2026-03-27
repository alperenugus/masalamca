# Masal Amca — developer setup checklist

Use this when configuring a new machine or shipping a build.

## Apple Developer & Xcode

1. **Apple ID / team**  
   Open the project in Xcode → **Signing & Capabilities** → select your **Team** for targets: `MasalAmca`, `MasalAmcaWidget`.

2. **App Group (required for Home Screen widget)**  
   - [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) → **Identifiers** → **App Groups** → create `group.alperenugus.MasalAmca` (or change the string in code + entitlements to match your group).  
   - In Xcode, for **MasalAmca** and **MasalAmcaWidget**, add capability **App Groups** and tick the same group ID.  
   - Entitlements files already list `group.alperenugus.MasalAmca`; they must match the portal.

3. **Live Activities**  
   - `Info.plist` includes `NSSupportsLiveActivities`.  
   - On device: **Settings → Face ID & Passcode** (or Touch ID) → allow Live Activities if needed; also **Settings → Masal Amca** if per-app toggles appear.  
   - Simulator: Live Activities work on supported simulators; lock the simulator to see the lock screen card.

4. **CloudKit** (optional / premium)  
   - Create an **iCloud** container in the developer portal.  
   - Add the container ID to `MasalAmca.entitlements` under `com.apple.developer.icloud-container-identifiers`.  
   - App already falls back to local-only SwiftData if CloudKit fails.

5. **Push notifications** (only if you add remote push later)  
   - Enable **Push Notifications** capability; update `aps-environment` for production when distributing.

6. **StoreKit**  
   - In [App Store Connect](https://appstoreconnect.apple.com), create subscription products whose IDs match `AppConfiguration` in the app (e.g. monthly/yearly premium).  
   - For local testing, add a **StoreKit Configuration** file in Xcode if you do not want to hit the sandbox yet.

---

## Edge proxy (Cloudflare Worker)

1. **Install tooling**  
   - Node.js + `npm install` inside `edge/`.  
   - Install Wrangler: `npm i -g wrangler` (or use `npx wrangler`).

2. **Provider API keys (never in the iOS app)**  
   - **OpenAI** or **Anthropic**: API key with billing enabled.  
   - **ElevenLabs**: API key + a **Turkish** voice ID you like (test several in the ElevenLabs UI).

3. **Worker secrets / env**  
   Copy `edge/.env.example` and set (names may match your `edge/src/index.ts`):

   - `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY`  
   - `ELEVENLABS_API_KEY`  
   - `ELEVENLABS_VOICE_ID` (default voice)  
   - `PROXY_AUTH_TOKEN` (shared secret; app sends `Authorization: Bearer <token>`)

   Deploy: `wrangler deploy` then `wrangler secret put OPENAI_API_KEY` (etc.) as needed.

4. **Rate limits & monitoring**  
   - Confirm KV / limits in Worker match your product policy.  
   - Set billing alerts on OpenAI, ElevenLabs, and Cloudflare.

---

## iOS app configuration (`Info.plist` or build settings)

Set these for real network + TTS (not committed with secrets):

| Key | Purpose |
|-----|--------|
| `ProxyBaseURL` | HTTPS base URL of the deployed Worker (no trailing slash). |
| `ProxyAuthToken` | Same value as `PROXY_AUTH_TOKEN` on the Worker. |
| `ElevenLabsVoiceID` | Voice UUID passed to `/v1/tts` (can match Worker default). |

Optional: move these to an **.xcconfig** per configuration (Debug/Release) so keys are not in the plist in git.

---

## Widget & Live Activity (after code)

1. Build and run on a **physical device** once (recommended) to verify signing + App Group.  
2. Add the **Masal Amca** widget from the iOS widget gallery (small/medium).  
3. Open a story in the player: Live Activity should start; sleep timer from the **⋯** menu should show a countdown on the lock screen / Dynamic Island.

---

## Quality & legal (before App Store)

- **KVKK / privacy**: hosting policy URL, what you store (child name, stories), AI disclosure.  
- **App Review**: kids/parent-facing copy, no ads, no unnecessary tracking.  
- **Encryption**: `ITSAppUsesNonExemptEncryption` is already `false` if you only use HTTPS.

---

## Quick verification commands

```bash
cd MasalAmca
xcodebuild build -scheme MasalAmca -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

```bash
cd edge && npx wrangler dev   # then curl /v1/story and /v1/tts per README
```
