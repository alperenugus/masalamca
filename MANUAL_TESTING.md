# Masal Amca — Manual testing checklist

Run on **physical device** for CloudKit, background audio, and StoreKit. Use **iPhone 17** (or current) simulator for UI smoke tests.

## Onboarding & paywall (repeat ×3 child names)

- [ ] Fresh install: onboarding shows hero, title, subtitle.
- [ ] Empty name: Devam Et disabled / faded.
- [ ] Enter name only: age defaults 2-4; themes optional.
- [ ] Toggle each age segment 2-4, 5-7, 8+.
- [ ] Select/deselect each theme chip (Hayvanlar, Uzay, Sihir, Masal Dünyası).
- [ ] Devam Et saves profile and presents paywall sheet.
- [ ] Paywall: close (X) dismisses and completes onboarding.
- [ ] Paywall: monthly card tap selects; yearly shows EN POPÜLER styling.
- [ ] Paywall: Ücretsiz Denemeyi Başlat runs purchase flow (or fails gracefully without products).
- [ ] Relaunch: skips onboarding when `onboarding_complete` set.

## Ana Sayfa (×2 orientations if supported)

- [ ] Greeting uses active child name.
- [ ] Generate CTA shows progress while generating.
- [ ] Without proxy URL: demo story created and full-screen player opens.
- [ ] With proxy: network error shows alert with Turkish message.
- [ ] Second free story allowed; third blocked with paywall (non-premium).
- [ ] Son Dinlenenler horizontal scroll; tap opens player.
- [ ] Quick noise: Rain / Şömine / Okyanus toggles (premium lock on şömine for free tier).
- [ ] Günün İpucu card visible.
- [ ] Tab bar: Ana Sayfa active pill; switch to Kitaplık / Ayarlar.

## Kitaplık

- [ ] Search filters titles (Turkish characters).
- [ ] Chips: Tümü, Favoriler, Uyku, Macera filter lists.
- [ ] Row tap opens player.
- [ ] Stats bento shows counts consistent with data.
- [ ] Cloud badge visible in nav (static label).

## Ayarlar

- [ ] Premium / Ücretsiz label matches StoreKit state.
- [ ] Aboneliği Yönet opens paywall.
- [ ] Satın Alımları Geri Yükle calls sync.
- [ ] Child list shows all profiles; tap switches active (checkmark).
- [ ] Swipe delete removes child (confirm data).
- [ ] Çocuk Ekle opens editor sheet; save creates profile.

## Story player

- [ ] Back dismisses full screen.
- [ ] Play / pause gradient button.
- [ ] Skip -10 / +30 seek.
- [ ] Star scrubber drag updates position (with audio file).
- [ ] Voice visualizer animates while playing.
- [ ] Mixer panel: each sound slider + toggle (premium gating).
- [ ] Menu: 15 dk / 30 dk sleep timer stops audio at end.
- [ ] Menu: cancel timer.
- [ ] On story natural end: 5s crossfade into enabled mixer layers (if any enabled).
- [ ] Lock screen Now Playing title/artist (device).

## White noise

- [ ] Each bundled WAV loops without gap (audible check).
- [ ] Master: multiple layers mix.
- [ ] Stop all when leaving player (timer / dismiss).

## Accessibility (sample screens ×3)

- [ ] VoiceOver: tab bar items labeled.
- [ ] VoiceOver: generate button announces role.
- [ ] Dynamic Type: largest size — layout no clipping on Home hero.
- [ ] Reduce Motion: disable or reduce bar animation (if implemented).

## Theme

- [ ] No raw `Color.primary` visible (spot check with design reference).
- [ ] Lists in Settings use hidden scroll background + row contrast.
- [ ] Sheets inherit `masalThemeManager` (paywall, editor).

## Edge proxy (staging)

- [ ] `POST /v1/story` returns JSON with title/body/genre.
- [ ] `POST /v1/tts` returns audio/mpeg.
- [ ] Wrong Bearer → 401 when token configured.

## Regression matrix (fill story id / build)

For builds **B1–B10**, repeat critical path: onboarding → 2 stories → paywall gate → restore → delete child.

- [ ] B1 critical path
- [ ] B2 critical path
- [ ] B3 critical path
- [ ] B4 critical path
- [ ] B5 critical path
- [ ] B6 critical path
- [ ] B7 critical path
- [ ] B8 critical path
- [ ] B9 critical path
- [ ] B10 critical path

## Extended VoiceOver pass (50)

- [ ] VO-01 Onboarding name field
- [ ] VO-02 Age segment 2-4
- [ ] VO-03 Age segment 5-7
- [ ] VO-04 Age segment 8+
- [ ] VO-05 Theme chip 1
- [ ] VO-06 Theme chip 2
- [ ] VO-07 Theme chip 3
- [ ] VO-08 Theme chip 4
- [ ] VO-09 Devam Et
- [ ] VO-10 Paywall close
- [ ] VO-11 Paywall monthly
- [ ] VO-12 Paywall yearly
- [ ] VO-13 Paywall CTA
- [ ] VO-14 Home greeting
- [ ] VO-15 Generate CTA
- [ ] VO-16 Recent card 1
- [ ] VO-17 Quick noise row 1
- [ ] VO-18 Quick noise row 2
- [ ] VO-19 Quick noise row 3
- [ ] VO-20 Tab Ana Sayfa
- [ ] VO-21 Tab Kitaplık
- [ ] VO-22 Tab Ayarlar
- [ ] VO-23 Library search
- [ ] VO-24 Library chip Tümü
- [ ] VO-25 Library chip Favoriler
- [ ] VO-26 Library row
- [ ] VO-27 Settings premium row
- [ ] VO-28 Settings restore
- [ ] VO-29 Settings child row
- [ ] VO-30 Settings add child
- [ ] VO-31 Player back
- [ ] VO-32 Player menu
- [ ] VO-33 Player rewind
- [ ] VO-34 Player play
- [ ] VO-35 Player forward
- [ ] VO-36 Mixer slider rain
- [ ] VO-37 Mixer toggle rain
- [ ] VO-38 Mixer fireplace
- [ ] VO-39 Mixer ocean
- [ ] VO-40 Mixer wind
- [ ] VO-41 Mixer shush
- [ ] VO-42 Mixer fan
- [ ] VO-43 Star scrubber
- [ ] VO-44 Tip card
- [ ] VO-45 Bell icon (header)
- [ ] VO-46 Avatar icon
- [ ] VO-47 Cloud badge library
- [ ] VO-48 Stats masal count
- [ ] VO-49 Stats minutes
- [ ] VO-50 Paywall feature row 1

## Dynamic Type matrix (40)

- [ ] DT-XS Home
- [ ] DT-S Home
- [ ] DT-M Home
- [ ] DT-L Home
- [ ] DT-XL Home
- [ ] DT-XXL Home
- [ ] DT-XXXL Home
- [ ] DT-XS Library
- [ ] DT-S Library
- [ ] DT-M Library
- [ ] DT-L Library
- [ ] DT-XL Library
- [ ] DT-XXL Library
- [ ] DT-XXXL Library
- [ ] DT-XS Settings
- [ ] DT-S Settings
- [ ] DT-M Settings
- [ ] DT-L Settings
- [ ] DT-XL Settings
- [ ] DT-XXL Settings
- [ ] DT-XXXL Settings
- [ ] DT-XS Player
- [ ] DT-S Player
- [ ] DT-M Player
- [ ] DT-L Player
- [ ] DT-XL Player
- [ ] DT-XXL Player
- [ ] DT-XXXL Player
- [ ] DT-XS Onboarding
- [ ] DT-S Onboarding
- [ ] DT-M Onboarding
- [ ] DT-L Onboarding
- [ ] DT-XL Onboarding
- [ ] DT-XXL Onboarding
- [ ] DT-XXXL Onboarding
- [ ] DT-XS Paywall
- [ ] DT-S Paywall
- [ ] DT-M Paywall
- [ ] DT-L Paywall
- [ ] DT-XL Paywall

## Network / offline (30)

- [ ] NF-01 Airplane on: open app
- [ ] NF-02 Airplane on: play cached story
- [ ] NF-03 Airplane on: generate shows error
- [ ] NF-04 Wi‑Fi on: generate success
- [ ] NF-05 Flaky network: retry alert
- [ ] NF-06 Timeout handling
- [ ] NF-07 Invalid proxy URL
- [ ] NF-08 Invalid token 401
- [ ] NF-09 TTS empty body
- [ ] NF-10 Story JSON malformed
- [ ] NF-11 Relaunch offline library list
- [ ] NF-12 Relaunch offline thumbnails
- [ ] NF-13 Offline mixer still plays
- [ ] NF-14 Online sync CloudKit (premium, device)
- [ ] NF-15 Second device receives story (CloudKit)
- [ ] NF-16 Delete story offline
- [ ] NF-17 Favorite toggle offline
- [ ] NF-18 Search offline
- [ ] NF-19 Paywall offline message
- [ ] NF-20 Restore offline
- [ ] NF-21–NF-30 reserved regression slots

## StoreKit / quota (20)

- [ ] SK-01 Free user story 1 OK
- [ ] SK-02 Free user story 2 OK
- [ ] SK-03 Free user story 3 paywall
- [ ] SK-04 Premium unlimited (cap if implemented)
- [ ] SK-05 Monthly purchase
- [ ] SK-06 Yearly purchase
- [ ] SK-07 Restore after reinstall
- [ ] SK-08 Refund handling (sandbox)
- [ ] SK-09 Subscription expired UI
- [ ] SK-10 Premium sounds unlock
- [ ] SK-11 Free sounds only gate
- [ ] SK-12 Product load empty state
- [ ] SK-13 Purchase pending state
- [ ] SK-14 Purchase cancel
- [ ] SK-15 Family sharing (if enabled)
- [ ] SK-16 Intro offer (if configured)
- [ ] SK-17 Win-back offer (if any)
- [ ] SK-18 Receipt refresh on launch
- [ ] SK-19 Transaction listener fires
- [ ] SK-20 storiesGeneratedCount persists

## Security & privacy (20)

- [ ] SEC-01 No API keys in binary strings dump
- [ ] SEC-02 Proxy only TLS
- [ ] SEC-03 Child name not logged server-side (verify Worker)
- [ ] SEC-04 Pasteboard story text (if any) not leaking
- [ ] SEC-05 Screenshots paywall OK
- [ ] SEC-06 App switcher snapshot
- [ ] SEC-07 Background audio indicator
- [ ] SEC-08 Microphone unused (no permission prompt)
- [ ] SEC-09 Location unused
- [ ] SEC-10 Tracking transparency N/A
- [ ] SEC-11–SEC-20 reserved

## Performance (10)

- [ ] PERF-01 Cold launch < 3s dev
- [ ] PERF-02 Scroll recent list 60fps
- [ ] PERF-03 Generate UI not frozen (progress)
- [ ] PERF-04 Large story text scroll
- [ ] PERF-05 Memory after 20 stories
- [ ] PERF-06 Disk audio cache size
- [ ] PERF-07 Mixer CPU while 6 layers
- [ ] PERF-08 Tab switch latency
- [ ] PERF-09 Image placeholder weight
- [ ] PERF-10 CloudKit sync duration

---

**Total checklist items:** 200+ (count sections above). Extend with device-specific iPad / multitasking when targeting iPad.
