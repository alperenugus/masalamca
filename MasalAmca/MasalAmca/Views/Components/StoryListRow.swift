//
//  StoryListRow.swift
//  MasalAmca
//

import SwiftUI

struct StoryListRow: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let durationText: String
    let dateText: String
    let showCloud: Bool
    let systemImageName: String

    var body: some View {
        let c = theme.colors
        HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(c.surfaceContainerHighest)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: systemImageName)
                        .foregroundStyle(c.primary.opacity(0.7))
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(MasalFont.bodyMedium())
                        .fontWeight(.bold)
                        .foregroundStyle(c.onSurface)
                        .lineLimit(1)
                    if showCloud {
                        Image(systemName: "cloud.fill")
                            .font(.caption2)
                            .foregroundStyle(c.primary)
                    }
                }
                HStack(spacing: 6) {
                    Text(durationText)
                    Circle()
                        .fill(c.outlineVariant.opacity(0.5))
                        .frame(width: 4, height: 4)
                    Text(dateText)
                }
                .font(MasalFont.labelMedium())
                .foregroundStyle(c.secondary.opacity(0.75))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.body.weight(.medium))
                .foregroundStyle(c.secondary.opacity(0.4))
        }
        .padding(DesignTokens.Spacing.md)
    }
}
