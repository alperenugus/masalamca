//
//  ModelTests.swift
//  MasalAmcaTests
//

import XCTest
@testable import MasalAmca

final class ModelTests: XCTestCase {
    func testChildProfileThemesRoundTrip() {
        let p = ChildProfile(
            name: "Deniz",
            ageGroup: .eightPlus,
            themes: [.space, .fairyTale, .animals],
            behavioralGoals: ["cesaret", "paylaşım"]
        )
        XCTAssertEqual(p.themes, [.space, .fairyTale, .animals])
        XCTAssertEqual(p.behavioralGoals, ["cesaret", "paylaşım"])

        p.themes = [.magic]
        p.behavioralGoals = ["sabır"]
        XCTAssertEqual(p.themes, [.magic])
        XCTAssertEqual(p.behavioralGoals, ["sabır"])
    }

    func testStoryGenreRoundTrip() {
        let s = Story(title: "T", body: "B", genre: .adventure)
        XCTAssertEqual(s.genre, .adventure)
        s.genre = .educational
        XCTAssertEqual(s.genre, .educational)
    }
}
