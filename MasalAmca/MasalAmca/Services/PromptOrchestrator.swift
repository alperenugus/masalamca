//
//  PromptOrchestrator.swift
//  MasalAmca
//

import Foundation

// MARK: - Request DTO (iOS → Worker)

struct StoryGenerateRequestDTO: Codable, Sendable {
    var messages: [Message]

    struct Message: Codable, Sendable {
        var role: String
        var content: String
    }
}

// MARK: - Response DTO (Worker → iOS)

struct StoryGenerateResponseDTO: Codable, Sendable {
    var title: String
    var body: String
    var genre: String
    var wordCount: Int?
    var model: String?

    enum CodingKeys: String, CodingKey {
        case title, body, genre, model
        case wordCount = "word_count"
    }
}

// MARK: - TTS DTO

struct TTSRequestDTO: Codable, Sendable {
    var text: String
    var voiceID: String
    var outputFormat: String

    enum CodingKeys: String, CodingKey {
        case text
        case voiceID = "voice_id"
        case outputFormat = "output_format"
    }
}

// MARK: - Prompt Builder

enum PromptOrchestrator {

    static func storyRequest(from profile: ChildProfile) -> StoryGenerateRequestDTO {
        let prefs = StoryPreferences.load(for: profile)
        let theme = StoryBentoTheme.randomForGeneration(from: prefs.bentoThemes)
        let places = StorySeeds.randomPlaces(count: Int.random(in: 1...2))
        let characters = StorySeeds.randomSideCharacters(count: Int.random(in: 1...2))

        let system = buildSystemPrompt()
        let user = buildUserMessage(
            childName: profile.name,
            ageGroup: profile.ageGroup,
            theme: theme,
            places: places,
            sideCharacters: characters
        )

        return StoryGenerateRequestDTO(messages: [
            .init(role: "system", content: system),
            .init(role: "user", content: user),
        ])
    }

    // MARK: - System Prompt

    private static func buildSystemPrompt() -> String {
        """
        Sen Türkçe konuşan, çocuklar için güvenli ve sürükleyici uyku masalları yazan bir yapay zeka asistanısın. \
        Görevin, verilen bilgilere dayanarak şefkatli ve uykuya hazırlayıcı bir masal oluşturmaktır.

        <KURALLAR>
        1. KAHRAMAN: Verilen çocuk ismini masalın ana kahramanı yap. Anlatım dilini ve hikayenin karmaşıklığını çocuğun yaşına uygun seviyede tut.
        2. İÇERİK VE İŞLEYİŞ: Sadece verilen temayı merkeze al. Hikayeye verilen mekanları ve yan karakterleri dahil ederek ilgi çekici bir kurgu yarat.
        3. YAPI: Masalı net bir "Giriş" (karakter ve mekan tanıtımı), "Gelişme" (temaya uygun macera) ve "Sonuç" (sakinleştirici, uykuya geçiş) şablonuyla kurgula.
        4. GÜVENLİK: Şiddet, korku, ölüm, kötü adam, tehdit, tehlike, ayrımcılık veya cinsel içerik KESİNLİKLE YASAKTIR. Hikayenin her anı çocuk güvenli olmalıdır.
        5. DİL VE METİN: Masalı baştan sona akıcı, tamamen Türkçe düz metin olarak yaz. Sahne yönergesi, İngilizce talimat, parantez içi yönergeler veya tırnakla ayrılmış “konuşma senaryosu” biçimi KULLANMA — sadece anlatı. Ses tonu ve tempo, seslendirme katmanında ayarlanır; metinde yalnızca hikâye olmalı. Tam ve kurallı cümleler; virgül ve noktaları doğal nefes için kullan. Abartılı ünlem (!!!) ve tamamı büyük harf kelimelerden kaçın.
        6. ÇEŞİTLİLİK: Her masalda tamamen farklı bir olay örgüsü, açılış ve bitiş kullan. Aynı kalıp sonuçları tekrarlama.
        7. DEĞER TEMALARI: Eğer tema bir değer içeriyorsa (ör. dürüstlük, sevgi, saygı), bu değeri hikayenin doğal bir parçası olarak işle; açıkça ders verme, göster.
        8. UZUNLUK: Masal metni en az 380 kelime olsun. Hedef dinleme süresi yaklaşık 3–4 dakika.
        </KURALLAR>

        ÇIKTI FORMATI:
        Aşağıdaki yapıya sahip geçerli bir JSON döndür. Markdown veya ek metin kullanma.
        "body" alanı tek bir metin (string) olmalıdır: masalın tamamı, paragraflar arasında satır sonları kullanabilirsin.
        İstersen eski uyumluluk için "body" dizi (array) olarak da dönebilirsin; o durumda her eleman bir paragraf veya bölüm metni olsun. Öncelik: tek string "body".
        genre alanı: calming, adventure veya educational.

        {"title":"Masalın Başlığı","body":"...","genre":"calming"}
        """
    }

    // MARK: - User Message

    private static func buildUserMessage(
        childName: String,
        ageGroup: AgeGroup,
        theme: StoryBentoTheme,
        places: [String],
        sideCharacters: [String]
    ) -> String {
        let themeDescription = buildThemeDescription(theme)
        let placesText = places.joined(separator: ", ")
        let charactersText = sideCharacters.joined(separator: ", ")
        let ageText = ageGroupDescription(ageGroup)

        return """
        <INPUT_DATA>
        - Çocuğun Adı: \(childName)
        - Çocuğun Yaşı: \(ageText)
        - Masalın Teması: \(themeDescription)
        - Mekan(lar): \(placesText)
        - Yan Karakter(ler): \(charactersText)
        </INPUT_DATA>
        """
    }

    // MARK: - Helpers

    private static func buildThemeDescription(_ theme: StoryBentoTheme) -> String {
        let hint = theme.apiThemeHints.randomElement() ?? theme.displayTitle
        if theme.isValueTheme {
            return hint
        }
        return "\(theme.displayTitle) — \(hint)"
    }

    private static func ageGroupDescription(_ age: AgeGroup) -> String {
        switch age {
        case .twoToFour: "2-4 yaş (çok basit cümleler)"
        case .fiveToSeven: "5-7 yaş"
        case .eightPlus: "8+ yaş"
        }
    }
}
