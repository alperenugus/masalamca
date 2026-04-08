//
//  OnboardingView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager

    @Bindable var subscription: SubscriptionManager

    @Binding var isComplete: Bool
    @State private var showCommerceParentGate = false
    @State private var showPaywall = false
    @State private var page: Int = 0

    @State private var childName = ""
    @State private var ageGroup: AgeGroup = .twoToFour
    @State private var selectedBentos: Set<StoryBentoTheme> = [.adventure]
    @State private var profileSaved = false

    private var hasPremiumThemeSelected: Bool {
        selectedBentos.contains { $0.requiresPremium }
    }

    private var nameIsValid: Bool {
        let trimmed = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmed.split(separator: " ").count
        return !trimmed.isEmpty && wordCount <= 2
    }

    var body: some View {
        let c = theme.colors
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                page1Welcome.tag(0)
                page2Themes.tag(1)
                page3Comparison.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: page)
            .onChange(of: page) { _, newPage in
                if !nameIsValid && newPage > 0 {
                    page = 0
                }
            }

            dotIndicator
                .padding(.bottom, 24)
        }
        .background(c.surface.ignoresSafeArea())
        .sheet(isPresented: $showCommerceParentGate) {
            ParentalGateSheet(kind: .commerce) {
                showPaywall = true
            }
            .masalThemeManager(theme)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription) {
                showPaywall = false
                if subscription.isPremium {
                    completeOnboarding()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Page 1: Welcome + Child Info

    private var page1Welcome: some View {
        let c = theme.colors
        return ScrollView {
            VStack(spacing: DesignTokens.Spacing.xxl) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(c.primary.opacity(0.2))
                            .frame(width: 220, height: 220)
                            .blur(radius: 40)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(c.primary)
                    }
                    Text("Masal Amca'ya Hoş Geldin")
                        .font(MasalFont.headlineMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.primaryFixed)
                    Text("Birlikte sihirli bir uyku yolculuğuna çıkmaya hazır mısın?")
                        .font(MasalFont.bodyLarge())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, DesignTokens.Spacing.xl)

                VStack(spacing: DesignTokens.Spacing.xl) {
                    InputField(title: "Çocuğun İsmi", text: $childName, placeholder: "Küçük kahramanın adı ne?")
                        .onChange(of: childName) { _, newValue in
                            let words = newValue.split(separator: " ", omittingEmptySubsequences: false)
                            if words.count > 2 {
                                childName = words.prefix(2).joined(separator: " ")
                            }
                            if childName.count > 30 {
                                childName = String(childName.prefix(30))
                            }
                        }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Yaş")
                            .font(MasalFont.bodyMedium())
                            .fontWeight(.semibold)
                            .foregroundStyle(c.secondary)
                        HStack(spacing: 8) {
                            ForEach(AgeGroup.allCases, id: \.self) { g in
                                Button {
                                    ageGroup = g
                                } label: {
                                    Text(g.displayName)
                                        .font(MasalFont.bodyMedium())
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                                                .fill(ageGroup == g ? c.surfaceContainerHigh : Color.clear)
                                        )
                                        .foregroundStyle(ageGroup == g ? c.primary : c.outline)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                        .background(c.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                GradientButton("Devam Et") {
                    withAnimation { page = 1 }
                }
                .disabled(!nameIsValid)
                .opacity(nameIsValid ? 1 : 0.45)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Page 2: Theme Selection

    private var page2Themes: some View {
        let c = theme.colors
        return ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(c.primary)
                        .padding(.top, DesignTokens.Spacing.xl)
                    Text("Hangi masallar ilgisini çeker?")
                        .font(MasalFont.headlineMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.onSurface)
                    Text("İstediğin kadarını seç; her masalda seçtiklerinden biri rastgele kullanılır.")
                        .font(MasalFont.bodyMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.secondary)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                    ForEach(StoryBentoTheme.allCases) { tile in
                        let on = selectedBentos.contains(tile)
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if on {
                                if selectedBentos.count > 1 {
                                    selectedBentos = selectedBentos.subtracting([tile])
                                }
                            } else {
                                selectedBentos = selectedBentos.union([tile])
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: DesignTokens.Spacing.sm) {
                                    Image(systemName: tile.systemImage)
                                        .font(.system(size: 26))
                                        .foregroundStyle(on ? c.tertiary : c.secondary)
                                    HStack(spacing: 4) {
                                        Text(tile.displayTitle)
                                            .font(MasalFont.labelMedium())
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(on ? c.onSurface : c.secondary)
                                        if tile.requiresPremium {
                                            Image(systemName: "crown.fill")
                                                .font(.caption2)
                                                .foregroundStyle(c.tertiary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.md)
                                if on {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(c.primary)
                                        .padding(8)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                    .fill(on ? c.surfaceContainerHigh : c.surfaceContainerLow)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                    .strokeBorder(on ? c.primary.opacity(0.35) : Color.clear, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .opacity(on ? 1 : 0.72)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                GradientButton("Devam Et") {
                    withAnimation { page = 2 }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Page 3: Free vs Premium Comparison

    private var page3Comparison: some View {
        let c = theme.colors
        return ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(c.primary)
                        .padding(.top, DesignTokens.Spacing.xl)
                    Text("Hazır mısın?")
                        .font(MasalFont.headlineMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.onSurface)
                    Text("Masal Amca ile her gece yeni bir macera seni bekliyor.")
                        .font(MasalFont.bodyMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(c.secondary)
                        .padding(.horizontal)
                }

                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    comparisonCard(
                        title: "Ücretsiz",
                        icon: "gift",
                        features: [
                            "2 masal (toplam)",
                            "3 beyaz gürültü",
                            "2 anlatıcı ses",
                            "6 hikaye teması"
                        ],
                        isPremium: false
                    )

                    comparisonCard(
                        title: "Premium",
                        icon: "crown.fill",
                        features: [
                            "Günde 2 yeni masal",
                            "6 beyaz gürültü",
                            "8 anlatıcı ses",
                            "15 hikaye teması",
                            "Arka plan müziği"
                        ],
                        isPremium: true
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                VStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        saveProfile()
                        showCommerceParentGate = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.body.weight(.semibold))
                            Text("3 Gün Ücretsiz Dene")
                                .font(MasalFont.titleMedium())
                        }
                        .foregroundStyle(c.onPrimaryContainer)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [c.primaryContainer, c.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                        .shadow(color: c.ctaShadow, radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    GhostButton(title: "Ücretsiz Başla") {
                        saveProfile()
                        if hasPremiumThemeSelected {
                            stripPremiumThemesAndResave()
                        }
                        completeOnboarding()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func comparisonCard(title: String, icon: String, features: [String], isPremium: Bool) -> some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isPremium ? c.tertiary : c.primary)
                Text(title)
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isPremium ? c.tertiary : c.primary)
                            .frame(width: 16)
                        Text(feature)
                            .font(MasalFont.labelMedium())
                            .foregroundStyle(c.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(isPremium ? c.tertiary.opacity(0.08) : c.surfaceContainerHigh)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(isPremium ? c.tertiary.opacity(0.25) : c.outlineVariant.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Dot Indicator

    private var dotIndicator: some View {
        let c = theme.colors
        return HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == page ? c.primary : c.outlineVariant.opacity(0.35))
                    .frame(width: i == page ? 10 : 8, height: i == page ? 10 : 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
            }
        }
    }

    // MARK: - Actions

    private func stripPremiumThemesAndResave() {
        selectedBentos = selectedBentos.filter { !$0.requiresPremium }
        if selectedBentos.isEmpty { selectedBentos = [.adventure] }
        let profiles = (try? modelContext.fetch(FetchDescriptor<ChildProfile>())) ?? []
        if let profile = profiles.last {
            let bentos = StoryBentoTheme.normalizedSelection(Array(selectedBentos))
            profile.bentoThemeRaw = StoryBentoTheme.serializeForStorage(bentos)
            profile.themes = StoryBentoTheme.mergedProfileThemes(bentos)
            try? modelContext.save()
        }
    }

    private func completeOnboarding() {
        isComplete = true
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
    }

    private func saveProfile() {
        let bentos = StoryBentoTheme.normalizedSelection(Array(selectedBentos))
        let themes = StoryBentoTheme.mergedProfileThemes(bentos)
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)

        if profileSaved {
            let profiles = (try? modelContext.fetch(FetchDescriptor<ChildProfile>())) ?? []
            if let existing = profiles.last {
                existing.name = trimmedName
                existing.ageGroup = ageGroup
                existing.themes = themes.isEmpty ? [.fairyTale] : themes
                existing.bentoThemeRaw = StoryBentoTheme.serializeForStorage(bentos)
                try? modelContext.save()
            }
            return
        }

        let profile = ChildProfile(
            name: trimmedName,
            ageGroup: ageGroup,
            themes: themes.isEmpty ? [.fairyTale] : themes
        )
        profile.bentoThemeRaw = StoryBentoTheme.serializeForStorage(bentos)
        profile.storyLengthRaw = StoryLengthPreference.short.rawValue
        modelContext.insert(profile)
        profileManager.switchTo(profile)
        try? modelContext.save()
        profileSaved = true
    }
}
