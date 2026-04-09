//
//  StorySeeds.swift
//  MasalAmca
//

import Foundation

enum StorySeeds {

    // MARK: - Places (~40 items for high variety)

    static let places: [String] = [
        // Outdoor — gardens & meadows
        "ıhlamur kokulu küçük bir bahçe",
        "sabah çiyinin parladığı yumuşak çayırlık",
        "rengarenk kelebeklerin uçuştuğu ılık bir vadi",
        "portakal çiçeği kokan bir seranın yanı",
        "gökyüzüne bakan yumuşak çimenler",
        "lavanta tarlaları arasında ince bir patika",
        "papatyalarla kaplı minik bir tepe",
        "yosun tutmuş taş duvarların çevrelediği gizli bir avlu",

        // Outdoor — water
        "uzaktan fener ışığı görünen küçük bir iskele",
        "kurbağaların mırıldandığı göl kıyısındaki sazlık",
        "küçük bir şelalenin fısıldadığı taşlar",
        "geceleyin hafifçe parlayan deniz yosunları olan koy",
        "kumulların üzerinde yumuşak esen meltem",
        "berrak suyun altından renkli taşların göründüğü sığ bir dere",
        "nilüferlerin yüzdüğü sakin bir gölet",
        "dalgaların ninniler fısıldadığı kumsaldaki tahta sandal",

        // Outdoor — forest & mountain
        "ışıldayan mantarların olduğu nemli ama sıcak bir orman açıklığı",
        "karlı ama rüzgârsız bir sırt",
        "yıldız tozunun hafifçe süzüldüğü sessiz bir tepe",
        "dev meşe ağaçlarının gölge verdiği yosunlu bir patika",
        "bulutların arasından geçen dar bir dağ geçidi",
        "çam ağaçlarının arasına gizlenmiş küçük bir kulübe",
        "kuş sesleriyle dolu sabah sisinin sarmaladığı orman",

        // Outdoor — sky & space
        "pamuk gibi bulutların altından geçilen taş köprü",
        "yıldızların suya yansıdığı gece gökyüzünün altında bir çayır",
        "gökkuşağının ucundaki ışıltılı bir tepe",
        "ay ışığının gümüş bir yol çizdiği geniş ova",

        // Indoor — cozy
        "çocukların çizim yaptığı duvarlı sıcak bir oda",
        "içinde eski kitap kokusu olan ahşap bir gözlem kulesi",
        "eski bir fırının koktuğu dar sokak",
        "tren yolunun yanındaki çiçek tarhı",
        "yumuşak yastıklarla dolu sıcak bir çatı katı",
        "duvarlara resimler asılmış renkli bir atölye",
        "mis gibi kokan taze kurabiye hazırlanan mutfak",
        "pencereden yağmurun izlendiği battaniyeli bir koltuk",
        "ışıltılı mumların aydınlattığı küçük bir kütüphane",

        // Whimsical
        "gökkuşağı renkli baloncukların süzüldüğü büyülü bir geçit",
        "konuşan çiçeklerin olduğu sihirli bir bahçe",
        "minik peri evlerinin sıralandığı mantar köyü",
        "buluttan yapılmış yumuşak bir ada",
    ]

    // MARK: - Side Characters (~40 items for high variety)

    static let sideCharacters: [String] = [
        // Magical & whimsical
        "konuşkan ama aceleci olmayan minik bir bulut",
        "parlak bir yıldız parçasından oluşmuş küçük bir arkadaş",
        "renkleri karıştırmayı seven utangaç bir gökkuşağı parçası",
        "küçük bir rüzgâr perisi",
        "çamurdan şekil yapan yaratıcı bir su pınarı perisi",
        "ışığı toplayan şeffaf bir kristal böcek",
        "gülümsemeyi öğreten maskot gibi bir taş heykelcik",
        "dokunduğu her şeyi parıldatan minik bir ateş böceği",
        "şekil değiştiren sevimli bir bulut parçası",
        "melodiler fısıldayan küçük bir rüzgâr çanı",

        // Animals — forest
        "soru sormayı seven meraklı bir sincap",
        "her şeyi yavaşlatmayı bilen bilge bir baykuş",
        "gölgede kitap okuyan tavşan",
        "yıldız kaydığını sayan küçük bir tilki yavrusu",
        "sessizce yanında yürüyen uzun bacaklı bir geyik",
        "fındık toplayan neşeli bir kirpi",
        "sabırla bal yapan yaşlı ve bilge bir arı",
        "ormanda yolunu kaybedip gülümseyen şaşkın bir ayı yavrusu",

        // Animals — water & sky
        "deniz kabuğu koleksiyoncusu minik bir yengeç",
        "pusulayı ters tutsa da yolu bulan şaşkın bir güvercin",
        "şarkı mırıldanan yaşlı bir kaplumbağa",
        "çiçek tohumlarını taşıyan neşeli bir arı",
        "suyun üzerinde dans eden renkli bir yusufçuk",
        "baloncuk üfleyen küçük bir balık",
        "daldan dala atlayan minik bir uğur böceği",
        "gökyüzünde daireler çizen zarif bir martı",

        // Wise & helpful characters
        "eski bir haritayı seven yorgun ama neşeli bir seyyah",
        "yıldız isimlerini bilen sabırlı bir gece bekçisi",
        "her bitkinin ismini fısıldayan yaşlı bir bahçıvan",
        "hikâyeler anlatan gezgin bir kukla ustası",
        "tüm dilleri bilen nazik bir tercüman kelebek",
        "kaybolan eşyaları bulan ufak tefek bir dedektif fare",

        // Cozy & warm
        "battaniye ören sevimli bir örümcek",
        "sıcak çorba pişiren cana yakın bir kirpi anne",
        "ninni söyleyen minik bir cırcır böceği",
        "her sabah günaydın diyen neşeli bir horoz",
        "mektup taşıyan sadık bir posta güvercini",
        "herkesin saçını tarayan şefkatli bir rüzgâr",
        "fısıltıyla masal anlatan gümüş kanatlı bir güve",
        "her adımında çiçek açtıran küçük bir peri",
    ]

    // MARK: - Random Selection (Fisher-Yates via Swift stdlib)

    /// Picks `count` unique random elements. Uses `randomElement()` with rejection
    /// for small picks (1-2) and `shuffled().prefix()` for larger picks to avoid
    /// birthday-paradox collisions.
    static func randomPlaces(count: Int = 2) -> [String] {
        pickUnique(from: places, count: count)
    }

    static func randomSideCharacters(count: Int = 2) -> [String] {
        pickUnique(from: sideCharacters, count: count)
    }

    private static func pickUnique(from pool: [String], count: Int) -> [String] {
        let n = min(count, pool.count)
        guard n > 0 else { return [] }
        if n == 1 {
            return [pool.randomElement()!]
        }
        // shuffled() uses Fisher-Yates internally — O(n) and uniform
        return Array(pool.shuffled().prefix(n))
    }
}
