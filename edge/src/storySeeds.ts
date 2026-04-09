/**
 * Rastgele masal çeşitliliği: mekân, yan karakter, olay, aile ipucu, nesne.
 * Uyku masalı güvenliği: korku, şiddet, yaralanma, ölüm içermez.
 *
 * Places and side characters expanded to ~40 each (aligned with iOS StorySeeds.swift).
 * Plot hooks, family threads, and objects are worker-only enrichments.
 */

export interface StorySeeds {
  place: string;
  side: string;
  plot: string;
  family: string;
  object: string;
}

const PLACES: string[] = [
  // Gardens & meadows
  "ıhlamur kokulu küçük bir bahçe",
  "sabah çiyinin parladığı yumuşak çayırlık",
  "rengarenk kelebeklerin uçuştuğu ılık bir vadi",
  "portakal çiçeği kokan bir seranın yanı",
  "gökyüzüne bakan yumuşak çimenler",
  "lavanta tarlaları arasında ince bir patika",
  "papatyalarla kaplı minik bir tepe",
  "yosun tutmuş taş duvarların çevrelediği gizli bir avlu",
  // Water
  "uzaktan fener ışığı görünen küçük bir iskele",
  "kurbağaların mırıldandığı göl kıyısındaki sazlık",
  "küçük bir şelalenin fısıldadığı taşlar",
  "geceleyin hafifçe parlayan deniz yosunları olan koy",
  "kumulların üzerinde yumuşak esen meltem",
  "berrak suyun altından renkli taşların göründüğü sığ bir dere",
  "nilüferlerin yüzdüğü sakin bir gölet",
  "dalgaların ninniler fısıldadığı kumsaldaki tahta sandal",
  // Forest & mountain
  "ışıldayan mantarların olduğu nemli ama sıcak bir orman açıklığı",
  "karlı ama rüzgârsız bir sırt",
  "yıldız tozunun hafifçe süzüldüğü sessiz bir tepe",
  "dev meşe ağaçlarının gölge verdiği yosunlu bir patika",
  "bulutların arasından geçen dar bir dağ geçidi",
  "çam ağaçlarının arasına gizlenmiş küçük bir kulübe",
  "kuş sesleriyle dolu sabah sisinin sarmaladığı orman",
  // Sky & space
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
];

const SIDE_CHARACTERS: string[] = [
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
  // Wise & helpful
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
];

const PLOT_HOOKS: string[] = [
  "kaybolmuş küçük bir nesneyi nazikçe bulma ve geri verme",
  "birinin küçük bir endişesini dinleyip birlikte çözüm bulma",
  "paylaşılmayı bekleyen son bir dilimi ikiye bölüşme",
  "geceye bırakılmış küçük bir sürprizi hazırlama",
  "unutulmuş bir geleneği hatırlatıp yeniden canlandırma",
  "küçük bir hayvanın yolunu güvenle aydınlatma",
  "yanlış anlaşılmayı gülümseyerek düzeltme",
  "sabırla bekleyerek güzel bir şeyin olgunlaşmasını izleme",
  "küçük bir yarış yerine iş birliğiyle bitirme",
  "sessizce yardım edip teşekkür beklemeden ayrılma",
  "korkmadan yeni bir şey deneme ve başarısız olsa da gülmek",
  "bir arkadaşa cesaret veren küçük bir hediye yapma",
  "gürültülü düşünceleri yumuşak bir nefesle sakinleştirme",
  "küçük bir hatayı düzeltip özür dilemenin gücünü gösterme",
  "yıldızları sayarak uyumayı kolaylaştırma",
  "doğanın küçük bir sesini dinleyip ona eşlik etme",
  "küçük bir merakı araştırıp güvenli cevap bulma",
  "gece yarısı gelen yumuşak bir daveti kabul etme",
];

const FAMILY_THREADS: string[] = [
  "annenin akşam öpücüğünün sıcaklığı hatırlanır",
  "babanın sabırla anlattığı kısa bir masal cümlesi yankılanır",
  "babaannenin ördüğü battaniyenin yumuşaklığı hissedilir",
  "dedenin eski bir şarkı mırıldanması uzaktan gelir",
  "abinin veya ablanın paylaştığı küçük bir sır güven verir",
  "kuzenle birlikte keşfetme anısı hafifçe anılır",
  "ailece içilen sıcak sütün kokusu geçer",
  "büyükannenin bahçede topladığı çiçekler anılır",
  "ebeveynin 'sen yeterlisin' dediği an hatırlanır",
  "aile fotoğrafındaki gülümsemelerden biri masala ışık tutar",
  "kardeşle yapılan küçük bir oyun barışla biter",
  "dayının veya halanın verdiği küçük hediye hatırlanır",
  "ailecek izlenen yıldızlı gökyüzü anısı",
  "annesinin elinden tutarak yürüme güveni",
  "babanın omzunda uyuklama hissi",
  "ailece söylenen iyi geceler dileği tekrarlanır",
  "büyükanne tarafından anlatılan kısa bir atasözü",
  "aile kahvaltısında paylaşılan küçük bir sevinç",
];

const OBJECTS: string[] = [
  "ısı veren küçük yuvarlak bir taş",
  "içinde yıldız deseni olan cam bir kavanoz",
  "sürekli yumuşak titreşen minik bir çan",
  "ışığı toplayan şeffaf bir tüy",
  "üzerinde bilinmeyen bir çiçek işlemesi olan eski bir düğme",
  "kırılmaz gibi duran ince bir seramik fincan",
  "içi boş ama uğultulu deniz sesi çıkaran bir deniz kabuğu",
  "geceleyen parlayan yumuşak bir mantar",
  "üç renk ipliği olan küçük bir yumak",
  "üzerinde ay haritası çizili eski bir mendil",
  "sallandıkça ninni çıkaran ahşap bir salıncak figürü",
  "içinden sıcak buhar tüten küçük bir demlik",
  "ışığı kıran gökkuşağı yapan prizma",
  "yumuşak tüylü devasa görünümlü ama hafif bir yastık",
  "üzerinde bilmece yazan kurşun kalem",
  "kilit açılmadan da mutluluk veren oyuncak bir anahtar",
  "içinde kurumuş çiçek yaprakları olan defter",
  "suya değince halka halka genişleyen ışık halkaları yapan taş",
];

function randomIndex(length: number): number {
  if (length <= 0) return 0;
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return buf[0]! % length;
}

function pick<T>(arr: readonly T[]): T {
  return arr[randomIndex(arr.length)]!;
}

export function sampleStorySeeds(): StorySeeds {
  return {
    place: pick(PLACES),
    side: pick(SIDE_CHARACTERS),
    plot: pick(PLOT_HOOKS),
    family: pick(FAMILY_THREADS),
    object: pick(OBJECTS),
  };
}

/** Variation block appended to the user message for per-request diversity. */
export function buildVariationBlock(s: StorySeeds): string {
  return `Bu üretim için çeşitlilik ipuçları (doğal biçimde örgüye yerleştir; madde madde listeleme yapma, hikâyeyi akıcı anlat):
- Mekân: ${s.place}
- Yan karakter: ${s.side}
- Olay çekirdeği: ${s.plot}
- Aile / yakınlık (isteğe bağlı, hafif bir dokunuş yeter): ${s.family}
- Nesne veya sihirli detay: ${s.object}`;
}
