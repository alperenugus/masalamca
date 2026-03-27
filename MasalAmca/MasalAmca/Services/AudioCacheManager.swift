//
//  AudioCacheManager.swift
//  MasalAmca
//

import Foundation

enum AudioCacheManager {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    static func fileURL(forStoryID id: UUID, extension ext: String = "mp3") -> URL {
        documentsDirectory().appendingPathComponent("story_\(id.uuidString).\(ext)")
    }

    static func save(data: Data, storyID: UUID, extension ext: String = "mp3") throws -> String {
        let url = fileURL(forStoryID: storyID, extension: ext)
        try data.write(to: url, options: .atomic)
        return url.lastPathComponent
    }

    static func removeFile(named fileName: String) throws {
        let url = documentsDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
