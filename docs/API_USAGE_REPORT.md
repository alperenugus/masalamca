# Masal Amca — API & Kullanım Raporu

Bu belge, uygulamanın **dış API'lere** nasıl bağlandığını, hangi **modelleri** kullandığını, **istemci ↔ edge worker ↔ sağlayıcı** akışını, **prompt / güvenlik** katmanını ve **maliyet** çerçevesini özetler.

---

## 1. Mimari özet

| Katman | Rol |
|--------|-----|
| **iOS uygulaması** | SwiftUI + SwiftData. `PromptOrchestrator` yapılandırılmış veri hazırlar (`child_name`, `age_group`, `themes`). `StoryService` ile yalnızca Cloudflare Worker'a bağlanır. API anahtarları uygulamada **tutulmaz**. |
| **Edge worker** (`edge/src/`) | Prompt oluşturma, rastgele çeşitlilik, auth ve rate limiting. `prompts.ts` sistem + kullanıcı promptunu hazırlar. `themes.ts` 24 tema tanımını tutar. `storySeeds.ts` mekan, karakter, olay, aile ve nesne havuzlarından örnekler. OpenAI'ye iletir. TTS isteğini Google Gemini Flash TTS'e iletir. |
| **OpenAI** | Masal metni (JSON): `gpt-4o-mini`, `response_format: json_object`, `temperature: 0.9` |
| **Google Gemini Flash TTS** | Masal sesli anlatımı (MP3): `gemini-2.5-flash-tts`, Türkçe (`tr-TR`), stil promptu ile |

---

## 2. Google Gemini Flash TTS

Uygulama, **Gemini 2.5 Flash TTS** modelini Cloud Text-to-Speech API üzerinden kullanır. Her anlatıcı, bir Gemini konuşmacı ismine karşılık gelir (ör. `Achernar`, `Algieba`). iOS uygulaması seçilen konuşmacı ismini doğrudan `voice_id` olarak gönderir.

**Stil promptu:** Worker, her TTS isteğinde İngilizce bir stil promptu ekler. Bu prompt, sesi sıcak, sakin ve masal anlatıcısına uygun şekilde yönlendirir.

---

## 3. Uç noktalar ve modeller

### 3.1 `POST /v1/story` (OpenAI)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.openai.com/v1/chat/completions` |
| **Model** | `gpt-4o-mini` |
| **Çıktı formatı** | `response_format: { type: "json_object" }` |
| **Sıcaklık** | `0.9` |

**İstek gövdesi (uygulama → worker):**

```json
{
  "child_name": "Ali",
  "age_group": "five_to_seven",
  "themes": ["adventure", "space"]
}
```

Worker bu yapılandırılmış veriden prompt oluşturur:
- **Tema seçimi**: `themes[]` dizisinden rastgele 1 tema seçer (`themes.ts`)
- **Çeşitlilik örnekleme**: `storySeeds.ts` — ~40 mekan, ~40 yan karakter, 18 olay çekirdeği, 18 aile bağı, 18 nesne
- **System prompt**: Güvenlik kuralları, metin optimizasyonu, JSON formatı, çeşitlilik direktifleri (`prompts.ts`)
- **User message**: Çocuğun adı, yaş grubu, seçilen tema, mekan, yan karakter, olay, aile, nesne (`prompts.ts`)

**Yanıt (worker → uygulama):** `{ title, body, genre, word_count, model, request_id }`
- `body` alanı OpenAI'den string veya paragraf dizisi olarak gelebilir; Worker her iki durumu da destekler.

### 3.2 `POST /v1/tts` (Google Gemini Flash TTS)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://texttospeech.googleapis.com/v1/text:synthesize` |
| **TTS modeli** | `gemini-2.5-flash-tts` |
| **Dil** | `tr-TR` |
| **Ses** | İstekteki `voice_id` (Gemini konuşmacı ismi, ör. `Achernar`) |

**İstek gövdesi:** `{ text, voice_id, output_format }`

**Yanıt:** `audio/mpeg` (ikili gövde — base64'ten çözülmüş MP3)

---

## 4. Prompt yapısı

### 4.1 System prompt (`edge/src/prompts.ts`)

Worker tarafında oluşturulur. Kurallar:
- Türkçe, çocuk uyku masalı
- Şiddet, korku, yaralanma, ölüm **yasak**
- Çocuk kahraman, yaşa uygun kelime hazinesi
- Düz metin, sahne yönergesi yok — seslendirme katmanı ayrı
- Çeşitlilik: aynı temada bile farklı olay örgüsü, klişe son yok
- JSON çıktısı: `{ "title": "...", "body": "...", "genre": "calming|adventure|educational" }`

### 4.2 User message (`edge/src/prompts.ts`)

```
Çocuğun Adı: [isim]
Çocuğun Yaşı: [yaş grubu]
Masalın Teması: [1 tema + ipuçları]

Çeşitlilik ipuçları:
- Mekân: [rastgele mekan]
- Yan karakter: [rastgele karakter]
- Olay çekirdeği: [rastgele olay]
- Aile / yakınlık: [rastgele aile bağı]
- Nesne veya sihirli detay: [rastgele nesne]
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

Tema tanımları iOS'ta (UI, premium gating) ve worker'da (prompt, hint seçimi) `rawValue` string'leri ile eşleşir. Her masal üretiminde worker, kullanıcının seçili temalarından **yalnızca 1 tanesi** rastgele seçer.

---

## 6. Güvenlik önlemleri

| Önlem | Açıklama |
|--------|-----------|
| **Anahtarlar cihazda değil** | OpenAI ve Google SA anahtarları yalnızca Worker ortamında (Wrangler secrets) |
| **Proxy auth** | `PROXY_AUTH_TOKEN` ayarlıysa `Authorization: Bearer …` zorunlu; aksi halde 401 |
| **Rate limiting** | Workers binding ile IP bazlı, 40 req/60s per PoP |
| **İçerik kuralları** | Worker system prompt'ta şiddet/korku/ölüm yasak, JSON şeması zorunlu |
| **Ücretsiz katman limiti** | `SubscriptionManager`: ömür boyu 2 ücretsiz masal |

---

## 7. Finansal çerçeve

### Masal başına maliyet (Gemini Flash TTS)

| Bileşen | Maliyet |
|---------|---------|
| OpenAI (GPT-4o-mini) | ~$0.001 |
| Google Gemini Flash TTS (~3,500 karakter) | ~$0.10–0.12 |
| **Toplam** | **~$0.10–0.12/masal** |

### Kullanıcı başına aylık maliyet

| Senaryo | Masal/ay | TTS maliyet/ay |
|---------|---------|----------------|
| Hafif | 8 | ~$0.88 |
| Ortalama | 20 | ~$2.20 |
| Ağır | 60 | ~$6.60 |

Detaylı analiz: [docs/FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md)

---

## 8. Kod referansları

| Dosya | Rol |
|-------|-----|
| `edge/src/index.ts` | Router, auth, rate limit, story handler, TTS handler |
| `edge/src/prompts.ts` | System prompt, user prompt template, yaş grubu eşleme |
| `edge/src/themes.ts` | 24 tema tanımı, `apiThemeHints`, tema seçimi |
| `edge/src/storySeeds.ts` | ~40 mekan, ~40 karakter, olay, aile, nesne havuzları |
| `edge/src/googleAuth.ts` | Google Cloud OAuth2 token (service account → JWT → access token) |
| `Services/PromptOrchestrator.swift` | Yapılandırılmış istek DTO'su (`StoryRequestDTO`) |
| `Services/StoryService.swift` | API çağrıları, hata yönetimi |
| `Models/StoryPreferences.swift` | Tema, kategori ve anlatıcı tanımları (UI + premium gating) |
| `Views/Components/ThemeCategoryPicker.swift` | Akordeon tema seçim UI'ı |

*Son güncelleme: Nisan 2026 — Worker-owned prompt mimarisi, Gemini Flash TTS, 24 tema.*
