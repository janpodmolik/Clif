import SwiftUI
import QuartzCore

/// Single source of truth for wind gust timing.
/// Both pet animation and wind lines subscribe to this rhythm for synchronized effects.
///
/// Wind lines use `gustIntensity` (look-ahead) for spawning - they "see" the future.
/// Pet animation uses `rawWave` (current time) so wind lines arrive before pet reacts.
@Observable
final class WindRhythm {

    // MARK: - Configuration

    /// How far ahead wind lines look into the future (in seconds).
    /// This makes wind lines arrive before pet reacts to the gust.
    static let windLookAhead: TimeInterval = 0.6

    // MARK: - Published State

    /// Current gust intensity (0 = calm, 1 = peak gust).
    /// Look-ahead value - wind lines use this to spawn before pet reacts.
    private(set) var gustIntensity: CGFloat = 0

    /// Raw wave value (-1 to +0.4 range) for pet animation.
    /// Uses current time - pet reacts after wind lines have already arrived.
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

        // Wind lines look ahead into the future (so they arrive before pet reacts)
        let futureTime = time + Self.windLookAhead
        let futureWave = computeWave(at: futureTime)
        gustIntensity = max(0, -futureWave)

        // Pet uses current time (reacts after wind lines have arrived)
        rawWave = computeWave(at: time)
    }

    /// Compute wave value at a specific time.
    /// Wave formula: three overlapping sine waves for organic feel.
    private func computeWave(at time: CFTimeInterval) -> CGFloat {
        let rawValue = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1
        // Asymmetric: full amplitude forward (negative), 40% back swing (positive)
        return rawValue < 0 ? rawValue : rawValue * 0.4
    }
}
