//
//  StoryPreferences.swift
//  MasalAmca
//

import Foundation
import SwiftData

// MARK: - Masal süresi (proxy prompt hedefi)

enum StoryLengthPreference: String, CaseIterable, Sendable {
    case short
    case medium
    case long

    var displayTitle: String {
        switch self {
        case .short: "Kısa (1 dk)"
        case .medium: "Orta (3 dk)"
        case .long: "Uzun (5 dk)"
        }
    }

    /// Kabaca hedef dinleme süresi (TTS tempoyu profil bazında bilmediğimiz için UI / meta).
    var targetListeningDurationSeconds: Int {
        switch self {
        case .short: 60
        case .medium: 180
        case .long: 300
        }
    }
}

// MARK: - Hikaye teması (bento → API + profil eşlemesi)

enum StoryBentoTheme: String, CaseIterable, Identifiable, Sendable {
    case adventure
    case nature
    case space
    case fairyTaleCastle
    case ocean
    case friendship
    case dreams
    case dinosaurs
    case vehicles
    case robots

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .adventure: "Macera"
        case .nature: "Doğa"
        case .space: "Uzay"
        case .fairyTaleCastle: "Masal"
        case .ocean: "Deniz"
        case .friendship: "Arkadaşlık"
        case .dreams: "Rüya"
        case .dinosaurs: "Dinozor"
        case .vehicles: "Araçlar"
        case .robots: "Robot"
        }
    }

    var systemImage: String {
        switch self {
        case .adventure: "safari.fill"
        case .nature: "leaf.fill"
        case .space: "star.fill"
        case .fairyTaleCastle: "building.columns.fill"
        case .ocean: "water.waves"
        case .friendship: "heart.circle.fill"
        case .dreams: "moon.zzz.fill"
        case .dinosaurs: "lizard.fill"
        case .vehicles: "car.fill"
        case .robots: "gearshape.2.fill"
        }
    }

    var apiThemeHints: [String] {
        switch self {
        case .adventure:
            ["macera, keşif, cesaret"]
        case .nature:
            ["doğa, orman, hayvanlar, huzur"]
        case .space:
            ["uzay, yıldızlar, gezegenler"]
        case .fairyTaleCastle:
            ["masal dünyası, krallık, sihir"]
        case .ocean:
            ["deniz, dalgalar, deniz canlıları, kumsal"]
        case .friendship:
            ["arkadaşlık, paylaşma, iş birliği, neşe"]
        case .dreams:
            ["rüyalar, yumuşak geçişler, hayal gücü, uyku"]
        case .dinosaurs:
            ["dinozorlar, tarih öncesi macera, merak (korku yok)"]
        case .vehicles:
            ["arabalar, trenler, yolculuk, keşif"]
        case .robots:
            ["robotlar, icat, teknoloji, yardımsever makineler"]
        }
    }

    func asProfileThemes() -> [StoryTheme] {
        switch self {
        case .adventure, .dinosaurs, .vehicles: [.magic]
        case .nature, .ocean: [.animals]
        case .space, .robots: [.space]
        case .fairyTaleCastle, .dreams: [.fairyTale]
        case .friendship: [.magic, .fairyTale]
        }
    }

    static func inferred(from profileTheme: StoryTheme?) -> StoryBentoTheme {
        switch profileTheme {
        case .animals: .nature
        case .space: .space
        case .fairyTale: .fairyTaleCastle
        case .magic, .none: .adventure
        }
    }
}

// MARK: - Anlatıcı

enum NarratorChoice: String, CaseIterable, Identifiable, Sendable {
    case yumuşakBulut
    case bilgeDede
    case neşeliPeri

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yumuşakBulut: "Yumuşak Bulut"
        case .bilgeDede: "Bilge Dede"
        case .neşeliPeri: "Neşeli Peri"
        }
    }

    var subtitle: String {
        switch self {
        case .yumuşakBulut: "Sakinleştirici ve alçak ses"
        case .bilgeDede: "Tok ve güven verici bir anlatım"
        case .neşeliPeri: "Canlı ve enerjik karakter sesleri"
        }
    }

    var symbolName: String {
        switch self {
        case .yumuşakBulut: "cloud.fill"
        case .bilgeDede: "person.fill"
        case .neşeliPeri: "wand.and.stars"
        }
    }

    /// ElevenLabs **Serdar Sağlam** (male, Bilge Dede).
    static let bilgeDedeVoiceID = "NfwyWIJnRR1RrYnStGUG"

    var isSelectable: Bool {
        switch self {
        case .neşeliPeri: false
        default: true
        }
    }

    /// ElevenLabs **Gökçe Deniz** — `Info.plist` `ElevenLabsVoiceID`, else `"default"`.
    static func defaultFemaleVoiceID() -> String {
        Bundle.main.object(forInfoDictionaryKey: "ElevenLabsVoiceID") as? String ?? "default"
    }

    func resolvedVoiceID() -> String? {
        switch self {
        case .yumuşakBulut:
            Self.defaultFemaleVoiceID()
        case .bilgeDede:
            Self.bilgeDedeVoiceID
        case .neşeliPeri:
            nil
        }
    }
}

// MARK: - Çocuk profili + CloudKit (UserDefaults yalnızca geriye dönük okuma)

enum StoryPreferences {
    enum Keys {
        static let length = "masal.storyLength"
        static let narrator = "masal.narrator"
        static let bentoTheme = "masal.bentoTheme"
        static let autoStopAfterStory = "masal.autoStopAfterStory"
        static let backgroundMusicInPlayer = "masal.backgroundMusicInPlayer"
    }

    struct Snapshot: Equatable {
        var length: StoryLengthPreference
        var narrator: NarratorChoice
        var bento: StoryBentoTheme
        var autoStopAfterStory: Bool
        var backgroundMusicInPlayer: Bool
    }

    /// Masal üretimi ve ayar ekranı: tercihler `ChildProfile` üzerinden (CloudKit).
    static func load(for profile: ChildProfile?) -> Snapshot {
        guard let profile else {
            return legacySnapshotFromUserDefaults()
        }

        let d = UserDefaults.standard

        let length: StoryLengthPreference = {
            if !profile.storyLengthRaw.isEmpty, let l = StoryLengthPreference(rawValue: profile.storyLengthRaw) {
                return l
            }
            if let s = d.string(forKey: Keys.length), let l = StoryLengthPreference(rawValue: s) {
                return l
            }
            return .medium
        }()

        let narrator: NarratorChoice = {
            if !profile.narratorRaw.isEmpty, let n = NarratorChoice(rawValue: profile.narratorRaw), n.isSelectable {
                return n
            }
            if let s = d.string(forKey: Keys.narrator), let n = NarratorChoice(rawValue: s), n.isSelectable {
                return n
            }
            return .yumuşakBulut
        }()

        let bento: StoryBentoTheme = {
            if !profile.bentoThemeRaw.isEmpty, let t = StoryBentoTheme(rawValue: profile.bentoThemeRaw) {
                return t
            }
            if let s = d.string(forKey: Keys.bentoTheme), let t = StoryBentoTheme(rawValue: s) {
                return t
            }
            return StoryBentoTheme.inferred(from: profile.themes.first)
        }()

        let autoStop: Bool = {
            if d.object(forKey: Keys.autoStopAfterStory) != nil {
                return d.object(forKey: Keys.autoStopAfterStory) as? Bool ?? true
            }
            return profile.preferenceAutoStopAfterStory
        }()

        let bgMusic: Bool = {
            if d.object(forKey: Keys.backgroundMusicInPlayer) != nil {
                return d.object(forKey: Keys.backgroundMusicInPlayer) as? Bool ?? true
            }
            return profile.preferenceBackgroundMusic
        }()

        return Snapshot(
            length: length,
            narrator: narrator,
            bento: bento,
            autoStopAfterStory: autoStop,
            backgroundMusicInPlayer: bgMusic
        )
    }

    /// Ayarlar değişince çağır; CloudKit ile senkronlanır.
    @MainActor
    static func persist(snapshot: Snapshot, to profile: ChildProfile, modelContext: ModelContext) {
        profile.storyLengthRaw = snapshot.length.rawValue
        profile.narratorRaw = snapshot.narrator.rawValue
        profile.bentoThemeRaw = snapshot.bento.rawValue
        profile.preferenceAutoStopAfterStory = snapshot.autoStopAfterStory
        profile.preferenceBackgroundMusic = snapshot.backgroundMusicInPlayer
        profile.themes = snapshot.bento.asProfileThemes()
        profile.updatedAt = .now
        let d = UserDefaults.standard
        d.set(snapshot.autoStopAfterStory, forKey: Keys.autoStopAfterStory)
        d.set(snapshot.backgroundMusicInPlayer, forKey: Keys.backgroundMusicInPlayer)
        d.removeObject(forKey: Keys.length)
        d.removeObject(forKey: Keys.narrator)
        d.removeObject(forKey: Keys.bentoTheme)
        try? modelContext.save()
    }

    /// Oynatıcı ve `UserDefaults` okuyan kodlar için; profil tercihlerini yansıt.
    static func mirrorPlaybackPreferencesToUserDefaults(for profile: ChildProfile?) {
        let snap = load(for: profile)
        let d = UserDefaults.standard
        d.set(snap.autoStopAfterStory, forKey: Keys.autoStopAfterStory)
        d.set(snap.backgroundMusicInPlayer, forKey: Keys.backgroundMusicInPlayer)
    }

    private static func legacySnapshotFromUserDefaults() -> Snapshot {
        let d = UserDefaults.standard
        let length = d.string(forKey: Keys.length).flatMap(StoryLengthPreference.init(rawValue:)) ?? .medium
        let stored = d.string(forKey: Keys.narrator).flatMap(NarratorChoice.init(rawValue:)) ?? .yumuşakBulut
        let narrator = stored.isSelectable ? stored : .yumuşakBulut
        let bento: StoryBentoTheme
        if let raw = d.string(forKey: Keys.bentoTheme), let t = StoryBentoTheme(rawValue: raw) {
            bento = t
        } else {
            bento = .adventure
        }
        let autoStop = d.object(forKey: Keys.autoStopAfterStory) as? Bool ?? true
        let bgMusic = d.object(forKey: Keys.backgroundMusicInPlayer) as? Bool ?? true
        return Snapshot(length: length, narrator: narrator, bento: bento, autoStopAfterStory: autoStop, backgroundMusicInPlayer: bgMusic)
    }

    static func resolvedVoiceID(for profile: ChildProfile?) -> String {
        let snap = load(for: profile)
        return snap.narrator.resolvedVoiceID() ?? NarratorChoice.defaultFemaleVoiceID()
    }

    static func defaultFemaleVoiceID() -> String {
        NarratorChoice.defaultFemaleVoiceID()
    }

    static var autoStopAfterStoryEnds: Bool {
        UserDefaults.standard.object(forKey: Keys.autoStopAfterStory) as? Bool ?? true
    }

    static var backgroundMusicDuringStory: Bool {
        UserDefaults.standard.object(forKey: Keys.backgroundMusicInPlayer) as? Bool ?? true
    }
}
