//
//  VoiceVisualizerView.swift
//  MasalAmca
//

import SwiftUI

struct VoiceVisualizerView: View {
    @Environment(\.masalThemeManager) private var theme
    let isActive: Bool
    let barCount: Int = 12

    var body: some View {
        let c = theme.colors
        TimelineView(.animation(minimumInterval: 0.12, paused: !isActive)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 4) {
                ForEach(0 ..< barCount, id: \.self) { i in
                    let phase = t + Double(i) * 0.35
                    let h = 12 + abs(sin(phase * 2.5)) * 28 + Double(i % 3) * 4
                    Capsule()
                        .fill(c.primary.opacity(0.35 + Double(i % 4) * 0.12))
                        .frame(width: 5, height: CGFloat(h))
                }
            }
            .frame(height: 56)
        }
    }
}
