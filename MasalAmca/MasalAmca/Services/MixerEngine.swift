//
//  MixerEngine.swift
//  MasalAmca
//

import AVFoundation
import Observation

enum MixerSound: String, CaseIterable, Identifiable, Sendable {
    case rain
    case fireplace
    case ocean
    case wind
    case shush
    case fan

    var id: String { rawValue }

    var bundleFileName: String { rawValue }

    var displayTitle: String {
        switch self {
        case .rain: "Yağmur"
        case .fireplace: "Şömine"
        case .ocean: "Okyanus"
        case .wind: "Rüzgar"
        case .shush: "Anne Şşş"
        case .fan: "Vantilatör"
        }
    }

    var systemImage: String {
        switch self {
        case .rain: "drop.fill"
        case .fireplace: "flame"
        case .ocean: "water.waves"
        case .wind: "wind"
        case .shush: "mouth"
        case .fan: "fanblades.fill"
        }
    }

    /// Free tier: first three (wiki)
    static var freeTier: [MixerSound] { [.rain, .ocean, .wind] }
}

@Observable
@MainActor
final class MixerEngine {
    private var players: [MixerSound: AVAudioPlayer] = [:]
    var levels: [MixerSound: Double] = Dictionary(uniqueKeysWithValues: MixerSound.allCases.map { ($0, 0.4) })
    var enabled: [MixerSound: Bool] = Dictionary(uniqueKeysWithValues: MixerSound.allCases.map { ($0, false) })

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in MixerSound.allCases {
            let url =
                Bundle.main.url(forResource: sound.bundleFileName, withExtension: "wav", subdirectory: "Resources/Audio")
                ?? Bundle.main.url(forResource: sound.bundleFileName, withExtension: "wav")
            if let url {
                let p = try? AVAudioPlayer(contentsOf: url)
                p?.numberOfLoops = -1
                p?.prepareToPlay()
                players[sound] = p
            }
        }
    }

    func setEnabled(_ sound: MixerSound, on: Bool) {
        enabled[sound] = on
        guard let p = players[sound] else { return }
        if on {
            p.volume = Float(levels[sound] ?? 0)
            p.play()
        } else {
            p.stop()
            p.currentTime = 0
        }
    }

    func setLevel(_ sound: MixerSound, level: Double) {
        levels[sound] = level
        guard enabled[sound] == true, let p = players[sound] else { return }
        p.volume = Float(level)
    }

    func stopAll() {
        for s in MixerSound.allCases {
            setEnabled(s, on: false)
        }
    }

    /// Fade enabled layers from 0 to current levels over `duration` seconds.
    func fadeInAllEnabled(duration: TimeInterval) {
        for s in MixerSound.allCases where enabled[s] == true {
            guard let p = players[s] else { continue }
            let target = Float(levels[s] ?? 0)
            p.volume = 0
            p.play()
            p.setVolume(target, fadeDuration: duration)
        }
    }
}
