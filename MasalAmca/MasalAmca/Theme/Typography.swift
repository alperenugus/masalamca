//
//  Typography.swift
//  MasalAmca
//

import SwiftUI

enum MasalFont {
    static let headlineFamily = "Plus Jakarta Sans"
    static let bodyFamily = "Manrope"

    /// Variable fonts from Google Fonts bundle.
    static func registerIfNeeded() {
        // Fonts are loaded via Info.plist UIAppFonts
    }

    static func displayLarge() -> Font {
        .custom(headlineFamily, size: 56, relativeTo: .largeTitle).weight(.heavy)
    }

    static func headlineMedium() -> Font {
        .custom(headlineFamily, size: 28, relativeTo: .title).weight(.bold)
    }

    static func titleMedium() -> Font {
        .custom(headlineFamily, size: 18, relativeTo: .title3).weight(.bold)
    }

    static func bodyLarge() -> Font {
        .custom(bodyFamily, size: 16, relativeTo: .body).weight(.regular)
    }

    static func bodyMedium() -> Font {
        .custom(bodyFamily, size: 14, relativeTo: .callout).weight(.medium)
    }

    static func labelMedium() -> Font {
        .custom(bodyFamily, size: 12, relativeTo: .caption).weight(.semibold)
    }

    static func labelSmall() -> Font {
        .custom(bodyFamily, size: 10, relativeTo: .caption2).weight(.bold)
    }
}
