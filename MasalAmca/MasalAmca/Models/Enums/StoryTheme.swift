//
//  StoryTheme.swift
//  MasalAmca
//

import Foundation

enum StoryTheme: String, Codable, CaseIterable, Sendable {
    case animals
    case space
    case magic
    case fairyTale

    var displayName: String {
        switch self {
        case .animals: "Hayvanlar"
        case .space: "Uzay"
        case .magic: "Sihir"
        case .fairyTale: "Masal Dünyası"
        }
    }

    var iconSystemName: String {
        switch self {
        case .animals: "pawprint"
        case .space: "rocket.fill"
        case .magic: "wand.and.stars"
        case .fairyTale: "building.columns.fill"
        }
    }
}
