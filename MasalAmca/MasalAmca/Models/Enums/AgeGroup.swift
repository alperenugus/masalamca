//
//  AgeGroup.swift
//  MasalAmca
//

import Foundation

enum AgeGroup: String, Codable, CaseIterable, Sendable {
    case twoToFour = "2-4"
    case fiveToSeven = "5-7"
    case eightPlus = "8+"

    var displayName: String { rawValue }
}
