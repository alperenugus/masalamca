//
//  ThemeManager.swift
//  MasalAmca
//

import SwiftUI

@Observable
final class ThemeManager {
    var currentMode: ThemeMode {
        didSet { UserDefaults.standard.set(currentMode.rawValue, forKey: Self.modeKey) }
    }

    var colors: DreamscapePalette {
        switch currentMode {
        case .midnight: .midnight
        }
    }

    private static let modeKey = "masal_theme_mode"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.modeKey),
           let mode = ThemeMode(rawValue: raw) {
            currentMode = mode
        } else {
            currentMode = .midnight
        }
    }
}

private struct MasalThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    /// Avoids clash with SwiftUI `Environment` overloads in newer SDKs.
    var masalThemeManager: ThemeManager {
        get { self[MasalThemeManagerKey.self] }
        set { self[MasalThemeManagerKey.self] = newValue }
    }
}

extension View {
    func masalThemeManager(_ manager: ThemeManager) -> some View {
        environment(\.masalThemeManager, manager)
    }
}
