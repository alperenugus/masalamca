//
//  BundledNarrationResources.swift
//  MasalAmca
//

import Foundation

/// Yerel örnek sesler — yalnızca **Masal Ayarları → Anlatıcı** önizlemesi için (masal üretimi API TTS kullanır).
enum BundledNarrationResources {
    private static let searchSubdirectories = ["Resources/Audio", "Audio"]

    static func audioFileURL(for narrator: NarratorChoice) -> URL? {
        let base = narrator.voiceName
        for ext in ["wav", "mp3"] {
            for sub in searchSubdirectories {
                if let u = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: sub) {
                    return u
                }
            }
            if let u = Bundle.main.url(forResource: base, withExtension: ext) {
                return u
            }
        }
        return nil
    }
}
