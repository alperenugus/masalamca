//
//  MiniPlayerBar.swift
//  MasalAmca
//

import SwiftUI

enum MiniPlayerMode {
    case story
    case whiteNoise
    case hidden
}

struct MiniPlayerBar: View {
    @Environment(\.masalThemeManager) private var theme
    @Bindable var audio: AudioPlayerService
    @Bindable var mixer: MixerEngine

    var mode: MiniPlayerMode
    var onTap: () -> Void

    var body: some View {
        let c = theme.colors
        switch mode {
        case .hidden:
            EmptyView()
        case .story:
            storyBar(c: c)
        case .whiteNoise:
            noiseBar(c: c)
        }
    }

    // MARK: - Story mode

    private func storyBar(c: DreamscapePalette) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .frame(width: 44, height: 44)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(c.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(audio.nowPlayingTitle)
                    .font(MasalFont.bodyMedium())
                    .fontWeight(.semibold)
                    .foregroundStyle(c.onSurface)
                    .lineLimit(1)
                Text("Masal Amca \u{2022} \(formatTime(audio.currentTime))")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            storyControls(c: c)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 10)
        .background(barBackground(c: c))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func storyControls(c: DreamscapePalette) -> some View {
        HStack(spacing: 16) {
            if audio.hasPreviousTrack {
                Button {
                    audio.skipToPreviousPublic()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(c.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            Button {
                if audio.isPlaying { audio.pause() } else { audio.play() }
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(c.onPrimaryContainer)
                    .frame(width: 36, height: 36)
                    .background(c.primaryContainer)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            if audio.hasNextTrack {
                Button {
                    audio.skipToNextPublic()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(c.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - White noise mode

    private func noiseBar(c: DreamscapePalette) -> some View {
        let sound = mixer.focusedSound
        let isPlaying = mixer.enabled[sound] == true

        return HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .frame(width: 44, height: 44)
                Image(systemName: sound.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(c.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sound.displayTitle)
                    .font(MasalFont.bodyMedium())
                    .fontWeight(.semibold)
                    .foregroundStyle(c.onSurface)
                    .lineLimit(1)
                Text("Beyaz Gürültü")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            noiseControls(c: c, isPlaying: isPlaying)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 10)
        .background(barBackground(c: c))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func noiseControls(c: DreamscapePalette, isPlaying: Bool) -> some View {
        HStack(spacing: 16) {
            Button {
                mixer.skipToPreviousSound()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(c.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Button {
                if isPlaying {
                    mixer.setEnabled(mixer.focusedSound, on: false)
                } else {
                    mixer.solo(mixer.focusedSound)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(c.onPrimaryContainer)
                    .frame(width: 36, height: 36)
                    .background(c.primaryContainer)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                mixer.skipToNextSound()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(c.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Shared

    private func barBackground(c: DreamscapePalette) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: DesignTokens.Radius.md,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: DesignTokens.Radius.md,
            style: .continuous
        )
        .fill(c.surfaceContainer.opacity(0.95))
        .shadow(color: c.ambientShadow, radius: 12, x: 0, y: -4)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
