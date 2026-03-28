# Masal Amca — API & kullanım raporu

Bu belge, uygulamanın **dış API’lere** nasıl bağlandığını, hangi **modelleri** kullandığını, **istemci ↔ edge proxy ↔ sağlayıcı** akışını, **prompt / güvenlik** katmanını ve **maliyet** için kabaca çerçeveyi özetler. Üretici fiyatları değiştiği için rakamlar **tahmini**dir; canlı faturalama için OpenAI ve ElevenLabs panellerini kullanın.

---

## 1. Mimari özet

| Katman | Rol |
|--------|-----|
| **iOS uygulaması** | SwiftUI + SwiftData. `StoryService` ile yalnızca **Cloudflare Worker** tabanlı proxy’ye konuşur; API anahtarları uygulamada **tutulmaz** (yalnızca `ProxyBaseURL`, isteğe bağlı `ProxyAuthToken`, `ElevenLabsVoiceID` gibi uç yapılandırma). |
| **Edge proxy** (`edge/src/index.ts`) | `POST /v1/story` → OpenAI; `POST /v1/tts` → ElevenLabs. Bearer token ile korunabilir. |
| **OpenAI** | Masal metni (JSON). |
| **ElevenLabs** | Masal gövdesinin seslendirilmesi (MP3). |

---

## 2. Uç noktalar ve modeller

### 2.1 `POST /v1/story` (OpenAI)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.openai.com/v1/chat/completions` |
| **Model** | **`gpt-4o-mini`** |
| **Çıktı formatı** | `response_format: { type: "json_object" }` |
| **Sıcaklık** | `0.7` |

**İstek gövdesi (uygulama → proxy)** — `StoryGenerateRequestDTO` / Worker `StoryRequest`:

- `child_name` — çocuk adı  
- `age_group` — örn. `2-4`, `5-7`, `8+`  
- `themes` — string dizisi (Masal Ayarları bento temalarından Türkçe ipuçları; bazı seçenekler birden fazla ipucu gönderebilir)  
- `behavioral_goal` — isteğe bağlı  
- `language` — `"tr"`  
- `target_length` — isteğe bağlı: `short` \| `medium` \| `long` (~1 / ~3 / ~5 dk hedef süre + kelime bandı + TTS için noktalama kuralları)

**Yanıt (proxy → uygulama):** `title`, `body`, `genre`, `word_count`, `model`.

---

### 2.2 `POST /v1/tts` (ElevenLabs)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.elevenlabs.io/v1/text-to-speech/{voice_id}` |
| **TTS modeli** | **`eleven_flash_v2_5`** (isteğe bağlı `language_code: tr`) |
| **Ses** | İstekteki `voice_id`; `"default"` veya boşsa Worker ortamındaki `ELEVENLABS_VOICE_ID` |

**İstek gövdesi:** `text`, `voice_id`, `output_format` (uygulama: `mp3_44100_128`).

**Yanıt:** `audio/mpeg` (ikili gövde).

---

## 3. Prompt’lar (özet)

### 3.1 System prompt (masal üretimi)

Worker içinde `systemPromptForAge(ageHint, targetLength)` ile oluşturulur. Özet kurallar:

- Türkçe, çocuk uyku masalı.  
- Şiddet, korku, yaralanma, **ölüm yok**.  
- Çocuk kahraman; yaş grubuna uygun kelime hazısı (`ageHint`).  
- Uzunluk: `target_length` ile **hedef dinleme süresi** (~1 dk / ~3 dk / ~5 dk) ve buna uygun **kelime bantları** (ör. ~90–130, ~280–380, ~480–620).  
- ElevenLabs TTS için **noktalama** (duraklar, tırnak, abartısız ünlem, ALL CAPS yok).  
- Sıcak, yatıştırıcı ton.  
- **JSON:** `{"title":"...","body":"...","genre":"calming|adventure|educational"}`.

### 3.2 User mesajı (masal)

Örnek şablon:

`Çocuğun adı: … Yaş grubu: … Temalar: … [Davranış hedefi: …] Masalı bu profile göre kişiselleştir.`

Temalar, uygulamadan gelen `themes[]` dizisinin virgülle birleştirilmiş hali.

---

## 4. Güvenlik ve güvenlik önlemleri

| Önlem | Açıklama |
|--------|-----------|
| **Anahtarlar cihazda değil** | OpenAI ve ElevenLabs anahtarları yalnızca Worker ortamında (Wrangler secrets). |
| **İsteğe bağlı proxy auth** | `PROXY_AUTH_TOKEN` ayarlıysa `Authorization: Bearer …` zorunlu; aksi halde 401. |
| **Yaş / tema kişiselleştirmesi** | Metin üretimi çocuk profili ve seçilen temalarla şekillenir. |
| **İçerik kuralları (system prompt)** | Türkçe, şiddet/korku/ölüm yok, uyku dostu ton, JSON şeması. |
| **JSON çıktı zorunluluğu** | `json_object` ile yapılandırılmış yanıt. |
| **Oran sınırlama** | Worker’da `RATE_LIMIT` KV ile genişletilebilir (şu an kodda opsiyonel; tam kısıt için KV + sayaç mantığı eklenmeli). |

Ek olarak uygulama tarafında **ücretsiz katmanda** üretim sayısı sınırlı (`SubscriptionManager`: premium değilse ömür boyu üretim sayacı eşiği; bu **günlük 2 masal** politikası değildir — aşağıdaki finans bölümü ayrı bir senaryodur).

---

## 5. Apple / sistem API’leri (AI değil)

- **StoreKit 2** — abonelik ve haklar.  
- **SwiftData / CloudKit** (yapılandırmaya bağlı) — yerel / senkron veri.  
- **AVFoundation** — oynatma, mikser, isteğe bağlı yerel konuşma önizlemesi (Masal Ayarları).  
- **ActivityKit / WidgetKit** — Now Playing / Live Activity (varsa hedefe bağlı).

---

## 6. Finansal tahmin: kullanıcı başına **günde en fazla 2 masal**

Aşağıdaki tablo **yalnızca API maliyeti** içindir; altyapı (Worker, iCloud, App Store komisyonu, vergi) hariç.

Varsayımlar (güncel fiyatları kendi sözleşmenizden doğrulayın):

- **OpenAI `gpt-4o-mini`:** tipik masal çağrısı ~1–2k token girdi + ~800–1.200 token çıktı (orta uzunluk metin). Birleşik maliyet çoğu senaryoda **masal başına ~US$0.001–0.005** bandında kalabilir (token başına fiyatlarınıza göre değişir).  
- **ElevenLabs `eleven_flash_v2_5`:** karakter / kredi; çok dilli v2’ye göre genelde daha düşük birim fiyat (planınıza göre). Kısa masallar (~1 dk hedef) karakter sayısını belirgin düşürür; **masal başına** aralık metin uzunluğuna ve tarifenize göre değişir.

**Günde 2 masal / kullanıcı:**

| Bileşen | Düşük tahmin (2 masal/gün) | Yüksek tahmin (2 masal/gün) |
|---------|---------------------------|----------------------------|
| OpenAI | ~US$0.002–0.01 | ~US$0.02 |
| ElevenLabs | ~US$0.06–0.15 | ~US$0.24 |
| **Toplam (yaklaşık)** | **~US$0.07–0.16 / kullanıcı / gün** | **~US$0.25+ / kullanıcı / gün** |

**Örnek ölçek (yalnızca API):**

- 1.000 aktif kullanıcı, hepsi günde 2 masal, “orta” tahmin ~US$0.10/kullanıcı/gün → **~US$100/gün** ≈ **~US$3.000/ay**.  
- Aynı senaryoda sadece OpenAI genelde toplamın küçük bir kısmı; **TTS baskın maliyet** olmaya devam eder.

**Maliyeti düşürmek için:** daha kısa hedef süre (`short` ≈ 1 dk), Flash TTS modeli, önbellek (aynı metni tekrar TTS etmeme), günlük üst sınır veya kısmi `AVSpeechSynthesizer` yedeği (kalite takası).

---

## 7. Kod referansları

- Proxy: `edge/src/index.ts`  
- iOS istek DTO’ları: `MasalAmca/MasalAmca/Services/PromptOrchestrator.swift`, `StoryService.swift`  
- Tema / uzunluk: `MasalAmca/MasalAmca/Models/StoryPreferences.swift`  

*Son güncelleme: repo içi kodla uyumlu; fiyatlandırma tahminleri bilgilendirme amaçlıdır.*
