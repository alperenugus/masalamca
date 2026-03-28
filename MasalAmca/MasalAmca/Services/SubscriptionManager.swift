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

    /// Ücretsiz: takvim günü başına en fazla 2 üretim (premium’da kullanılmaz).
    private static let freeDailyDateKey = "masal_free_daily_gen_date"
    private static let freeDailyCountKey = "masal_free_daily_gen_count"

    var products: [Product] = []
    var isPremium: Bool = false
    /// Ömür boyu / analitik için CloudKit (`AppSyncState`); günlük kota ayrı tutulur.
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

    private func startOfToday() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Bugün (yerel takvim) ücretsiz kullanıcı kaç masal üretti — yalnızca UserDefaults.
    func freeStoriesGeneratedTodayCount() -> Int {
        let today = startOfToday().timeIntervalSince1970
        let stored = UserDefaults.standard.double(forKey: Self.freeDailyDateKey)
        guard stored == today else { return 0 }
        return UserDefaults.standard.integer(forKey: Self.freeDailyCountKey)
    }

    /// Ücretsiz günlük kota: hem yerel sayaç hem SwiftData’daki bugünkü masallar.
    /// Uygulama silinip CloudKit ile masallar geri gelince UserDefaults sıfırlanır; mağaza sayısı kotayı korur.
    func canGenerateStory(storiesCreatedTodayFromStore: Int = 0) -> Bool {
        if isPremium { return true }
        let fromDefaults = freeStoriesGeneratedTodayCount()
        let usedToday = max(fromDefaults, storiesCreatedTodayFromStore)
        return usedToday < 2
    }

    func registerStoryGenerated(modelContext: ModelContext) {
        storiesGeneratedCount += 1
        AppSyncPersistence.persistStoryGenerationCount(storiesGeneratedCount, modelContext: modelContext)
        guard !isPremium else { return }
        let today = startOfToday().timeIntervalSince1970
        let stored = UserDefaults.standard.double(forKey: Self.freeDailyDateKey)
        if stored != today {
            UserDefaults.standard.set(today, forKey: Self.freeDailyDateKey)
            UserDefaults.standard.set(1, forKey: Self.freeDailyCountKey)
        } else {
            let c = UserDefaults.standard.integer(forKey: Self.freeDailyCountKey)
            UserDefaults.standard.set(c + 1, forKey: Self.freeDailyCountKey)
        }
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
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        UserDefaults.standard.set(today, forKey: Self.freeDailyDateKey)
        if premium {
            UserDefaults.standard.set(0, forKey: Self.freeDailyCountKey)
        } else {
            UserDefaults.standard.set(min(storiesGenerated, 2), forKey: Self.freeDailyCountKey)
        }
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
