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
}
