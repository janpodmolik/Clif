import Foundation

/// Configuration for tap animation parameters.
struct TapConfig: Equatable {
    var intensity: CGFloat
    var decayRate: CGFloat
    var frequency: CGFloat

    static let none = TapConfig(
        intensity: 0,
        decayRate: 0,
        frequency: 0
    )

    /// Default configurations for each animation type.
    static func `default`(for type: TapAnimationType) -> TapConfig {
        switch type {
        case .none:
            return .none
        case .wiggle:
            return TapConfig(
                intensity: 8,       // pixels of horizontal displacement
                decayRate: 8.0,     // fast decay
                frequency: 40       // Hz - rapid oscillation
            )
        case .squeeze:
            return TapConfig(
                intensity: 0.1,     // 10% vertical compression
                decayRate: 6.0,     // medium decay
                frequency: 12       // Hz - spring-like
            )
        case .jiggle:
            return TapConfig(
                intensity: 15,      // pixels of wave displacement
                decayRate: 5.0,     // medium-slow decay
                frequency: 15       // Hz - jelly wobble
            )
        }
    }
}
