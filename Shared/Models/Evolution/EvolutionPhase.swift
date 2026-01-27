import SwiftUI

/// Represents a single phase in an evolution tree.
struct EvolutionPhase: Hashable {
    let phaseNumber: Int
    let evolutionId: String
    let displayScale: CGFloat
    let idleConfig: IdleConfig

    func assetName(for windLevel: WindLevel) -> String {
        "evolutions/\(evolutionId)/\(windLevel.assetFolder)/\(phaseNumber)"
    }

    func assetName(for windLevel: WindLevel, isBlownAway: Bool) -> String {
        let folder = isBlownAway ? WindLevel.blownAssetFolder : windLevel.assetFolder
        return "evolutions/\(evolutionId)/\(folder)/\(phaseNumber)"
    }

    func tapConfig(for type: TapAnimationType) -> TapConfig {
        .default(for: type)
    }
}
