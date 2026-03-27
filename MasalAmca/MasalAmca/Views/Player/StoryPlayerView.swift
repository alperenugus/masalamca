//
//  StoryPlayerView.swift
//  MasalAmca
//

import SwiftUI

struct StoryPlayerView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var audio: AudioPlayerService
    @Bindable var mixer: MixerEngine
    @Bindable var subscription: SubscriptionManager

    let story: Story

    @State private var showMixer = true
    @State private var sleepTimer = SleepTimerController()

    var body: some View {
        let c = theme.colors
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    header
                    hero
                    titles
                    VoiceVisualizerView(isActive: audio.isPlaying)
                    progressSection
                    controls
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 220)
            }
            .scrollIndicators(.hidden)

            if showMixer {
                WhiteNoiseMixerView(mixer: mixer, subscription: subscription)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, 8)
            }
        }
        .background(c.surface.ignoresSafeArea())
        .task {
            await loadAudioIfNeeded()
        }
        .onAppear {
            audio.onPlaybackFinished = { [mixer] in
                mixer.fadeInAllEnabled(duration: 5)
            }
        }
        .onDisappear {
            sleepTimer.cancel()
            audio.onPlaybackFinished = nil
            audio.pause()
        }
    }

    private var header: some View {
        let c = theme.colors
        return HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(c.primary)
            }
            Spacer()
            Text("Masal Amca")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.primary)
            Spacer()
            Menu {
                Button("Uyku zamanlayıcı — 15 dk") {
                    sleepTimer.start(minutes: 15) {
                        audio.pause()
                        mixer.stopAll()
                    }
                }
                Button("30 dk") {
                    sleepTimer.start(minutes: 30) {
                        audio.pause()
                        mixer.stopAll()
                    }
                }
                Button("Zamanlayıcıyı iptal et") { sleepTimer.cancel() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(c.primary)
            }
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        let c = theme.colors
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(c.surfaceContainerHigh)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(c.primary.opacity(0.45))
                }
                .shadow(color: c.surface.opacity(0.5), radius: 24, x: 0, y: 12)
            LinearGradient(
                colors: [c.surface.opacity(0.9), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        }
    }

    private var titles: some View {
        let c = theme.colors
        return VStack(spacing: 8) {
            Text(story.title)
                .font(MasalFont.headlineMedium())
                .multilineTextAlignment(.center)
                .foregroundStyle(c.onSurface)
            Text("Seslendiren: Masal Amca • \(max(1, story.durationSeconds / 60)) Dakika")
                .font(MasalFont.bodyMedium())
                .foregroundStyle(c.secondary.opacity(0.85))
        }
    }

    private var progressSection: some View {
        let c = theme.colors
        return VStack(spacing: 8) {
            StarProgressBar(progress: audio.progress) { p in
                let t = TimeInterval(p) * audio.duration
                audio.seek(to: t)
            }
            HStack {
                Text(format(audio.currentTime))
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.65))
                Spacer()
                Text(format(audio.duration))
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary.opacity(0.65))
            }
        }
    }

    private var controls: some View {
        let c = theme.colors
        return HStack(spacing: 48) {
            Button {
                audio.seek(to: max(0, audio.currentTime - 10))
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(c.secondary)
            }
            Button {
                if audio.isPlaying { audio.pause() } else { audio.play() }
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(c.onPrimaryContainer)
                    .frame(width: 80, height: 80)
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
            Button {
                audio.seek(to: min(audio.duration, audio.currentTime + 30))
            } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 32))
                    .foregroundStyle(c.secondary)
            }
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func loadAudioIfNeeded() async {
        guard let name = story.audioFileName else { return }
        let url = AudioCacheManager.documentsDirectory().appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? audio.load(fileURL: url, title: story.title)
        audio.play()
    }
}
