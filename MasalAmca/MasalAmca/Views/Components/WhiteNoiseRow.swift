//
//  WhiteNoiseRow.swift
//  MasalAmca
//

import SwiftUI

struct WhiteNoiseRow: View {
    @Environment(\.masalThemeManager) private var theme
    let title: String
    let systemImageName: String
    @Binding var level: Double
    @Binding var isOn: Bool

    var body: some View {
        let c = theme.colors
        HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(c.surfaceContainerHigh)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: systemImageName)
                        .foregroundStyle(c.primary)
                }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(MasalFont.bodyMedium())
                        .foregroundStyle(c.onSurface)
                    Spacer()
                    Text("\(Int(level * 100))%")
                        .font(MasalFont.labelSmall())
                        .foregroundStyle(c.secondary.opacity(0.65))
                }
                Slider(value: $level, in: 0 ... 1)
                    .tint(c.primary)
                    .disabled(!isOn)
                    .opacity(isOn ? 1 : 0.45)
            }
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(c.primary)
                .onChange(of: isOn) { _, new in
                    if new { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                }
        }
    }
}
