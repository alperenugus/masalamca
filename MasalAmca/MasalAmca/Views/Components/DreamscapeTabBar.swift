//
//  DreamscapeTabBar.swift
//  MasalAmca
//

import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case library
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Ana Sayfa"
        case .library: "Kitaplık"
        case .settings: "Ayarlar"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "sparkles"
        case .library: "books.vertical"
        case .settings: "gearshape"
        }
    }
}

struct DreamscapeTabBar: View {
    @Environment(\.masalThemeManager) private var theme
    @Binding var selection: MainTab

    var body: some View {
        let c = theme.colors
        HStack {
            ForEach(MainTab.allCases) { tab in
                let isSelected = selection == tab
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                            .symbolVariant(isSelected ? .fill : .none)
                        Text(tab.title)
                            .font(MasalFont.labelMedium())
                            .fontWeight(isSelected ? .bold : .medium)
                    }
                    .foregroundStyle(isSelected ? c.primary : c.secondary.opacity(0.65))
                    .padding(.horizontal, isSelected ? 18 : 12)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                    .fill(c.surfaceContainerHigh)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.md)
        .padding(.bottom, 28)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.Radius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: DesignTokens.Radius.xl,
                style: .continuous
            )
            .fill(c.surfaceContainer.opacity(0.92))
            .shadow(color: c.ambientShadow, radius: 16, x: 0, y: -8)
        }
    }
}
