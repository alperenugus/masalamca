//
//  PresentedStory.swift
//  MasalAmca
//

import Foundation
import SwiftData

/// Full-screen player session: stable `id` so switching tracks does not dismiss the cover.
struct PresentedStory: Identifiable, Equatable {
    let sessionID: UUID
    let startStory: Story
    let playlist: [Story]

    var id: UUID { sessionID }

    init(startStory: Story, playlist: [Story]) {
        self.sessionID = UUID()
        self.startStory = startStory
        let sorted = playlist.sorted { $0.createdAt > $1.createdAt }
        let ids = Set(sorted.map(\.persistentModelID))
        if ids.contains(startStory.persistentModelID) {
            self.playlist = sorted
        } else {
            self.playlist = ([startStory] + sorted).sorted { $0.createdAt > $1.createdAt }
        }
    }

    static func == (lhs: PresentedStory, rhs: PresentedStory) -> Bool {
        lhs.sessionID == rhs.sessionID
    }
}
