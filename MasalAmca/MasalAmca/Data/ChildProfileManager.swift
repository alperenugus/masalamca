//
//  ChildProfileManager.swift
//  MasalAmca
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class ChildProfileManager {
    private enum Keys {
        static let activeProfile = "active_profile_id"
    }

    var activeProfileID: UUID? {
        didSet {
            if let id = activeProfileID {
                UserDefaults.standard.set(id.uuidString, forKey: Keys.activeProfile)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeProfile)
            }
        }
    }

    init() {
        if let s = UserDefaults.standard.string(forKey: Keys.activeProfile),
           let id = UUID(uuidString: s) {
            activeProfileID = id
        }
    }

    func activeProfile(from profiles: [ChildProfile]) -> ChildProfile? {
        guard !profiles.isEmpty else { return nil }
        if let id = activeProfileID, let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        let first = profiles.first!
        activeProfileID = first.id
        return first
    }

    func switchTo(_ profile: ChildProfile) {
        activeProfileID = profile.id
    }
}

private struct MasalChildProfileManagerKey: EnvironmentKey {
    static let defaultValue = ChildProfileManager()
}

extension EnvironmentValues {
    /// Custom key avoids clash with SwiftUI `Environment` Observable overloads.
    var masalChildProfileManager: ChildProfileManager {
        get { self[MasalChildProfileManagerKey.self] }
        set { self[MasalChildProfileManagerKey.self] = newValue }
    }
}

extension View {
    func masalChildProfileManager(_ manager: ChildProfileManager) -> some View {
        environment(\.masalChildProfileManager, manager)
    }
}
