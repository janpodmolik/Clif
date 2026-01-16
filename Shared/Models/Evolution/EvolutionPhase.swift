import SwiftUI

/// Represents a single phase in an evolution tree.
struct EvolutionPhase: Hashable {
    let phaseNumber: Int
    let evolutionId: String
    let displayScale: CGFloat
    let idleConfig: IdleConfig

    func assetName(for mood: Mood) -> String {
        "evolutions/\(evolutionId)/\(mood.forAsset.rawValue)/\(phaseNumber)"
    }

    /// Convenience method to get asset name from wind level.
    func assetName(for windLevel: WindLevel) -> String {
        assetName(for: Mood(from: windLevel))
    }

    func tapConfig(for type: TapAnimationType) -> TapConfig {
        .default(for: type)
    }
}
