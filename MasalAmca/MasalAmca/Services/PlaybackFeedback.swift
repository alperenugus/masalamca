//
//  PlaybackFeedback.swift
//  MasalAmca
//

import AVFoundation
import Observation
import SwiftUI

// MARK: - Toast

@MainActor
@Observable
final class ToastCenter {
    var message: String?
    private var dismissTask: Task<Void, Never>?

    func show(_ text: String, duration: TimeInterval = 3.5) {
        dismissTask?.cancel()
        message = text
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            message = nil
        }
    }
}

struct MasalToastBanner: View {
    @Environment(\.masalThemeManager) private var theme
    let text: String

    var body: some View {
        let c = theme.colors
        Text(text)
            .font(MasalFont.bodyMedium())
            .foregroundStyle(c.onSurface)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(c.surfaceContainerHigh)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, 12)
    }
}

// MARK: - System volume

@MainActor
final class VolumeMonitor {
    private(set) var outputVolume: Float
    private var observation: NSKeyValueObservation?
    private var lastWarningShown: Date?
    /// Aynı uyarıyı çok sık göstermemek için (saniye).
    private let minSecondsBetweenWarnings: TimeInterval = 90

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        outputVolume = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.initial, .new]) { [weak self] s, _ in
            Task { @MainActor in
                self?.outputVolume = s.outputVolume
            }
        }
    }

    /// Sistem medya sesi kapalıyken uyarır; `true` dönerse toast gösterildi.
    @discardableResult
    func warnIfSilent(toast: ToastCenter) -> Bool {
        guard outputVolume < 0.02 else { return false }
        if let last = lastWarningShown,
           Date().timeIntervalSince(last) < minSecondsBetweenWarnings {
            return false
        }
        lastWarningShown = Date()
        toast.show("Sesi duymak için telefon sesini açmayı unutma.")
        return true
    }
}

// MARK: - Environment

private enum MasalToastCenterKey: EnvironmentKey {
    static let defaultValue: ToastCenter? = nil
}

private enum MasalVolumeMonitorKey: EnvironmentKey {
    static let defaultValue: VolumeMonitor? = nil
}

private enum MasalMixerPinStoreKey: EnvironmentKey {
    static let defaultValue: MixerPinStore? = nil
}

extension EnvironmentValues {
    var masalToastCenter: ToastCenter? {
        get { self[MasalToastCenterKey.self] }
        set { self[MasalToastCenterKey.self] = newValue }
    }

    var masalVolumeMonitor: VolumeMonitor? {
        get { self[MasalVolumeMonitorKey.self] }
        set { self[MasalVolumeMonitorKey.self] = newValue }
    }

    var masalMixerPinStore: MixerPinStore? {
        get { self[MasalMixerPinStoreKey.self] }
        set { self[MasalMixerPinStoreKey.self] = newValue }
    }
}
