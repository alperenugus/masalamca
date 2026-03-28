//
//  HomeView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager

    @Bindable var subscription: SubscriptionManager
    @Bindable var mixer: MixerEngine
    @Bindable var pinStore: MixerPinStore
    @Binding var tabSelection: MainTab

    @Query(sort: \Story.createdAt, order: .reverse) private var stories: [Story]
    @Query private var profiles: [ChildProfile]

    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var playerPresentation: PresentedStory?
    @State private var showPaywall = false
    @State private var showNotificationsSheet = false
    @State private var storyAudio = AudioPlayerService()
    @State private var randomQuickNoisePick: [MixerSound]?

    private let storyService = StoryService()

    private func todayStartEnd() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        return (start, end)
    }

    /// Bugün (yerel takvim) oluşturulmuş tüm masallar — Premium günlük kota.
    private var storiesCreatedTodayCount: Int {
        let (start, end) = todayStartEnd()
        return stories.filter { $0.createdAt >= start && $0.createdAt < end }.count
    }

    /// Ücretsiz: ömür boyu 2 üretim sonrası paywall.
    private var freeTrialExhausted: Bool {
        !subscription.isPremium
            && subscription.storiesGeneratedCount >= SubscriptionManager.freeTierLifetimeGenerationLimit
    }

    /// Premium: bugün zaten 2 masal üretildiyse yeni üretim yok (ertesi güne kadar).
    private var premiumDailyQuotaReached: Bool {
        subscription.isPremium
            && storiesCreatedTodayCount >= SubscriptionManager.premiumDailyGenerationLimit
    }

    var body: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    header
                    greeting(name: active?.name ?? "Can")
                    generateButton(profile: active)
                    recentSection(active: active)
                    quickNoise
                    tipCard
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            if isGenerating {
                StoryGenerationLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .background(c.surface.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: isGenerating)
        .fullScreenCover(item: $playerPresentation, onDismiss: { storyAudio.stop() }) { wrap in
            StoryPlayerView(
                audio: storyAudio,
                mixer: mixer,
                subscription: subscription,
                startStory: wrap.startStory,
                playlist: wrap.playlist
            )
            .masalThemeManager(theme)
        }
        .alert("Bir şeyler ters gitti", isPresented: Binding(
            get: { generationError != nil },
            set: { if !$0 { generationError = nil } }
        )) {
            Button("Anladım", role: .cancel) { generationError = nil }
        } message: {
            Text(generationError ?? "")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription) {
                showPaywall = false
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NotificationsInfoSheet()
                .masalThemeManager(theme)
                .presentationDetents([.medium])
        }
        .onAppear {
            ensureQuickNoisePick()
        }
        .onChange(of: pinStore.pinnedRawValues) { _, _ in
            if pinStore.pinnedSounds.isEmpty {
                randomQuickNoisePick = Array(MixerSound.allCases.shuffled().prefix(3))
            } else {
                randomQuickNoisePick = nil
            }
        }
    }

    /// Sabit yokken rastgele üçlü yalnızca ilk kez veya sabitler kaldırılınca yenilenir.
    private func ensureQuickNoisePick() {
        guard pinStore.pinnedSounds.isEmpty else {
            randomQuickNoisePick = nil
            return
        }
        if randomQuickNoisePick == nil {
            randomQuickNoisePick = Array(MixerSound.allCases.shuffled().prefix(3))
        }
    }

    private var header: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        return HStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(c.primary)
                Text("Masal Amca")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.primary)
            }
            Spacer(minLength: 8)
            childSwitcherMenu(active: active)
            Button {
                showNotificationsSheet = true
            } label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(c.primary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bildirimler")
            .accessibilityHint("Uyku hatırlatıcıları hakkında bilgi")
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func childSwitcherMenu(active: ChildProfile?) -> some View {
        let c = theme.colors
        Menu {
            if profiles.isEmpty {
                Text("Kayıtlı çocuk yok")
            }
            ForEach(profiles, id: \.id) { profile in
                Button {
                    profileManager.switchTo(profile)
                } label: {
                    HStack {
                        Text(profile.name)
                        Spacer()
                        if profile.id == active?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.caption.weight(.semibold))
                Text(active?.name ?? "Çocuk")
                    .font(MasalFont.labelMedium())
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(c.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(c.surfaceContainerHigh.opacity(0.85))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(c.outlineVariant.opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityLabel("Aktif çocuk: \(active?.name ?? "yok")")
        .accessibilityHint("Çocuk profiline geçmek için menüyü açın")
    }

    private func greeting(name: String) -> some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 6) {
            Text("İyi Geceler, \(name)")
                .font(MasalFont.headlineMedium())
                .foregroundStyle(c.onSurface)
            Text("Hangi masalla rüyalara dalalım?")
                .font(MasalFont.bodyLarge())
                .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
        }
    }

    private func generateButton(profile: ChildProfile?) -> some View {
        let c = theme.colors
        let canGenerateNew = subscription.canGenerateStory(storiesCreatedTodayFromStore: storiesCreatedTodayCount)
        return Button {
            if freeTrialExhausted {
                showPaywall = true
            } else if premiumDailyQuotaReached {
                tabSelection = .library
            } else if canGenerateNew {
                Task { await generateStory(profile: profile) }
            }
        } label: {
            ZStack {
                LinearGradient(
                    colors: (freeTrialExhausted || premiumDailyQuotaReached)
                        ? [c.surfaceContainerHigh, c.surfaceContainer]
                        : [c.primaryContainer, c.primary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: freeTrialExhausted ? "crown.fill" : (premiumDailyQuotaReached ? "calendar.badge.clock" : "sparkles"))
                        .font(.system(size: 36))
                        .foregroundStyle((freeTrialExhausted || premiumDailyQuotaReached) ? c.primary.opacity(0.85) : c.onPrimaryContainer)
                    Text(buttonTitle)
                        .font(MasalFont.titleMedium())
                        .multilineTextAlignment(.center)
                        .foregroundStyle((freeTrialExhausted || premiumDailyQuotaReached) ? c.onSurface : c.onPrimaryContainer)
                    if freeTrialExhausted {
                        Text("İki ücretsiz masalın bu geceye eşlik etti. İstersen Premium ile her gün iki yeni masal üretmeye devam edebilirsin.")
                            .font(MasalFont.labelMedium())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(c.secondary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                    } else if premiumDailyQuotaReached {
                        Text("Bugün için yeterince masal ürettin gibi görünüyor. Kitaplığındakileri tekrar dinleyebilir veya yarın yeni bir masal için dönebilirsin.")
                            .font(MasalFont.labelMedium())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(c.secondary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                    }
                }
                .padding(DesignTokens.Spacing.xl)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .shadow(color: c.ctaShadow.opacity((freeTrialExhausted || premiumDailyQuotaReached) ? 0.35 : 1), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isGenerating || (!freeTrialExhausted && !premiumDailyQuotaReached && profile == nil))
    }

    private var buttonTitle: String {
        if freeTrialExhausted { return "Premium’u keşfet" }
        if premiumDailyQuotaReached { return "Kitaplığına göz at" }
        return "Bu gece bir masal üret"
    }

    private func recentSection(active: ChildProfile?) -> some View {
        let c = theme.colors
        let recent = stories.filter { $0.profile?.id == active?.id }.prefix(8)
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Son Dinlenenler")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
                Spacer()
                Button("Tümünü Gör") {
                    tabSelection = .library
                }
                .font(MasalFont.bodyMedium())
                .foregroundStyle(c.primary)
            }
            if recent.isEmpty {
                Text("Henüz masal yok — yukarıdaki düğmeyle ilk masalı üret.")
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.secondary.opacity(0.8))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(Array(recent), id: \.persistentModelID) { s in
                            Button {
                                presentPlayer(story: s, active: active)
                            } label: {
                                StoryCard(
                                    title: s.title,
                                    subtitle: "\(s.genre.displayName) • Uyku",
                                    durationMinutes: max(1, s.durationSeconds / 60),
                                    systemImageName: "moon.stars"
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    toggleFavorite(s)
                                } label: {
                                    Label(
                                        s.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                                        systemImage: s.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                Button(role: .destructive) {
                                    deleteStory(s)
                                } label: {
                                    Label("Masalı Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var quickNoiseSounds: [MixerSound] {
        let pinned = pinStore.pinnedSounds
        if !pinned.isEmpty {
            return Array(pinned.prefix(3))
        }
        return randomQuickNoisePick ?? [.rain, .fireplace, .ocean]
    }

    private var quickNoise: some View {
        let c = theme.colors
        let sounds = quickNoiseSounds
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hızlı Beyaz Gürültü")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(c.tertiary)
                    Text("Taçlı sesler Premium ile birlikte gelir")
                        .font(MasalFont.labelSmall())
                        .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
                }
            }
            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(sounds, id: \.self) { sound in
                    quickNoiseRow(sound: sound, title: sound.displayTitle, subtitle: sound.playlistSubtitle)
                }
            }
        }
    }

    private func quickNoiseRow(sound: MixerSound, title: String, subtitle: String) -> some View {
        let c = theme.colors
        let isPremiumOnly = !MixerSound.freeTier.contains(sound)
        let on = mixer.enabled[sound] ?? false
        return Button {
            if !subscription.canUseSound(sound) {
                showPaywall = true
                return
            }
            mixer.setEnabled(sound, on: !on)
        } label: {
            HStack {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Circle()
                        .fill(c.primary.opacity(0.12))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: sound.systemImage)
                                .foregroundStyle(c.primary)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(MasalFont.bodyMedium())
                                .fontWeight(.bold)
                                .foregroundStyle(c.onSurface)
                            if isPremiumOnly {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundStyle(c.tertiary)
                                    .accessibilityLabel("Premium ses")
                            }
                        }
                        Text(subtitle)
                            .font(MasalFont.labelMedium())
                            .foregroundStyle(c.onSurfaceVariant.opacity(0.65))
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { mixer.enabled[sound] ?? false },
                    set: { new in
                        if new, !subscription.canUseSound(sound) {
                            showPaywall = true
                            return
                        }
                        mixer.setEnabled(sound, on: new)
                    }
                ))
                .labelsHidden()
                .tint(c.primary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(c.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tipCard: some View {
        let c = theme.colors
        let tip = DailyTips.tipForToday()
        return HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Günün ipucu")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.tertiary)
                Text(tip.title)
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.onSurface)
                Text(tip.message)
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.onSurfaceVariant)
            }
            Image(systemName: tip.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(c.primary.opacity(0.35))
        }
        .padding(DesignTokens.Spacing.lg)
        .background(c.surfaceContainerHigh.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
    }

    private func profilePlaylist(active: ChildProfile?) -> [Story] {
        stories.filter { $0.profile?.id == active?.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func presentPlayer(story: Story, active: ChildProfile?) {
        playerPresentation = PresentedStory(startStory: story, playlist: profilePlaylist(active: active))
    }

    private func toggleFavorite(_ s: Story) {
        s.isFavorite.toggle()
        try? modelContext.save()
    }

    private func deleteStory(_ s: Story) {
        if let name = s.audioFileName {
            try? AudioCacheManager.removeFile(named: name)
        }
        modelContext.delete(s)
        try? modelContext.save()
    }

    @MainActor
    private func generateStory(profile: ChildProfile?) async {
        guard let profile else { return }
        let prefs = StoryPreferences.load(for: profile)
        guard subscription.canUseNarrator(prefs.narrator) else {
            showPaywall = true
            return
        }
        guard subscription.canGenerateStory(storiesCreatedTodayFromStore: storiesCreatedTodayCount) else { return }
        isGenerating = true
        defer { isGenerating = false }

        do {
            if AppConfiguration.proxyBaseURL == nil {
                let demoLen = prefs.length.targetListeningDurationSeconds
                let demo = Story(
                    title: "Yıldız Tozu Yolculuğu",
                    body: "Bir varmış bir yokmuş, \(profile.name) adında cesur bir çocuk varmış. Her gece yıldızlar ona fısıldarmış ve rüyalarına yolculuk etmiş. Bu gece de huzurla uyumuş ve sabaha kadar güzel rüyalar görmüş.",
                    durationSeconds: demoLen,
                    audioFileName: nil,
                    genre: .calming,
                    generationModel: "demo-local",
                    profile: profile
                )
                modelContext.insert(demo)
                subscription.registerStoryGenerated(modelContext: modelContext)
                try modelContext.save()
                playerPresentation = PresentedStory(startStory: demo, playlist: profilePlaylist(active: profile))
                return
            }

            let voice = StoryPreferences.resolvedVoiceID(for: profile)
            let result = try await storyService.generateStoryAndAudio(
                profile: profile,
                voiceID: voice,
                authToken: AppConfiguration.proxyAuthToken
            )
            let genre = StoryGenre(rawValue: result.story.genre) ?? .adventure
            let story = Story(
                title: result.story.title,
                body: result.story.body,
                durationSeconds: prefs.length.targetListeningDurationSeconds,
                audioFileName: nil,
                genre: genre,
                generationModel: result.story.model ?? "unknown",
                profile: profile
            )
            modelContext.insert(story)
            let fileName = try AudioCacheManager.save(data: result.audioData, storyID: story.id, extension: "mp3")
            story.audioFileName = fileName
            story.audioBlob = result.audioData
            subscription.registerStoryGenerated(modelContext: modelContext)
            try modelContext.save()
            playerPresentation = PresentedStory(startStory: story, playlist: profilePlaylist(active: profile))
        } catch {
            generationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
