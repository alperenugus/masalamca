//
//  DailyTips.swift
//  MasalAmca
//

import Foundation

struct DailyTip: Sendable, Equatable {
    var title: String
    var message: String
    var systemImage: String = "lightbulb.fill"
}

enum DailyTips {
    /// Ana sayfa “Günün İpucu” havuzu; sıra yok, gün bazlı seçilir.
    static let all: [DailyTip] = [
        DailyTip(
            title: "Uyku Zamanı Ritüeli",
            message: "Masaldan birkaç dakika önce beyaz gürültü açmak çocukların uykuya geçişini kolaylaştırır.",
            systemImage: "moon.zzz.fill"
        ),
        DailyTip(
            title: "Aynı Saat, Aynı Sıcaklık",
            message: "Her gece benzer saatte masal dinlemek, vücudun “uyku zamanı” sinyalini güçlendirir.",
            systemImage: "clock.fill"
        ),
        DailyTip(
            title: "Ekranı Yumuşat",
            message: "Masal öncesi parlaklığı düşürmek ve bildirimleri kapatmak daha sakin bir ortam yaratır.",
            systemImage: "sun.min.fill"
        ),
        DailyTip(
            title: "Kısa ve Öz",
            message: "Uykuya yakın kısa masallar genelde daha iyi işler; uzun maceraları gündüze bırakabilirsin.",
            systemImage: "book.pages.fill"
        ),
        DailyTip(
            title: "Birlikte Nefes",
            message: "Masal bitince birkaç yavaş nefes ve fısıldanan iyi geceler, kaygıyı azaltmaya yardım eder.",
            systemImage: "wind"
        ),
        DailyTip(
            title: "Sevdiği Ses",
            message: "Çocuğunun sakin kaldığı ses tonunu ve masal uzunluğunu not et; tekrar kullanmak huzur verir.",
            systemImage: "heart.fill"
        ),
        DailyTip(
            title: "Odanın Sıcaklığı",
            message: "Serin ama üşütmeyen bir oda, hafif bir battaniye ve loş ışık uyku için idealdir.",
            systemImage: "thermometer.medium"
        ),
        DailyTip(
            title: "Gündüz Enerjisi",
            message: "Gündüz hareket ve gün ışığı almak, gece uykusunun daha derin olmasına yardımcı olur.",
            systemImage: "figure.walk"
        ),
        DailyTip(
            title: "Masal Sonrası Sessizlik",
            message: "Masal bittikten sonra konuşmayı azaltmak, çocuğun kendi kendine uykuya kaymasını kolaylaştırır.",
            systemImage: "speaker.slash.fill"
        ),
        DailyTip(
            title: "Sabırlı Geçiş",
            message: "Bazı geceler uykuya geçiş uzun sürer; rutini koruyup sakin kalmak en iyi destektir.",
            systemImage: "leaf.fill"
        )
    ]

    /// Yerel takvim günü boyunca aynı ipucu; ertesi gün farklı bir indeks (deterministik “rastgele”).
    static func tipForToday(referenceDate: Date = .now, calendar: Calendar = .current) -> DailyTip {
        guard !all.isEmpty else {
            return DailyTip(
                title: "İpucu",
                message: "İyi geceler dileriz.",
                systemImage: "lightbulb.fill"
            )
        }
        let c = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        let y = c.year ?? 0
        let m = c.month ?? 0
        let d = c.day ?? 0
        var seed = y &* 10_000 &+ m &* 100 &+ d
        seed = seed &* 1_103_515_245 &+ 12_345
        seed ^= seed >> 16
        seed &*= 2_246_822_507
        seed ^= seed >> 13
        let n = all.count
        let idx = ((seed % n) + n) % n
        return all[idx]
    }
}
