//
//  WhiteNoiseMixerView.swift
//  MasalAmca
//

import SwiftUI

struct WhiteNoiseMixerView: View {
    @Environment(\.masalThemeManager) private var theme
    @Bindable var mixer: MixerEngine
    @Bindable var subscription: SubscriptionManager

    /// Collapse the panel (e.g. drag down or tap chevron).
    var onCollapse: (() -> Void)? = nil

    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        let c = theme.colors
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack {
                    Text("Beyaz Gürültü Mikseri")
                        .font(MasalFont.titleMedium())
                        .foregroundStyle(c.primary)
                    Spacer()
                    if let onCollapse {
                        Button {
                            onCollapse()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(c.secondary.opacity(0.85))
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mikseri gizle")
                    }
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(c.secondary.opacity(0.6))
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragTranslation = value.translation.height
                            }
                        }
                        .onEnded { value in
                            let shouldClose = value.translation.height > 56
                                || value.predictedEndTranslation.height > 100
                            dragTranslation = 0
                            if shouldClose {
                                onCollapse?()
                            }
                        }
                )

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
        .offset(y: dragTranslation)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: dragTranslation)
    }
}
