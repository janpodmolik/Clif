import UIKit

/// Shared offset applied to drag preview position relative to the finger.
/// Both blob drop and essence drop flows position the preview slightly
/// above-left of the touch point so the dragged item isn't hidden under the finger.
enum DragPreviewOffset {
    static let x: CGFloat = -20
    static let y: CGFloat = -50
    static let size = CGSize(width: x, height: y)

    /// Returns the visual position of the dragged item given a raw touch `location`.
    static func adjustedPosition(from location: CGPoint) -> CGPoint {
        CGPoint(x: location.x + x, y: location.y + y)
    }
}

/// Controls proximity-based haptic feedback during drag-to-drop interactions.
///
/// Emits periodic ticks whose intensity scales with the drag position's
/// proximity to a target frame. Used by both CreatePet blob drop and
/// essence picker drop flows.
final class DragHapticController {
    private var timer: Timer?
    private var generator = UIImpactFeedbackGenerator(style: .light)
    private var intensity: CGFloat = 0.2

    private static let tickInterval: TimeInterval = 0.15
    private static let defaultIntensity: CGFloat = 0.2

    private enum ProximityConfig {
        static let maxDistanceMultiplier: CGFloat = 2.4
        static let baseIntensity: CGFloat = 0.15
        static let intensityRange: CGFloat = 0.85
        static let fallbackIntensity: CGFloat = 0.2
    }

    func startDragging() {
        intensity = Self.defaultIntensity
        timer?.invalidate()
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()

        timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Updates tick intensity based on proximity of `location` to `targetFrame`.
    /// Closer → stronger haptics. Falls back to a subtle baseline when no target is available.
    func updateProximityIntensity(at location: CGPoint, targetFrame: CGRect?) {
        guard let targetFrame else {
            updateIntensity(ProximityConfig.fallbackIntensity)
            return
        }

        let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let distance = hypot(location.x - center.x, location.y - center.y)
        let maxDistance = max(targetFrame.width, targetFrame.height) * ProximityConfig.maxDistanceMultiplier
        let normalized = max(0, min(1, 1 - (distance / maxDistance)))
        let newIntensity = ProximityConfig.baseIntensity + (normalized * ProximityConfig.intensityRange)
        updateIntensity(newIntensity)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func updateIntensity(_ newIntensity: CGFloat) {
        intensity = max(0, min(1, newIntensity))
    }

    private func tick() {
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    deinit {
        stop()
    }
}
