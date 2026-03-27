//
//  AudioPlayerService.swift
//  MasalAmca
//

import AVFoundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class AudioPlayerService: NSObject {
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var timer: Timer?

    /// Called when narration reaches natural end (e.g. crossfade into white noise).
    var onPlaybackFinished: (() -> Void)?

    override init() {
        super.init()
    }

    private var nowPlayingTitle: String = "Masal"

    func load(fileURL: URL, title: String = "Masal") throws {
        stop()
        nowPlayingTitle = title
        let p = try AVAudioPlayer(contentsOf: fileURL)
        p.delegate = self
        p.prepareToPlay()
        player = p
        duration = p.duration
        currentTime = 0
        updateNowPlaying(title: title)
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        isPlaying = true
        startTimer()
        updateNowPlaying(title: nowPlayingTitle)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlaying(title: nowPlayingTitle)
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = min(max(0, time), p.duration)
        currentTime = p.currentTime
        updateNowPlaying(title: nowPlayingTitle)
    }

    var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(currentTime / duration)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let p = self.player else { return }
                self.currentTime = p.currentTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateNowPlaying(title: String, artist: String = "Masal Amca") {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopTimer()
            self.updateNowPlaying(title: self.nowPlayingTitle)
            let cb = self.onPlaybackFinished
            self.onPlaybackFinished = nil
            cb?()
        }
    }
}
