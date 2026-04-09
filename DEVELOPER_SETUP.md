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
   - **Introductory offer / trial:** 3-day free trial. Paywall copy is driven from `Product.subscription?.introductoryOffer`. Configure in App Store Connect.
   - **Local testing:** Create a StoreKit Configuration File (`.storekit`) in Xcode with the same product IDs. Set the scheme's **Run → Options → StoreKit Configuration** to that file.
   - **Sandbox:** Sign in with a sandbox Apple ID under **Settings → Developer**.

7. **Subscription model**
   | Tier | Limit | Gates |
   |------|-------|-------|
   | Free | 2 stories lifetime | 3 white noise sounds, 2 narrators, 9 themes |
   | Premium | 2 stories/day | All 24 themes (5 categories), 6 sounds, 8 narrators, background music |
   | Trial | 3 days | Full premium |

8. **Legal links**
   Set in `Info.plist`: `TermsOfUseURL`, `PrivacyPolicyURL`. Paywall shows tappable links per Guideline 3.1.2(c).

9. **Bedtime reminders**
   Uses `UserNotifications` with `UNCalendarNotificationTrigger`. No remote push needed. Only the active child's reminder is scheduled.

---

## Edge Proxy (Cloudflare Worker)

The Worker is a **pure proxy** — it does NOT build prompts or hold story logic. The iOS app sends the complete `messages` array.

1. **Install tooling**
   ```bash
   cd edge && npm install
   npm i -g wrangler   # or use npx wrangler
   ```

2. **Provider API keys (never in the iOS app)**
   - **OpenAI**: API key with billing enabled (GPT-4o-mini)
   - **Google Cloud**: Service account JSON with Cloud Text-to-Speech API enabled

3. **Worker secrets**
   ```bash
   wrangler secret put OPENAI_API_KEY
   wrangler secret put PROXY_AUTH_TOKEN
   wrangler secret put GOOGLE_SERVICE_ACCOUNT_JSON
   ```

4. **Deploy**
   ```bash
   npx wrangler deploy
   ```

5. **Story generation pipeline**
   The Worker receives the full `{ messages: [...] }` from the iOS app and forwards to OpenAI. It parses the response, joins `body[]` array into a string, and returns `{ title, body, genre, word_count, model }`.

   Prompt logic lives entirely in the iOS app:
   - `PromptOrchestrator.swift` — builds system + user messages
   - `StorySeeds.swift` — 41 places, 40 side characters, randomized per request
   - `StoryPreferences.swift` — 24 themes in 5 categories via `StoryThemeCategory`

   TTS uses **Google Gemini Flash TTS** (`gemini-2.5-flash-tts`) via the Cloud Text-to-Speech API.

---

## iOS App Configuration (`Info.plist`)

| Key | Purpose |
|-----|---------|
| `ProxyBaseURL` | HTTPS base URL of deployed Worker |
| `ProxyAuthToken` | Shared secret with Worker |
| `TermsOfUseURL` | EULA link for paywall |
| `PrivacyPolicyURL` | Privacy policy link for paywall |

**Security:** Move secrets to `.xcconfig` per configuration (Debug/Release) so keys are not in the plist in git.

---

## Audio Architecture

- **Audio session**: `.playback` category, no `.mixWithOthers` (enables lock screen Now Playing card). Multiple AVAudioPlayers in the same process play concurrently regardless.
- **AudioPlayerService**: Singleton at app level. Owns story playback, Now Playing metadata, remote commands (play/pause/next/prev), playlist tracking. Survives navigation and tab switches. Verifies audio-story identity (both ID and title must match).
- **MixerEngine**: Singleton at app level. Owns white noise playback, focused sound tracking, skip logic with subscription checks. Takes over Now Playing when no story is active. `solo()` stops story playback. Skip automatically bypasses premium sounds for free users.

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
