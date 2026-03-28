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
    @Bindable var mixer: MixerEngine

    var body: some View {
        Group {
            if onboardingComplete {
                MainTabView(subscription: subscription, mixer: mixer)
            } else {
                OnboardingView(subscription: subscription, isComplete: $onboardingComplete)
            }
        }
        .preferredColorScheme(.dark)
        .tint(theme.colors.primary)
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
        }
    }

    private func hydrateFromSwiftData() {
        let sync = AppSyncPersistence.ensureAppSyncState(modelContext: modelContext)
        subscription.hydrateStoryCountFromCloud(sync.storiesGeneratedCount)
        applyCloudActiveProfileIfNeeded(sync)
        mirrorPlaybackPreferencesForActiveChild()
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
