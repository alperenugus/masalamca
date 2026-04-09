/**
 * Theme definitions for story generation.
 * Ported from iOS StoryBentoTheme enum — rawValue strings are the contract
 * between the iOS app (UI/premium gating) and this worker (prompt building).
 */

export interface ThemeDef {
  readonly rawValue: string;
  readonly displayTitle: string;
  readonly isValueTheme: boolean;
  readonly apiThemeHints: readonly string[];
}

const THEMES: readonly ThemeDef[] = [
  {
    rawValue: "adventure",
    displayTitle: "Macera",
    isValueTheme: false,
    apiThemeHints: ["macera ve keşif", "cesaret ve merak", "bilinmeyen toprakları keşfetme"],
  },
  {
    rawValue: "nature",
    displayTitle: "Doğa",
    isValueTheme: false,
    apiThemeHints: ["doğa ve orman", "ağaçlar ve çiçekler arasında huzur", "doğanın sesleri ve kokuları"],
  },
  {
    rawValue: "space",
    displayTitle: "Uzay",
    isValueTheme: false,
    apiThemeHints: ["uzay ve yıldızlar", "gezegenler arası yolculuk", "gökyüzünün sırları"],
  },
  {
    rawValue: "ocean",
    displayTitle: "Deniz",
    isValueTheme: false,
    apiThemeHints: ["deniz ve dalgalar", "deniz canlıları ve mercan resifleri", "kumsal ve deniz feneri"],
  },
  {
    rawValue: "friendship",
    displayTitle: "Arkadaşlık",
    isValueTheme: false,
    apiThemeHints: ["arkadaşlık ve paylaşma", "iş birliği ve birlikte başarma", "yeni arkadaşlarla tanışma"],
  },
  {
    rawValue: "dreams",
    displayTitle: "Rüya",
    isValueTheme: false,
    apiThemeHints: ["rüyalar ve hayal gücü", "yumuşak geçişler ve uyku", "bulutların üzerinde süzülme"],
  },
  {
    rawValue: "dinosaurs",
    displayTitle: "Dinozor",
    isValueTheme: false,
    apiThemeHints: ["dinozorlar ve tarih öncesi dünya", "nazik dev dinozorlar", "merak dolu keşif (korku yok)"],
  },
  {
    rawValue: "vehicles",
    displayTitle: "Araçlar",
    isValueTheme: false,
    apiThemeHints: ["arabalar ve trenler", "uçaklar ve gemiler", "yolculuk ve keşif macerası"],
  },
  {
    rawValue: "robots",
    displayTitle: "Robot",
    isValueTheme: false,
    apiThemeHints: ["robotlar ve icatlar", "teknoloji ve yardımsever makineler", "yaratıcı mühendislik"],
  },
  {
    rawValue: "animals",
    displayTitle: "Hayvanlar",
    isValueTheme: false,
    apiThemeHints: ["sevimli hayvanlar", "orman ve çiftlik hayvanlarıyla arkadaşlık", "hayvan yavruları ve onların maceraları"],
  },
  {
    rawValue: "music",
    displayTitle: "Müzik",
    isValueTheme: false,
    apiThemeHints: ["müzik ve melodiler", "enstrümanlar ve ritim", "şarkı söyleyen karakterler ve dans"],
  },
  {
    rawValue: "seasons",
    displayTitle: "Mevsimler",
    isValueTheme: false,
    apiThemeHints: ["mevsimler ve hava durumu", "kar taneleri veya yaz güneşi", "sonbahar yaprakları veya ilkbahar çiçekleri"],
  },
  {
    rawValue: "pirates",
    displayTitle: "Korsanlar",
    isValueTheme: false,
    apiThemeHints: ["korsanlar ve hazine avı", "gemiler ve adalar", "harita ve pusula ile macera"],
  },
  {
    rawValue: "princesKnight",
    displayTitle: "Prenses & Şövalye",
    isValueTheme: false,
    apiThemeHints: ["cesur şövalye ve nazik prenses", "kale ve krallık", "cesaret ve nezaketle zorlukları aşma"],
  },
  {
    rawValue: "magicForest",
    displayTitle: "Sihirli Orman",
    isValueTheme: false,
    apiThemeHints: ["sihirli orman ve büyülü ağaçlar", "konuşan hayvanlar ve periler", "orman derinliklerindeki gizli dünya"],
  },
  // Value themes
  {
    rawValue: "durustluk",
    displayTitle: "Dürüstlük",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: dürüstlük — doğru olanı söylemenin güzelliği",
      "küçük bir durumu doğru ve nazikçe anlatma cesareti",
      "içtenlik ve güvenin huzur getirdiği bir olay örgüsü",
    ],
  },
  {
    rawValue: "dogruluk",
    displayTitle: "Doğruluk",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: doğruluk — gerçeği kırmadan paylaşma",
      "dürüst seçimler yapmanın güzelliği ve rahatlatıcılığı",
      "doğru sözün ödüllendirildiği nazik bir olay örgüsü",
    ],
  },
  {
    rawValue: "sevgi",
    displayTitle: "Sevgi",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: sevgi — aile ve arkadaşlara sıcak ilgi gösterme",
      "şefkat ve paylaşmanın mutluluğu",
      "sevginin zorlukları aştığı bir olay örgüsü",
    ],
  },
  {
    rawValue: "caliskanlik",
    displayTitle: "Çalışkanlık",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: çalışkanlık — küçük adımlarla hedefe ulaşmanın güzelliği",
      "sabırla denemenin ve vazgeçmemenin ödüllendirilmesi",
      "merakla öğrenmenin maceraya dönüştüğü bir olay örgüsü",
    ],
  },
  {
    rawValue: "saygi",
    displayTitle: "Saygı",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: saygı — dinlemenin ve anlamaya çalışmanın önemi",
      "farklılıklara sıcak yaklaşmanın güzelliği",
      "nezaketin ve saygının kahramanı ödüllendirdiği bir olay örgüsü",
    ],
  },
  {
    rawValue: "comertlik",
    displayTitle: "Cömertlik",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: cömertlik — paylaşmanın ve iyilik etmenin güzelliği",
      "küçük jestlerin büyük mutluluk getirdiği bir olay örgüsü",
      "başkalarını düşünmenin kahramanı zenginleştirdiği bir hikaye",
    ],
  },
  {
    rawValue: "adalet",
    displayTitle: "Adalet",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: adalet — herkesin duygularını düşünme ve eşitlik",
      "kurallara uygun nazik çözümler bulmanın güzelliği",
      "adaletli davranmanın herkesi mutlu ettiği bir olay örgüsü",
    ],
  },
  {
    rawValue: "sorumluluk",
    displayTitle: "Sorumluluk",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: sorumluluk — emanetlere iyi bakmanın önemi",
      "sözünü tutmanın güven inşa ettiği bir olay örgüsü",
      "küçük sorumlulukların büyük başarılara dönüştüğü bir hikaye",
    ],
  },
  {
    rawValue: "yardimseverlik",
    displayTitle: "Yardımseverlik",
    isValueTheme: true,
    apiThemeHints: [
      "hikayenin ana değeri: yardımseverlik — birine destek olmanın güzelliği",
      "dayanışma ve birlikte başarmanın mutluluğu",
      "küçük yardımların büyük fark yarattığı bir olay örgüsü",
    ],
  },
] as const;

const THEME_MAP = new Map<string, ThemeDef>(THEMES.map((t) => [t.rawValue, t]));

export function lookupTheme(rawValue: string): ThemeDef | undefined {
  return THEME_MAP.get(rawValue);
}

/**
 * Pick one random theme from the client's selection.
 * Mirrors iOS `StoryBentoTheme.randomForGeneration`: normalizes empty → adventure,
 * then picks uniformly at random.
 */
export function pickTheme(themeRawValues: string[]): ThemeDef {
  const valid = themeRawValues
    .map((r) => THEME_MAP.get(r))
    .filter((t): t is ThemeDef => t !== undefined);

  if (valid.length === 0) return THEME_MAP.get("adventure")!;
  return pick(valid);
}

/**
 * Build the theme description line for the user prompt.
 * Mirrors iOS `PromptOrchestrator.buildThemeDescription`.
 */
export function buildThemeDescription(theme: ThemeDef): string {
  const hint = pick(theme.apiThemeHints);
  if (theme.isValueTheme) return hint;
  return `${theme.displayTitle} — ${hint}`;
}

function pick<T>(arr: readonly T[]): T {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return arr[buf[0]! % arr.length]!;
}
