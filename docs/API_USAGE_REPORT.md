# Masal Amca — API & Kullanım Raporu

Bu belge, uygulamanın **dış API'lere** nasıl bağlandığını, hangi **modelleri** kullandığını, **istemci ↔ edge proxy ↔ sağlayıcı** akışını, **prompt / güvenlik** katmanını ve **maliyet** çerçevesini özetler.

---

## 1. Mimari özet

| Katman | Rol |
|--------|-----|
| **iOS uygulaması** | SwiftUI + SwiftData. `PromptOrchestrator` tüm prompt mantığını (system + user mesajları) hazırlar. `StorySeeds` rastgele mekan ve karakter seçer. `StoryService` ile yalnızca Cloudflare Worker proxy'ye bağlanır. API anahtarları uygulamada **tutulmaz**. |
| **Edge proxy** (`edge/src/index.ts`) | Saf proxy: iOS'tan gelen `messages[]` dizisini OpenAI'ye iletir. `body[]` dizisini string'e dönüştürür. TTS isteğini Google Gemini Flash TTS'e iletir. Bearer token ile korunur. Rate limiting uygulanır. Prompt mantığı **yoktur**. |
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
- **System prompt**: Güvenlik kuralları, metin optimizasyonu, JSON formatı, çeşitlilik direktifleri
- **User message**: Çocuğun adı, yaş grubu, seçilen tema (1 adet), rastgele mekanlar (1-2), rastgele yan karakterler (1-2)

**İçerik çeşitlilik motoru (`StorySeeds.swift`):**
- 41 farklı mekan (açık hava, su, orman, gökyüzü, kapalı, fantastik)
- 40 farklı yan karakter (sihirli, orman, su/gökyüzü, bilge, sevimli)
- Her istek için `shuffled().prefix()` ile benzersiz seçim

**Yanıt (proxy → uygulama):** `{ title, body, genre, word_count, model }`
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

### 4.1 System prompt (`PromptOrchestrator.buildSystemPrompt()`)

iOS tarafında oluşturulur. Kurallar:
- Türkçe, çocuk uyku masalı
- Şiddet, korku, yaralanma, ölüm **yasak**
- Çocuk kahraman, yaşa uygun kelime hazinesi
- Düz metin, sahne yönergesi yok — seslendirme katmanı ayrı
- Çeşitlilik: aynı temada bile farklı olay örgüsü, klişe son yok
- JSON çıktısı: `{ "title": "...", "body": "...", "genre": "calming|adventure|educational" }`

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
| **Anahtarlar cihazda değil** | OpenAI ve Google SA anahtarları yalnızca Worker ortamında (Wrangler secrets) |
| **Proxy auth** | `PROXY_AUTH_TOKEN` ayarlıysa `Authorization: Bearer …` zorunlu; aksi halde 401 |
| **Rate limiting** | Workers binding ile IP bazlı, 40 req/60s per PoP |
| **İçerik kuralları** | System prompt'ta şiddet/korku/ölüm yasak, JSON şeması zorunlu |
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
| `edge/src/index.ts` | Saf proxy: auth, rate limit, OpenAI + Google Gemini TTS iletimi |
| `edge/src/googleAuth.ts` | Google Cloud OAuth2 token (service account → JWT → access token) |
| `Services/PromptOrchestrator.swift` | Prompt oluşturma, DTO tanımları |
| `Services/StorySeeds.swift` | 41 mekan, 40 yan karakter, rastgele seçim |
| `Services/StoryService.swift` | API çağrıları, hata yönetimi |
| `Models/StoryPreferences.swift` | Tema, kategori ve anlatıcı tanımları |
| `Views/Components/ThemeCategoryPicker.swift` | Akordeon tema seçim UI'ı |

*Son güncelleme: Nisan 2026 — Gemini Flash TTS, saf proxy mimarisi, 24 tema.*
