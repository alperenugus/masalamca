//
//  AudioPlayerService.swift
//  MasalAmca
//

import AVFoundation
import MediaPlayer
import Observation
import SwiftUI

@Observable
@MainActor
final class AudioPlayerService: NSObject {
    private static let logPrefix = "[AudioPlayer]"
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var timer: Timer?
    private var remoteCommandsWired = false
    private var sessionObserversInstalled = false

    /// True when a track is loaded (regardless of play/pause state).
    var hasActiveTrack: Bool { duration > 0 }

    /// Called when narration reaches natural end (e.g. crossfade into white noise).
    var onPlaybackFinished: (() -> Void)?

    // MARK: - Playlist tracking (survives player view dismissal)

    private(set) var playlist: [Story] = []
    private(set) var currentStoryID: UUID?

    var hasNextTrack: Bool {
        guard let id = currentStoryID,
              let idx = playlist.firstIndex(where: { $0.id == id }) else { return false }
        return idx + 1 < playlist.count
    }

    var hasPreviousTrack: Bool {
        guard let id = currentStoryID,
              let idx = playlist.firstIndex(where: { $0.id == id }) else { return false }
        return idx > 0
    }

    /// Called by the view when it wants to be notified that the user skipped track from the lock screen.
    var onTrackChanged: ((Story) -> Void)?

    override init() {
        super.init()
        installAudioSessionObserversIfNeeded()
    }

    private(set) var nowPlayingTitle: String = "Masal"

    func setPlaylist(_ stories: [Story], currentID: UUID) {
        playlist = stories
        currentStoryID = currentID
        refreshSkipCommandState()
    }

    func updateCurrentStoryID(_ id: UUID) {
        currentStoryID = id
        refreshSkipCommandState()
    }

    func load(fileURL: URL, title: String = "Masal") throws {
        stopPlayer()
        nowPlayingTitle = title
        let p = try AVAudioPlayer(contentsOf: fileURL)
        p.delegate = self
        p.prepareToPlay()
        player = p
        duration = p.duration
        currentTime = 0
        wireRemoteTransportIfNeeded()
        publishFullNowPlayingInfo(title: title)
        debugLog("load(fileURL): \(title) duration=\(String(format: "%.2f", duration))s url=\(fileURL.lastPathComponent)")
    }

    func load(data: Data, title: String = "Masal") throws {
        stopPlayer()
        nowPlayingTitle = title
        let p = try AVAudioPlayer(data: data)
        p.delegate = self
        p.prepareToPlay()
        player = p
        duration = p.duration
        currentTime = 0
        wireRemoteTransportIfNeeded()
        publishFullNowPlayingInfo(title: title)
        debugLog("load(data): \(title) duration=\(String(format: "%.2f", duration))s bytes=\(data.count)")
    }

    func play() {
        let session = AVAudioSession.sharedInstance()
        player?.play()
        isPlaying = true
        startTimer()
        publishFullNowPlayingInfo(title: nowPlayingTitle)
        debugLog("play(): \(nowPlayingTitle) session(category=\(session.category.rawValue) mode=\(session.mode.rawValue))")
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        publishFullNowPlayingInfo(title: nowPlayingTitle)
        debugLog("pause()")
    }

    /// Fully stop playback and clear Now Playing.
    func stop() {
        stopPlayer()
        playlist = []
        currentStoryID = nil
        onPlaybackFinished = nil
        onTrackChanged = nil
        debugLog("stop()")
    }

    /// Stop current playback without clearing playlist state or callbacks.
    func stopCurrentPlayback() {
        stopPlayer()
        debugLog("stopCurrentPlayback()")
    }

    /// Stop the player and clear remote commands, but keep playlist state.
    private func stopPlayer() {
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
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
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

    // MARK: - Skip logic

    func skipToNextPublic() { skipToNext() }
    func skipToPreviousPublic() { skipToPrevious() }

    private func skipToNext() {
        guard let id = currentStoryID,
              let idx = playlist.firstIndex(where: { $0.id == id }),
              idx + 1 < playlist.count else { return }
        let next = playlist[idx + 1]
        loadAndPlay(story: next)
    }

    private func skipToPrevious() {
        guard let id = currentStoryID,
              let idx = playlist.firstIndex(where: { $0.id == id }),
              idx > 0 else { return }
        let prev = playlist[idx - 1]
        loadAndPlay(story: prev)
    }

    private func loadAndPlay(story: Story) {
        currentStoryID = story.id
        do {
            if let blob = story.audioBlob, !blob.isEmpty {
                try load(data: blob, title: story.title)
                play()
            } else if let name = story.audioFileName {
                let url = AudioCacheManager.documentsDirectory().appendingPathComponent(name)
                guard FileManager.default.fileExists(atPath: url.path) else { return }
                try load(fileURL: url, title: story.title)
                play()
            }
        } catch {
            debugLog("loadAndPlay failed: \(error)")
        }
        refreshSkipCommandState()
        onTrackChanged?(story)
    }

    private func refreshSkipCommandState() {
        guard remoteCommandsWired else { return }
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = hasNextTrack
        center.previousTrackCommand.isEnabled = hasPreviousTrack
    }

    // MARK: - Timer

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

    // MARK: - Now Playing

    static let nowPlayingArtwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "NowPlayingArtwork") else { return nil }
        let size = CGSize(width: 512, height: 512)
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }()

    private func wireRemoteTransportIfNeeded() {
        guard !remoteCommandsWired else { return }
        remoteCommandsWired = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = hasNextTrack
        center.previousTrackCommand.isEnabled = hasPreviousTrack
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToNext() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToPrevious() }
            return .success
        }
    }

    func publishFullNowPlayingInfo(title: String, artist: String = "Masal Amca") {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
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

    private func debugLog(_ msg: String) {
        #if DEBUG
        print("\(Self.logPrefix) \(msg)")
        #endif
    }

    // MARK: - Session observers

    private func installAudioSessionObserversIfNeeded() {
        guard !sessionObserversInstalled else { return }
        sessionObserversInstalled = true

        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            guard let self else { return }
            let t = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let type = AVAudioSession.InterruptionType(rawValue: t ?? 0)
            self.debugLog("AVAudioSession interruption: \(String(describing: type))")
            if type == .began {
                Task { @MainActor in
                    self.player?.pause()
                    self.isPlaying = false
                    self.stopTimer()
                    self.publishFullNowPlayingInfo(title: self.nowPlayingTitle)
                }
            } else if type == .ended {
                let opts = n.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let shouldResume = AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume)
                Task { @MainActor in
                    if shouldResume, self.player != nil {
                        self.play()
                    }
                }
            }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] n in
            guard let self else { return }
            let r = n.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            let reason = AVAudioSession.RouteChangeReason(rawValue: r ?? 0)
            self.debugLog("AVAudioSession route change: \(String(describing: reason))")
        }
        nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            self?.debugLog("AVAudioSession mediaServicesWereReset")
        }
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

// MARK: - Environment Key

private enum MasalAudioPlayerKey: EnvironmentKey {
    static let defaultValue: AudioPlayerService? = nil
}

extension EnvironmentValues {
    var masalAudioPlayer: AudioPlayerService? {
        get { self[MasalAudioPlayerKey.self] }
        set { self[MasalAudioPlayerKey.self] = newValue }
    }
}
