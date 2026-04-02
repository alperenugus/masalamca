//
//  SettingsView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager
    @AppStorage("onboarding_complete") private var onboardingComplete = false

    @Bindable var subscription: SubscriptionManager

    @Query private var profiles: [ChildProfile]
    @State private var showPaywall = false
    @State private var showEditor = false
    @State private var pendingProfileDeleteOffsets: IndexSet?

    var body: some View {
        let c = theme.colors
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        StorySettingsView(subscription: subscription)
                            .masalThemeManager(theme)
                    } label: {
                        Label("Masal Ayarları", systemImage: "book.pages.fill")
                    }
                } header: {
                    Text("Masal")
                }
                .listRowBackground(c.surfaceContainer)

                Section {
                    HStack {
                        Text("Premium")
                        Spacer()
                        Text(subscription.isPremium ? "Aktif" : "Ücretsiz")
                            .foregroundStyle(c.secondary)
                    }
                    Button("Aboneliği Yönet") { showPaywall = true }
                    Button("Satın Alımları Geri Yükle") {
                        Task { await subscription.restore() }
                    }
                } header: {
                    Text("Abonelik")
                }
                .listRowBackground(c.surfaceContainer)

                Section {
                    Link(destination: AppLegalURLs.terms) {
                        Label("Kullanım Şartları (EULA)", systemImage: "doc.text")
                    }
                    Link(destination: AppLegalURLs.privacy) {
                        Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                    }
                } header: {
                    Text("Yasal")
                } footer: {
                    Text("Abonelik ve uygulama kullanımı için geçerlidir.")
                        .font(MasalFont.labelSmall())
                }
                .listRowBackground(c.surfaceContainer)

                Section {
                    ForEach(profiles) { p in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(p.name)
                                    .font(MasalFont.bodyMedium())
                                    .foregroundStyle(c.onSurface)
                                Text(p.ageGroup.displayName)
                                    .font(MasalFont.labelMedium())
                                    .foregroundStyle(c.secondary)
                            }
                            Spacer()
                            if profileManager.activeProfile(from: profiles)?.id == p.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(c.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { profileManager.switchTo(p) }
                    }
                    .onDelete { offsets in
                        pendingProfileDeleteOffsets = offsets
                    }
                    Button("Çocuk Ekle / Düzenle") { showEditor = true }
                } header: {
                    Text("Çocuklar")
                }
                .listRowBackground(c.surfaceContainer)

                Section {
                    Text("Masal Amca — AI ile kişiselleştirilmiş Türkçe uyku masalları.")
                        .font(MasalFont.bodyMedium())
                        .foregroundStyle(c.onSurfaceVariant)
                } header: {
                    Text("Hakkında")
                }
                .listRowBackground(c.surfaceContainer)

                #if DEBUG
                Section {
                    Toggle(
                        "Sahte Premium (yerel test)",
                        isOn: Binding(
                            get: { subscription.mockPremiumForLocalTesting },
                            set: { subscription.mockPremiumForLocalTesting = $0 }
                        )
                    )
                    Text("StoreKit olmadan tüm premium özellikleri dener; yalnızca DEBUG derlemelerde görünür.")
                        .font(MasalFont.labelMedium())
                        .foregroundStyle(c.onSurfaceVariant)

                    Toggle(
                        "Sınırsız Masal Üret (yerel test)",
                        isOn: Binding(
                            get: { subscription.unlimitedGenerationForLocalTesting },
                            set: { subscription.unlimitedGenerationForLocalTesting = $0 }
                        )
                    )
                    Text("Kota kontrolünü kapatır (ücretsiz 2 masal ve Premium günlük limit). Yalnızca DEBUG derlemelerde görünür.")
                        .font(MasalFont.labelMedium())
                        .foregroundStyle(c.onSurfaceVariant)
                } header: {
                    Text("Geliştirici")
                }
                .listRowBackground(c.surfaceContainer)
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(c.surface)
            .navigationTitle("Ayarlar")
            .toolbarBackground(c.surface, for: .navigationBar)
            .alert(
                "Çocuğu sil?",
                isPresented: Binding(
                    get: { pendingProfileDeleteOffsets != nil },
                    set: { if !$0 { pendingProfileDeleteOffsets = nil } }
                )
            ) {
                Button("Sil", role: .destructive) {
                    guard let offsets = pendingProfileDeleteOffsets else { return }
                    pendingProfileDeleteOffsets = nil
                    deleteProfiles(at: offsets)
                }
                Button("İptal", role: .cancel) {
                    pendingProfileDeleteOffsets = nil
                }
            } message: {
                let count = pendingProfileDeleteOffsets?.count ?? 1
                Text(
                    count > 1
                        ? "Seçtiğin çocuklar ve onlara ait tüm masallar/indirilen sesler silinecek. Bu işlem geri alınamaz."
                        : "Bu çocuk ve ona ait tüm masallar/indirilen sesler silinecek. Bu işlem geri alınamaz."
                )
            }
            .task {
                await subscription.loadProducts()
                await subscription.refreshEntitlements()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscription: subscription) { showPaywall = false }
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showEditor) {
                ChildProfileEditorView()
                    .masalThemeManager(theme)
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        let activeIDBefore = profileManager.activeProfileID
        let remaining = profiles.enumerated().compactMap { idx, p in
            offsets.contains(idx) ? nil : p
        }
        let deleted = offsets.compactMap { i in
            (profiles.indices.contains(i)) ? profiles[i] : nil
        }

        for i in offsets {
            let p = profiles[i]
            deleteStoriesAndAudio(for: p)
            modelContext.delete(p)
        }
        try? modelContext.save()

        if remaining.isEmpty {
            profileManager.activeProfileID = nil
            onboardingComplete = false
            Task { await BedtimeNotificationService.syncBedtimeReminders(activeProfile: nil) }
            return
        }

        if let activeIDBefore, deleted.contains(where: { $0.id == activeIDBefore }) {
            profileManager.activeProfileID = remaining.first?.id
        }

        Task { @MainActor in
            let active = profileManager.activeProfile(from: remaining)
            await BedtimeNotificationService.syncBedtimeReminders(activeProfile: active)
        }
    }

    private func deleteStoriesAndAudio(for profile: ChildProfile) {
        let profileID = profile.id
        let fd = FetchDescriptor<Story>(predicate: #Predicate { story in
            story.profile?.id == profileID
        })
        let stories = (try? modelContext.fetch(fd)) ?? []
        for s in stories {
            if let name = s.audioFileName {
                try? AudioCacheManager.removeFile(named: name)
            }
            modelContext.delete(s)
        }
    }
}
