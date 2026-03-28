//
//  AppSyncPersistence.swift
//  MasalAmca
//

import Foundation
import SwiftData

enum AppSyncPersistence {
    private static let singletonKey = "app"
    private static let legacyStoryCountKey = "masal_stories_generated_count"

    @MainActor
    static func ensureAppSyncState(modelContext: ModelContext) -> AppSyncState {
        let key = singletonKey
        let fd = FetchDescriptor<AppSyncState>(predicate: #Predicate { $0.singletonKey == key })
        if let existing = try? modelContext.fetch(fd).first {
            return existing
        }
        let legacyCount = UserDefaults.standard.integer(forKey: legacyStoryCountKey)
        let legacyActive = UserDefaults.standard.string(forKey: "active_profile_id")
        let s = AppSyncState(
            singletonKey: key,
            storiesGeneratedCount: legacyCount,
            activeProfileUUIDString: legacyActive
        )
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    @MainActor
    static func persistStoryGenerationCount(_ count: Int, modelContext: ModelContext) {
        let s = ensureAppSyncState(modelContext: modelContext)
        s.storiesGeneratedCount = count
        try? modelContext.save()
    }

    @MainActor
    static func persistActiveProfileID(_ id: UUID?, modelContext: ModelContext) {
        let s = ensureAppSyncState(modelContext: modelContext)
        s.activeProfileUUIDString = id?.uuidString
        try? modelContext.save()
    }
}
