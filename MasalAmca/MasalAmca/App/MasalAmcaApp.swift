//
//  MasalAmcaApp.swift
//  MasalAmca
//

import SwiftData
import SwiftUI
import AVFoundation

@main
struct MasalAmcaApp: App {
    init() {
        BedtimeNotificationCenter.shared.install()
        let session = AVAudioSession.sharedInstance()
        // Centralized audio session configuration to avoid mid-playback category/mode churn.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay, .allowBluetoothA2DP])
        try? session.setActive(true)
    }

    @State private var themeManager = ThemeManager()
    @State private var childProfileManager = ChildProfileManager()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var mixerEngine = MixerEngine()
    @State private var mixerPinStore = MixerPinStore()
    @State private var toastCenter = ToastCenter()
    @State private var volumeMonitor = VolumeMonitor()

    private static let modelContainer: ModelContainer = {
        let schema = Schema([ChildProfile.self, Story.self, AppSyncState.self])
        // NOTE: CloudKit-backed SwiftData requires a CloudKit-compatible schema (no unique constraints,
        // all relationships optional, and defaults for non-optional attributes). Our current models
        // are not compatible yet, so we force local storage to avoid runtime store load failures.
        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(
                subscription: subscriptionManager,
                mixer: mixerEngine,
                pinStore: mixerPinStore,
                toastCenter: toastCenter,
                volumeMonitor: volumeMonitor
            )
            .modelContainer(Self.modelContainer)
            .masalThemeManager(themeManager)
            .masalChildProfileManager(childProfileManager)
            .environment(subscriptionManager)
            .environment(mixerEngine)
        }
    }
}
