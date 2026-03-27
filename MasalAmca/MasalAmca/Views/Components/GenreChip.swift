//
//  GenreChip.swift
//  MasalAmca
//

import SwiftUI

struct GenreChip: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let systemImageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let c = theme.colors
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImageName)
                    .font(.body.weight(.regular))
                Text(title)
                    .font(MasalFont.bodyMedium())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? c.surfaceContainerHighest : c.surfaceContainerLow)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? c.primary.opacity(0.35) : c.outlineVariant.opacity(0.15), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? c.onPrimaryContainer : c.outline)
        }
        .buttonStyle(.plain)
    }
}
