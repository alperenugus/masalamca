//
//  SleepTimerController.swift
//  MasalAmca
//

import Foundation
import Observation

@Observable
@MainActor
final class SleepTimerController {
    private var task: Task<Void, Never>?
    private(set) var remaining: TimeInterval = 0
    private(set) var isRunning = false

    var onFire: (() -> Void)?

    func start(minutes: Int, onFire: @escaping () -> Void) {
        cancel()
        self.onFire = onFire
        remaining = TimeInterval(minutes * 60)
        isRunning = true
        task = Task { [weak self] in
            guard let self else { return }
            let end = Date().addingTimeInterval(self.remaining)
            while !Task.isCancelled {
                let left = end.timeIntervalSinceNow
                await MainActor.run { self.remaining = max(0, left) }
                if left <= 0 { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            await MainActor.run {
                self.isRunning = false
                self.remaining = 0
                self.onFire?()
                self.onFire = nil
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        isRunning = false
        remaining = 0
        onFire = nil
    }
}
