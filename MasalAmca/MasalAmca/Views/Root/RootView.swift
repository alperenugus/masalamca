//
//  RootView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager
    @AppStorage("onboarding_complete") private var onboardingComplete = false

    @Query(filter: #Predicate<AppSyncState> { $0.singletonKey == "app" }) private var appSyncRows: [AppSyncState]
    @Query(sort: \ChildProfile.createdAt) private var childProfiles: [ChildProfile]

    @Bindable var subscription: SubscriptionManager
    @Bindable var audioPlayer: AudioPlayerService
    @Bindable var mixer: MixerEngine
    @Bindable var pinStore: MixerPinStore
    @Bindable var toastCenter: ToastCenter
    var volumeMonitor: VolumeMonitor

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if onboardingComplete {
                    MainTabView(
                        subscription: subscription,
                        audioPlayer: audioPlayer,
                        mixer: mixer,
                        pinStore: pinStore
                    )
                } else {
                    OnboardingView(subscription: subscription, isComplete: $onboardingComplete)
                }
            }
            if let msg = toastCenter.message {
                MasalToastBanner(text: msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: toastCenter.message)
        .preferredColorScheme(.dark)
        .tint(theme.colors.primary)
        .environment(\.masalToastCenter, toastCenter)
        .environment(\.masalVolumeMonitor, volumeMonitor)
        .environment(\.masalMixerPinStore, pinStore)
        .environment(\.masalAudioPlayer, audioPlayer)
        .task {
            hydrateFromSwiftData()
        }
        .onChange(of: appSyncRows) { _, _ in
            hydrateFromSwiftData()
        }
        .onChange(of: childProfiles.count) { _, _ in
            hydrateFromSwiftData()
        }
        .onChange(of: profileManager.activeProfileID) { _, _ in
            mirrorPlaybackPreferencesForActiveChild()
            Task { await resyncBedtimeNotifications() }
        }
    }

    private func hydrateFromSwiftData() {
        let sync = AppSyncPersistence.ensureAppSyncState(modelContext: modelContext)
        subscription.hydrateStoryCountFromCloud(sync.storiesGeneratedCount)
        applyCloudActiveProfileIfNeeded(sync)
        mirrorPlaybackPreferencesForActiveChild()
        Task { await resyncBedtimeNotifications() }
    }

    private func resyncBedtimeNotifications() async {
        let active = profileManager.activeProfile(from: childProfiles)
        await BedtimeNotificationService.syncBedtimeReminders(activeProfile: active)
    }

    private func applyCloudActiveProfileIfNeeded(_ sync: AppSyncState) {
        guard let s = sync.activeProfileUUIDString,
              let uuid = UUID(uuidString: s),
              childProfiles.contains(where: { $0.id == uuid }) else { return }
        if profileManager.activeProfileID != uuid {
            profileManager.activeProfileID = uuid
        }
    }

    private func mirrorPlaybackPreferencesForActiveChild() {
        let active = profileManager.activeProfile(from: childProfiles)
        StoryPreferences.mirrorPlaybackPreferencesToUserDefaults(for: active)
    }
}
