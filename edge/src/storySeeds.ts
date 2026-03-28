/**
 * Rastgele masal çeşitliliği: mekân, yan karakter, olay, aile ipucu, nesne.
 * Uyku masalı güvenliği: korku, şiddet, yaralanma, ölüm içermez.
 */

export interface StorySeeds {
  place: string;
  side: string;
  plot: string;
  family: string;
  object: string;
}

const PLACES: string[] = [
  "ıhlamur kokulu küçük bir bahçe",
  "yıldız tozunun hafifçe süzüldüğü sessiz bir tepe",
  "sabah çiyinin parladığı yumuşak çayırlık",
  "rengarenk kelebeklerin uçuştuğu ılık bir vadi",
  "uzaktan fener ışığı görünen küçük bir iskele",
  "kurbağaların mırıldandığı göl kıyısındaki sazlık",
  "içinde eski kitap kokusu olan ahşap bir gözlem kulesi",
  "pamuk gibi bulutların altından geçilen taş köprü",
  "portakal çiçeği kokan bir seranın yanı",
  "kumulların üzerinde yumuşak esen meltem",
  "ışıldayan mantarların olduğu nemli ama sıcak bir orman açıklığı",
  "küçük bir şelalenin fısıldadığı taşlar",
  "geceleyin hafifçe parlayan deniz yosunları olan koy",
  "karlı ama rüzgârsız bir sırt",
  "çocukların çizim yaptığı duvarlı sıcak bir oda (pencereden ay görünür)",
  "tren yolunun yanındaki çiçek tarhı",
  "eski bir fırının koktuğu dar sokak",
  "gökyüzüne bakan yumuşak çimenler",
];

const SIDE_CHARACTERS: string[] = [
  "konuşkan ama aceleci olmayan minik bir bulut",
  "eski bir haritayı seven yorgun ama neşeli bir seyyah",
  "parlak bir yıldız parçasından oluşmuş küçük bir arkadaş",
  "şarkı mırıldanan yaşlı bir kaplumbağa",
  "renkleri karıştırmayı seven utangaç bir gökkuşağı parçası",
  "soru sormayı seven meraklı bir sincap",
  "her şeyi yavaşlatmayı bilen bilge bir baykuş",
  "küçük bir rüzgâr perisi (sert üflemez)",
  "deniz kabuğu koleksiyoncusu minik bir yengeç",
  "yıldız isimlerini bilen sabırlı bir gece bekçisi",
  "çiçek tohumlarını taşıyan neşeli bir arı",
  "gölgede kitap okuyan tavşan",
  "ışığı toplayan şeffaf bir kristal böcek",
  "gülümsemeyi öğreten maskot gibi bir taş heykelcik",
  "pusulayı ters tutsa da yolu bulan şaşkın bir güvercin",
  "çamurdan şekil yapan yaratıcı bir su pınarı perisi",
  "yıldız kaydığını sayan küçük bir tilki yavrusu",
  "sessizce yanında yürüyen uzun bacaklı bir geyik",
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

/** Kullanıcı mesajına eklenecek çeşitlilik bloğu (örneklemeler her istekte değişir). */
export function buildVariationBlock(s: StorySeeds): string {
  return `Bu üretim için çeşitlilik ipuçları (doğal biçimde örgüye yerleştir; madde madde listeleme yapma, hikâyeyi akıcı anlat):
- Mekân: ${s.place}
- Yan karakter: ${s.side}
- Olay çekirdeği: ${s.plot}
- Aile / yakınlık (isteğe bağlı, hafif bir dokunuş yeter): ${s.family}
- Nesne veya sihirli detay: ${s.object}`;
}
