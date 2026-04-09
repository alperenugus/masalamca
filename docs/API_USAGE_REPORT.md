# Masal Amca — API & Kullanım Raporu

Bu belge, uygulamanın **dış API'lere** nasıl bağlandığını, hangi **modelleri** kullandığını, **istemci ↔ edge proxy ↔ sağlayıcı** akışını, **prompt / güvenlik** katmanını ve **maliyet** çerçevesini özetler.

---

## 1. Mimari özet

| Katman | Rol |
|--------|-----|
| **iOS uygulaması** | SwiftUI + SwiftData. `PromptOrchestrator` tüm prompt mantığını (system + user mesajları) hazırlar. `StorySeeds` rastgele mekan ve karakter seçer. `StoryService` ile yalnızca Cloudflare Worker proxy'ye bağlanır. API anahtarları uygulamada **tutulmaz**. |
| **Edge proxy** (`edge/src/index.ts`) | Saf proxy: iOS'tan gelen `messages[]` dizisini OpenAI'ye iletir. `body[]` dizisini string'e dönüştürür. TTS isteğini ElevenLabs'e iletir. Bearer token ile korunur. Rate limiting uygulanır. Prompt mantığı **yoktur**. |
| **OpenAI** | Masal metni (JSON): `gpt-4o-mini`, `response_format: json_object`, `temperature: 0.7` |
| **ElevenLabs** | Masal sesli anlatımı (MP3): `eleven_flash_v2_5`, Türkçe (`language_code: tr`) |

---

## 2. ElevenLabs paneli: TTS ile müzik üretimini karıştırmayın

ElevenLabs panelindeki toplam "Credit Usage" rakamı, hesaptaki **tüm** ürünleri (TTS, müzik, vb.) kapsar. Masal Amca yalnızca **Text to Speech** hattını kullanır. Beyaz gürültü döngüleri yerel (bundle) dosyalardır — ElevenLabs çağrılmaz.

Maliyet analizi için panelde **yalnızca TTS satırını** filtreleyin.

**Aktif model:** `eleven_flash_v2_5` (Flash v2.5) — Multilingual v2'ye göre ~%50 daha düşük birim maliyet. Türkçe uzun anlatım kalitesi yetersiz kalırsa `eleven_multilingual_v2`'ye dönüş değerlendirilebilir.

---

## 3. Uç noktalar ve modeller

### 3.1 `POST /v1/story` (OpenAI)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.openai.com/v1/chat/completions` |
| **Model** | `gpt-4o-mini` |
| **Çıktı formatı** | `response_format: { type: "json_object" }` |
| **Sıcaklık** | `0.7` |

**İstek gövdesi (uygulama → proxy):**

```json
{
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user", "content": "..." }
  ]
}
```

`PromptOrchestrator` (iOS) bu mesajları hazırlar:
- **System prompt**: Güvenlik kuralları, TTS optimizasyonu, JSON formatı, çeşitlilik direktifleri
- **User message**: Çocuğun adı, yaş grubu, seçilen tema (1 adet), rastgele mekanlar (1-2), rastgele yan karakterler (1-2)

**İçerik çeşitlilik motoru (`StorySeeds.swift`):**
- 41 farklı mekan (açık hava, su, orman, gökyüzü, kapalı, fantastik)
- 40 farklı yan karakter (sihirli, orman, su/gökyüzü, bilge, sevimli)
- Her istek için `shuffled().prefix()` ile benzersiz seçim

**Yanıt (proxy → uygulama):** `{ title, body, genre, word_count, model }`
- `body` alanı OpenAI'den paragraf dizisi (`string[]`) olarak gelir, Worker `\n\n` ile birleştirir.

### 3.2 `POST /v1/tts` (ElevenLabs)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.elevenlabs.io/v1/text-to-speech/{voice_id}` |
| **TTS modeli** | `eleven_flash_v2_5` |
| **Dil** | `language_code: tr` |
| **Ses** | İstekteki `voice_id`; boşsa Worker ortamındaki `ELEVENLABS_VOICE_ID` |

**İstek gövdesi:** `{ text, voice_id, output_format }` (uygulama: `mp3_44100_128`)

**Yanıt:** `audio/mpeg` (ikili gövde)

---

## 4. Prompt yapısı

### 4.1 System prompt (`PromptOrchestrator.buildSystemPrompt()`)

iOS tarafında oluşturulur. Kurallar:
- Türkçe, çocuk uyku masalı
- Şiddet, korku, yaralanma, ölüm **yasak**
- Çocuk kahraman, yaşa uygun kelime hazinesi
- ElevenLabs TTS optimizasyonu (noktalama, duraklar, tırnak, abartısız ünlem)
- Çeşitlilik: aynı temada bile farklı olay örgüsü, klişe son yok
- JSON çıktısı: `{ "title": "...", "body": ["paragraf1", "paragraf2", ...] }`

### 4.2 User message (`PromptOrchestrator.buildUserMessage()`)

```
Çocuğun Adı: [isim]
Çocuğun Yaşı: [yaş grubu]
Masalın Teması: [1 tema + ipuçları]
Mekan(lar): [rastgele 1-2 mekan]
Yan Karakter(ler): [rastgele 1-2 karakter]
```

---

## 5. Tema sistemi

24 tema, 5 kategori (`StoryThemeCategory`):

| Kategori | Temalar |
|----------|---------|
| Macera & Keşif | Macera, Uzay, Korsanlar, Deniz |
| Doğa & Hayvanlar | Doğa, Hayvanlar, Mevsimler, Sihirli Orman |
| Hayal Dünyası | Rüya, Prenses & Şövalye, Robot, Dinozor |
| Günlük Hayat | Arkadaşlık, Müzik, Araçlar |
| Değerler Eğitimi | Dürüstlük, Doğruluk, Sevgi, Çalışkanlık, Saygı, Cömertlik, Adalet, Sorumluluk, Yardımseverlik |

Her masal üretiminde kullanıcının seçili temalarından **yalnızca 1 tanesi** rastgele seçilir.

---

## 6. Güvenlik önlemleri

| Önlem | Açıklama |
|--------|-----------|
| **Anahtarlar cihazda değil** | OpenAI ve ElevenLabs anahtarları yalnızca Worker ortamında (Wrangler secrets) |
| **Proxy auth** | `PROXY_AUTH_TOKEN` ayarlıysa `Authorization: Bearer …` zorunlu; aksi halde 401 |
| **Rate limiting** | Workers binding ile IP bazlı, 40 req/60s per PoP |
| **İçerik kuralları** | System prompt'ta şiddet/korku/ölüm yasak, JSON şeması zorunlu |
| **Ücretsiz katman limiti** | `SubscriptionManager`: ömür boyu 2 ücretsiz masal |

---

## 7. Finansal çerçeve

### Masal başına maliyet (Flash v2.5, Pro plan)

| Bileşen | Maliyet |
|---------|---------|
| OpenAI (GPT-4o-mini) | ~$0.001 |
| ElevenLabs TTS (~3,500 karakter) | ~$0.42 |
| **Toplam** | **~$0.42/masal** |

### Kullanıcı başına aylık maliyet

| Senaryo | Masal/ay | TTS maliyet/ay |
|---------|---------|----------------|
| Hafif | 8 | $3.36 |
| Ortalama | 20 | $8.40 |
| Ağır | 60 | $25.20 |

### Kârlılık özeti (50 abone, ortalama kullanım)

| Kalem | Tutar |
|-------|-------|
| Gelir (50 × $8.49) | $424.50 |
| ElevenLabs (Scale yearly, 4M dahil) | -$275.00 |
| OpenAI (~1,000 masal) | -$1.00 |
| **Net kâr** | **+$148.50/ay** |

Detaylı analiz: [docs/FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md)

---

## 8. Kod referansları

| Dosya | Rol |
|-------|-----|
| `edge/src/index.ts` | Saf proxy: auth, rate limit, OpenAI + ElevenLabs iletimi |
| `Services/PromptOrchestrator.swift` | Prompt oluşturma, DTO tanımları |
| `Services/StorySeeds.swift` | 41 mekan, 40 yan karakter, rastgele seçim |
| `Services/StoryService.swift` | API çağrıları, hata yönetimi |
| `Models/StoryPreferences.swift` | Tema ve kategori tanımları |
| `Views/Components/ThemeCategoryPicker.swift` | Akordeon tema seçim UI'ı |

*Son güncelleme: Nisan 2026 — Flash v2.5, saf proxy mimarisi, 24 tema.*
