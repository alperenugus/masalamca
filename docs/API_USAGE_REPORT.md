# Masal Amca — API & kullanım raporu

Bu belge, uygulamanın **dış API’lere** nasıl bağlandığını, hangi **modelleri** kullandığını, **istemci ↔ edge proxy ↔ sağlayıcı** akışını, **prompt / güvenlik** katmanını ve **maliyet** için kabaca çerçeveyi özetler. Üretici fiyatları değiştiği için rakamlar **tahmini**dir; canlı faturalama için OpenAI ve ElevenLabs panellerini kullanın.

---

## 1. Mimari özet

| Katman | Rol |
|--------|-----|
| **iOS uygulaması** | SwiftUI + SwiftData. `StoryService` ile yalnızca **Cloudflare Worker** tabanlı proxy’ye konuşur; API anahtarları uygulamada **tutulmaz** (yalnızca `ProxyBaseURL`, isteğe bağlı `ProxyAuthToken`, `ElevenLabsVoiceID` gibi uç yapılandırma). |
| **Edge proxy** (`edge/src/index.ts`, `edge/src/storySeeds.ts`) | `POST /v1/story` → OpenAI (her istekte rastgele **çeşitlilik ipuçları**); `POST /v1/tts` → ElevenLabs TTS. Bearer token ile korunabilir. |
| **OpenAI** | Masal metni (JSON). |
| **ElevenLabs** | Yalnızca masal gövdesinin **TTS** ile seslendirilmesi (MP3). |

---

## 2. ElevenLabs paneli: TTS ile müzik üretimini karıştırmayın

ElevenLabs **Analytics → Usage** ekranı, hesabınızdaki **tüm** kredi tüketen ürünleri (farklı modeller / hatlar) **tek grafikte** toplayabilir. Masal Amca üretim hattında kullanılan şey:

| Ürün / hat (örnek panel etiketi) | Masal Amca ile ilişki |
|----------------------------------|------------------------|
| **Text to Speech** (ör. Eleven Multilingual, Flash, …) | **Evet** — `POST /v1/tts` bu hattı kullanır; masal metni uzunluğuna göre karakter / kredi. |
| **Music, `music_v1` vb.** | **Hayır** — uygulama içi **beyaz gürültü döngüleri yerel (bundle)**; bu müzik üretimi masal proxy’sinden **çağrılmaz**. Panelde gördüğünüz büyük **music** spike’ları genelde **ElevenLabs müzik aracı / API** ile deneme veya başka projelerden gelir. |

**Sonuç:** Toplam “Credit Usage” veya “Total Cost” rakamı, **masal TTS maliyetini tek başına göstermez**. Maliyet kökü analizi için panelde **ürün veya model kırılımına** (TTS satırı vs müzik satırı) bakın. Örnek: bir gecede **~73K kredi müzik**, **~8K kredi TTS** gibi bir dağılımda, masal ürününün baskın maliyeti **müzik denemesi** olabilir; **Flash ↔ Multilingual** seçiminden bağımsızdır.

**Öneri (model seçimi):** Baskın maliyet **müzik** kaynaklıysa, paneldeki toplam spike’ı TTS değişimi tek başına “düzeltmez”; yine de masal hattında **Flash** ile **Multilingual** arasında **kalite / birim fiyat** takası yapılabilir. Şu an proxy’de lansman için **Flash v2.5** kullanılıyor; Türkçe uzun anlatım kalitesi yetersiz kalırsa **`eleven_multilingual_v2`**’ye dönüş planlanabilir.

---

## 3. Uç noktalar ve modeller

### 3.1 `POST /v1/story` (OpenAI)

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
- `target_length` — isteğe bağlı: `short` \| `medium` \| `long` (~3 / ~5 / ~10 dk hedef süre + kelime bandı + TTS noktalama kuralları)

**Worker tarafı (iOS gövdesinde yok):** Her `/v1/story` çağrısında `storySeeds.ts` içinden **mekân, yan karakter, olay çekirdeği, aile/yakınlık, nesne** için rastgele örnekler seçilir ve kullanıcı mesajına Türkçe bir **çeşitlilik bloğu** olarak eklenir (`crypto.getRandomValues`). Amaç aynı temalarda tekrarlayan örgüleri çeşitlendirmek.

**Yanıt (proxy → uygulama):** `title`, `body`, `genre`, `word_count`, `model`.

---

### 3.2 `POST /v1/tts` (ElevenLabs)

| Alan | Değer |
|------|--------|
| **HTTP** | `POST`, gövde JSON |
| **Upstream** | `https://api.elevenlabs.io/v1/text-to-speech/{voice_id}` |
| **TTS modeli** | **`eleven_flash_v2_5`** (lansman: daha düşük birim maliyet; `language_code: tr` — API reddederse Worker’da kaldırılabilir) |
| **Ses** | İstekteki `voice_id`; `"default"` veya boşsa Worker ortamındaki `ELEVENLABS_VOICE_ID` |

**İstek gövdesi:** `text`, `voice_id`, `output_format` (uygulama: `mp3_44100_128`).

**Yanıt:** `audio/mpeg` (ikili gövde).

---

## 4. Prompt’lar (özet)

### 4.1 System prompt (masal üretimi)

Worker içinde `systemPromptForAge(ageHint, targetLength)` ile oluşturulur. Özet kurallar:

- Türkçe, çocuk uyku masalı.  
- Şiddet, korku, yaralanma, **ölüm yok**.  
- Çocuk kahraman; yaş grubuna uygun kelime hazısı (`ageHint`).  
- Uzunluk: `target_length` ile **hedef dinleme süresi** (~3 dk / ~5 dk / ~10 dk) ve **kelime bantları** (kabaca ~250–350, ~400–650, ~650–950).  
- ElevenLabs TTS için **noktalama** (duraklar, tırnak, abartısız ünlem, ALL CAPS yok).  
- **Çeşitlilik:** Aynı temalar tekrarlansa bile farklı olay örgüsü; kullanıcı mesajındaki ipuçları yön verir, klişeden kaçın.  
- Sıcak, yatıştırıcı ton.  
- **JSON:** `{"title":"...","body":"...","genre":"calming|adventure|educational"}`.

### 4.2 User mesajı (masal)

Örnek şablon (üst kısım):

`Çocuğun adı: … Yaş grubu: … Temalar: … [Davranış hedefi: …] Masalı bu profile göre kişiselleştir.`

Temalar, uygulamadan gelen `themes[]` dizisinin virgülle birleştirilmiş hali.

Altına Worker her seferinde ekler: **çeşitlilik ipuçları** (mekân, yan karakter, olay çekirdeği, isteğe bağlı aile dokunuşu, nesne) — ayrıntı için `edge/src/storySeeds.ts`.

---

## 5. Güvenlik ve güvenlik önlemleri

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

## 6. Apple / sistem API’leri (AI değil)

- **StoreKit 2** — abonelik ve haklar.  
- **SwiftData / CloudKit** (yapılandırmaya bağlı) — yerel / senkron veri.  
- **AVFoundation** — oynatma, mikser, isteğe bağlı yerel konuşma önizlemesi (Masal Ayarları).  
- **ActivityKit / WidgetKit** — Now Playing / Live Activity (varsa hedefe bağlı).

---

## 7. Finansal çerçeve (masal hattı)

Aşağıdaki tablo **yalnızca masal üretim API maliyeti** (OpenAI + **TTS**) içindir; **ElevenLabs müzik üretimi yok**. Altyapı (Worker, iCloud, App Store komisyonu, vergi) hariç.

Varsayımlar (güncel fiyatları kendi sözleşmenizden doğrulayın):

- **OpenAI `gpt-4o-mini`:** tipik masal çağrısı girdi + çıktı token’ları; çoğu senaryoda **masal başına ~US$0.001–0.006** bandı (uzunluk ve modele göre).  
- **ElevenLabs TTS (`eleven_flash_v2_5` — lansman):** **karakter / kredi**; planınıza göre çok dilli v2’den genelde daha uygun birim maliyet. **Uzun masal** daha çok karakter demektir. Kalite yetersizse **`eleven_multilingual_v2`**’ye geçiş değerlendirilir. Panelde **yalnızca TTS satırını** filtreleyerek izleyin (müzik karışmasın).

**Günde 2 masal / kullanıcı** (kabaca, TTS ağırlıklı):

| Bileşen | Düşük tahmin (2 masal/gün) | Yüksek tahmin (2 masal/gün) |
|---------|---------------------------|----------------------------|
| OpenAI | ~US$0.002–0.012 | ~US$0.03 |
| ElevenLabs TTS | ~US$0.04–0.12 | ~US$0.35+ |
| **Toplam (yaklaşık)** | **~US$0.05–0.14 / kullanıcı / gün** | **~US$0.38+ / kullanıcı / gün** |

Üst sınır, **uzun** seçenek ve yüksek tarife varsayımlarıyla büyür; **müzik üretimi** bu tabloda yoktur.

**Maliyeti düşürmek (masal hattı):** daha kısa `target_length`, TTS’de Flash (şu an lansmanda açık), aynı metni tekrar TTS etmeme (önbellek), günlük üst sınır veya `AVSpeechSynthesizer` yedeği (kalite takası). **Müzik denemelerini** aynı API anahtarında sınırlamak veya ayrı proje / anahtar kullanmak, paneldeki toplam gürültüyü azaltır.

---

## 8. Kod referansları

- Proxy: `edge/src/index.ts`, `edge/src/storySeeds.ts`  
- iOS istek DTO’ları: `MasalAmca/MasalAmca/Services/PromptOrchestrator.swift`, `StoryService.swift`  
- Tema / uzunluk: `MasalAmca/MasalAmca/Models/StoryPreferences.swift`  

*Son güncelleme: repo içi kodla uyumlu; ElevenLabs toplam kullanımı TTS + müzik + diğer ürünleri kapsayabilir — masal maliyeti için kırılım kullanın.*
