//
//  AudioPlayerService.swift
//  MasalAmca
//

import AVFoundation
import MediaPlayer
import Observation

#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
final class AudioPlayerService: NSObject {
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var timer: Timer?
    private var remoteCommandsWired = false

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
        wireRemoteTransportIfNeeded()
        publishFullNowPlayingInfo(title: title)
    }

    func load(data: Data, title: String = "Masal") throws {
        stop()
        nowPlayingTitle = title
        let p = try AVAudioPlayer(data: data)
        p.delegate = self
        p.prepareToPlay()
        player = p
        duration = p.duration
        currentTime = 0
        wireRemoteTransportIfNeeded()
        publishFullNowPlayingInfo(title: title)
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        isPlaying = true
        startTimer()
        publishFullNowPlayingInfo(title: nowPlayingTitle)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        publishFullNowPlayingInfo(title: nowPlayingTitle)
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopTimer()
        remoteCommandsWired = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
    }

    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = min(max(0, time), p.duration)
        currentTime = p.currentTime
        publishFullNowPlayingInfo(title: nowPlayingTitle)
    }

    var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(currentTime / duration)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard let p = self.player else { return }
                self.currentTime = p.currentTime
                self.publishElapsedOnly()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private static let nowPlayingArtwork: MPMediaItemArtwork? = {
        #if canImport(UIKit)
        guard let image = UIImage(named: "NowPlayingArtwork") else { return nil }
        let size = CGSize(width: 512, height: 512)
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
        #else
        return nil
        #endif
    }()

    private func wireRemoteTransportIfNeeded() {
        guard !remoteCommandsWired else { return }
        remoteCommandsWired = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
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

    private func publishFullNowPlayingInfo(title: String, artist: String = "Masal Amca") {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let art = Self.nowPlayingArtwork {
            info[MPMediaItemPropertyArtwork] = art
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func publishElapsedOnly() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopTimer()
            self.publishFullNowPlayingInfo(title: self.nowPlayingTitle)
            let cb = self.onPlaybackFinished
            self.onPlaybackFinished = nil
            cb?()
        }
    }
}
