//
//  NotificationsInfoSheet.swift
//  MasalAmca
//

import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// Yerel yatma hatırlatıcısı: **seçili çocuk profili** başına bir günlük saat (Premium gerekmez). Veri sunucuya gönderilmez.
struct NotificationsInfoSheet: View {
    @Environment(\.masalThemeManager) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.masalChildProfileManager) private var profileManager
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]

    @State private var reminderOn = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? .now
    @State private var showSettingsAlert = false
    @State private var showParentGateBeforeSettingsApp = false
    @State private var hasUnsavedChanges = false

    private var active: ChildProfile? {
        profileManager.activeProfile(from: profiles)
    }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(c.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Text("Bildirimler")
                        .font(MasalFont.headlineMedium())
                        .foregroundStyle(c.onSurface)

                    Text(
                        "Hatırlatıcılar yalnızca bu cihazda çalışır; kişisel veri veya reklam için sunucuya gönderilmez. İstediğin an buradan kapatabilirsin."
                    )
                    .font(MasalFont.bodyLarge())
                    .foregroundStyle(c.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)

                    if active == nil {
                        Text("Yatma hatırlatıcısı için önce üst menüden bir çocuk profili seç.")
                            .font(MasalFont.bodyMedium())
                            .foregroundStyle(c.secondary)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Toggle(
                                "Yatma saati hatırlatıcısı",
                                isOn: Binding(
                                    get: { reminderOn },
                                    set: { new in
                                        if new {
                                            Task { await requestEnableReminder() }
                                        } else {
                                            reminderOn = false
                                            hasUnsavedChanges = true
                                        }
                                    }
                                )
                            )
                            .font(MasalFont.bodyMedium())
                            .tint(c.primaryContainer)

                            Text("Seçili profil: \(active?.name ?? "")")
                                .font(MasalFont.labelMedium())
                                .foregroundStyle(c.secondary)

                            DatePicker(
                                "Hatırlatma saati",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(MasalFont.bodyMedium())
                            .disabled(!reminderOn)
                            .onChange(of: reminderTime) { _, _ in
                                guard reminderOn else { return }
                                hasUnsavedChanges = true
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(c.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, 32)
            }
            .background(c.surface.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundStyle(c.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        persistAndSync()
                        dismiss()
                    }
                    .foregroundStyle(c.primary)
                    .disabled(active == nil || !hasUnsavedChanges)
                }
            }
            .onAppear {
                syncUIFromActiveProfile()
            }
            .onChange(of: profileManager.activeProfileID) { _, _ in
                syncUIFromActiveProfile()
            }
            .sheet(isPresented: $showParentGateBeforeSettingsApp) {
                ParentalGateSheet(kind: .externalContent) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .masalThemeManager(theme)
                .presentationDetents([.medium, .large])
            }
            .alert("Bildirim izni", isPresented: $showSettingsAlert) {
                Button("Ayarlara git") {
                    showSettingsAlert = false
                    showParentGateBeforeSettingsApp = true
                }
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Hatırlatıcılar için bildirim izni gerekiyor. Ayarlar → Masal Amca → Bildirimler bölümünden açabilirsin.")
            }
        }
    }

    private func syncUIFromActiveProfile() {
        guard let p = active else {
            reminderOn = false
            hasUnsavedChanges = false
            return
        }
        reminderOn = p.bedtimeReminderEnabled
        reminderTime = Self.dateFor(hour: p.bedtimeReminderHour, minute: p.bedtimeReminderMinute)
        hasUnsavedChanges = false
    }

    private static func dateFor(hour: Int, minute: Int) -> Date {
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dc.hour = hour
        dc.minute = minute
        return Calendar.current.date(from: dc) ?? Date()
    }

    @MainActor
    private func requestEnableReminder() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .denied {
            showSettingsAlert = true
            return
        }
        let ok = await BedtimeNotificationService.ensureAuthorizedForBedtime()
        if ok {
            reminderOn = true
            hasUnsavedChanges = true
        } else {
            showSettingsAlert = true
        }
    }

    private func persistAndSync() {
        guard let p = active else { return }
        let cal = Calendar.current
        let parts = cal.dateComponents([.hour, .minute], from: reminderTime)
        p.bedtimeReminderEnabled = reminderOn
        p.bedtimeReminderHour = parts.hour ?? 20
        p.bedtimeReminderMinute = parts.minute ?? 0
        p.updatedAt = .now
        try? modelContext.save()
        Task { await BedtimeNotificationService.syncBedtimeReminders(activeProfile: profileManager.activeProfile(from: profiles)) }
        hasUnsavedChanges = false
    }
}
