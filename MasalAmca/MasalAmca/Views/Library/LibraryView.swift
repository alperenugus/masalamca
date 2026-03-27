//
//  LibraryView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager

    @Bindable var subscription: SubscriptionManager
    @Bindable var mixer: MixerEngine

    @Query(sort: \Story.createdAt, order: .reverse) private var stories: [Story]
    @Query private var profiles: [ChildProfile]

    @State private var search = ""
    @State private var filter: LibraryFilter = .all
    @State private var playerPresentation: PresentedStory?
    @State private var storyAudio = AudioPlayerService()

    private var df: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        let filtered = filteredStories(active: active)
        let recent = Array(filtered.prefix(5))
        let older = Array(filtered.dropFirst(5))

        List {
            Section {
                navBar
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                searchAndChips
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if !recent.isEmpty {
                Section {
                    ForEach(recent, id: \.persistentModelID) { s in
                        storyListRow(s, active: active)
                    }
                } header: {
                    sectionTitle("Son Dinlenenler")
                }
                .listRowSeparator(.hidden)
            }

            if !older.isEmpty {
                Section {
                    ForEach(older, id: \.persistentModelID) { s in
                        storyListRow(s, active: active)
                    }
                } header: {
                    sectionTitle("Eski Masallar")
                }
                .listRowSeparator(.hidden)
            }

            if filtered.isEmpty {
                Section {
                    Text("Masal bulunamadı.")
                        .font(MasalFont.bodyLarge())
                        .foregroundStyle(c.secondary)
                        .listRowBackground(Color.clear)
                }
                .listRowSeparator(.hidden)
            }

            Section {
                statsBento
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 24, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(c.surface.ignoresSafeArea())
        .fullScreenCover(item: $playerPresentation, onDismiss: { storyAudio.stop() }) { wrap in
            StoryPlayerView(
                audio: storyAudio,
                mixer: mixer,
                subscription: subscription,
                startStory: wrap.startStory,
                playlist: wrap.playlist
            )
            .masalThemeManager(theme)
        }
    }

    @ViewBuilder
    private func storyListRow(_ s: Story, active: ChildProfile?) -> some View {
        let playlist = playlistForProfile(active: active)
        Button {
            playerPresentation = PresentedStory(startStory: s, playlist: playlist)
        } label: {
            StoryListRow(
                title: s.title,
                durationText: "\(max(1, s.durationSeconds / 60)) dk",
                dateText: df.string(from: s.createdAt),
                showCloud: true,
                systemImageName: "moon.stars",
                isFavorite: s.isFavorite,
                onFavoriteToggle: { toggleFavorite(s) }
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(theme.colors.surfaceContainer)
        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteStory(s)
            } label: {
                Label("Sil", systemImage: "trash.fill")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleFavorite(s)
            } label: {
                Label(
                    s.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                    systemImage: s.isFavorite ? "star.slash.fill" : "star.fill"
                )
            }
            .tint(theme.colors.tertiary)
        }
    }

    private func playlistForProfile(active: ChildProfile?) -> [Story] {
        stories.filter { $0.profile?.id == active?.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func toggleFavorite(_ s: Story) {
        s.isFavorite.toggle()
        try? modelContext.save()
    }

    private func deleteStory(_ s: Story) {
        if let name = s.audioFileName {
            try? AudioCacheManager.removeFile(named: name)
        }
        modelContext.delete(s)
        try? modelContext.save()
    }

    private var navBar: some View {
        let c = theme.colors
        return HStack {
            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .foregroundStyle(c.primary)
                Text("Kitaplık")
                    .font(MasalFont.titleMedium())
                    .foregroundStyle(c.primary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(c.tertiary)
                Text("Bulut Eşlendi")
                    .font(MasalFont.labelSmall())
                    .foregroundStyle(c.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(c.surfaceContainerHigh)
            .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    private var searchAndChips: some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(c.outline)
                TextField("Masallarda ara...", text: $search)
                    .foregroundStyle(c.onSurface)
            }
            .padding(DesignTokens.Spacing.md)
            .background(c.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LibraryFilter.allCases) { f in
                        Button {
                            filter = f
                        } label: {
                            Text(f.title)
                                .font(MasalFont.bodyMedium())
                                .fontWeight(filter == f ? .bold : .medium)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(filter == f ? c.primary : c.surfaceContainerHigh)
                                )
                                .foregroundStyle(filter == f ? c.onPrimary : c.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(MasalFont.labelMedium())
            .foregroundStyle(theme.colors.secondary.opacity(0.65))
            .textCase(nil)
    }

    private var statsBento: some View {
        let c = theme.colors
        let active = profileManager.activeProfile(from: profiles)
        let mine = stories.filter { $0.profile?.id == active?.id }
        let minutes = mine.reduce(0) { $0 + max(1, $1.durationSeconds / 60) }
        return HStack(spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .foregroundStyle(c.primary)
                Text("\(mine.count)")
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onPrimaryContainer)
                Text("Toplam Masal")
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(c.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.lg)
            .background(c.primaryContainer.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(c.primary.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(c.tertiary)
                Text("\(minutes)")
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onSurface)
                Text("Dakika Dinlendi")
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(c.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.lg)
            .background(c.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        }
        .padding(.top, 8)
    }

    private func filteredStories(active: ChildProfile?) -> [Story] {
        var list = stories.filter { $0.profile?.id == active?.id }
        if !search.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(search) }
        }
        switch filter {
        case .all: break
        case .favorites: list = list.filter(\.isFavorite)
        case .sleep: list = list.filter { $0.genre == .calming }
        case .adventure: list = list.filter { $0.genre == .adventure }
        }
        return list
    }
}

private enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, favorites, sleep, adventure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "Tümü"
        case .favorites: "Favoriler"
        case .sleep: "Uyku"
        case .adventure: "Macera"
        }
    }
}
