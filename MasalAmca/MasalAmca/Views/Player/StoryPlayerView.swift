//
//  StoryPlayerView.swift
//  MasalAmca
//
//  Layout: DesignProposal/story_player_with_playlist_compact_mixer + story_player_mixer_open
//

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

    @State private var showMixerPanel = false
    @State private var sleepTimer = SleepTimerController()
    @State private var hasPlayableAudio = false
    @State private var appliedBackgroundMusicPreset = false
    @State private var showStoryRead = false

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
        ZStack(alignment: .bottom) {
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
                    if sleepTimer.isRunning {
                        sleepTimerBanner
                    }
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
                .padding(.bottom, showMixerPanel ? 12 : 48)
            }
            .scrollIndicators(.hidden)

            if showMixerPanel {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                            showMixerPanel = false
                        }
                    }
                    .transition(.opacity)

                floatingMixerPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: showMixerPanel)
        .task(id: activeStory.id) {
            StoryPreferences.mirrorPlaybackPreferencesToUserDefaults(for: activeStory.profile)
            await loadAudioIfNeeded()
            applyBackgroundMusicIfNeeded()
        }
        .onAppear {
            wirePlaybackFinishedHandler()
        }
        .onChange(of: activeStory.id) { _, _ in
            wirePlaybackFinishedHandler()
            appliedBackgroundMusicPreset = false
        }
        .fullScreenCover(isPresented: $showStoryRead) {
            StoryReadView(story: activeStory, onFinish: { showStoryRead = false })
                .masalThemeManager(theme)
        }
        .onChange(of: showStoryRead) { _, isReading in
            if isReading { audio.pause() }
        }
        .onDisappear {
            appliedBackgroundMusicPreset = false
            sleepTimer.cancel()
            audio.onPlaybackFinished = nil
            Task {
                await PlaybackSessionSync.endSession()
            }
            audio.pause()
            mixer.stopAll()
        }
    }

    private var floatingMixerPanel: some View {
        let c = theme.colors
        return VStack(spacing: 0) {
            Capsule()
                .fill(c.outlineVariant.opacity(0.35))
                .frame(width: 48, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            WhiteNoiseMixerView(
                mixer: mixer,
                subscription: subscription,
                onCollapse: {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        showMixerPanel = false
                    }
                },
                showGlassHandle: false,
                embedsInStoryPlayerPanel: true
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, 10)
        .background {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignTokens.Radius.lg,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: DesignTokens.Radius.lg,
                    style: .continuous
                )
                .fill(c.surfaceContainer.opacity(0.82))
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignTokens.Radius.lg,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: DesignTokens.Radius.lg,
                    style: .continuous
                )
                .stroke(c.outlineVariant.opacity(0.14), lineWidth: 1)
            }
        }
        .background(.ultraThinMaterial, in: UnevenRoundedRectangle(
            topLeadingRadius: DesignTokens.Radius.lg,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: DesignTokens.Radius.lg,
            style: .continuous
        ))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: -8)
    }

    private var header: some View {
        let c = theme.colors
        return ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(c.primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 10) {
                    if hasReadableBody {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showStoryRead = true
                        } label: {
                            Image(systemName: "book.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(c.primary)
                                .frame(width: 34, height: 34)
                                .background(c.surfaceContainerHigh)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Masalı oku")
                    }

                    Menu {
                        Button("3 dakika") {
                            sleepTimer.start(minutes: 3) {
                                audio.pause()
                                mixer.stopAll()
                            }
                        }
                        Button("5 dakika") {
                            sleepTimer.start(minutes: 5) {
                                audio.pause()
                                mixer.stopAll()
                            }
                        }
                        Button("10 dakika") {
                            sleepTimer.start(minutes: 10) {
                                audio.pause()
                                mixer.stopAll()
                            }
                        }
                        Button("Zamanlayıcıyı iptal et") { sleepTimer.cancel() }
                    } label: {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(c.primary)
                            .frame(width: 34, height: 34)
                            .background(c.surfaceContainerHigh)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Uyku zamanlayıcısı")

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                            showMixerPanel.toggle()
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(c.primary)
                            .frame(width: 34, height: 34)
                            .background(c.surfaceContainerHigh)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Beyaz gürültü mikseri")
                }
            }

            Text("Masal Amca")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.primary)
        }
        .padding(.top, 8)
    }

    private var sleepTimerBanner: some View {
        let c = theme.colors
        let sec = max(0, Int(sleepTimer.remaining.rounded(.down)))
        let m = sec / 60
        let s = sec % 60
        return HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(c.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Uyku zamanlayıcısı")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.onSurfaceVariant)
                Text(String(format: "%d:%02d", m, s))
                    .font(.custom(MasalFont.headlineFamily, size: 22, relativeTo: .title3).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(c.primary)
            }
            Spacer(minLength: 8)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                sleepTimer.cancel()
            } label: {
                Text("İptal")
                    .font(MasalFont.labelMedium())
                    .fontWeight(.semibold)
                    .foregroundStyle(c.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(c.surfaceContainerHighest.opacity(0.5))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zamanlayıcıyı iptal et")
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(c.surfaceContainer.opacity(0.95))
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(c.primary.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var hero: some View {
        let c = theme.colors
        let side: CGFloat = 152
        return HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .frame(width: side, height: side)
                    .overlay {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(c.primary.opacity(0.45))
                    }
                    .shadow(color: c.surface.opacity(0.45), radius: 16, x: 0, y: 8)
                LinearGradient(
                    colors: [c.surface.opacity(0.88), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .frame(width: side, height: side)
            }
            Spacer(minLength: 0)
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
            if hasReadableBody {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showStoryRead = true
                } label: {
                    Text("Metni kendim oku")
                        .font(MasalFont.labelMedium())
                        .fontWeight(.semibold)
                        .foregroundStyle(c.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(c.primary.opacity(0.14))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private var hasReadableBody: Bool {
        !activeStory.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        return HStack(spacing: 40) {
            Button {
                audio.seek(to: max(0, audio.currentTime - 10))
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 28))
                    .foregroundStyle(c.secondary)
            }
            .accessibilityLabel("On saniye geri")

            Button {
                if audio.isPlaying {
                    audio.pause()
                    mixer.stopAll()
                    appliedBackgroundMusicPreset = false
                } else {
                    audio.play()
                    applyBackgroundMusicIfNeeded()
                }
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
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
            .accessibilityLabel(audio.isPlaying ? "Duraklat" : "Oynat")

            Button {
                audio.seek(to: min(audio.duration, audio.currentTime + 10))
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 28))
                    .foregroundStyle(c.secondary)
            }
            .accessibilityLabel("On saniye ileri")
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

    private func wirePlaybackFinishedHandler() {
        audio.onPlaybackFinished = { [mixer] in
            if StoryPreferences.autoStopAfterStoryEnds {
                mixer.stopAll()
            } else {
                mixer.fadeInAllEnabled(duration: 5)
            }
        }
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
        do {
            if let blob = activeStory.audioBlob, !blob.isEmpty {
                try audio.load(data: blob, title: activeStory.title)
                hasPlayableAudio = true
                audio.play()
                return
            }
            guard let name = activeStory.audioFileName else { return }
            let url = AudioCacheManager.documentsDirectory().appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            try audio.load(fileURL: url, title: activeStory.title)
            hasPlayableAudio = true
            audio.play()
        } catch {
            hasPlayableAudio = false
        }
    }

}
