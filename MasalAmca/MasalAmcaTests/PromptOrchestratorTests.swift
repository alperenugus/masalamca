//
//  PromptOrchestratorTests.swift
//  MasalAmcaTests
//

import XCTest
@testable import MasalAmca

final class PromptOrchestratorTests: XCTestCase {
    func testStoryRequestEncodesSnakeCaseKeys() throws {
        let profile = ChildProfile(
            name: "Can",
            ageGroup: .fiveToSeven,
            themes: [.animals, .magic],
            behavioralGoals: ["paylaşma"]
        )
        let dto = PromptOrchestrator.storyRequest(from: profile)
        let data = try JSONEncoder().encode(dto)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["child_name"] as? String, "Can")
        XCTAssertEqual(obj?["age_group"] as? String, "5-7")
        XCTAssertEqual(obj?["themes"] as? [String], ["animals", "magic"])
        XCTAssertEqual(obj?["behavioral_goal"] as? String, "paylaşma")
        XCTAssertEqual(obj?["language"] as? String, "tr")
    }
}
