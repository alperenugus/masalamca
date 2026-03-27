//
//  PlaybackWidgetStore.swift
//  MasalAmca
//

import Foundation

#if canImport(WidgetKit) && os(iOS)
import WidgetKit
#endif

/// Home Screen widget reads this snapshot from the shared App Group container.
enum PlaybackWidgetStore {
    /// Must match `NowPlayingWidget.kind` in the widget extension.
    static let widgetKind = "NowPlayingWidget"

    private enum Keys {
        static let storyTitle = "widget.storyTitle"
        static let subtitle = "widget.subtitle"
        static let isPlaying = "widget.isPlaying"
        static let elapsed = "widget.elapsed"
        static let duration = "widget.duration"
        static let sleepEnd = "widget.sleepEnd"
        static let hasSession = "widget.hasSession"
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: PlaybackWidgetAppGroup.id)
    }

    static func writeSnapshot(
        storyTitle: String,
        subtitle: String,
        isPlaying: Bool,
        elapsedSeconds: Double,
        durationSeconds: Double,
        sleepTimerEnd: Date?
    ) {
        guard let d = defaults else { return }
        d.set(storyTitle, forKey: Keys.storyTitle)
        d.set(subtitle, forKey: Keys.subtitle)
        d.set(isPlaying, forKey: Keys.isPlaying)
        d.set(elapsedSeconds, forKey: Keys.elapsed)
        d.set(durationSeconds, forKey: Keys.duration)
        if let end = sleepTimerEnd {
            d.set(end.timeIntervalSince1970, forKey: Keys.sleepEnd)
        } else {
            d.removeObject(forKey: Keys.sleepEnd)
        }
        d.set(true, forKey: Keys.hasSession)
        d.synchronize()
        reloadWidgetTimelines()
    }

    static func clear() {
        guard let d = defaults else { return }
        d.removeObject(forKey: Keys.storyTitle)
        d.removeObject(forKey: Keys.subtitle)
        d.set(false, forKey: Keys.isPlaying)
        d.set(0.0, forKey: Keys.elapsed)
        d.set(0.0, forKey: Keys.duration)
        d.removeObject(forKey: Keys.sleepEnd)
        d.set(false, forKey: Keys.hasSession)
        d.synchronize()
        reloadWidgetTimelines()
    }

    private static func reloadWidgetTimelines() {
        #if canImport(WidgetKit) && os(iOS)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        #endif
    }
}
