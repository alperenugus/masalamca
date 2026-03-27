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
    @State private var selectedThemes: Set<StoryTheme> = []

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
                        Text("Temalar")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                            ForEach(StoryTheme.allCases, id: \.self) { t in
                                GenreChip(
                                    title: t.displayName,
                                    systemImageName: t.iconSystemName,
                                    isSelected: selectedThemes.contains(t)
                                ) {
                                    if selectedThemes.contains(t) { selectedThemes.remove(t) }
                                    else { selectedThemes.insert(t) }
                                }
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
        let themes = Array(selectedThemes)
        let p = ChildProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ageGroup: ageGroup,
            themes: themes.isEmpty ? [.fairyTale] : themes
        )
        modelContext.insert(p)
        profileManager.switchTo(p)
        try? modelContext.save()
    }
}
