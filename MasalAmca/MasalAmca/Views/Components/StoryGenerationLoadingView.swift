//
//  StoryGenerationLoadingView.swift
//  MasalAmca
//
//  Visual match: DesignProposal/loader/code.html
//

import SwiftUI

struct StoryGenerationLoadingView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let c = theme.colors
        ZStack {
            LinearGradient(
                colors: [c.surface, c.surfaceContainerLow, c.surfaceContainerHigh],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(c.primary.opacity(0.1))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -120)

            Circle()
                .fill(c.tertiary.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 100, y: 160)

            if reduceMotion {
                staticContent(c: c)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    animatedContent(c: c, t: t)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Masal oluşturuluyor, lütfen bekleyin")
    }

    @ViewBuilder
    private func staticContent(c: DreamscapePalette) -> some View {
        VStack(spacing: 0) {
            Spacer()
            centerpiece(c: c, orbitAngle: 0, coreScale: 1)
            Spacer().frame(height: 48)
            messagingBlock(c: c, textOffset: 0, barShift: 0.5)
            Spacer()
            bottomPill(c: c)
                .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private func animatedContent(c: DreamscapePalette, t: TimeInterval) -> some View {
        let orbit = (t.truncatingRemainder(dividingBy: 8)) / 8 * 360
        let coreScale = 1 + 0.05 * sin(t * 2 * .pi / 3)
        let barShift = 0.5 + 0.5 * sin(t * 1.15)
        let textOffset = -6 * sin(t * 2 * .pi / 4)

        VStack(spacing: 0) {
            Spacer()
            centerpiece(c: c, orbitAngle: orbit, coreScale: CGFloat(coreScale))
            Spacer().frame(height: 48)
            messagingBlock(c: c, textOffset: textOffset, barShift: CGFloat(barShift))
            Spacer()
            bottomPill(c: c)
                .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private func centerpiece(c: DreamscapePalette, orbitAngle: Double, coreScale: CGFloat) -> some View {
        ZStack {
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    orbitIcon(index: i, c: c)
                        .rotationEffect(.degrees(-orbitAngle - Double(i) * 90))
                        .offset(y: -72)
                        .rotationEffect(.degrees(orbitAngle + Double(i) * 90))
                }
            }
            .frame(width: 200, height: 200)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(c.primary.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .opacity(0.5)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .frame(width: 128, height: 128)
                    .overlay {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [c.primaryContainer, c.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: c.primaryContainer.opacity(0.4), radius: 30, x: 0, y: 8)
                    .scaleEffect(coreScale)
            }
        }
        .frame(height: 220)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func orbitIcon(index: Int, c: DreamscapePalette) -> some View {
        let symbols = ["sparkles", "star.fill", "sparkles", "star"]
        let colors: [Color] = [
            c.tertiary,
            c.primary.opacity(0.6),
            c.tertiary.opacity(0.8),
            c.primaryFixed
        ]
        let sizes: [CGFloat] = [22, 18, 18, 14]
        Image(systemName: symbols[index])
            .font(.system(size: sizes[index], weight: .medium))
            .foregroundStyle(colors[index])
    }

    @ViewBuilder
    private func messagingBlock(c: DreamscapePalette, textOffset: CGFloat, barShift: CGFloat) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Text("Masal Amca rüyalardan ilham alıyor...")
                .font(MasalFont.headlineMedium())
                .multilineTextAlignment(.center)
                .foregroundStyle(c.onPrimaryContainer)
                .offset(y: textOffset)

            loadingBar(c: c, barShift: barShift)

            Text("Bu işlem bir dakika veya daha kısa sürebilir!")
                .font(MasalFont.bodyMedium())
                .foregroundStyle(c.secondary.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }

    /// `barShift` in 0...1 — sweeps the glowing fill for an indeterminate feel.
    @ViewBuilder
    private func loadingBar(c: DreamscapePalette, barShift: CGFloat) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(c.surfaceContainerHigh)
                    .frame(height: 8)

                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [c.tertiary, c.primary, c.primaryContainer],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(100, w * 0.72), height: 8)
                    .clipShape(Capsule())
                    .shadow(color: c.tertiary.opacity(0.35), radius: 8, x: 0, y: 0)
                }
                .offset(x: CGFloat(barShift) * (w * 0.28) - w * 0.08)
                .mask {
                    Capsule()
                        .frame(height: 8)
                }

                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(c.tertiary)
                    .position(x: min(w * 0.72, w - 14), y: 12)
            }
            .frame(height: 24)
        }
        .frame(height: 24)
    }

    private func bottomPill(c: DreamscapePalette) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "text.book.closed")
                .font(.caption)
                .foregroundStyle(c.primary)
            Text("Sihirli Anlatıcı Hazırlanıyor")
                .font(MasalFont.labelSmall())
                .tracking(1.2)
                .foregroundStyle(c.onSurfaceVariant)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(c.surfaceContainerHigh.opacity(0.55))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(c.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}
