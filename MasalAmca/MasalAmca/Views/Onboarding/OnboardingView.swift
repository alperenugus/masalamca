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
    @State private var showPaywall = false

    @State private var childName = ""
    @State private var ageGroup: AgeGroup = .twoToFour
    @State private var selectedBento: StoryBentoTheme = .adventure

    var body: some View {
        let c = theme.colors
        ScrollView {
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

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Hikaye Teması")
                            .font(MasalFont.bodyMedium())
                            .fontWeight(.semibold)
                            .foregroundStyle(c.secondary)
                        Text("Masal Ayarları ile aynı temalar; masallar bu atmosfere göre şekillenir.")
                            .font(MasalFont.labelMedium())
                            .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                            ForEach(StoryBentoTheme.allCases) { tile in
                                let on = selectedBento == tile
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedBento = tile
                                } label: {
                                    VStack(spacing: DesignTokens.Spacing.sm) {
                                        Image(systemName: tile.systemImage)
                                            .font(.system(size: 26))
                                            .foregroundStyle(on ? c.tertiary : c.secondary)
                                        Text(tile.displayTitle)
                                            .font(MasalFont.labelMedium())
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(on ? c.onSurface : c.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.md)
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
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                GradientButton("Devam Et") {
                    saveProfile()
                    showPaywall = true
                }
                .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 48)
            }
        }
        .background(c.surface.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription) {
                showPaywall = false
                isComplete = true
                UserDefaults.standard.set(true, forKey: "onboarding_complete")
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func saveProfile() {
        let bento = selectedBento
        let themes = bento.asProfileThemes()
        let profile = ChildProfile(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            ageGroup: ageGroup,
            themes: themes.isEmpty ? [.fairyTale] : themes
        )
        profile.bentoThemeRaw = bento.rawValue
        modelContext.insert(profile)
        profileManager.switchTo(profile)
        try? modelContext.save()
    }
}
