//
//  StoryPlaybackLiveActivityWidget.swift
//  MasalAmcaWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen + Dynamic Island UI for story playback and sleep timer.
struct StoryPlaybackLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MasalAmcaPlaybackAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Masal Amca")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if context.state.isPlaying {
                        Label("Oynatılıyor", systemImage: "play.fill")
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                    } else {
                        Label("Duraklatıldı", systemImage: "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(context.state.storyTitle)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                Text(context.state.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if context.state.durationSeconds > 1 {
                    ProgressView(
                        value: min(1, context.state.elapsedSeconds / context.state.durationSeconds)
                    )
                    .tint(.indigo)
                }
                if let end = context.state.sleepTimerEnd {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(.orange)
                        Text("Uyku zamanlayıcı: ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(end, style: .timer)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.05, green: 0.08, blue: 0.15))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.indigo)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = context.state.sleepTimerEnd {
                        VStack(alignment: .trailing) {
                            Text("Uyku")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(end, style: .timer)
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.storyTitle)
                            .font(.headline)
                            .lineLimit(2)
                        Text(context.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if context.state.durationSeconds > 1 {
                            ProgressView(
                                value: min(1, context.state.elapsedSeconds / context.state.durationSeconds)
                            )
                            .tint(.indigo)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.indigo)
            } compactTrailing: {
                if context.state.isPlaying {
                    Image(systemName: "play.fill")
                } else {
                    Image(systemName: "pause.fill")
                }
            } minimal: {
                Image(systemName: "moon.stars.fill")
            }
        }
    }
}
