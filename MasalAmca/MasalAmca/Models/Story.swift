//
//  Story.swift
//  MasalAmca
//

import Foundation
import SwiftData

@Model
final class Story {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var durationSeconds: Int
    var audioFileName: String?
    /// CloudKit senkronu için ses verisi (yerel dosyadan öncelikli yüklenir).
    @Attribute(.externalStorage) var audioBlob: Data?
    var isFavorite: Bool
    var genreRaw: String
    var generationModel: String
    var createdAt: Date

    var profile: ChildProfile?

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        durationSeconds: Int = 0,
        audioFileName: String? = nil,
        audioBlob: Data? = nil,
        isFavorite: Bool = false,
        genre: StoryGenre = .calming,
        generationModel: String = "",
        createdAt: Date = .now,
        profile: ChildProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.durationSeconds = durationSeconds
        self.audioFileName = audioFileName
        self.audioBlob = audioBlob
        self.isFavorite = isFavorite
        self.genreRaw = genre.rawValue
        self.generationModel = generationModel
        self.createdAt = createdAt
        self.profile = profile
    }

    var genre: StoryGenre {
        get { StoryGenre(rawValue: genreRaw) ?? .calming }
        set { genreRaw = newValue.rawValue }
    }
}
