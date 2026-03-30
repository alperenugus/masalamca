//
//  ChildProfile.swift
//  MasalAmca
//

import Foundation
import SwiftData

@Model
final class ChildProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var ageGroupRaw: String
    /// Comma-separated `StoryTheme.rawValue`
    var themesSerialized: String
    /// Pipe-separated goals e.g. "paylaşma|cesaret"
    var behavioralGoalsSerialized: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Masal ayarları (CloudKit ile senkron; üretimde kullanılır)
    /// `StoryLengthPreference.rawValue`; boşsa orta uzunluk varsayılır.
    var storyLengthRaw: String = ""
    /// `NarratorChoice.rawValue`
    var narratorRaw: String = ""
    /// Virgülle ayrılmış `StoryBentoTheme.rawValue` (çoklu seçim). Boşsa `themes` üzerinden çıkarım.
    var bentoThemeRaw: String = ""
    var preferenceAutoStopAfterStory: Bool = true
    var preferenceBackgroundMusic: Bool = true

    /// Yerel bildirim: yatma saati hatırlatıcısı (çocuk profili başına; yalnızca seçili profil için zamanlanır).
    var bedtimeReminderEnabled: Bool = false
    var bedtimeReminderHour: Int = 20
    var bedtimeReminderMinute: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Story.profile)
    var stories: [Story]

    init(
        id: UUID = UUID(),
        name: String,
        ageGroup: AgeGroup,
        themes: [StoryTheme],
        behavioralGoals: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        stories: [Story] = []
    ) {
        self.id = id
        self.name = name
        self.ageGroupRaw = ageGroup.rawValue
        self.themesSerialized = themes.map(\.rawValue).joined(separator: ",")
        self.behavioralGoalsSerialized = behavioralGoals.joined(separator: "|")
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stories = stories
        self.storyLengthRaw = StoryLengthPreference.medium.rawValue
        self.narratorRaw = NarratorChoice.yumuşakBulut.rawValue
        self.bentoThemeRaw = ""
        self.preferenceAutoStopAfterStory = true
        self.preferenceBackgroundMusic = true
        self.bedtimeReminderEnabled = false
        self.bedtimeReminderHour = 20
        self.bedtimeReminderMinute = 0
    }

    var ageGroup: AgeGroup {
        get { AgeGroup(rawValue: ageGroupRaw) ?? .twoToFour }
        set { ageGroupRaw = newValue.rawValue }
    }

    var themes: [StoryTheme] {
        get {
            themesSerialized
                .split(separator: ",")
                .compactMap { StoryTheme(rawValue: String($0)) }
        }
        set {
            themesSerialized = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var behavioralGoals: [String] {
        get {
            behavioralGoalsSerialized
                .split(separator: "|")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        set {
            behavioralGoalsSerialized = newValue.joined(separator: "|")
        }
    }
}
