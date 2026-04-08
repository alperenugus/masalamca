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
    @Environment(\.masalToastCenter) private var toastCenter
    @Bindable var subscription: SubscriptionManager
    @Query private var profiles: [ChildProfile]

    @State private var length: StoryLengthPreference = .short
    @State private var narrator: NarratorChoice = .yumuşakBulut
    @State private var bentoSelection: Set<StoryBentoTheme> = [.adventure]
    @State private var autoStop: Bool = true
    @State private var backgroundMusic: Bool = false
    @State private var backgroundSound: MixerSound = .rain
    @State private var previewError: String?
    @State private var previewing: NarratorChoice?
    @State private var mp3PreviewPlayer: AVAudioPlayer?

    @State private var localPreview = LocalVoicePreview()
    @State private var persistTask: Task<Void, Never>?
    @State private var showCommerceParentGate = false
    @State private var showPaywall = false

    var body: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                hero
                narratorSection
                bentoSection
                extraSettingsSection
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
            let storedPremiumWhileLocked = snap.narrator.requiresPremium && !subscription.isPremium
            applySnapshot(snap)
            if storedPremiumWhileLocked {
                persistSnapshot()
            }
            localPreview.onFinish = { previewing = nil }
        }
        .onChange(of: profileManager.activeProfileID) { _, _ in
            let a = profileManager.activeProfile(from: profiles)
            let snap = StoryPreferences.load(for: a)
            let storedPremiumWhileLocked = snap.narrator.requiresPremium && !subscription.isPremium
            applySnapshot(snap)
            if storedPremiumWhileLocked {
                persistSnapshot()
            }
        }
        .onChange(of: subscription.isPremium) { _, _ in
            let a = profileManager.activeProfile(from: profiles)
            let snap = StoryPreferences.load(for: a)
            let storedPremiumWhileLocked = snap.narrator.requiresPremium && !subscription.isPremium
            applySnapshot(snap)
            if storedPremiumWhileLocked {
                persistSnapshot()
            }
        }
        .onChange(of: narrator) { _, _ in schedulePersistSnapshot() }
        .onChange(of: bentoSelection) { _, _ in schedulePersistSnapshot() }
        .onChange(of: autoStop) { _, _ in schedulePersistSnapshot() }
        .onChange(of: backgroundMusic) { _, _ in schedulePersistSnapshot() }
        .onChange(of: backgroundSound) { _, _ in schedulePersistSnapshot() }
        .onDisappear {
            persistTask?.cancel()
            persistTask = nil
            persistSnapshot()
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
        .sheet(isPresented: $showCommerceParentGate) {
            ParentalGateSheet(kind: .commerce) {
                showPaywall = true
            }
            .masalThemeManager(theme)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription) {
                showPaywall = false
            }
            .presentationDetents([.large])
        }
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
        let selected = narrator == choice
        let isPreviewing = previewing == choice

        return HStack(spacing: DesignTokens.Spacing.lg) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                guard subscription.canUseNarrator(choice) else {
                    showCommerceParentGate = true
                    return
                }
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
                        HStack(spacing: 6) {
                            Text(choice.title)
                                .font(MasalFont.titleMedium())
                                .foregroundStyle(selected ? c.primary.opacity(0.95) : c.onSurface)
                            if choice.requiresPremium {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundStyle(c.tertiary)
                                    .accessibilityLabel("Premium ses")
                            }
                        }
                        Text(choice.subtitle)
                            .font(MasalFont.labelSmall())
                            .foregroundStyle(c.secondary.opacity(0.72))
                    }

                    Spacer(minLength: 8)

                    if selected {
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

            previewButton(choice: choice, isPreviewing: isPreviewing)
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
                    .allowsHitTesting(false)
            }
        }
        .opacity(subscription.canUseNarrator(choice) || selected ? 1 : 0.88)
    }

    private func previewButton(choice: NarratorChoice, isPreviewing: Bool) -> some View {
        let c = theme.colors
        let isSelectedRow = choice == narrator
        return Button {
            Task { await togglePreview(for: choice) }
        } label: {
            Image(systemName: isPreviewing ? "pause.fill" : "play.fill")
                .font(.title3)
                .foregroundStyle(isSelectedRow ? c.onPrimaryContainer : c.primary.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelectedRow ? c.primaryContainer : Color.clear)
                        .overlay {
                            Circle()
                                .stroke(c.outlineVariant.opacity(0.25), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPreviewing ? "Önizlemeyi durdur" : "Sesi önizle")
    }

    private var bentoSection: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Hikaye Teması")
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
            Text("Birden fazla seçebilirsin; her yeni masalda seçtiklerinden biri rastgele kullanılır.")
                .font(MasalFont.labelMedium())
                .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
                .padding(.horizontal, DesignTokens.Spacing.sm)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                ForEach(StoryBentoTheme.allCases) { tile in
                    let on = bentoSelection.contains(tile)
                    let locked = tile.requiresPremium && !subscription.isPremium
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if locked {
                            showCommerceParentGate = true
                            return
                        }
                        if on {
                            if bentoSelection.count > 1 {
                                bentoSelection = bentoSelection.subtracting([tile])
                            }
                        } else {
                            bentoSelection = bentoSelection.union([tile])
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: tile.systemImage)
                                    .font(.system(size: 26))
                                    .foregroundStyle(on ? c.tertiary : c.secondary)
                                HStack(spacing: 4) {
                                    Text(tile.displayTitle)
                                        .font(MasalFont.labelMedium())
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(on ? c.onSurface : c.secondary)
                                    if tile.requiresPremium {
                                        Image(systemName: "crown.fill")
                                            .font(.caption2)
                                            .foregroundStyle(c.tertiary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            if on {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(c.primary)
                                    .padding(8)
                            }
                        }
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
                    .opacity(on ? 1 : (locked ? 0.55 : 0.72))
                    .accessibilityLabel(tile.displayTitle)
                    .accessibilityAddTraits(on ? [.isSelected] : [])
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
                    title: "Masal Sırasında Beyaz Gürültü",
                    isOn: $backgroundMusic,
                    subtitle: "Masal oynarken seçtiğin sesi düşük seviyede çal"
                )
                if backgroundMusic {
                    Divider().opacity(0.12)
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: backgroundSound.systemImage)
                            .font(.title3)
                            .foregroundStyle(c.primary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seçili ses")
                                .font(MasalFont.bodyMedium())
                                .foregroundStyle(c.onSurface)
                            HStack(spacing: 6) {
                                Text(backgroundSound.displayTitle)
                                    .font(MasalFont.labelSmall())
                                    .foregroundStyle(c.onSurfaceVariant.opacity(0.75))
                                if !MixerSound.freeTier.contains(backgroundSound) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundStyle(c.tertiary)
                                }
                            }
                        }
                        Spacer()
                        Picker("Seçili ses", selection: Binding(
                            get: { backgroundSound },
                            set: { newSound in
                                if subscription.canUseSound(newSound) {
                                    backgroundSound = newSound
                                } else {
                                    showCommerceParentGate = true
                                }
                            }
                        )) {
                            ForEach(MixerSound.allCases) { s in
                                Label {
                                    Text(s.displayTitle)
                                } icon: {
                                    if !MixerSound.freeTier.contains(s) {
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(c.tertiary)
                                    }
                                }
                                .tag(s)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                }
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

    private func applySnapshot(_ snap: StoryPreferences.Snapshot) {
        length = .short
        var n = snap.narrator
        if n.requiresPremium && !subscription.isPremium {
            n = .yumuşakBulut
        }
        narrator = n
        var themes = snap.bentoThemes
        if !subscription.isPremium {
            themes = themes.filter { !$0.requiresPremium }
            if themes.isEmpty { themes = [.adventure] }
        }
        bentoSelection = Set(themes)
        autoStop = snap.autoStopAfterStory
        backgroundMusic = snap.backgroundMusicInPlayer
        var bgSound = snap.backgroundSoundInPlayer
        if !subscription.canUseSound(bgSound) {
            bgSound = .rain
        }
        backgroundSound = bgSound
    }

    private func schedulePersistSnapshot() {
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            persistSnapshot()
        }
    }

    private func persistSnapshot() {
        guard let profile = profileManager.activeProfile(from: profiles) else { return }
        let snap = StoryPreferences.Snapshot(
            length: .short,
            narrator: narrator,
            bentoThemes: StoryBentoTheme.normalizedSelection(Array(bentoSelection)),
            autoStopAfterStory: autoStop,
            backgroundMusicInPlayer: backgroundMusic,
            backgroundSoundInPlayer: backgroundSound
        )
        StoryPreferences.persist(snapshot: snap, to: profile, modelContext: modelContext)
    }

    private func togglePreview(for choice: NarratorChoice) async {
        if previewing == choice {
            mp3PreviewPlayer?.stop()
            mp3PreviewPlayer = nil
            localPreview.stop()
            previewing = nil
            return
        }

        mp3PreviewPlayer?.stop()
        localPreview.stop()

        if let url = BundledNarrationResources.audioFileURL(for: choice) {
            previewing = choice
            do {
                mp3PreviewPlayer = try AVAudioPlayer(contentsOf: url)
                mp3PreviewPlayer?.prepareToPlay()
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                mp3PreviewPlayer?.play()
            } catch {
                previewing = nil
                previewError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            return
        }

        toastCenter?.show("Bu anlatıcı için önizleme sesi henüz hazır değil.")
    }
}
