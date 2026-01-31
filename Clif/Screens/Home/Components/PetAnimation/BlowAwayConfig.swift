import Foundation

/// Configuration for the blow away animation effect.
struct BlowAwayConfig: Equatable {
    /// Duration of the blow away animation (seconds)
    let duration: TimeInterval

    /// Final rotation angle in degrees (tilts pet downward in wind direction)
    let rotationDegrees: CGFloat

    /// Default blow away configuration
    static let `default` = BlowAwayConfig(
        duration: 0.8,
        rotationDegrees: 25
    )

    /// Slow-motion variant for replay (longer duration, same rotation)
    static let slowmo = BlowAwayConfig(
        duration: 2.0,
        rotationDegrees: 25
    )

    /// Duration for the rewind phase (reverse animation back to island)
    static let rewindDuration: TimeInterval = 0.6

    /// Pause between rewind and slow-motion blow away
    static let rewindPause: TimeInterval = 1.0
}
