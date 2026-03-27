//
//  SwiftDataRepository.swift
//  MasalAmca
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataRepository {
    func insert(_ profile: ChildProfile) throws {
        modelContext.insert(profile)
        try modelContext.save()
    }

    func insert(_ story: Story) throws {
        modelContext.insert(story)
        try modelContext.save()
    }

    func delete(_ story: Story) throws {
        modelContext.delete(story)
        try modelContext.save()
    }

    func delete(_ profile: ChildProfile) throws {
        modelContext.delete(profile)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }
}
