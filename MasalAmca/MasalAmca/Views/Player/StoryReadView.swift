//
//  StoryReadView.swift
//  MasalAmca
//
//  Tasarım: DesignProposal/story_read_view/code.html
//

import SwiftUI

struct StoryReadView: View {
    @Environment(\.masalThemeManager) private var theme
    let story: Story
    var onFinish: () -> Void

    @AppStorage("masal_story_read_font_step") private var fontStepRaw: Int = 0

    private var fontScale: CGFloat {
        switch fontStepRaw % 3 {
        case 0: return 1.0
        case 1: return 1.12
        default: return 1.26
        }
    }

    private var paragraphs: [String] {
        story.body
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var readingMinutes: Int {
        max(1, story.durationSeconds / 60)
    }

    var body: some View {
        let c = theme.colors
        VStack(spacing: 0) {
            topBar(c: c)
            GeometryReader { _ in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            readHero(c: c)
                                .padding(.top, DesignTokens.Spacing.md)

                            articleBody(c: c)
                                .padding(.top, DesignTokens.Spacing.xl)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.bottom, 120)
                    }

                    bottomChrome(c: c)
                }
            }
        }
        .background(c.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .id(story.id)
    }

    private func topBar(c: DreamscapePalette) -> some View {
        HStack {
            Button {
                onFinish()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(c.primary.opacity(0.85))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text(story.title)
                .font(MasalFont.titleMedium())
                .foregroundStyle(c.primary)
                .lineLimit(1)

            Spacer()

            Button {
                fontStepRaw = (fontStepRaw + 1) % 3
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "textformat.size")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(c.primary.opacity(0.85))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Yazı boyutu")
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, 12)
        .background(c.surface.opacity(0.98))
    }

    private func readHero(c: DreamscapePalette) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(c.surfaceContainerHigh)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(c.primary.opacity(0.4))
                }
            LinearGradient(
                colors: [c.surface.opacity(0.98), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))

            Text("\(readingMinutes) Dakika Okuma")
                .font(MasalFont.labelMedium())
                .foregroundStyle(c.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(c.surfaceContainerHighest.opacity(0.55))
                .background(.ultraThinMaterial, in: Capsule())
                .padding(DesignTokens.Spacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private func articleBody(c: DreamscapePalette) -> some View {
        let parts = paragraphs
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            HStack {
                Spacer()
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundStyle(c.tertiary.opacity(0.85))
                Spacer()
            }

            ForEach(Array(parts.enumerated()), id: \.offset) { index, para in
                if index > 0, index == parts.count / 2 {
                    nightsDivider(c: c)
                }
                paragraphView(para, index: index, count: parts.count, c: c)
            }

            HStack {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(c.tertiary.opacity(0.45))
                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
    }

    private func nightsDivider(c: DreamscapePalette) -> some View {
        HStack {
            Spacer(minLength: 0)
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(c.primary.opacity(0.35))
            Spacer(minLength: 0)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    @ViewBuilder
    private func paragraphView(_ text: String, index: Int, count: Int, c: DreamscapePalette) -> some View {
        if isPullQuote(text) {
            pullQuoteBlock(pullQuoteInner(text), c: c)
        } else if index == 0 && count > 1 {
            Text(text)
                .font(.custom(MasalFont.headlineFamily, size: 30 * fontScale, relativeTo: .title2).weight(.bold))
                .foregroundStyle(c.onSurface)
                .lineSpacing(8 * fontScale)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
                .font(.custom(MasalFont.bodyFamily, size: 20 * fontScale, relativeTo: .title3).weight(.regular))
                .foregroundStyle(c.secondary.opacity(0.92))
                .lineSpacing(10 * fontScale)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func isPullQuote(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > 6, t.hasPrefix("\""), t.hasSuffix("\"") else { return false }
        return true
    }

    private func pullQuoteInner(_ t: String) -> String {
        var u = t.trimmingCharacters(in: .whitespacesAndNewlines)
        if u.hasPrefix("\"") { u.removeFirst() }
        if u.hasSuffix("\"") { u.removeLast() }
        return u.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func pullQuoteBlock(_ inner: String, c: DreamscapePalette) -> some View {
        Text("“\(inner)”")
            .font(.custom(MasalFont.bodyFamily, size: 18 * fontScale, relativeTo: .body).weight(.medium))
            .italic()
            .foregroundStyle(c.primary.opacity(0.82))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(c.surfaceContainerLow)
                    Circle()
                        .fill(c.primary.opacity(0.08))
                        .frame(width: 96, height: 96)
                        .offset(x: 40, y: -36)
                        .blur(radius: 28)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private func bottomChrome(c: DreamscapePalette) -> some View {
        HStack {
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onFinish()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Bitir")
                        .font(MasalFont.labelMedium())
                        .fontWeight(.bold)
                }
                .foregroundStyle(c.onPrimaryContainer)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [c.primaryContainer, c.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: c.ctaShadow, radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
        .background(c.surfaceContainer.opacity(0.78))
        .background(.ultraThinMaterial)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.Radius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: DesignTokens.Radius.xl,
                style: .continuous
            )
        )
        .shadow(color: c.ctaShadow.opacity(0.35), radius: 20, x: 0, y: -8)
    }
}
