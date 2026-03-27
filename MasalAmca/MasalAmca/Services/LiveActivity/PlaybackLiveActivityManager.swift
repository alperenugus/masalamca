//
//  PlaybackLiveActivityManager.swift
//  MasalAmca
//

import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

@MainActor
final class PlaybackLiveActivityManager {
    static let shared = PlaybackLiveActivityManager()

    private var activity: Activity<MasalAmcaPlaybackAttributes>?

    private init() {}

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func startOrUpdate(
        storyTitle: String,
        subtitle: String,
        isPlaying: Bool,
        elapsedSeconds: Double,
        durationSeconds: Double,
        sleepTimerEnd: Date?
    ) async {
        let state = MasalAmcaPlaybackAttributes.ContentState(
            storyTitle: storyTitle,
            subtitle: subtitle,
            isPlaying: isPlaying,
            elapsedSeconds: elapsedSeconds,
            durationSeconds: durationSeconds,
            sleepTimerEnd: sleepTimerEnd
        )

        if let existing = activity {
            await existing.update(ActivityContent(state: state, staleDate: nil))
            return
        }

        guard isSupported else { return }

        let attributes = MasalAmcaPlaybackAttributes(sessionKind: "story")
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func end() async {
        guard let activity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
    }
}

#else

@MainActor
final class PlaybackLiveActivityManager {
    static let shared = PlaybackLiveActivityManager()

    private init() {}

    var isSupported: Bool { false }

    func startOrUpdate(
        storyTitle: String,
        subtitle: String,
        isPlaying: Bool,
        elapsedSeconds: Double,
        durationSeconds: Double,
        sleepTimerEnd: Date?
    ) async {}

    func end() async {}
}

#endif
