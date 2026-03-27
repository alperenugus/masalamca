//
//  InputField.swift
//  MasalAmca
//

import SwiftUI

struct InputField: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    @Binding var text: String
    var placeholder: String = ""

    @FocusState private var focused: Bool

    var body: some View {
        let c = theme.colors
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(MasalFont.bodyMedium())
                .fontWeight(.semibold)
                .foregroundStyle(c.secondary)
            TextField(placeholder, text: $text)
                .focused($focused)
                .font(MasalFont.bodyLarge())
                .foregroundStyle(c.onSurface)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .frame(height: 56)
                .background(c.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .stroke(focused ? c.primary.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        }
    }
}
