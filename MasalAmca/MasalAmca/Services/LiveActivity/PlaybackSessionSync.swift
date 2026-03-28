//
//  PlaybackSessionSync.swift
//  MasalAmca
//

import Foundation

@MainActor
enum PlaybackSessionSync {
    /// Kilit ekranında yalnızca sistem **Now Playing** (`MPNowPlayingInfoCenter`) kullanılır; Live Activity ve
    /// ana ekran widget anlık görüntüsü aynı bilgiyi tekrarladığı için güncellenmez.
    static func publish(
        story: Story,
        audio: AudioPlayerService,
        sleepTimer: SleepTimerController,
        hasPlayableAudio: Bool
    ) async {
        _ = story
        _ = audio
        _ = sleepTimer
        _ = hasPlayableAudio
    }

    /// Eski oturumlardan kalan widget / Live Activity kalıntılarını temizler.
    static func endSession() async {
        PlaybackWidgetStore.clear()
        await PlaybackLiveActivityManager.shared.end()
    }
}
