//
//  WhiteNoisePlayerView.swift
//  MasalAmca
//
//  Layout: DesignProposal/white_noise_player + StoryPlayerView playlist satırları
//

import SwiftUI

struct WhiteNoisePlayerView: View {
    @Environment(\.masalThemeManager) private var theme
    @Bindable var subscription: SubscriptionManager
    @Bindable var mixer: MixerEngine
    @Bindable var pinStore: MixerPinStore

    @State private var focusedSound: MixerSound = .rain
    @State private var showPaywall = false

    private var playlist: [MixerSound] { MixerSound.allCases }

    private var focusedPlaying: Bool {
        mixer.enabled[focusedSound] == true
    }

    var body: some View {
        let c = theme.colors
        ZStack {
            LinearGradient(
                colors: [
                    c.surface.opacity(0.92),
                    c.surfaceContainer.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    header
                    hero
                    VoiceVisualizerView(isActive: focusedPlaying)
                    loopStrip
                    transportControls
                    playlistSection
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            syncFocusedFromMixerIfNeeded()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription) {
                showPaywall = false
            }
            .presentationDetents([.large])
        }
    }

    private var header: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 6) {
            Text("Beyaz Gürültü")
                .font(MasalFont.headlineMedium())
                .foregroundStyle(c.onSurface)
            Text("Uyku öncesi sakinleştirici sesler")
                .font(MasalFont.bodyMedium())
                .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var hero: some View {
        let c = theme.colors
        let sound = focusedSound
        let premiumOnly = !MixerSound.freeTier.contains(sound)
        return VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                    .fill(c.surfaceContainerHigh.opacity(0.65))
                    .frame(height: 160)
                Image(systemName: sound.systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(c.primary)
            }
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(sound.displayTitle)
                        .font(MasalFont.titleMedium())
                        .foregroundStyle(c.onSurface)
                    if premiumOnly {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(c.tertiary)
                    }
                }
                Text(focusedPlaying ? "Seslendiriliyor…" : "Duraklatıldı")
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(c.secondary.opacity(0.75))
            }
        }
    }

    private var loopStrip: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(c.outlineVariant.opacity(0.2))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [c.tertiary.opacity(0.85), c.primary.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width, height: 6)
                }
            }
            .frame(height: 6)
            HStack {
                Text("Sürekli döngü")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.65))
                Spacer()
                Text("Kesintisiz")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.45))
            }
        }
    }

    private var transportControls: some View {
        let c = theme.colors
        return HStack(spacing: 40) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                stepFocus(delta: -1)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(c.secondary)
            }
            .accessibilityLabel("Önceki ses")

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                toggleFocusedPlayback()
            } label: {
                Image(systemName: focusedPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(c.onPrimaryContainer)
                    .frame(width: 76, height: 76)
                    .background(
                        LinearGradient(
                            colors: [c.primaryContainer, c.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: c.ctaShadow, radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel(focusedPlaying ? "Duraklat" : "Oynat")

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                stepFocus(delta: 1)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(c.secondary)
            }
            .accessibilityLabel("Sonraki ses")
        }
    }

    private var playlistSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Çalma Listesi")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
                Spacer()
                Text("Sabitlenebilir")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.primary.opacity(0.85))
            }
            .padding(.top, DesignTokens.Spacing.md)

            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(playlist) { sound in
                    noisePlaylistRow(sound: sound)
                }
            }
        }
    }

    private func noisePlaylistRow(sound: MixerSound) -> some View {
        let c = theme.colors
        let isCurrent = sound == focusedSound
        let on = mixer.enabled[sound] == true
        let subtitle: String = {
            if isCurrent {
                return on ? "Çalıyor • \(sound.playlistSubtitle)" : "Duraklatıldı • \(sound.playlistSubtitle)"
            }
            return sound.playlistSubtitle
        }()

        return HStack(spacing: DesignTokens.Spacing.md) {
            Button {
                selectSound(sound)
            } label: {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                            .fill(c.surfaceContainerHigh)
                            .frame(width: 48, height: 48)
                        if isCurrent {
                            Image(systemName: sound.systemImage)
                                .font(.title3)
                                .foregroundStyle(c.primary)
                        } else {
                            Image(systemName: sound.systemImage)
                                .foregroundStyle(c.primary.opacity(0.55))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(sound.displayTitle)
                                .font(MasalFont.bodyMedium())
                                .fontWeight(isCurrent ? .bold : .medium)
                                .foregroundStyle(isCurrent ? c.primary : c.onSurface)
                                .lineLimit(1)
                            if !MixerSound.freeTier.contains(sound) {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundStyle(c.tertiary)
                            }
                        }
                        Text(subtitle)
                            .font(MasalFont.labelSmall())
                            .foregroundStyle(c.secondary.opacity(0.65))
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                pinStore.togglePin(sound)
            } label: {
                Image(systemName: pinStore.isPinned(sound) ? "pin.fill" : "pin")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(pinStore.isPinned(sound) ? c.primary : c.secondary.opacity(0.45))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(pinStore.isPinned(sound) ? "Sabitlemeyi kaldır" : "Ana sayfaya sabitle")
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(isCurrent ? c.primary.opacity(0.12) : c.surfaceContainer.opacity(0.45))
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(isCurrent ? c.primary.opacity(0.28) : c.outlineVariant.opacity(0.12), lineWidth: 1)
        }
    }

    private func syncFocusedFromMixerIfNeeded() {
        for s in MixerSound.allCases where mixer.enabled[s] == true {
            focusedSound = s
            return
        }
    }

    private func selectSound(_ sound: MixerSound) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if sound == focusedSound {
            toggleFocusedPlayback()
            return
        }
        guard subscription.canUseSound(sound) else {
            showPaywall = true
            return
        }
        let wasPlaying = focusedPlaying
        focusedSound = sound
        if wasPlaying {
            mixer.solo(sound)
        }
    }

    private func toggleFocusedPlayback() {
        guard subscription.canUseSound(focusedSound) else {
            showPaywall = true
            return
        }
        if focusedPlaying {
            mixer.setEnabled(focusedSound, on: false)
        } else {
            mixer.solo(focusedSound)
        }
    }

    private func stepFocus(delta: Int) {
        guard let idx = playlist.firstIndex(of: focusedSound) else { return }
        let n = playlist.count
        let nextIndex = (idx + delta + n) % n
        let next = playlist[nextIndex]
        guard subscription.canUseSound(next) else {
            showPaywall = true
            return
        }
        let wasPlaying = focusedPlaying
        focusedSound = next
        if wasPlaying {
            mixer.solo(next)
        }
    }
}
