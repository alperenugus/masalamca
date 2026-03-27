//
//  SubscriptionManager.swift
//  MasalAmca
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionManager {
    private enum Keys {
        static let storiesGenerated = "masal_stories_generated_count"
    }

    var products: [Product] = []
    var isPremium: Bool = false
    var storiesGeneratedCount: Int {
        didSet { UserDefaults.standard.set(storiesGeneratedCount, forKey: Keys.storiesGenerated) }
    }

    private var updatesTask: Task<Void, Never>?

    init() {
        storiesGeneratedCount = UserDefaults.standard.integer(forKey: Keys.storiesGenerated)
        updatesTask = Task { await listenForTransactions() }
        Task { await refreshEntitlements() }
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

    func canGenerateStory() -> Bool {
        isPremium || storiesGeneratedCount < 2
    }

    func registerStoryGenerated() {
        storiesGeneratedCount += 1
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
}
#endif
