import SwiftUI

/// Represents a single phase in an evolution tree.
struct EvolutionPhase: Hashable {
    let phaseNumber: Int
    let evolutionId: String
    let displayScale: CGFloat
    let idleConfig: IdleConfig

    func bodyAssetName(for windLevel: WindLevel) -> String {
        "evolutions/\(evolutionId)/\(phaseNumber)/body"
    }

    func eyesAssetName(for windLevel: WindLevel) -> String {
        "evolutions/\(evolutionId)/\(phaseNumber)/eyes/\(windLevel.eyes)"
    }

    func blownAwayEyesAssetName() -> String {
        "evolutions/\(evolutionId)/\(phaseNumber)/eyes/sad"
    }

    func reactionConfig(for type: PetReactionType) -> ReactionConfig {
        .default(for: type)
    }
}
