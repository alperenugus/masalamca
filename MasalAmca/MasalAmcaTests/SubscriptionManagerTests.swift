//
//  SubscriptionManagerTests.swift
//  MasalAmcaTests
//

import XCTest
@testable import MasalAmca

@MainActor
final class SubscriptionManagerTests: XCTestCase {
    func testStoryQuotaFreeTier() {
        let sub = SubscriptionManager()
        sub.applyTestingState(premium: false, storiesGenerated: 0)
        XCTAssertTrue(sub.canGenerateStory())
        sub.applyTestingState(premium: false, storiesGenerated: 1)
        XCTAssertTrue(sub.canGenerateStory())
        sub.applyTestingState(premium: false, storiesGenerated: 2)
        XCTAssertFalse(sub.canGenerateStory())
    }

    func testStoryQuotaPremium() {
        let sub = SubscriptionManager()
        sub.applyTestingState(premium: true, storiesGenerated: 50)
        XCTAssertTrue(sub.canGenerateStory())
    }

    func testMixerSoundGating() {
        let sub = SubscriptionManager()
        sub.applyTestingState(premium: false, storiesGenerated: 0)
        XCTAssertTrue(sub.canUseSound(.rain))
        XCTAssertTrue(sub.canUseSound(.ocean))
        XCTAssertTrue(sub.canUseSound(.wind))
        XCTAssertFalse(sub.canUseSound(.fireplace))

        sub.applyTestingState(premium: true, storiesGenerated: 0)
        XCTAssertTrue(sub.canUseSound(.fireplace))
    }
}
