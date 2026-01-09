import Foundation

/// Configuration for evolution transition animation parameters.
struct EvolutionTransitionConfig: Equatable {
    var type: EvolutionTransitionType
    var duration: TimeInterval

    // Dissolve-specific
    var dissolveNoiseScale: CGFloat
    var dissolveEdgeSoftness: CGFloat

    // Glow burst-specific
    var glowColorR: CGFloat
    var glowColorG: CGFloat
    var glowColorB: CGFloat
    var glowPeakIntensity: CGFloat
    var flashDuration: CGFloat

    var glowColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        (glowColorR, glowColorG, glowColorB)
    }

    static func `default`(for type: EvolutionTransitionType) -> EvolutionTransitionConfig {
        switch type {
        case .dissolve:
            return EvolutionTransitionConfig(
                type: .dissolve,
                duration: type.defaultDuration,
                dissolveNoiseScale: 25,
                dissolveEdgeSoftness: 0.2,
                glowColorR: 1, glowColorG: 1, glowColorB: 1,
                glowPeakIntensity: 1.0,
                flashDuration: 0.15
            )
        case .glowBurst:
            return EvolutionTransitionConfig(
                type: .glowBurst,
                duration: type.defaultDuration,
                dissolveNoiseScale: 25,
                dissolveEdgeSoftness: 0.2,
                glowColorR: 1, glowColorG: 0.9, glowColorB: 0.6,
                glowPeakIntensity: 2.5,
                flashDuration: 0.2
            )
        }
    }
}
