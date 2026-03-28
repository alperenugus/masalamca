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
        case .short: "Kısa (3 dk)"
        case .medium: "Orta (5 dk)"
        case .long: "Uzun (10 dk)"
        }
    }

    /// Kabaca hedef dinleme süresi (TTS tempoyu profil bazında bilmediğimiz için UI / meta).
    var targetListeningDurationSeconds: Int {
        switch self {
        case .short: 180
        case .medium: 300
        case .long: 600
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
    /// Premium — erkek
    case yakamoz
    /// Premium — kadın
    case ihlamur
    /// Premium — erkek
    case camFisiltisi
    /// Premium — kadın
    case lavanta
    /// Premium — erkek
    case ruzgar
    /// Premium — kadın
    case gelincik

    var id: String { rawValue }

    /// Premium abonelik gerektiren ElevenLabs sesleri.
    var requiresPremium: Bool {
        switch self {
        case .yumuşakBulut, .bilgeDede: false
        case .yakamoz, .ihlamur, .camFisiltisi, .lavanta, .ruzgar, .gelincik: true
        }
    }

    var title: String {
        switch self {
        case .yumuşakBulut: "Yumuşak Bulut"
        case .bilgeDede: "Bilge Dede"
        case .yakamoz: "Yakamoz"
        case .ihlamur: "Ihlamur"
        case .camFisiltisi: "Çam Fısıltısı"
        case .lavanta: "Lavanta"
        case .ruzgar: "Rüzgar"
        case .gelincik: "Gelincik"
        }
    }

    var subtitle: String {
        switch self {
        case .yumuşakBulut: "Sakinleştirici ve alçak ses"
        case .bilgeDede: "Tok ve güven verici bir anlatım"
        case .yakamoz: "Premium • sıcak erkek anlatım"
        case .ihlamur: "Premium • yumuşak kadın anlatım"
        case .camFisiltisi: "Premium • dingin erkek anlatım"
        case .lavanta: "Premium • huzurlu kadın anlatım"
        case .ruzgar: "Premium • net erkek anlatım"
        case .gelincik: "Premium • sıcak kadın anlatım"
        }
    }

    var symbolName: String {
        switch self {
        case .yumuşakBulut: "cloud.fill"
        case .bilgeDede, .yakamoz, .ihlamur, .camFisiltisi, .lavanta, .ruzgar, .gelincik: "person.fill"
        }
    }

    /// ElevenLabs **Serdar Sağlam** (male, Bilge Dede).
    static let bilgeDedeVoiceID = "NfwyWIJnRR1RrYnStGUG"

    static let yakamozVoiceID = "mF7tIc9VLrznhGooGjaT"
    static let ihlamurVoiceID = "LYfSi2g3Frvxg50fRl91"
    static let camFisiltisiVoiceID = "LCHGt3rsPMP50Vs28amI"
    static let lavantaVoiceID = "ywzrmJ3AgYiLqAeZAGrq"
    static let ruzgarVoiceID = "j9K9HnBcmgA6xNWqjlX0"
    static let gelincikVoiceID = "bqaNYmxFgK1TN7CL95PZ"

    /// Eski kayıtlar (`neşeliPeri` vb.) için.
    static func resolvedFromStoredRaw(_ raw: String) -> NarratorChoice? {
        if raw == "neşeliPeri" { return .yumuşakBulut }
        return NarratorChoice(rawValue: raw)
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
        case .yakamoz:
            Self.yakamozVoiceID
        case .ihlamur:
            Self.ihlamurVoiceID
        case .camFisiltisi:
            Self.camFisiltisiVoiceID
        case .lavanta:
            Self.lavantaVoiceID
        case .ruzgar:
            Self.ruzgarVoiceID
        case .gelincik:
            Self.gelincikVoiceID
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
            if !profile.narratorRaw.isEmpty, let n = NarratorChoice.resolvedFromStoredRaw(profile.narratorRaw) {
                return n
            }
            if let s = d.string(forKey: Keys.narrator), let n = NarratorChoice.resolvedFromStoredRaw(s) {
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
        let narrator = d.string(forKey: Keys.narrator).flatMap(NarratorChoice.resolvedFromStoredRaw) ?? .yumuşakBulut
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
