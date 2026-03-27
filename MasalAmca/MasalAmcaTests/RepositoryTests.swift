//
//  RepositoryTests.swift
//  MasalAmcaTests
//

import SwiftData
import XCTest
@testable import MasalAmca

final class RepositoryTests: XCTestCase {
    @MainActor
    func testInsertProfileAndStory() async throws {
        let schema = Schema([ChildProfile.self, Story.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo = SwiftDataRepository(modelContainer: container)

        let profile = ChildProfile(name: "Ece", ageGroup: .twoToFour, themes: [.fairyTale])
        try await repo.insert(profile)

        let story = Story(title: "Masal", body: "İçerik", profile: profile)
        try await repo.insert(story)

        let ctx = ModelContext(container)
        let pFetch = FetchDescriptor<ChildProfile>()
        let profiles = try ctx.fetch(pFetch)
        XCTAssertEqual(profiles.count, 1)

        let sFetch = FetchDescriptor<Story>()
        let stories = try ctx.fetch(sFetch)
        XCTAssertEqual(stories.count, 1)
        XCTAssertEqual(stories.first?.profile?.id, profile.id)
    }

    @MainActor
    func testDeleteProfileCascadesStories() async throws {
        let schema = Schema([ChildProfile.self, Story.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo = SwiftDataRepository(modelContainer: container)

        let profile = ChildProfile(name: "Ali", ageGroup: .fiveToSeven, themes: [])
        try await repo.insert(profile)
        try await repo.insert(Story(title: "S1", body: "B", profile: profile))
        try await repo.delete(profile)

        let ctx = ModelContext(container)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ChildProfile>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Story>()).count, 0)
    }
}
