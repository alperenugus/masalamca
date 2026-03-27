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

    @Bindable var subscription: SubscriptionManager

    @Query private var profiles: [ChildProfile]
    @State private var showPaywall = false
    @State private var showEditor = false

    var body: some View {
        let c = theme.colors
        NavigationStack {
            List {
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
                    .onDelete(perform: deleteProfiles)
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
            }
            .scrollContentBackground(.hidden)
            .background(c.surface)
            .navigationTitle("Ayarlar")
            .toolbarBackground(c.surface, for: .navigationBar)
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
        for i in offsets {
            let p = profiles[i]
            if profileManager.activeProfileID == p.id {
                profileManager.activeProfileID = nil
            }
            modelContext.delete(p)
        }
        try? modelContext.save()
    }
}
