import Foundation

/// Configuration for evolution transition animation.
struct EvolutionTransitionConfig: Equatable {
    /// Total animation duration in seconds.
    var duration: TimeInterval

    /// Glow color RGB components (0-1).
    var glowColorR: CGFloat
    var glowColorG: CGFloat
    var glowColorB: CGFloat

    /// Peak glow intensity multiplier.
    var glowPeakIntensity: CGFloat

    /// Flash duration as fraction of total duration.
    var flashDuration: CGFloat

    var glowColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        (glowColorR, glowColorG, glowColorB)
    }

    /// Progress point (0-1) when new image starts appearing (during flash).
    static let assetSwapPoint: CGFloat = 0.58

    /// Progress point (0-1) when old image is hidden completely.
    static let oldImageHidePoint: CGFloat = 0.60

    /// Default duration for the transition.
    static let defaultDuration: TimeInterval = 2.0

    static let `default` = EvolutionTransitionConfig(
        duration: defaultDuration,
        glowColorR: 1,
        glowColorG: 0.9,
        glowColorB: 0.6,
        glowPeakIntensity: 2.5,
        flashDuration: 0.2
    )
}
