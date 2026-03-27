//
//  PromptOrchestrator.swift
//  MasalAmca
//

import Foundation

struct StoryGenerateRequestDTO: Codable, Sendable {
    var childName: String
    var ageGroup: String
    var themes: [String]
    var behavioralGoal: String?
    var language: String

    enum CodingKeys: String, CodingKey {
        case childName = "child_name"
        case ageGroup = "age_group"
        case themes
        case behavioralGoal = "behavioral_goal"
        case language
    }
}

struct StoryGenerateResponseDTO: Codable, Sendable {
    var title: String
    var body: String
    var genre: String
    var wordCount: Int?
    var model: String?

    enum CodingKeys: String, CodingKey {
        case title, body, genre, model
        case wordCount = "word_count"
    }
}

struct TTSRequestDTO: Codable, Sendable {
    var text: String
    var voiceID: String
    var outputFormat: String

    enum CodingKeys: String, CodingKey {
        case text
        case voiceID = "voice_id"
        case outputFormat = "output_format"
    }
}

enum PromptOrchestrator {
    static func storyRequest(from profile: ChildProfile) -> StoryGenerateRequestDTO {
        StoryGenerateRequestDTO(
            childName: profile.name,
            ageGroup: profile.ageGroup.rawValue,
            themes: profile.themes.map(\.rawValue),
            behavioralGoal: profile.behavioralGoals.first,
            language: "tr"
        )
    }
}
