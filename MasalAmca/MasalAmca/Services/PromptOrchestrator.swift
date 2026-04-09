//
//  PromptOrchestrator.swift
//  MasalAmca
//

import Foundation

// MARK: - Request DTO (iOS → Worker)

/// Structured story request. The worker builds prompts from these fields.
struct StoryRequestDTO: Codable, Sendable {
    var childName: String
    var ageGroup: String
    var themes: [String]

    enum CodingKeys: String, CodingKey {
        case childName = "child_name"
        case ageGroup = "age_group"
        case themes
    }
}

// MARK: - Response DTO (Worker → iOS)

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

// MARK: - TTS DTO

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

// MARK: - Request Builder

enum PromptOrchestrator {

    static func storyRequest(from profile: ChildProfile) -> StoryRequestDTO {
        let prefs = StoryPreferences.load(for: profile)
        let themeRawValues = StoryBentoTheme.normalizedSelection(prefs.bentoThemes)
            .map(\.rawValue)

        let ageGroupString: String = {
            switch profile.ageGroup {
            case .twoToFour: return "two_to_four"
            case .fiveToSeven: return "five_to_seven"
            case .eightPlus: return "eight_plus"
            }
        }()

        return StoryRequestDTO(
            childName: profile.name,
            ageGroup: ageGroupString,
            themes: themeRawValues
        )
    }
}
