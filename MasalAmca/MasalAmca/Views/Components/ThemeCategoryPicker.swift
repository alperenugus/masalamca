//
//  ThemeCategoryPicker.swift
//  MasalAmca
//

import SwiftUI

struct ThemeCategoryPicker: View {
    @Binding var selection: Set<StoryBentoTheme>
    var isPremium: Bool
    var showPremiumGate: (() -> Void)?

    @Environment(\.masalThemeManager) private var theme
    @State private var expandedCategories: Set<StoryThemeCategory> = []

    var body: some View {
        let c = theme.colors
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(StoryThemeCategory.allCases) { category in
                categorySection(category, colors: c)
            }
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(_ category: StoryThemeCategory, colors c: DreamscapePalette) -> some View {
        let isExpanded = expandedCategories.contains(category)
        let selectedCount = category.selectedCount(in: selection)

        VStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    if isExpanded {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: category.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(selectedCount > 0 ? c.primary : c.secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.displayTitle)
                            .font(MasalFont.labelMedium())
                            .fontWeight(.bold)
                            .foregroundStyle(c.onSurface)
                        if selectedCount > 0 {
                            Text("\(selectedCount) seçili")
                                .font(MasalFont.labelSmall())
                                .foregroundStyle(c.primary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(c.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(c.surfaceContainerLow)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                themeGrid(for: category, colors: c)
                    .padding(.top, DesignTokens.Spacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Theme Grid (expanded body)

    private func themeGrid(for category: StoryThemeCategory, colors c: DreamscapePalette) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            selectAllRow(for: category, colors: c)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                ForEach(category.themes) { tile in
                    themeChip(tile, colors: c)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
    }

    // MARK: - Select All / Remove All

    private func selectAllRow(for category: StoryThemeCategory, colors c: DreamscapePalette) -> some View {
        let selectableThemes = isPremium ? category.themes : category.freeThemes()
        let allSelected = !selectableThemes.isEmpty && selectableThemes.allSatisfy { selection.contains($0) }

        return HStack {
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if allSelected {
                    let removing = Set(selectableThemes)
                    let remaining = selection.subtracting(removing)
                    if remaining.isEmpty {
                        selection = Set([StoryBentoTheme.adventure])
                    } else {
                        selection = remaining
                    }
                } else {
                    selection = selection.union(selectableThemes)
                }
            } label: {
                Text(allSelected ? "Tümünü Kaldır" : "Tümünü Seç")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
    }

    // MARK: - Theme Chip

    private func themeChip(_ tile: StoryBentoTheme, colors c: DreamscapePalette) -> some View {
        let on = selection.contains(tile)
        let locked = tile.requiresPremium && !isPremium && showPremiumGate != nil

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if locked {
                showPremiumGate?()
                return
            }
            if on {
                if selection.count > 1 {
                    selection.remove(tile)
                }
            } else {
                selection.insert(tile)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: tile.systemImage)
                        .font(.system(size: 22))
                        .foregroundStyle(on ? c.tertiary : c.secondary)
                    HStack(spacing: 3) {
                        Text(tile.displayTitle)
                            .font(MasalFont.labelSmall())
                            .fontWeight(.semibold)
                            .foregroundStyle(on ? c.onSurface : c.secondary)
                        if tile.requiresPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(c.tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm + 2)
                if on {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(c.primary)
                        .padding(6)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(on ? c.surfaceContainerHigh : c.surfaceContainerLow.opacity(0.6))
            )
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .strokeBorder(on ? c.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .opacity(on ? 1 : (locked ? 0.5 : 0.7))
    }
}
