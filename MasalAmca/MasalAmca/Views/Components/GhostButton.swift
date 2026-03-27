//
//  GhostButton.swift
//  MasalAmca
//

import SwiftUI

struct GhostButton: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let action: () -> Void

    var body: some View {
        let c = theme.colors
        Button(action: action) {
            Text(title)
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.primary)
                .padding(.vertical, DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                        .stroke(c.outlineVariant.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
