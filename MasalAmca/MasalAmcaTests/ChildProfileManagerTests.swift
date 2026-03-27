//
//  ChildProfileManagerTests.swift
//  MasalAmcaTests
//

import XCTest
@testable import MasalAmca

final class ChildProfileManagerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "active_profile_id")
    }

    func testActiveProfileFallsBackToFirst() {
        let manager = ChildProfileManager()
        manager.activeProfileID = nil
        let a = ChildProfile(name: "A", ageGroup: .twoToFour, themes: [])
        let b = ChildProfile(name: "B", ageGroup: .fiveToSeven, themes: [])
        let active = manager.activeProfile(from: [a, b])
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.id, a.id)
        XCTAssertEqual(manager.activeProfileID, a.id)
    }

    func testSwitchToProfile() {
        let manager = ChildProfileManager()
        let a = ChildProfile(name: "A", ageGroup: .twoToFour, themes: [])
        let b = ChildProfile(name: "B", ageGroup: .fiveToSeven, themes: [])
        _ = manager.activeProfile(from: [a, b])
        manager.switchTo(b)
        XCTAssertEqual(manager.activeProfile(from: [a, b])?.id, b.id)
    }
}
