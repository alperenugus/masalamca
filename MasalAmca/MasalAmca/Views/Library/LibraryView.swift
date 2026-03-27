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
    @State private var playerStory: Story?
    @State private var showPlayer = false
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
        let recent = filtered.prefix(5)
        let older = Array(filtered.dropFirst(5))

        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                navBar
                searchAndChips
                if !recent.isEmpty {
                    sectionTitle("Son Dinlenenler")
                    storyGroup(Array(recent))
                }
                if !older.isEmpty {
                    sectionTitle("Eski Masallar")
                    storyGroup(older)
                }
                if filtered.isEmpty {
                    Text("Masal bulunamadı.")
                        .font(MasalFont.bodyLarge())
                        .foregroundStyle(c.secondary)
                        .padding(.top, 24)
                }
                statsBento
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, 120)
        }
        .background(c.surface.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPlayer, onDismiss: { playerStory = nil }) {
            if let story = playerStory {
                StoryPlayerView(audio: storyAudio, mixer: mixer, subscription: subscription, story: story)
                    .masalThemeManager(theme)
            }
        }
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
            .padding(.horizontal, 4)
    }

    private func storyGroup(_ items: [Story]) -> some View {
        let c = theme.colors
        return VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { idx, s in
                Button {
                    playerStory = s
                    showPlayer = true
                } label: {
                    StoryListRow(
                        title: s.title,
                        durationText: "\(max(1, s.durationSeconds / 60)) dk",
                        dateText: df.string(from: s.createdAt),
                        showCloud: true,
                        systemImageName: "moon.stars"
                    )
                }
                .buttonStyle(.plain)
                if idx < items.count - 1 {
                    Color.clear.frame(height: 1)
                        .background(c.surfaceContainerHighest.opacity(0.35))
                }
            }
        }
        .background(c.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous))
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
