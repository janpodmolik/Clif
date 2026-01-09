import SwiftUI
import QuartzCore

/// Single source of truth for wind gust timing.
/// Both pet animation and wind lines subscribe to this rhythm for synchronized effects.
///
/// Wind lines use `gustIntensity` (immediate) for spawning.
/// Pet animation uses `rawWave` (delayed) so wind lines arrive before pet reacts.
@Observable
final class WindRhythm {

    // MARK: - Configuration

    /// Delay in seconds for pet animation relative to wind lines.
    /// Wind lines spawn immediately, pet reacts after this delay.
    static let petDelay: TimeInterval = 0.0

    // MARK: - Published State

    /// Current gust intensity (0 = calm, 1 = peak gust).
    /// Immediate value - used by wind lines for spawning.
    private(set) var gustIntensity: CGFloat = 0

    /// Raw wave value (-1 to +0.4 range) for pet animation.
    /// Delayed by `petDelay` so wind lines arrive before pet reacts.
    /// Negative = bending forward (with wind), positive = back swing.
    private(set) var rawWave: CGFloat = 0

    // MARK: - Internal

    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0

    // MARK: - Lifecycle

    init() {
        startTime = CACurrentMediaTime()
    }

    func start() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit {
        stop()
    }

    // MARK: - Wave Computation

    @objc private func tick(_ link: CADisplayLink) {
        let time = link.timestamp - startTime

        // Gust intensity is immediate (for wind line spawning)
        let currentWave = computeWave(at: time)
        gustIntensity = max(0, -currentWave)

        // Raw wave for pet is delayed (so wind lines arrive first)
        let delayedTime = max(0, time - Self.petDelay)
        rawWave = computeWave(at: delayedTime)
    }

    /// Compute wave value at a specific time.
    /// Wave formula: three overlapping sine waves for organic feel.
    private func computeWave(at time: CFTimeInterval) -> CGFloat {
        let rawValue = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1
        // Asymmetric: full amplitude forward (negative), 40% back swing (positive)
        return rawValue < 0 ? rawValue : rawValue * 0.4
    }
}
