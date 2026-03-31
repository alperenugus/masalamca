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
        .system(size: 56, weight: .heavy, design: .rounded)
    }

    static func headlineMedium() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func titleMedium() -> Font {
        .system(size: 18, weight: .bold, design: .rounded)
    }

    static func bodyLarge() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    static func bodyMedium() -> Font {
        .system(size: 14, weight: .medium, design: .default)
    }

    static func labelMedium() -> Font {
        .system(size: 12, weight: .semibold, design: .default)
    }

    static func labelSmall() -> Font {
        .system(size: 10, weight: .bold, design: .default)
    }
}
