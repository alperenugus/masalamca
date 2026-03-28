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
    @Bindable var mixer: MixerEngine

    @State private var tab: MainTab = .home

    var body: some View {
        let c = theme.colors
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeView(subscription: subscription, mixer: mixer, tabSelection: $tab)
                case .library:
                    LibraryView(subscription: subscription, mixer: mixer)
                case .settings:
                    SettingsView(subscription: subscription)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DreamscapeTabBar(selection: $tab)
        }
        .background(c.surface.ignoresSafeArea())
        .task {
            AppSyncPersistence.persistActiveProfileID(profileManager.activeProfileID, modelContext: modelContext)
        }
        .onChange(of: profileManager.activeProfileID) { _, new in
            AppSyncPersistence.persistActiveProfileID(new, modelContext: modelContext)
        }
    }
}
