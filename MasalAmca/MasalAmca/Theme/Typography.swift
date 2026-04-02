//
//  Typography.swift
//  MasalAmca
//

import SwiftUI

enum MasalFont {
    static let headlineFamily = "Plus Jakarta Sans"
    static let bodyFamily = "Manrope"

    /// PostScript names for bundled static faces. Do not chain `.weight()` on `.custom(headlineFamily, …)` — UIKit logs descriptor failures for non-variable fonts.
    private static let plusJakartaBold = "PlusJakartaSans-Bold"
    private static let plusJakartaSemiBold = "PlusJakartaSans-SemiBold"
    private static let manropeRegular = "Manrope-Regular"
    private static let manropeMedium = "Manrope-Medium"

    /// Variable fonts from Google Fonts bundle.
    static func registerIfNeeded() {
        // Fonts are loaded via Info.plist UIAppFonts
    }

    static func readerFirstParagraph(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title2) -> Font {
        .custom(plusJakartaBold, size: size, relativeTo: textStyle)
    }

    static func readerBody(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title3) -> Font {
        .custom(manropeRegular, size: size, relativeTo: textStyle)
    }

    static func readerPullQuote(size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom(manropeMedium, size: size, relativeTo: textStyle)
    }

    static func timerDigits(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title3) -> Font {
        .custom(plusJakartaSemiBold, size: size, relativeTo: textStyle)
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
