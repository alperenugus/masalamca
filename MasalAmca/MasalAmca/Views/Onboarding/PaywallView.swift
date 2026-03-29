//
//  PaywallView.swift
//  MasalAmca
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscription: SubscriptionManager

    /// Paywall kapanınca (x ile, başarılı satın alma sonrası veya sistem dismiss): ebeveyn görünümü state güncellesin.
    var onContinue: () -> Void

    @State private var selectedProduct: Product?
    @State private var isLoadingProducts = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var activeAlert: PaywallAlert?

    private var chosenProduct: Product? {
        selectedProduct ?? subscription.products.first
    }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                            onContinue()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(c.onSurface.opacity(0.55))
                                .padding(10)
                                .background(c.surfaceContainer.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Kapat")
                    }
                    .padding(.horizontal)

                    if subscription.isPremium {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(c.tertiary)
                            Text("Premium aktif")
                                .font(MasalFont.headlineMedium())
                                .foregroundStyle(c.onSurface)
                            Text("Tüm premium özellikler hesabında açık.")
                                .font(MasalFont.bodyMedium())
                                .foregroundStyle(c.secondary)
                                .multilineTextAlignment(.center)
                            Button("Tamam") {
                                dismiss()
                                onContinue()
                            }
                            .font(MasalFont.titleMedium())
                            .foregroundStyle(c.primary)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.xl)
                    } else {
                        paywallContent
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(c.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if !subscription.isPremium {
                        Button {
                            Task { await restoreTapped() }
                        } label: {
                            if isRestoring {
                                ProgressView()
                            } else {
                                Text("Satın Alımları Geri Yükle")
                                    .font(MasalFont.labelMedium())
                            }
                        }
                        .disabled(isRestoring || isPurchasing)
                    }
                }
            }
            .task {
                isLoadingProducts = true
                await subscription.loadProducts()
                await subscription.refreshEntitlements()
                isLoadingProducts = false
                if selectedProduct == nil {
                    selectedProduct = subscription.products.first { $0.id == AppConfiguration.ProductID.yearly }
                        ?? subscription.products.first
                }
            }
            .onChange(of: subscription.products) { _, products in
                if selectedProduct == nil, let first = products.first {
                    selectedProduct = products.first { $0.id == AppConfiguration.ProductID.yearly } ?? first
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .message(_, let title, let message):
                    Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("Tamam")))
                case .pending:
                    Alert(
                        title: Text("Onay bekleniyor"),
                        message: Text("Satın alma bir ebeveyn veya hesap ayarı onayı bekliyor olabilir. Durum netleşince bildirim alırsın."),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var paywallContent: some View {
        let c = theme.colors
        VStack(spacing: DesignTokens.Spacing.xl) {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(c.tertiary)
                    Text("Daha yumuşak geceler")
                        .font(MasalFont.labelMedium())
                        .foregroundStyle(c.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(c.tertiary.opacity(0.12))
                .overlay(
                    Capsule().stroke(c.tertiary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(Capsule())

                Text("Her geceye yeni bir masal")
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onSurface)
                Text("Günde iki yeni masal, tüm sakinleştirici sesler ve cihazlar arası senkron seninle")
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.secondary)
            }

            VStack(spacing: DesignTokens.Spacing.md) {
                featureRow(icon: "book.pages.fill", title: "Günde iki yeni masal", subtitle: "Her geceye taze bir hikâye bırak")
                featureRow(icon: "waveform", title: "Yumuşak AI sesleri", subtitle: "Daha doğal, sakin anlatım tonları")
                featureRow(icon: "icloud.fill", title: "Senkron", subtitle: "Tüm cihazlarında kaldığın yerden devam")
            }
            .padding(.horizontal)

            if isLoadingProducts {
                ProgressView()
                    .tint(c.primary)
                    .padding()
            } else if subscription.products.isEmpty {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Abonelik seçenekleri yüklenemedi. İnternet bağlantını kontrol edip yeniden dene.")
                        .font(MasalFont.bodyMedium())
                        .foregroundStyle(c.secondary)
                        .multilineTextAlignment(.center)
                    Button("Yeniden dene") {
                        Task {
                            isLoadingProducts = true
                            await subscription.loadProducts()
                            await subscription.refreshEntitlements()
                            isLoadingProducts = false
                        }
                    }
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.primary)
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(subscription.products, id: \.id) { p in
                        productCard(p)
                    }
                }
                .padding(.horizontal)
            }

            if isPurchasing {
                ProgressView()
                    .tint(c.primary)
            }

            let primaryTitle = SubscriptionPaywallCopy.primaryButtonTitle(for: chosenProduct)
            let primarySubtitle = SubscriptionPaywallCopy.primaryButtonSubtitle(for: chosenProduct)
            GradientButton(
                primaryTitle,
                subtitle: primarySubtitle,
                disabled: isPurchasing || chosenProduct == nil || subscription.products.isEmpty
            ) {
                Task { await purchaseTapped() }
            }
            .padding(.horizontal)

            legalFooterBlock

            if let terms = AppLegalURLs.terms, let privacy = AppLegalURLs.privacy {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Link("Kullanım koşulları", destination: terms)
                    Text("·")
                    Link("Gizlilik", destination: privacy)
                }
                .font(MasalFont.labelSmall())
                .foregroundStyle(c.primary.opacity(0.9))
            } else {
                Text("Kullanım koşulları ve gizlilik politikası için web sitemize göz at.")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.outline)
            }
        }
    }

    private var legalFooterBlock: some View {
        let c = theme.colors
        return Text(SubscriptionPaywallCopy.legalFooter(for: chosenProduct))
            .font(MasalFont.labelSmall())
            .multilineTextAlignment(.center)
            .foregroundStyle(c.outline)
            .padding(.horizontal, 24)
    }

    private func purchaseTapped() async {
        guard let product = chosenProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        let outcome = await subscription.purchase(product)
        switch outcome {
        case .purchased:
            dismiss()
            onContinue()
        case .userCancelled:
            break
        case .pending:
            activeAlert = .pending
        case .failed(let message):
            activeAlert = .message(UUID(), "Satın alma", message)
        case .unverified:
            activeAlert = .message(
                UUID(),
                "Satın alma",
                "İşlem doğrulanamadı. Bir süre sonra tekrar dene veya destek ile iletişime geç."
            )
        }
    }

    private func restoreTapped() async {
        isRestoring = true
        defer { isRestoring = false }
        await subscription.restore()
        if subscription.isPremium {
            dismiss()
            onContinue()
        } else {
            activeAlert = .message(
                UUID(),
                "Geri yükleme",
                "Aktif abonelik bulunamadı. Apple Kimliğinle daha önce satın aldığın bir abonelik varsa Ayarlar → Apple Kimliği’nden kontrol et."
            )
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        let c = theme.colors
        return HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(c.primary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(c.primary)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MasalFont.bodyMedium())
                    .fontWeight(.bold)
                    .foregroundStyle(c.onSurface)
                Text(subtitle)
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(c.outline)
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(c.surfaceContainer.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private func productCard(_ product: Product) -> some View {
        let c = theme.colors
        let isYearly = product.id == AppConfiguration.ProductID.yearly
        let isSelected = selectedProduct?.id == product.id
        return Button {
            selectedProduct = product
        } label: {
            VStack(spacing: 6) {
                if isYearly {
                    Text("En sevilen")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(c.onPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(c.primaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text(" ").font(.system(size: 8))
                }
                Text(product.id == AppConfiguration.ProductID.monthly ? "Aylık" : "Yıllık")
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(isYearly ? c.primary : c.outline)
                Text(product.displayPrice)
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onSurface)
                Text(product.id == AppConfiguration.ProductID.monthly ? "İptal edilebilir" : "Yıllık ödeme")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(isYearly ? c.primary.opacity(0.7) : c.outline)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(isYearly ? c.primary.opacity(0.12) : c.surfaceContainerLow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(isSelected ? c.primary : c.outlineVariant.opacity(0.35), lineWidth: isYearly ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum PaywallAlert: Identifiable {
    case message(UUID, String, String)
    case pending

    var id: String {
        switch self {
        case .message(let uuid, _, _): uuid.uuidString
        case .pending: "pending"
        }
    }
}
