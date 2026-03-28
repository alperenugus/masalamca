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
    /// Outer chrome may provide a drag handle (e.g. floating bottom panel on story player).
    var showGlassHandle: Bool = true
    /// When true, skips inner `GlassPanel` so the parent can supply blur + rounded shell (`story_player_mixer_open`).
    var embedsInStoryPlayerPanel: Bool = false

    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        Group {
            if embedsInStoryPlayerPanel {
                mixerCore
            } else {
                GlassPanel(showHandle: showGlassHandle) {
                    mixerCore
                }
            }
        }
        .offset(y: dragTranslation)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: dragTranslation)
    }

    private var mixerCore: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 0) {
            mixerHeaderBlock(c: c)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, embedsInStoryPlayerPanel ? 2 : DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.md)

            mixerAccentRule(c: c)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.lg)

            VStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(MixerSound.allCases) { sound in
                    let locked = !subscription.canUseSound(sound)
                    WhiteNoiseRow(
                        title: sound.displayTitle + (locked ? " · Premium" : ""),
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
            .padding(.bottom, embedsInStoryPlayerPanel ? DesignTokens.Spacing.lg : 0)
        }
    }

    private func mixerHeaderBlock(c: DreamscapePalette) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [c.primaryContainer.opacity(0.55), c.primary.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "waveform")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(c.onPrimaryContainer)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Beyaz Gürültü Mikseri")
                            .font(MasalFont.titleMedium())
                            .foregroundStyle(c.onSurface)
                        Text("Katmanları aç, seviyeleri yumuşakça karıştır.")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onCollapse {
                Button {
                    onCollapse()
                } label: {
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(c.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(c.surfaceContainerHigh.opacity(0.9))
                        )
                        .overlay {
                            Circle()
                                .stroke(c.outlineVariant.opacity(0.18), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mikseri gizle")
            }
        }
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
    }

    private func mixerAccentRule(c: DreamscapePalette) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        c.primary.opacity(0),
                        c.primary.opacity(0.35),
                        c.tertiary.opacity(0.45),
                        c.primary.opacity(0.35),
                        c.primary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .blur(radius: 0.3)
    }
}
