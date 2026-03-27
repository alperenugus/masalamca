//
//  NotificationsInfoSheet.swift
//  MasalAmca
//

import SwiftUI

/// Explains the header bell: future bedtime reminders (not wired to push yet).
struct NotificationsInfoSheet: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let c = theme.colors
        NavigationStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(c.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                Text("Bildirimler")
                    .font(MasalFont.headlineMedium())
                    .foregroundStyle(c.onSurface)
                Text(
                    "Buradan ileride uyku hatırlatıcıları ve yeni masal önerileri için bildirimleri yönetebileceksiniz. Şu an yalnızca tasarım yer tutucusudur; izin ve zamanlama bir sonraki sürümde eklenecek."
                )
                .font(MasalFont.bodyLarge())
                .foregroundStyle(c.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .background(c.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundStyle(c.primary)
                }
            }
        }
    }
}
