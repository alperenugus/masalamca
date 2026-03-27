//
//  MasalAmcaPlaybackAttributes.swift
//  MasalAmca
//
//  IMPORTANT: Keep in sync with MasalAmcaWidget/MasalAmcaPlaybackAttributes.swift
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

enum PlaybackWidgetAppGroup {
    /// Create in Apple Developer → App Groups; enable for main app + widget extension.
    static let id = "group.alperenugus.MasalAmca"
}

/// Live Activity payload (must match widget target copy).
struct MasalAmcaPlaybackAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        var storyTitle: String
        var subtitle: String
        var isPlaying: Bool
        var elapsedSeconds: Double
        var durationSeconds: Double
        var sleepTimerEnd: Date?
    }

    var sessionKind: String
}

#else

enum PlaybackWidgetAppGroup {
    static let id = "group.alperenugus.MasalAmca"
}

struct MasalAmcaPlaybackAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var storyTitle: String
        var subtitle: String
        var isPlaying: Bool
        var elapsedSeconds: Double
        var durationSeconds: Double
        var sleepTimerEnd: Date?
    }

    var sessionKind: String
}

#endif
