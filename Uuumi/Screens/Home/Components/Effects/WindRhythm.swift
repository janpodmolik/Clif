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

    /// Gust frequency range: interpolates from min (progress=0) to max (progress=1).
    private static let gustFrequencyMin: CGFloat = 1.0
    private static let gustFrequencyMax: CGFloat = 1.5

    /// Current wind progress (0-1). Higher progress = faster gusts.
    var windProgress: CGFloat = 0 {
        didSet {
            gustFrequency = Self.gustFrequencyMin + (Self.gustFrequencyMax - Self.gustFrequencyMin) * windProgress
        }
    }

    /// Computed frequency multiplier based on wind progress.
    private(set) var gustFrequency: CGFloat = gustFrequencyMin

    // MARK: - Published State

    /// Current gust intensity (0 = calm, 1 = peak gust).
    /// Look-ahead value - wind lines use this to spawn before pet reacts.
    private(set) var gustIntensity: CGFloat = 0

    /// Raw wave value (-1 to +0.4 range) for pet animation.
    /// Uses current time - pet reacts after wind lines have already arrived.
    /// Negative = bending forward (with wind), positive = back swing.
    private(set) var rawWave: CGFloat = 0

    /// Elapsed time since rhythm started (in seconds).
    /// Use this for shader time to keep all animations synchronized.
    private(set) var elapsedTime: CFTimeInterval = 0

    /// When true, CADisplayLink callbacks are suspended to save CPU.
    /// Use this when wind is .none — all consumers have fallback paths.
    /// The link stays alive for instant resume (no invalidation).
    var paused: Bool = false {
        didSet {
            guard paused != oldValue else { return }
            displayLink?.isPaused = paused
        }
    }

    // MARK: - Internal

    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var lowPowerModeObserver: NSObjectProtocol?

    /// Whether animations should be reduced (Low Power Mode or Reduce Motion)
    private var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: - Lifecycle

    func start() {
        guard displayLink == nil else { return }
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))

        // Cap frame rate to 30fps for battery efficiency (60fps not needed for wind animation)
        // In Low Power Mode, reduce further to 20fps
        let preferredFps: Float = isLowPowerMode ? 20 : 30
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: preferredFps, preferred: preferredFps)

        displayLink?.add(to: .main, forMode: .common)

        // Observe Low Power Mode changes
        lowPowerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFrameRate()
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        if let observer = lowPowerModeObserver {
            NotificationCenter.default.removeObserver(observer)
            lowPowerModeObserver = nil
        }
    }

    deinit {
        stop()
    }

    private func updateFrameRate() {
        let preferredFps: Float = isLowPowerMode ? 20 : 30
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: preferredFps, preferred: preferredFps)
    }

    // MARK: - Wave Computation

    @objc private func tick(_ link: CADisplayLink) {
        let time = link.timestamp - startTime
        elapsedTime = time

        // Wind lines look ahead into the future (so they arrive before pet reacts)
        let futureTime = time + Self.windLookAhead
        let futureWave = computeWave(at: futureTime)
        gustIntensity = max(0, -futureWave)

        // Pet uses current time (reacts after wind lines have arrived)
        rawWave = computeWave(at: time)
    }

    /// Compute wave value at a specific time.
    /// Wave formula: three overlapping sine waves for organic feel.
    /// Frequency is scaled by `gustFrequency` (derived from wind progress).
    private func computeWave(at time: CFTimeInterval) -> CGFloat {
        let f = gustFrequency
        let rawValue = sin(time * 1.5 * f) * 0.6 + sin(time * 2.3 * f) * 0.3 + sin(time * 0.7 * f) * 0.1
        // Asymmetric: full amplitude forward (negative), 40% back swing (positive)
        return rawValue < 0 ? rawValue : rawValue * 0.4
    }
}
