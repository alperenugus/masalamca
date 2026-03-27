//
//  StorySettingsView.swift
//  MasalAmca
//
//  Tasarım: DesignProposal/story_settings/code.html
//

import AVFoundation
import SwiftData
import SwiftUI

private let previewSampleText =
    "Merhaba, ben Masal Amca. Bu gece sana huzurlu bir masal anlatacağım."

@MainActor
private final class LocalVoicePreview: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speakSample() {
        synthesizer.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: previewSampleText)
        u.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.speak(u)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        onFinish?()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinish?()
        }
    }
}

struct StorySettingsView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager
    @Query private var profiles: [ChildProfile]

    @State private var length: StoryLengthPreference = .medium
    @State private var narrator: NarratorChoice = .yumuşakBulut
    @State private var bento: StoryBentoTheme = .adventure
    @State private var autoStop: Bool = true
    @State private var backgroundMusic: Bool = true
    @State private var saveSucceeded = false
    @State private var previewError: String?
    @State private var previewing: NarratorChoice?
    @State private var mp3PreviewPlayer: AVAudioPlayer?

    @State private var localPreview = LocalVoicePreview()

    private let storyService = StoryService()

    var body: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                hero
                lengthSection
                narratorSection
                bentoSection
                extraSettingsSection
                GradientButton("Ayarları Kaydet") {
                    save(active: active)
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(c.surface.ignoresSafeArea())
        .navigationTitle("Masal Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(c.surface, for: .navigationBar)
        .onAppear {
            let snap = StoryPreferences.load(for: active)
            length = snap.length
            narrator = snap.narrator
            bento = snap.bento
            autoStop = snap.autoStopAfterStory
            backgroundMusic = snap.backgroundMusicInPlayer
            localPreview.onFinish = { previewing = nil }
        }
        .onDisappear {
            mp3PreviewPlayer?.stop()
            mp3PreviewPlayer = nil
            localPreview.stop()
        }
        .alert("Önizleme", isPresented: Binding(
            get: { previewError != nil },
            set: { if !$0 { previewError = nil } }
        )) {
            Button("Tamam", role: .cancel) { previewError = nil }
        } message: {
            Text(previewError ?? "")
        }
        .sensoryFeedback(.success, trigger: saveSucceeded)
    }

    private var hero: some View {
        let c = theme.colors
        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [c.primaryContainer.opacity(0.45), c.surfaceContainerHigh, c.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 192)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(c.primary.opacity(0.35))
                }
            LinearGradient(
                colors: [.clear, c.surface.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 192)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Ayarları düzenle ve")
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.secondary)
                Text("Sihirli Yolculuğa Başla")
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.primary.opacity(0.95))
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private var lengthSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Masal Süresi")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)

            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(StoryLengthPreference.allCases, id: \.rawValue) { opt in
                    let on = length == opt
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        length = opt
                    } label: {
                        Text(opt.displayTitle)
                            .font(MasalFont.labelMedium())
                            .fontWeight(on ? .bold : .medium)
                            .foregroundStyle(on ? c.onPrimaryContainer : c.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                                    .fill(on ? AnyShapeStyle(c.primaryContainer) : AnyShapeStyle(c.surfaceContainerHigh.opacity(0.35)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.surfaceContainer)
            )
        }
    }

    private var narratorSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Anlatıcı Sesi")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.secondary)
                Spacer()
                Text("Önizleme için dokun")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.primary.opacity(0.55))
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)

            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(NarratorChoice.allCases) { choice in
                    narratorRow(choice: choice)
                }
            }
        }
    }

    private func narratorRow(choice: NarratorChoice) -> some View {
        let c = theme.colors
        let selected = narrator == choice && choice.isSelectable
        let locked = !choice.isSelectable
        let isPreviewing = previewing == choice

        return HStack(spacing: DesignTokens.Spacing.lg) {
            Button {
                guard choice.isSelectable else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                narrator = choice
            } label: {
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(selected ? AnyShapeStyle(c.primary) : AnyShapeStyle(c.primary.opacity(0.12)))
                            .frame(width: 48, height: 48)
                        Image(systemName: choice.symbolName)
                            .font(.title3)
                            .foregroundStyle(selected ? c.onPrimary : c.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(choice.title)
                            .font(MasalFont.titleMedium())
                            .foregroundStyle(selected ? c.primary.opacity(0.95) : c.onSurface)
                        Text(locked ? "Çok yakında" : choice.subtitle)
                            .font(MasalFont.labelSmall())
                            .foregroundStyle(c.secondary.opacity(locked ? 0.5 : 0.72))
                    }

                    Spacer(minLength: 8)

                    if selected, choice.isSelectable {
                        Text("Seçili")
                            .font(MasalFont.labelSmall())
                            .fontWeight(.bold)
                            .foregroundStyle(c.primary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(locked)

            previewButton(choice: choice, isPreviewing: isPreviewing, locked: locked)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(c.surfaceContainerHigh)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(selected ? c.primary.opacity(0.4) : Color.clear, lineWidth: 1)
        }
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.primary.opacity(0.05))
            }
        }
        .opacity(locked ? 0.55 : 1)
    }

    private func previewButton(choice: NarratorChoice, isPreviewing: Bool, locked: Bool) -> some View {
        let c = theme.colors
        return Button {
            guard !locked else { return }
            Task { await togglePreview(for: choice) }
        } label: {
            Image(systemName: isPreviewing ? "pause.fill" : "play.fill")
                .font(.title3)
                .foregroundStyle(choice == narrator && choice.isSelectable ? c.onPrimaryContainer : c.primary.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(choice == narrator && choice.isSelectable ? c.primaryContainer : Color.clear)
                        .overlay {
                            Circle()
                                .stroke(c.outlineVariant.opacity(0.25), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPreviewing ? "Önizlemeyi durdur" : "Sesi önizle")
        .disabled(locked)
    }

    private var bentoSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Hikaye Teması")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
                ForEach(StoryBentoTheme.allCases) { tile in
                    let on = bento == tile
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        bento = tile
                    } label: {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: tile.systemImage)
                                .font(.system(size: 36))
                                .foregroundStyle(on ? c.tertiary : c.secondary)
                            Text(tile.displayTitle)
                                .font(MasalFont.titleMedium())
                                .foregroundStyle(on ? c.onSurface : c.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                .fill(on ? c.surfaceContainerHigh : c.surfaceContainerLow)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                .strokeBorder(on ? c.primary.opacity(0.35) : Color.clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .opacity(on ? 1 : 0.72)
                }
            }
        }
    }

    private var extraSettingsSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Ek Ayarlar")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)

            VStack(spacing: 0) {
                toggleRow(
                    icon: "moon.zzz.fill",
                    title: "Otomatik Kapanma",
                    isOn: $autoStop,
                    subtitle: "Masal bitince beyaz gürültüyü otomatik kapat"
                )
                Divider().opacity(0.12)
                toggleRow(
                    icon: "music.note",
                    title: "Arkaplan Müziği",
                    isOn: $backgroundMusic,
                    subtitle: "Oynatıcıda hafif yağmur ile başlat"
                )
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.surfaceContainerHigh)
            )
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>, subtitle: String) -> some View {
        let c = theme.colors
        return HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(c.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.onSurface)
                Text(subtitle)
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.onSurfaceVariant.opacity(0.75))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(c.primaryContainer)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    private func save(active: ChildProfile?) {
        let snap = StoryPreferences.Snapshot(
            length: length,
            narrator: narrator,
            bento: bento,
            autoStopAfterStory: autoStop,
            backgroundMusicInPlayer: backgroundMusic
        )
        do {
            try StoryPreferences.save(snap, profile: active, modelContext: modelContext)
            saveSucceeded.toggle()
        } catch {
            previewError = error.localizedDescription
        }
    }

    private func togglePreview(for choice: NarratorChoice) async {
        guard let voiceID = choice.resolvedVoiceID(), voiceID != "default" else {
            if previewing == choice {
                localPreview.stop()
                previewing = nil
            } else {
                mp3PreviewPlayer?.stop()
                previewing = choice
                localPreview.speakSample()
            }
            return
        }

        if previewing == choice {
            mp3PreviewPlayer?.stop()
            mp3PreviewPlayer = nil
            localPreview.stop()
            previewing = nil
            return
        }

        mp3PreviewPlayer?.stop()
        localPreview.stop()

        guard AppConfiguration.proxyBaseURL != nil else {
            previewing = choice
            localPreview.speakSample()
            return
        }

        previewing = choice
        let token = AppConfiguration.proxyAuthToken
        do {
            let data = try await storyService.fetchSpeechAudio(
                text: previewSampleText,
                voiceID: voiceID,
                authToken: token
            )
            mp3PreviewPlayer = try AVAudioPlayer(data: data)
            mp3PreviewPlayer?.prepareToPlay()
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            mp3PreviewPlayer?.play()
        } catch {
            previewing = nil
            previewError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
