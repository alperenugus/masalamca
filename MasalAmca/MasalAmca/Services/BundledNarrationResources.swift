//
//  BundledNarrationResources.swift
//  MasalAmca
//

import Foundation

/// Yerel örnek sesler — yalnızca **Masal Ayarları → Anlatıcı** önizlemesi için (masal üretimi API TTS kullanır).
enum BundledNarrationResources {
    private static let searchSubdirectories = ["Resources/Audio", "Audio"]

    static func audioFileURL(for narrator: NarratorChoice) -> URL? {
        let baseName: String
        switch narrator {
        case .yumuşakBulut, .neşeliPeri:
            baseName = "female_voice"
        case .bilgeDede:
            baseName = "male_voice"
        }
        for sub in searchSubdirectories {
            if let u = Bundle.main.url(forResource: baseName, withExtension: "mp3", subdirectory: sub) {
                return u
            }
        }
        return Bundle.main.url(forResource: baseName, withExtension: "mp3")
    }
}
