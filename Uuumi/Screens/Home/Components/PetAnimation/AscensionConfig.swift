import Foundation

/// Configuration for the archive ascension animation effect.
struct AscensionConfig: Equatable {
    /// Duration of the slow rise phase (seconds)
    let slowRiseDuration: TimeInterval

    /// Duration of the fast fly-off phase (seconds)
    let fastFlyDuration: TimeInterval

    /// Delay before the card starts sliding off (seconds after rise begins)
    let cardDelay: TimeInterval

    /// Duration for the card to slide off-screen (seconds)
    let cardDismissDuration: TimeInterval

    /// Distance the pet rises during slow phase (points)
    let slowRiseDistance: CGFloat

    /// Shadow radius for the glow effect
    let glowRadius: CGFloat

    /// Stretch amount for shader deformation during fly-off (0 = none, 1 = full)
    let flyStretchAmount: CGFloat

    static let `default` = AscensionConfig(
        slowRiseDuration: 3.0,
        fastFlyDuration: 0.4,
        cardDelay: 1.5,
        cardDismissDuration: 0.7,
        slowRiseDistance: 60,
        glowRadius: 12,
        flyStretchAmount: 1.0
    )
}
