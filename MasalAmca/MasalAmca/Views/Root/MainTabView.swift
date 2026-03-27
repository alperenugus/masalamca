//
//  MainTabView.swift
//  MasalAmca
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.masalThemeManager) private var theme
    @Bindable var subscription: SubscriptionManager
    @Bindable var mixer: MixerEngine

    @State private var tab: MainTab = .home

    var body: some View {
        let c = theme.colors
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeView(subscription: subscription, mixer: mixer)
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
    }
}
