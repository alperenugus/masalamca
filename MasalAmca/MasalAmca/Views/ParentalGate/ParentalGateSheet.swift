//
//  ParentalGateSheet.swift
//  MasalAmca
//
//  Kids category: required before IAP, restore, and opening web / system URLs (Guideline 3.1.2 / Kids).
//  Aligns with Apple’s Kids guidance: “adult-level tasks” for parental gates; pre-literate users should
//  involve a parent (https://developer.apple.com/app-store/kids-apps/).
//  No user-facing toggle — gate always runs for these actions.
//

import SwiftUI

enum ParentalGateKind {
    /// Satın alma, abonelik, geri yükleme.
    case commerce
    /// Safari / web, Apple EULA, gizlilik politikası, Ayarlar uygulaması vb.
    case externalContent
}

struct ParentalGateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.masalThemeManager) private var theme

    let kind: ParentalGateKind
    let onPassed: () -> Void

    @State private var leftOperand: Int
    @State private var rightOperand: Int
    @State private var answerText = ""
    @State private var showMistake = false

    init(kind: ParentalGateKind, onPassed: @escaping () -> Void) {
        self.kind = kind
        self.onPassed = onPassed
        let pair = Self.randomMultiplicationPair()
        _leftOperand = State(initialValue: pair.0)
        _rightOperand = State(initialValue: pair.1)
    }

    /// Adult-level challenge: çarpım tablosu (4…12) — toplamadan daha zor; okul öncesi için uygun değil, ebeveyn seviyesi.
    private static func randomMultiplicationPair() -> (Int, Int) {
        (Int.random(in: 4 ... 12), Int.random(in: 4 ... 12))
    }

    private var expected: Int { leftOperand * rightOperand }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text(headline)
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onSurface)
                Text(detail)
                    .font(MasalFont.bodyMedium())
                    .foregroundStyle(c.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Okuyamıyorsan veya sayıları çözemiyorsan bir yetişkinden yardım iste.")
                    .font(MasalFont.labelMedium())
                    .foregroundStyle(c.outline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Okuyamıyorsan bir yetişkinden yardım iste.")

                Text("\(leftOperand) × \(rightOperand) = ?")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(c.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Çarpma: \(leftOperand) çarpı \(rightOperand)")

                TextField("Cevabını yaz", text: $answerText)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .font(MasalFont.bodyLarge())
                    .padding(12)
                    .background(c.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))

                if showMistake {
                    Text("Bu cevap doğru değil. Tekrar dene.")
                        .font(MasalFont.labelMedium())
                        .foregroundStyle(Color.red.opacity(0.9))
                        .accessibilityIdentifier("parental_gate_wrong")
                }

                Button(action: submit) {
                    Text("Devam")
                        .font(MasalFont.titleMedium())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(c.primaryContainer)

                Spacer(minLength: 0)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(c.surface.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityHint("Bu adım yalnızca yetişkinler içindir. Çarpma sorusunu doğru yanıtlayın.")
        }
    }

    private var headline: String {
        switch kind {
        case .commerce:
            return "Ebeveyn doğrulaması"
        case .externalContent:
            return "Dış bağlantı"
        }
    }

    private var detail: String {
        switch kind {
        case .commerce:
            return "Satın alma ve abonelik işlemleri yalnızca yetişkinler içindir. Devam etmek için aşağıdaki çarpma sorusunu çöz."
        case .externalContent:
            return "Tarayıcı veya başka uygulamalara geçmeden önce bir yetişkinin bu adımı tamamlaması gerekir. Lütfen çarpma sorusunu çöz."
        }
    }

    private func submit() {
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value == expected else {
            showMistake = true
            let next = Self.randomMultiplicationPair()
            leftOperand = next.0
            rightOperand = next.1
            answerText = ""
            return
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onPassed()
        }
    }
}

// MARK: - Gated web / legal links

/// Tappable text that opens `url` in Safari only after the parental gate succeeds.
struct ParentalGatedWebLinkText: View {
    let title: String
    let url: URL
    @Environment(\.openURL) private var openURL
    @Environment(\.masalThemeManager) private var theme
    @State private var showGate = false

    var body: some View {
        Button(title) { showGate = true }
            .buttonStyle(.plain)
            .sheet(isPresented: $showGate) {
                ParentalGateSheet(kind: .externalContent) {
                    openURL(url)
                }
                .masalThemeManager(theme)
            }
    }
}

/// List row with `Label` that opens `url` after the gate.
struct ParentalGatedLegalListLink: View {
    let title: String
    let systemImage: String
    let url: URL
    @Environment(\.openURL) private var openURL
    @Environment(\.masalThemeManager) private var theme
    @State private var showGate = false

    var body: some View {
        Button {
            showGate = true
        } label: {
            Label(title, systemImage: systemImage)
        }
        .sheet(isPresented: $showGate) {
            ParentalGateSheet(kind: .externalContent) {
                openURL(url)
            }
            .masalThemeManager(theme)
        }
    }
}
