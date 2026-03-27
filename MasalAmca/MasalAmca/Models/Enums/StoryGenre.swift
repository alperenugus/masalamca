//
//  StoryGenre.swift
//  MasalAmca
//

import Foundation

enum StoryGenre: String, Codable, CaseIterable, Sendable {
    case calming
    case adventure
    case educational

    var displayName: String {
        switch self {
        case .calming: "Sakinleştirici"
        case .adventure: "Macera"
        case .educational: "Eğitici"
        }
    }
}
