//
//  NowPlayingWidget.swift
//  MasalAmcaWidget
//

import SwiftUI
import WidgetKit

struct NowPlayingWidget: Widget {
    /// Must match `PlaybackWidgetStore.widgetKind` in the main app.
    var kind: String { "NowPlayingWidget" }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingTimelineProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Şimdi dinleniyor")
        .description("Masal oynatıcı ve uyku zamanlayıcısı özeti.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let isPlaying: Bool
    let elapsed: Double
    let duration: Double
    let sleepTimerEnd: Date?
    let hasSession: Bool
}

struct NowPlayingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(
            date: Date(),
            title: "Masal Amca",
            subtitle: "Masal seçin",
            isPlaying: false,
            elapsed: 0,
            duration: 1,
            sleepTimerEnd: nil,
            hasSession: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        let entry = readEntry()
        let next = Date().addingTimeInterval(entry.hasSession ? 30 : 3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> NowPlayingEntry {
        let d = UserDefaults(suiteName: PlaybackWidgetAppGroup.id)
        let has = d?.bool(forKey: "widget.hasSession") ?? false
        let title = d?.string(forKey: "widget.storyTitle") ?? "Masal Amca"
        let subtitle = d?.string(forKey: "widget.subtitle") ?? "Uygulamada masal açın"
        let playing = d?.bool(forKey: "widget.isPlaying") ?? false
        let elapsed = d?.double(forKey: "widget.elapsed") ?? 0
        let duration = max(d?.double(forKey: "widget.duration") ?? 1, 1)
        let sleepRaw = d?.double(forKey: "widget.sleepEnd")
        let sleepEnd = sleepRaw.map { Date(timeIntervalSince1970: $0) }
        return NowPlayingEntry(
            date: Date(),
            title: title,
            subtitle: subtitle,
            isPlaying: playing,
            elapsed: elapsed,
            duration: duration,
            sleepTimerEnd: sleepEnd,
            hasSession: has
        )
    }
}

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: NowPlayingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.isPlaying ? "waveform" : "moon.stars.fill")
                    .foregroundStyle(.indigo)
                Spacer()
            }
            Text(entry.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(entry.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let end = entry.sleepTimerEnd, entry.hasSession {
                Label {
                    Text(end, style: .timer)
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                }
                .font(.caption2)
                .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color(red: 0.02, green: 0.075, blue: 0.16)
        }
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                Text(entry.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if entry.duration > 1, entry.hasSession {
                    ProgressView(value: min(1, entry.elapsed / entry.duration))
                        .tint(.indigo)
                }
            }
            Spacer()
            if let end = entry.sleepTimerEnd, entry.hasSession {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Uyku zamanlayıcı")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(end, style: .timer)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color(red: 0.02, green: 0.075, blue: 0.16)
        }
    }
}
