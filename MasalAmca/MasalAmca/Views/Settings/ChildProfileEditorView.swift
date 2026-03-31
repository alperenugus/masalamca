//
//  ChildProfileEditorView.swift
//  MasalAmca
//

import SwiftData
import SwiftUI

struct ChildProfileEditorView: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.masalChildProfileManager) private var profileManager

    @State private var name = ""
    @State private var ageGroup: AgeGroup = .twoToFour
    @State private var bentoSelection: Set<StoryBentoTheme> = [.adventure]

    var body: some View {
        let c = theme.colors
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    InputField(title: "Çocuğun İsmi", text: $name, placeholder: "İsim")
                    // reuse age + themes similar to onboarding (compact)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yaş")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary)
                        Picker("Yaş", selection: $ageGroup) {
                            ForEach(AgeGroup.allCases, id: \.self) { g in
                                Text(g.displayName).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hikaye Teması")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary)
                        Text("İstediğin kadarını seç; her masalda seçtiklerinden biri rastgele kullanılır (Onboarding ve Masal Ayarları ile aynı).")
                            .font(MasalFont.labelMedium())
                            .foregroundStyle(c.onSurfaceVariant.opacity(0.85))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                            ForEach(StoryBentoTheme.allCases) { tile in
                                let on = bentoSelection.contains(tile)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if on {
                                        if bentoSelection.count > 1 {
                                            bentoSelection = bentoSelection.subtracting([tile])
                                        }
                                    } else {
                                        bentoSelection = bentoSelection.union([tile])
                                    }
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        VStack(spacing: DesignTokens.Spacing.sm) {
                                            Image(systemName: tile.systemImage)
                                                .font(.system(size: 26))
                                                .foregroundStyle(on ? c.tertiary : c.secondary)
                                            Text(tile.displayTitle)
                                                .font(MasalFont.labelMedium())
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                                .foregroundStyle(on ? c.onSurface : c.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignTokens.Spacing.md)
                                        if on {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(c.primary)
                                                .padding(8)
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                            .fill(on ? c.surfaceContainerHigh : c.surfaceContainerLow)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                            .strokeBorder(on ? c.primary.opacity(0.35) : Color.clear, lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .opacity(on ? 1 : 0.72)
                            }
                        }
                    }
                    GradientButton("Kaydet") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                }
                .padding()
            }
            .background(c.surface)
            .navigationTitle("Yeni Çocuk")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let bentos = StoryBentoTheme.normalizedSelection(Array(bentoSelection))
        let themes = StoryBentoTheme.mergedProfileThemes(bentos)
        let p = ChildProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ageGroup: ageGroup,
            themes: themes.isEmpty ? [.fairyTale] : themes
        )
        p.bentoThemeRaw = StoryBentoTheme.serializeForStorage(bentos)
        modelContext.insert(p)
        profileManager.switchTo(p)
        try? modelContext.save()
    }
}
