import UIKit
import CoreHaptics

/// Available haptic feedback types for pet interaction.
enum HapticType: String, CaseIterable {
    // Impact feedback styles
    case impactLight = "Light"
    case impactMedium = "Medium"
    case impactHeavy = "Heavy"
    case impactSoft = "Soft"
    case impactRigid = "Rigid"

    // Notification feedback
    case notificationSuccess = "Success"
    case notificationWarning = "Warning"
    case notificationError = "Error"

    // Selection feedback
    case selection = "Selection"

    // Core Haptics - custom patterns
    case continuousBuzz = "Buzz"
    case purr = "Purr"

    var category: String {
        switch self {
        case .impactLight, .impactMedium, .impactHeavy, .impactSoft, .impactRigid:
            return "Impact"
        case .notificationSuccess, .notificationWarning, .notificationError:
            return "Notification"
        case .selection:
            return "Selection"
        case .continuousBuzz, .purr:
            return "Custom"
        }
    }

    var description: String {
        switch self {
        case .impactLight:
            return "Jemný tap"
        case .impactMedium:
            return "Střední tap"
        case .impactHeavy:
            return "Silný tap"
        case .impactSoft:
            return "Měkké zavrnění"
        case .impactRigid:
            return "Ostré klepnutí"
        case .notificationSuccess:
            return "Dvojité vibrace"
        case .notificationWarning:
            return "Varování"
        case .notificationError:
            return "Trojité vibrace"
        case .selection:
            return "Jemné tick"
        case .continuousBuzz:
            return "Delší vibrace (nastavitelná)"
        case .purr:
            return "Opakované jemné pulzy"
        }
    }

    /// Whether this haptic type supports custom duration.
    var supportsDuration: Bool {
        switch self {
        case .continuousBuzz, .purr:
            return true
        default:
            return false
        }
    }

    /// Returns UIImpactFeedbackGenerator.FeedbackStyle for impact types, nil for others.
    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .impactLight: return .light
        case .impactMedium: return .medium
        case .impactHeavy: return .heavy
        case .impactSoft: return .soft
        case .impactRigid: return .rigid
        default: return nil
        }
    }

    /// Triggers the haptic feedback.
    func trigger(duration: TimeInterval = 0.3, intensity: Float = 0.8) {
        switch self {
        case .impactLight:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .impactMedium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .impactHeavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .impactSoft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .impactRigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .notificationSuccess:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .notificationWarning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .notificationError:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .continuousBuzz:
            HapticEngine.shared.playContinuousBuzz(duration: duration, intensity: intensity)
        case .purr:
            HapticEngine.shared.playPurr(duration: duration, intensity: intensity)
        }
    }
}

// MARK: - Core Haptics Engine

final class HapticEngine {
    static let shared = HapticEngine()

    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                self?.prepareEngine()
            }
            engine?.stoppedHandler = { _ in }
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }

    /// Continuous vibration for specified duration.
    func playContinuousBuzz(duration: TimeInterval, intensity: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }

    /// Repeating soft pulses (purring effect).
    func playPurr(duration: TimeInterval, intensity: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }

        var events: [CHHapticEvent] = []
        let pulseInterval: TimeInterval = 0.08
        var time: TimeInterval = 0

        while time < duration {
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.6)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: time
            )
            events.append(event)
            time += pulseInterval
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
}
