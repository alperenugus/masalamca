//
//  MasalAmcaApp.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

@main
struct MasalAmcaApp: App {
    @State private var themeManager = ThemeManager()
    @State private var childProfileManager = ChildProfileManager()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var mixerEngine = MixerEngine()
    @State private var mixerPinStore = MixerPinStore()

    private static let modelContainer: ModelContainer = {
        let schema = Schema([ChildProfile.self, Story.self, AppSyncState.self])
        let cloud = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
            return container
        }
        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(subscription: subscriptionManager, mixer: mixerEngine, pinStore: mixerPinStore)
                .modelContainer(Self.modelContainer)
                .masalThemeManager(themeManager)
                .masalChildProfileManager(childProfileManager)
                .environment(subscriptionManager)
                .environment(mixerEngine)
        }
    }
}
