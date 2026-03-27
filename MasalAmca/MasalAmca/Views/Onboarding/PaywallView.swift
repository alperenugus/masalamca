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

    var onContinue: () -> Void

    @State private var selectedProduct: Product?

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
                    }
                    .padding(.horizontal)

                    VStack(spacing: DesignTokens.Spacing.md) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(c.tertiary)
                            Text("Premium Deneyim")
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

                        Text("Sınırsız Hayal Gücü")
                            .font(MasalFont.headlineMedium())
                            .foregroundStyle(c.onSurface)
                        Text("Masal Amca'nın tüm hazinelerini keşfet")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary)
                    }

                    VStack(spacing: DesignTokens.Spacing.md) {
                        featureRow(icon: "book.pages.fill", title: "Sınırsız Hikaye", subtitle: "Her gün yeni bir macera")
                        featureRow(icon: "waveform", title: "Premium AI Sesler", subtitle: "En doğal ve rahatlatıcı tonlar")
                        featureRow(icon: "icloud.fill", title: "CloudKit Senkronizasyon", subtitle: "Tüm cihazlarında kaldığın yerden devam et")
                    }
                    .padding(.horizontal)

                    if subscription.products.isEmpty {
                        ProgressView()
                            .tint(c.primary)
                            .padding()
                    } else {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            ForEach(subscription.products, id: \.id) { p in
                                productCard(p)
                            }
                        }
                        .padding(.horizontal)
                    }

                    GradientButton("Ücretsiz Denemeyi Başlat", subtitle: "3 Gün Ücretsiz Deneme") {
                        Task {
                            if let p = selectedProduct ?? subscription.products.first {
                                try? await subscription.purchase(p)
                            }
                            onContinue()
                            dismiss()
                        }
                    }
                    .padding(.horizontal)

                    Text("Deneme süresi sonunda iptal edilmezse otomatik yenilenir. Kullanım Koşulları ve Gizlilik Politikası")
                        .font(MasalFont.labelSmall())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.outline)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(c.surface.ignoresSafeArea())
            .task {
                await subscription.loadProducts()
                selectedProduct = subscription.products.first { $0.id == AppConfiguration.ProductID.yearly }
                    ?? subscription.products.first
            }
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
                    Text("EN POPÜLER")
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
