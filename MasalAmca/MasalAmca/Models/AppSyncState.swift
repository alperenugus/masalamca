//
//  AppSyncState.swift
//  MasalAmca
//
//  Tek kayıt — CloudKit ile cihazlar arası: toplam üretim sayısı (ücretsiz deneme sınırı), aktif çocuk.
//

import Foundation
import SwiftData

@Model
final class AppSyncState {
    /// Sabit anahtar; tek satır kullanılır.
    @Attribute(.unique) var singletonKey: String
    var storiesGeneratedCount: Int
    var activeProfileUUIDString: String?

    init(
        singletonKey: String = "app",
        storiesGeneratedCount: Int = 0,
        activeProfileUUIDString: String? = nil
    ) {
        self.singletonKey = singletonKey
        self.storiesGeneratedCount = storiesGeneratedCount
        self.activeProfileUUIDString = activeProfileUUIDString
    }
}
