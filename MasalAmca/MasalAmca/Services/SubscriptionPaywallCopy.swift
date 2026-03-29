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

enum AppLegalURLs {
    static var terms: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "TermsOfUseURL") as? String,
              let u = URL(string: s), !s.isEmpty else { return nil }
        return u
    }

    static var privacy: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
              let u = URL(string: s), !s.isEmpty else { return nil }
        return u
    }
}
