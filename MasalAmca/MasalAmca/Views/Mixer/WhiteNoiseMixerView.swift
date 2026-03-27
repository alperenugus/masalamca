//
//  WhiteNoiseMixerView.swift
//  MasalAmca
//

import SwiftUI

struct WhiteNoiseMixerView: View {
    @Environment(\.masalThemeManager) private var theme
    @Bindable var mixer: MixerEngine
    @Bindable var subscription: SubscriptionManager

    var body: some View {
        let c = theme.colors
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack {
                    Text("Beyaz Gürültü Mikseri")
                        .font(MasalFont.titleMedium())
                        .foregroundStyle(c.primary)
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(c.secondary.opacity(0.6))
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                VStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(MixerSound.allCases) { sound in
                        let locked = !subscription.canUseSound(sound)
                        WhiteNoiseRow(
                            title: sound.displayTitle + (locked ? " (Premium)" : ""),
                            systemImageName: sound.systemImage,
                            level: Binding(
                                get: { mixer.levels[sound] ?? 0 },
                                set: { mixer.setLevel(sound, level: $0) }
                            ),
                            isOn: Binding(
                                get: { mixer.enabled[sound] ?? false },
                                set: { new in
                                    if new, locked {
                                        return
                                    }
                                    mixer.setEnabled(sound, on: new)
                                }
                            )
                        )
                        .opacity(locked ? 0.45 : 1)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }
}
