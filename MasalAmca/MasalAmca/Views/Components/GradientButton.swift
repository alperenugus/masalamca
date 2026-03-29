//
//  GradientButton.swift
//  MasalAmca
//

import SwiftUI

struct GradientButton: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let subtitle: String?
    var disabled: Bool = false
    let action: () -> Void

    init(_ title: String, subtitle: String? = nil, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        let c = theme.colors
        Button(action: {
            guard !disabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onPrimaryContainer)
                if let subtitle {
                    Text(subtitle)
                        .font(MasalFont.labelMedium())
                        .foregroundStyle(c.onPrimaryContainer.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [c.primaryContainer, c.primary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .shadow(color: c.ctaShadow, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}
