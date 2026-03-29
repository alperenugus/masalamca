//
//  BedtimeNotificationService.swift
//  MasalAmca
//

import Foundation
import UserNotifications

/// Seçili çocuk profili için günlük yerel yatma hatırlatıcısı. Sunucu veya pazarlama bildirimi yoktur.
enum BedtimeNotificationService {
    private static let idPrefix = "masal.bedtime."

    static func identifier(for profileID: UUID) -> String {
        idPrefix + profileID.uuidString
    }

    /// İzin iste veya mevcut izni döndür.
    static func ensureAuthorizedForBedtime() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// Tüm yatma hatırlatıcılarını kaldırır; seçili profil için ayar açıksa tek günlük bildirim planlar.
    @MainActor
    static func syncBedtimeReminders(activeProfile: ChildProfile?) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let bedtimeIDs = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: bedtimeIDs)

        guard let profile = activeProfile, profile.bedtimeReminderEnabled else { return }

        let authorized = await ensureAuthorizedForBedtime()
        guard authorized else { return }

        var dc = DateComponents()
        dc.hour = profile.bedtimeReminderHour
        dc.minute = profile.bedtimeReminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Uyku masalı vakti"
        content.body = "\(profile.name) ile bu geceye yumuşak bir masal eşlik etsin."
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: identifier(for: profile.id),
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(req)
        } catch {}
    }
}

/// Ön planda bildirim göstermek için.
final class BedtimeNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BedtimeNotificationCenter()

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
