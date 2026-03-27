//
//  StoryCard.swift
//  MasalAmca
//

import SwiftUI

struct StoryCard: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let subtitle: String
    let durationMinutes: Int
    let systemImageName: String

    var body: some View {
        let c = theme.colors
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .overlay {
                        Image(systemName: systemImageName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(c.primary.opacity(0.6))
                    }
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundStyle(c.tertiary)
                    Text("\(durationMinutes) Dakika")
                        .font(MasalFont.labelSmall())
                        .foregroundStyle(c.onPrimaryContainer)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(c.surface.opacity(0.55))
                .clipShape(Capsule())
                .padding(10)
            }
            Text(title)
                .font(MasalFont.bodyMedium())
                .fontWeight(.bold)
                .foregroundStyle(c.onSurface)
                .lineLimit(2)
            Text(subtitle)
                .font(MasalFont.labelMedium())
                .foregroundStyle(c.onSurfaceVariant.opacity(0.7))
        }
        .frame(width: 200)
    }
}
