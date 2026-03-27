//
//  RootView.swift
//  MasalAmca
//

import SwiftUI

struct RootView: View {
    @Environment(\.masalThemeManager) private var theme
    @AppStorage("onboarding_complete") private var onboardingComplete = false

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
    }
}
