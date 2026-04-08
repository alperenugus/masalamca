//
//  AppStoreReviewManager.swift
//  MasalAmca
//

import StoreKit
import SwiftUI

@MainActor
enum AppStoreReviewManager {
    /// Milestones at which to prompt for a review (total stories generated).
    private static let reviewMilestones: Set<Int> = [3, 10, 25]

    /// Key to track which milestones have already triggered a request.
    private static let promptedMilestonesKey = "reviewPromptedMilestones"

    /// Requests a review if the current story count hits a milestone that hasn't been prompted yet.
    static func requestReviewIfAppropriate(
        storiesGenerated: Int,
        requestReview: RequestReviewAction
    ) {
        let prompted = promptedMilestones()
        guard let milestone = reviewMilestones.first(where: { $0 == storiesGenerated && !prompted.contains($0) }) else {
            return
        }
        markMilestonePrompted(milestone)
        requestReview()
    }

    private static func promptedMilestones() -> Set<Int> {
        let raw = UserDefaults.standard.array(forKey: promptedMilestonesKey) as? [Int] ?? []
        return Set(raw)
    }

    private static func markMilestonePrompted(_ milestone: Int) {
        var current = promptedMilestones()
        current.insert(milestone)
        UserDefaults.standard.set(Array(current), forKey: promptedMilestonesKey)
    }
}
