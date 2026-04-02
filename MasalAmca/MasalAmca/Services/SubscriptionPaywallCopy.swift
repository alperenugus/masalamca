//
//  SubscriptionPaywallCopy.swift
//  MasalAmca
//

import Foundation
import StoreKit

/// Metinler App Store Connect’teki abonelik ve tanıtım teklifi ile uyumlu olmalı; mümkün olduğunca `Product` üzerinden türetilir.
enum SubscriptionPaywallCopy {
    static func primaryButtonTitle(for product: Product?) -> String {
        guard let product, let intro = product.subscription?.introductoryOffer else {
            return "Aboneliği başlat"
        }
        switch intro.paymentMode {
        case .freeTrial:
            return "Ücretsiz denemeyi başlat"
        case .payAsYouGo, .payUpFront:
            return "Özel teklifle başlat"
        default:
            return "Aboneliği başlat"
        }
    }

    static func primaryButtonSubtitle(for product: Product?) -> String? {
        guard let product, let intro = product.subscription?.introductoryOffer else { return nil }
        let period = formatPeriod(intro.period)
        switch intro.paymentMode {
        case .freeTrial:
            return "\(period) hediye"
        case .payUpFront:
            return "\(intro.displayPrice) / \(period)"
        case .payAsYouGo:
            return intro.displayPrice
        default:
            return nil
        }
    }

    static func legalFooter(for product: Product?) -> String {
        if let product, product.subscription?.introductoryOffer != nil {
            return "Tanıtım süresi bitince iptal etmezsen abonelik dönem sonunda yenilenir. Aboneliği istediğin an Ayarlar’dan yönetebilirsin."
        }
        return "Abonelik, iptal etmedikçe dönem sonunda yenilenir. Aboneliği istediğin an Ayarlar’dan yönetebilirsin."
    }

    private static func formatPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let v = period.value
        switch period.unit {
        case .day: return v == 1 ? "1 gün" : "\(v) gün"
        case .week: return v == 1 ? "1 hafta" : "\(v) hafta"
        case .month: return v == 1 ? "1 ay" : "\(v) ay"
        case .year: return v == 1 ? "1 yıl" : "\(v) yıl"
        @unknown default: return "\(v) dönem"
        }
    }
}

/// Required for App Store Guideline 3.1.2(c): functional Terms (EULA) + Privacy links in the subscription UI.
enum AppLegalURLs {
    /// Apple’s standard EULA — use when you do not provide a custom EULA in App Store Connect.
    private static let appleStandardEULA =
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Canonical policy (plain text). Keep in sync with `docs/MasalAmca.txt` in the masalamca repo and `PrivacyPolicies` repo.
    private static let defaultPrivacyPolicy =
        URL(string: "https://github.com/alperenugus/PrivacyPolicies/blob/main/MasalAmca.txt")!

    static var terms: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "TermsOfUseURL") as? String,
           let u = URL(string: s), !s.isEmpty {
            return u
        }
        return appleStandardEULA
    }

    static var privacy: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
           let u = URL(string: s), !s.isEmpty {
            return u
        }
        return defaultPrivacyPolicy
    }
}
