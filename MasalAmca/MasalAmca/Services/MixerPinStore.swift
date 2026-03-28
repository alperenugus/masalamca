//
//  MixerPinStore.swift
//  MasalAmca
//

import Foundation
import Observation

@MainActor
@Observable
final class MixerPinStore {
    private static let storageKey = "masal_mixer_pinned_sounds_v1"

    private(set) var pinnedRawValues: [String] = []

    init() {
        load()
    }

    var pinnedSounds: [MixerSound] {
        pinnedRawValues.compactMap { MixerSound(rawValue: $0) }
    }

    func isPinned(_ sound: MixerSound) -> Bool {
        pinnedRawValues.contains(sound.rawValue)
    }

    func togglePin(_ sound: MixerSound) {
        if let i = pinnedRawValues.firstIndex(of: sound.rawValue) {
            pinnedRawValues.remove(at: i)
        } else {
            pinnedRawValues.append(sound.rawValue)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else {
            pinnedRawValues = []
            return
        }
        pinnedRawValues = decoded.filter { MixerSound(rawValue: $0) != nil }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(pinnedRawValues) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
