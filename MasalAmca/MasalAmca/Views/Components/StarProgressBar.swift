//
//  StarProgressBar.swift
//  MasalAmca
//

import SwiftUI

struct StarProgressBar: View {
    @Environment(\.masalThemeManager) private var theme
    /// 0...1
    var progress: CGFloat
    var onSeek: ((CGFloat) -> Void)?

    var body: some View {
        let c = theme.colors
        GeometryReader { geo in
            let w = geo.size.width
            let fillW = max(0, min(1, progress)) * w
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(c.surfaceContainer)
                    .frame(height: 6)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [c.primaryContainer, c.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillW, height: 6)
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(c.tertiary)
                    .shadow(color: c.tertiary.opacity(0.6), radius: 6)
                    .offset(x: max(0, fillW - 10), y: 0)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = value.location.x / w
                        onSeek?(CGFloat(max(0, min(1, p))))
                    }
            )
        }
        .frame(height: 24)
    }
}
