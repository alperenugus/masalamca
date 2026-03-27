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
        case .short: "Kısa (5 dk)"
        case .medium: "Orta (10 dk)"
        case .long: "Uzun (15+ dk)"
        }
    }
}

// MARK: - Hikaye teması (bento → API + profil eşlemesi)

enum StoryBentoTheme: String, CaseIterable, Identifiable, Sendable {
    case adventure
    case nature
    case space
    case fairyTaleCastle

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .adventure: "Macera"
        case .nature: "Doğa"
        case .space: "Uzay"
        case .fairyTaleCastle: "Masal"
        }
    }

    var systemImage: String {
        switch self {
        case .adventure: "safari.fill"
        case .nature: "leaf.fill"
        case .space: "rocket.fill"
        case .fairyTaleCastle: "building.columns.fill"
        }
    }

    /// Sunucuya giden tema ipuçları (Türkçe, tek öğe).
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
        }
    }

    /// Onboarding `StoryTheme` ile uyum için profilde saklanan değerler.
    func asProfileThemes() -> [StoryTheme] {
        switch self {
        case .adventure: [.magic]
        case .nature: [.animals]
        case .space: [.space]
        case .fairyTaleCastle: [.fairyTale]
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
    /// Kadın — Info.plist `ElevenLabsVoiceID`
    case yumuşakBulut
    /// Erkek — sabit ID
    case bilgeDede
    /// Üçüncü ses için ayrı ElevenLabs ID eklenince seçilebilir yapılabilir.
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

    /// Erkek anlatıcı (ElevenLabs).
    static let bilgeDedeVoiceID = "NfwyWIJnRR1RrYnStGUG"

    var isSelectable: Bool {
        switch self {
        case .neşeliPeri: false
        default: true
        }
    }

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

// MARK: - UserDefaults

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

    static func load(for profile: ChildProfile?) -> Snapshot {
        let d = UserDefaults.standard
        let length = d.string(forKey: Keys.length).flatMap(StoryLengthPreference.init(rawValue:)) ?? .medium
        let storedNarrator = d.string(forKey: Keys.narrator).flatMap(NarratorChoice.init(rawValue:)) ?? .yumuşakBulut
        let narrator = storedNarrator.isSelectable ? storedNarrator : .yumuşakBulut
        let bento: StoryBentoTheme
        if let raw = d.string(forKey: Keys.bentoTheme), let t = StoryBentoTheme(rawValue: raw) {
            bento = t
        } else {
            bento = StoryBentoTheme.inferred(from: profile?.themes.first)
        }
        let autoStop = d.object(forKey: Keys.autoStopAfterStory) as? Bool ?? true
        let bgMusic = d.object(forKey: Keys.backgroundMusicInPlayer) as? Bool ?? true
        return Snapshot(
            length: length,
            narrator: narrator.isSelectable ? narrator : .yumuşakBulut,
            bento: bento,
            autoStopAfterStory: autoStop,
            backgroundMusicInPlayer: bgMusic
        )
    }

    static func save(_ snapshot: Snapshot, profile: ChildProfile?, modelContext: ModelContext?) throws {
        let d = UserDefaults.standard
        d.set(snapshot.length.rawValue, forKey: Keys.length)
        d.set(snapshot.narrator.rawValue, forKey: Keys.narrator)
        d.set(snapshot.bento.rawValue, forKey: Keys.bentoTheme)
        d.set(snapshot.autoStopAfterStory, forKey: Keys.autoStopAfterStory)
        d.set(snapshot.backgroundMusicInPlayer, forKey: Keys.backgroundMusicInPlayer)

        if let profile, let modelContext {
            profile.themes = snapshot.bento.asProfileThemes()
            profile.updatedAt = .now
            try modelContext.save()
        }
    }

    static func resolvedVoiceID() -> String {
        let snap = load(for: nil)
        return snap.narrator.resolvedVoiceID() ?? defaultFemaleVoiceID()
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
