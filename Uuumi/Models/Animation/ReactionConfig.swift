import Foundation

/// Configuration for pet reaction animation parameters.
struct ReactionConfig: Equatable, Hashable {
    var intensity: CGFloat
    var decayRate: CGFloat
    var frequency: CGFloat

    static let none = ReactionConfig(
        intensity: 0,
        decayRate: 0,
        frequency: 0
    )

    /// Default configurations for each animation type.
    static func `default`(for type: PetReactionType) -> ReactionConfig {
        switch type {
        case .none:
            return .none
        case .wiggle:
            return ReactionConfig(
                intensity: 15,
                decayRate: 5.0,
                frequency: 35,
            )
        case .squeeze:
            return ReactionConfig(
                intensity: 0.5,
                decayRate: 8.0,
                frequency: 25,
            )
        case .jiggle:
            return ReactionConfig(
                intensity: 20,
                decayRate: 3.5,
                frequency: 20,
            )
        case .bounce:
            return ReactionConfig(
                intensity: 0.2,
                decayRate: 4.0,
                frequency: 8,
            )
        }
    }
}
