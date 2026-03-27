//
//  DreamscapePalette.swift
//  MasalAmca
//

import SwiftUI

/// Midnight palette tokens from DesignProposal (Dreamscape Narrative).
struct DreamscapePalette: Sendable {
    var surface: Color
    var surfaceContainer: Color
    var surfaceContainerLow: Color
    var surfaceContainerLowest: Color
    var surfaceContainerHigh: Color
    var surfaceContainerHighest: Color
    var surfaceVariant: Color
    var surfaceBright: Color
    var onSurface: Color
    var onSurfaceVariant: Color
    var onBackground: Color
    var primary: Color
    var primaryContainer: Color
    var onPrimary: Color
    var onPrimaryContainer: Color
    var primaryFixed: Color
    var secondary: Color
    var secondaryContainer: Color
    var onSecondary: Color
    var tertiary: Color
    var tertiaryContainer: Color
    var onTertiary: Color
    var outline: Color
    var outlineVariant: Color
    var error: Color
    var errorContainer: Color

    static let midnight = DreamscapePalette(
        surface: Color(hex: "041329"),
        surfaceContainer: Color(hex: "112036"),
        surfaceContainerLow: Color(hex: "0d1c32"),
        surfaceContainerLowest: Color(hex: "010e24"),
        surfaceContainerHigh: Color(hex: "1c2a41"),
        surfaceContainerHighest: Color(hex: "27354c"),
        surfaceVariant: Color(hex: "27354c"),
        surfaceBright: Color(hex: "2c3951"),
        onSurface: Color(hex: "d6e3ff"),
        onSurfaceVariant: Color(hex: "c9c4d5"),
        onBackground: Color(hex: "d6e3ff"),
        primary: Color(hex: "c8bfff"),
        primaryContainer: Color(hex: "6a5acd"),
        onPrimary: Color(hex: "2d128f"),
        onPrimaryContainer: Color(hex: "f0ebff"),
        primaryFixed: Color(hex: "e5deff"),
        secondary: Color(hex: "b9c7e4"),
        secondaryContainer: Color(hex: "3c4962"),
        onSecondary: Color(hex: "233148"),
        tertiary: Color(hex: "e9c400"),
        tertiaryContainer: Color(hex: "c9a900"),
        onTertiary: Color(hex: "3a3000"),
        outline: Color(hex: "928f9e"),
        outlineVariant: Color(hex: "474553"),
        error: Color(hex: "ffb4ab"),
        errorContainer: Color(hex: "93000a")
    )

    var ambientShadow: Color { Color(hex: "6A5ACD").opacity(0.15) }
    var ctaShadow: Color { Color(hex: "6A5ACD").opacity(0.3) }
}
