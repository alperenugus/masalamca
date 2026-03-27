//
//  GlassPanel.swift
//  MasalAmca
//

import SwiftUI

struct GlassPanel<Content: View>: View {
    @Environment(\.masalThemeManager) private var theme
    @ViewBuilder var content: () -> Content
    var showHandle: Bool = true

    var body: some View {
        let c = theme.colors
        VStack(spacing: 0) {
            if showHandle {
                Capsule()
                    .fill(c.outlineVariant.opacity(0.35))
                    .frame(width: 48, height: 4)
                    .padding(.vertical, 10)
            }
            content()
        }
        .padding(.bottom, DesignTokens.Spacing.lg)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(c.surfaceContainerHigh.opacity(0.45))
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(c.outlineVariant.opacity(0.12), lineWidth: 1)
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
    }
}
