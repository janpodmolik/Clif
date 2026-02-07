import Foundation

/// Configuration for tap animation parameters.
struct TapConfig: Equatable, Hashable {
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
                intensity: 15,
                decayRate: 5.0,
                frequency: 35,
            )
        case .squeeze:
            return TapConfig(
                intensity: 0.5,
                decayRate: 8.0,
                frequency: 25,
            )
        case .jiggle:
            return TapConfig(
                intensity: 20,
                decayRate: 3.5,
                frequency: 20,
            )
        case .bounce:
            return TapConfig(
                intensity: 0.2,
                decayRate: 4.0,
                frequency: 8,
            )
        }
    }
}
