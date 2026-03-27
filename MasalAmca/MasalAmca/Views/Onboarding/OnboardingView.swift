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
    @State private var selectedThemes: Set<StoryTheme> = []

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

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Favori Temalar")
                            .font(MasalFont.bodyMedium())
                            .fontWeight(.semibold)
                            .foregroundStyle(c.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(StoryTheme.allCases, id: \.self) { t in
                                GenreChip(
                                    title: t.displayName,
                                    systemImageName: t.iconSystemName,
                                    isSelected: selectedThemes.contains(t)
                                ) {
                                    if selectedThemes.contains(t) { selectedThemes.remove(t) }
                                    else { selectedThemes.insert(t) }
                                }
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
        let themes = Array(selectedThemes).sorted { $0.rawValue < $1.rawValue }
        let profile = ChildProfile(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            ageGroup: ageGroup,
            themes: themes.isEmpty ? [.fairyTale] : themes
        )
        modelContext.insert(profile)
        profileManager.switchTo(profile)
        try? modelContext.save()
    }
}

/// Simple wrapping flow for chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let height = y + rowHeight
        return (CGSize(width: maxWidth, height: height), positions)
    }
}
