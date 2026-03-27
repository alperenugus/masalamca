//
//  AppConfiguration.swift
//  MasalAmca
//

import Foundation

enum AppConfiguration {
    /// Set `ProxyBaseURL` string in Info.plist (e.g. https://your-worker.workers.dev)
    static var proxyBaseURL: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "ProxyBaseURL") as? String,
              let url = URL(string: s), !s.isEmpty else { return nil }
        return url
    }

    static var proxyAuthToken: String {
        (Bundle.main.object(forInfoDictionaryKey: "ProxyAuthToken") as? String) ?? ""
    }

    enum ProductID {
        static let monthly = "alperenugus.MasalAmca.premium.monthly"
        static let yearly = "alperenugus.MasalAmca.premium.yearly"
    }
}
