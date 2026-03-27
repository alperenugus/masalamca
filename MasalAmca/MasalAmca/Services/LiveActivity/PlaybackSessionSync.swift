//
//  PlaybackSessionSync.swift
//  MasalAmca
//

import Foundation

@MainActor
enum PlaybackSessionSync {
    /// Pushes state to the Home Screen widget (App Group) and Live Activity (Lock Screen / Dynamic Island).
    static func publish(
        story: Story,
        audio: AudioPlayerService,
        sleepTimer: SleepTimerController,
        hasPlayableAudio: Bool
    ) async {
        let title = story.title
        let subtitle: String
        if hasPlayableAudio {
            subtitle = audio.isPlaying ? "Seslendirme • Oynatılıyor" : "Seslendirme • Duraklatıldı"
        } else {
            subtitle = "Metin modu"
        }

        PlaybackWidgetStore.writeSnapshot(
            storyTitle: title,
            subtitle: subtitle,
            isPlaying: hasPlayableAudio && audio.isPlaying,
            elapsedSeconds: audio.currentTime,
            durationSeconds: audio.duration,
            sleepTimerEnd: sleepTimer.sleepTimerEndDate
        )

        await PlaybackLiveActivityManager.shared.startOrUpdate(
            storyTitle: title,
            subtitle: subtitle,
            isPlaying: hasPlayableAudio && audio.isPlaying,
            elapsedSeconds: audio.currentTime,
            durationSeconds: audio.duration,
            sleepTimerEnd: sleepTimer.sleepTimerEndDate
        )
    }

    static func endSession() async {
        PlaybackWidgetStore.clear()
        await PlaybackLiveActivityManager.shared.end()
    }
}
