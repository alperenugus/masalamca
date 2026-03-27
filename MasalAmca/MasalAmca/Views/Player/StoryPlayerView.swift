//
//  StoryPlayerView.swift
//  MasalAmca
//

import Combine
import SwiftData
import SwiftUI

struct StoryPlayerView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var audio: AudioPlayerService
    @Bindable var mixer: MixerEngine
    @Bindable var subscription: SubscriptionManager

    let playlist: [Story]
    @State private var activeStory: Story

    @State private var mixerSheet = false
    @State private var sleepTimer = SleepTimerController()
    @State private var hasPlayableAudio = false
    @State private var appliedBackgroundMusicPreset = false
    private let sessionTicker = Timer.publish(every: 0.75, on: .main, in: .common).autoconnect()

    init(
        audio: AudioPlayerService,
        mixer: MixerEngine,
        subscription: SubscriptionManager,
        startStory: Story,
        playlist: [Story]
    ) {
        self.audio = audio
        self.mixer = mixer
        self.subscription = subscription
        self.playlist = playlist
        _activeStory = State(initialValue: startStory)
    }

    var body: some View {
        let c = theme.colors
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                header
                hero
                titles
                if hasPlayableAudio {
                    VoiceVisualizerView(isActive: audio.isPlaying)
                    progressSection
                    controls
                } else {
                    textOnlySection
                }
                playlistSection
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(c.surface.ignoresSafeArea())
        .task(id: activeStory.id) {
            await loadAudioIfNeeded()
            applyBackgroundMusicIfNeeded()
            await pushPlaybackToWidgetAndLiveActivity()
        }
        .onAppear {
            audio.onPlaybackFinished = { [mixer] in
                if StoryPreferences.autoStopAfterStoryEnds {
                    mixer.stopAll()
                } else {
                    mixer.fadeInAllEnabled(duration: 5)
                }
            }
        }
        .onReceive(sessionTicker) { _ in
            Task { await pushPlaybackToWidgetAndLiveActivity() }
        }
        .onChange(of: audio.isPlaying) { _, _ in
            Task { await pushPlaybackToWidgetAndLiveActivity() }
        }
        .onChange(of: hasPlayableAudio) { _, _ in
            Task { await pushPlaybackToWidgetAndLiveActivity() }
        }
        .onChange(of: sleepTimer.sleepTimerEndDate) { _, _ in
            Task { await pushPlaybackToWidgetAndLiveActivity() }
        }
        .onChange(of: activeStory.id) { _, _ in
            appliedBackgroundMusicPreset = false
        }
        .onDisappear {
            appliedBackgroundMusicPreset = false
            sleepTimer.cancel()
            audio.onPlaybackFinished = nil
            Task {
                await PlaybackSessionSync.endSession()
            }
            audio.pause()
        }
        .sheet(isPresented: $mixerSheet) {
            WhiteNoiseMixerView(
                mixer: mixer,
                subscription: subscription,
                onCollapse: { mixerSheet = false }
            )
            .padding(.top, DesignTokens.Spacing.md)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .masalThemeManager(theme)
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
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    mixerSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(c.primary)
                        .frame(width: 44, height: 44)
                        .background(c.surfaceContainerHigh)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Beyaz gürültü mikseri")

                Menu {
                    Button {
                        activeStory.isFavorite.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(
                            activeStory.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                            systemImage: activeStory.isFavorite ? "star.slash" : "star.fill"
                        )
                    }
                    Button("15 dakika") {
                        sleepTimer.start(minutes: 15) {
                            audio.pause()
                            mixer.stopAll()
                        }
                    }
                    Button("30 dakika") {
                        sleepTimer.start(minutes: 30) {
                            audio.pause()
                            mixer.stopAll()
                        }
                    }
                    Button("45 dakika") {
                        sleepTimer.start(minutes: 45) {
                            audio.pause()
                            mixer.stopAll()
                        }
                    }
                    Button("60 dakika") {
                        sleepTimer.start(minutes: 60) {
                            audio.pause()
                            mixer.stopAll()
                        }
                    }
                    Button("Zamanlayıcıyı iptal et") { sleepTimer.cancel() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(c.primary)
                        .frame(width: 44, height: 44)
                }
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
            Text(activeStory.title)
                .font(MasalFont.headlineMedium())
                .multilineTextAlignment(.center)
                .foregroundStyle(c.onSurface)
            Text("Seslendiren: Masal Amca • \(max(1, activeStory.durationSeconds / 60)) Dakika")
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

    private var playlistSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Çalma Listesi")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
                Spacer()
                Text("Sıradaki bölümler")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.primary.opacity(0.85))
            }
            .padding(.top, DesignTokens.Spacing.md)

            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(playlist, id: \.persistentModelID) { item in
                    playlistRow(item: item)
                }
            }
        }
    }

    private func playlistRow(item: Story) -> some View {
        let c = theme.colors
        let isCurrent = item.persistentModelID == activeStory.persistentModelID
        let minutes = max(1, item.durationSeconds / 60)
        let subtitle: String = {
            if isCurrent {
                return audio.isPlaying ? "Oynatılıyor • \(minutes) dk" : "Duraklatıldı • \(minutes) dk"
            }
            return "Sıradaki • \(minutes) dk"
        }()

        return HStack(spacing: DesignTokens.Spacing.md) {
            Button {
                guard !isCurrent else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                activeStory = item
            } label: {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                            .fill(c.surfaceContainerHigh)
                            .frame(width: 48, height: 48)
                        if isCurrent {
                            Image(systemName: "waveform")
                                .font(.title3)
                                .foregroundStyle(c.primary)
                        } else {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(c.primary.opacity(0.55))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(MasalFont.bodyMedium())
                            .fontWeight(isCurrent ? .bold : .medium)
                            .foregroundStyle(isCurrent ? c.primary : c.onSurface)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(MasalFont.labelSmall())
                            .foregroundStyle(c.secondary.opacity(0.65))
                    }

                    Spacer(minLength: 8)
                }
            }
            .buttonStyle(.plain)

            Button {
                item.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(item.isFavorite ? c.tertiary : c.secondary.opacity(0.45))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isFavorite ? "Favoriden çıkar" : "Favorilere ekle")
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

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var textOnlySection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(c.tertiary)
                Text("Ses kaydı yok")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
            }
            Text("Bu masalı seslendirme olmadan okuyabilirsiniz. Premium ile üretilen masallarda ses otomatik eklenir.")
                .font(MasalFont.bodyMedium())
                .foregroundStyle(c.onSurfaceVariant)
            Text(activeStory.body)
                .font(MasalFont.bodyLarge())
                .foregroundStyle(c.onSurface)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
        .background(c.surfaceContainerLow.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
    }

    @MainActor
    private func applyBackgroundMusicIfNeeded() {
        guard StoryPreferences.backgroundMusicDuringStory, !appliedBackgroundMusicPreset else { return }
        let sound = MixerSound.rain
        guard subscription.canUseSound(sound) else { return }
        appliedBackgroundMusicPreset = true
        mixer.setLevel(sound, level: 0.22)
        mixer.setEnabled(sound, on: true)
    }

    @MainActor
    private func loadAudioIfNeeded() async {
        audio.stop()
        hasPlayableAudio = false
        guard let name = activeStory.audioFileName else { return }
        let url = AudioCacheManager.documentsDirectory().appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try audio.load(fileURL: url, title: activeStory.title)
            hasPlayableAudio = true
            audio.play()
        } catch {
            hasPlayableAudio = false
        }
    }

    @MainActor
    private func pushPlaybackToWidgetAndLiveActivity() async {
        #if os(iOS)
        await PlaybackSessionSync.publish(
            story: activeStory,
            audio: audio,
            sleepTimer: sleepTimer,
            hasPlayableAudio: hasPlayableAudio
        )
        #endif
    }
}
