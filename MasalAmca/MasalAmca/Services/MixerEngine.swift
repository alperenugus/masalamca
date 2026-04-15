//
//  MixerEngine.swift
//  MasalAmca
//

import AVFoundation
import MediaPlayer
import Observation

enum MixerSound: String, CaseIterable, Identifiable, Sendable {
    case rain
    case fireplace
    case ocean
    case wind
    case shush
    case fan
    case forest
    case train
    case womb

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
        case .forest: "Orman"
        case .train: "Tren"
        case .womb: "Anne Karnı"
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
        case .forest: "tree.fill"
        case .train: "tram.fill"
        case .womb: "heart.circle.fill"
        }
    }

    var playlistSubtitle: String {
        switch self {
        case .rain: "Rahatlatıcı Doğa"
        case .fireplace: "Sıcak Atmosfer"
        case .ocean: "Derin Dalgalar"
        case .wind: "Hafif Esinti"
        case .shush: "Sakinleştirici"
        case .fan: "Sabit Akış"
        case .forest: "Yeşil Orman"
        case .train: "Rayların Üzerinde"
        case .womb: "Yumuşak ve Sıcak"
        }
    }

    static var freeTier: [MixerSound] { [.rain, .ocean, .wind] }
}

@Observable
@MainActor
final class MixerEngine {
    private var players: [MixerSound: AVAudioPlayer] = [:]
    var levels: [MixerSound: Double] = Dictionary(uniqueKeysWithValues: MixerSound.allCases.map { ($0, 0.4) })
    var enabled: [MixerSound: Bool] = Dictionary(uniqueKeysWithValues: MixerSound.allCases.map { ($0, false) })

    /// Set to true when AudioPlayerService has an active story track.
    var storyIsActive: Bool = false {
        didSet { updateNowPlayingIfNeeded() }
    }

    // MARK: - Focused sound & skip (survives view dismissal)

    /// The currently focused sound for solo white noise playback.
    var focusedSound: MixerSound = .rain

    /// Ordered playlist for skip commands. Set by WhiteNoisePlayerView.
    var orderedPlaylist: [MixerSound] = MixerSound.allCases

    /// Subscription manager reference for premium checks during lock screen skip.
    weak var subscriptionManager: SubscriptionManager?

    /// Audio player reference — mixer stops the story when taking over solo white noise playback.
    weak var audioPlayerService: AudioPlayerService?

    private var mixerRemoteCommandsWired = false

    init() {
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
        updateNowPlayingIfNeeded()
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

    func solo(_ sound: MixerSound) {
        focusedSound = sound
        if let audio = audioPlayerService, audio.hasActiveTrack {
            audio.stop()
        }
        for s in MixerSound.allCases {
            setEnabled(s, on: s == sound)
        }
    }

    func fadeInAllEnabled(duration: TimeInterval) {
        for s in MixerSound.allCases where enabled[s] == true {
            guard let p = players[s] else { continue }
            let target = Float(levels[s] ?? 0)
            p.volume = 0
            p.play()
            p.setVolume(target, fadeDuration: duration)
        }
    }

    // MARK: - Skip logic (self-contained, no view references)

    func skipToNextSound() {
        let list = orderedPlaylist
        guard let idx = list.firstIndex(of: focusedSound) else { return }
        for offset in 1..<list.count {
            let candidate = list[(idx + offset) % list.count]
            if subscriptionManager?.canUseSound(candidate) ?? MixerSound.freeTier.contains(candidate) {
                solo(candidate)
                return
            }
        }
    }

    func skipToPreviousSound() {
        let list = orderedPlaylist
        guard let idx = list.firstIndex(of: focusedSound) else { return }
        for offset in 1..<list.count {
            let candidate = list[(idx - offset + list.count) % list.count]
            if subscriptionManager?.canUseSound(candidate) ?? MixerSound.freeTier.contains(candidate) {
                solo(candidate)
                return
            }
        }
    }

    // MARK: - Now Playing for white noise

    private func updateNowPlayingIfNeeded() {
        guard !storyIsActive else { return }
        let activeSounds = MixerSound.allCases.filter { enabled[$0] == true }
        if activeSounds.isEmpty {
            if !mixerRemoteCommandsWired { return }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            removeMixerRemoteCommands()
        } else {
            wireMixerRemoteCommandsIfNeeded()
            let title = activeSounds.count == 1 ? activeSounds[0].displayTitle : "Beyaz Gürültü"
            var info: [String: Any] = [
                MPMediaItemPropertyTitle: title,
                MPMediaItemPropertyArtist: "Masal Amca",
                MPNowPlayingInfoPropertyPlaybackRate: 1.0,
                MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
                MPNowPlayingInfoPropertyIsLiveStream: true
            ]
            if let artwork = AudioPlayerService.nowPlayingArtwork {
                info[MPMediaItemPropertyArtwork] = artwork
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func wireMixerRemoteCommandsIfNeeded() {
        guard !mixerRemoteCommandsWired else { return }
        mixerRemoteCommandsWired = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                for s in MixerSound.allCases where self.enabled[s] == true {
                    self.players[s]?.play()
                }
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                for s in MixerSound.allCases where self.enabled[s] == true {
                    self.players[s]?.pause()
                }
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToNextSound() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToPreviousSound() }
            return .success
        }
    }

    private func removeMixerRemoteCommands() {
        mixerRemoteCommandsWired = false
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
    }
}
