//
//  BundledNarrationResources.swift
//  MasalAmca
//

import Foundation

/// Yerel örnek sesler — yalnızca **Masal Ayarları → Anlatıcı** önizlemesi için (masal üretimi API TTS kullanır).
enum BundledNarrationResources {
    private static let searchSubdirectories = ["Resources/Audio", "Audio"]

    static func audioFileURL(for narrator: NarratorChoice) -> URL? {
        // Convention: each narrator preview is bundled as `{voice_id}.mp3`.
        let voiceID = narrator.resolvedVoiceID() ?? NarratorChoice.defaultFemaleVoiceID()
        if voiceID != "default" {
            for sub in searchSubdirectories {
                if let u = Bundle.main.url(forResource: voiceID, withExtension: "mp3", subdirectory: sub) {
                    return u
                }
            }
            if let u = Bundle.main.url(forResource: voiceID, withExtension: "mp3") {
                return u
            }
        }
        return nil
    }
}
