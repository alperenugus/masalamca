//
//  SubscriptionManager.swift
//  MasalAmca
//

import Foundation
import StoreKit
import Observation
import SwiftData

@MainActor
@Observable
final class SubscriptionManager {
    #if DEBUG
    /// Ayarlar → Geliştirici: yerel test için StoreKit olmadan premium kapıları.
    static let mockPremiumUserDefaultsKey = "masal_debug_mock_premium"
    #endif

    /// Ücretsiz: uygulama ömrünce en fazla bu kadar üretim; sonra paywall.
    static let freeTierLifetimeGenerationLimit = 2

    /// Premium: yerel gün başına en fazla bu kadar yeni masal (SwiftData’daki bugünkü kayıt sayısı ile kontrol).
    static let premiumDailyGenerationLimit = 2

    var products: [Product] = []
    var isPremium: Bool = false
    /// Toplam üretim sayısı; CloudKit (`AppSyncState`) ile eşlenir — ücretsiz kota buradan.
    var storiesGeneratedCount: Int = 0

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refreshEntitlements() }
    }

    func hydrateStoryCountFromCloud(_ count: Int) {
        storiesGeneratedCount = count
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                AppConfiguration.ProductID.monthly,
                AppConfiguration.ProductID.yearly
            ])
        } catch {
            products = []
        }
    }

    func refreshEntitlements() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: Self.mockPremiumUserDefaultsKey) {
            isPremium = true
            return
        }
        #endif
        var premium = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            if t.productID == AppConfiguration.ProductID.monthly ||
                t.productID == AppConfiguration.ProductID.yearly {
                premium = true
            }
        }
        isPremium = premium
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            guard case .verified(let t) = update else { continue }
            await t.finish()
            await refreshEntitlements()
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let t) = verification else { return }
            await t.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// Ücretsiz: `storiesGeneratedCount` (CloudKit) ömür boyu kota.
    /// Premium: `storiesCreatedTodayFromStore` bugün (yerel takvim) oluşturulmuş masal sayısı — günlük kota.
    func canGenerateStory(storiesCreatedTodayFromStore: Int = 0) -> Bool {
        if isPremium {
            return storiesCreatedTodayFromStore < Self.premiumDailyGenerationLimit
        }
        return storiesGeneratedCount < Self.freeTierLifetimeGenerationLimit
    }

    func registerStoryGenerated(modelContext: ModelContext) {
        storiesGeneratedCount += 1
        AppSyncPersistence.persistStoryGenerationCount(storiesGeneratedCount, modelContext: modelContext)
    }

    func canUseSound(_ sound: MixerSound) -> Bool {
        isPremium || MixerSound.freeTier.contains(sound)
    }
}

#if DEBUG
extension SubscriptionManager {
    /// Reset gating state for unit tests (avoids flaking on live StoreKit entitlements).
    func applyTestingState(premium: Bool, storiesGenerated: Int) {
        isPremium = premium
        storiesGeneratedCount = storiesGenerated
    }

    var mockPremiumForLocalTesting: Bool {
        get { UserDefaults.standard.bool(forKey: Self.mockPremiumUserDefaultsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.mockPremiumUserDefaultsKey)
            if newValue {
                isPremium = true
            } else {
                isPremium = false
                Task { await refreshEntitlements() }
            }
        }
    }
}
#endif
