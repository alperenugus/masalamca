//
//  MainTabView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager
    @Bindable var subscription: SubscriptionManager
    @Bindable var audioPlayer: AudioPlayerService
    @Bindable var mixer: MixerEngine
    @Bindable var pinStore: MixerPinStore

    @State private var tab: MainTab = .home
    @State private var playerPresentation: PresentedStory?
    @State private var lastMiniPlayerMode: MiniPlayerMode = .hidden

    private var miniPlayerMode: MiniPlayerMode {
        let storyPlayerPushed = playerPresentation != nil
        let storyLoaded = audioPlayer.hasActiveTrack
        let noiseActive = MixerSound.allCases.contains { mixer.enabled[$0] == true }
        let onNoiseTab = tab == .noise

        // Always hide when the full story player is on screen
        if storyPlayerPushed {
            return .hidden
        }

        if storyLoaded {
            return .story
        }
        if noiseActive, !onNoiseTab {
            return .whiteNoise
        }
        // Keep showing after pause/stop
        if lastMiniPlayerMode == .story, audioPlayer.currentStoryID != nil {
            return .story
        }
        if lastMiniPlayerMode == .whiteNoise, !onNoiseTab {
            return .whiteNoise
        }
        return .hidden
    }

    var body: some View {
        let c = theme.colors
        let playerVisible = playerPresentation != nil
        let showMini = miniPlayerMode != .hidden
        ZStack(alignment: .bottom) {
            ZStack {
                NavigationStack {
                    HomeView(
                        subscription: subscription,
                        mixer: mixer,
                        pinStore: pinStore,
                        tabSelection: $tab,
                        playerPresentation: $playerPresentation
                    )
                }
                .opacity(tab == .home ? 1 : 0)
                .allowsHitTesting(tab == .home)

                NavigationStack {
                    LibraryView(
                        subscription: subscription,
                        mixer: mixer,
                        playerPresentation: $playerPresentation
                    )
                }
                .opacity(tab == .library ? 1 : 0)
                .allowsHitTesting(tab == .library)

                WhiteNoisePlayerView(subscription: subscription, mixer: mixer, pinStore: pinStore)
                    .opacity(tab == .noise ? 1 : 0)
                    .allowsHitTesting(tab == .noise)

                SettingsView(subscription: subscription)
                    .opacity(tab == .settings ? 1 : 0)
                    .allowsHitTesting(tab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                if showMini {
                    MiniPlayerBar(
                        audio: audioPlayer,
                        mixer: mixer,
                        mode: miniPlayerMode,
                        onTap: { handleMiniPlayerTap() }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                DreamscapeTabBar(selection: $tab)
                    .opacity(playerVisible ? 0 : 1)
                    .allowsHitTesting(!playerVisible)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: showMini)
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: playerVisible)
        }
        .background(c.surface.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
        .task {
            AppSyncPersistence.persistActiveProfileID(profileManager.activeProfileID, modelContext: modelContext)
        }
        .onChange(of: profileManager.activeProfileID) { _, new in
            AppSyncPersistence.persistActiveProfileID(new, modelContext: modelContext)
        }
        .onChange(of: audioPlayer.hasActiveTrack) { _, active in
            mixer.storyIsActive = active
        }
        .onChange(of: miniPlayerMode) { _, newMode in
            if newMode != .hidden {
                lastMiniPlayerMode = newMode
            }
        }
    }

    private func handleMiniPlayerTap() {
        switch miniPlayerMode {
        case .story:
            if let id = audioPlayer.currentStoryID,
               let story = audioPlayer.playlist.first(where: { $0.id == id }) {
                let presentation = PresentedStory(startStory: story, playlist: audioPlayer.playlist)
                if tab == .home || tab == .library {
                    playerPresentation = presentation
                } else {
                    tab = .home
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        playerPresentation = presentation
                    }
                }
            }
        case .whiteNoise:
            tab = .noise
        case .hidden:
            break
        }
    }
}
