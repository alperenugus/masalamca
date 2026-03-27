//
//  MasalAmcaPlaybackAttributes.swift
//  MasalAmcaWidget
//
//  IMPORTANT: Keep in sync with MasalAmca/Services/LiveActivity/MasalAmcaPlaybackAttributes.swift
//

import ActivityKit
import Foundation

enum PlaybackWidgetAppGroup {
    static let id = "group.alperenugus.MasalAmca"
}

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
