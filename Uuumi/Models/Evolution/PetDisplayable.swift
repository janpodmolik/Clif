import Foundation

/// Protocol for types that can be displayed as a pet in IslandView.
protocol PetDisplayable {
    var displayScale: CGFloat { get }
    var idleConfig: IdleConfig { get }
    func assetName(for windLevel: WindLevel) -> String
    func assetName(for windLevel: WindLevel, isBlownAway: Bool) -> String
    func reactionConfig(for type: PetReactionType) -> ReactionConfig
}

// MARK: - EvolutionPhase Conformance

extension EvolutionPhase: PetDisplayable {}

// MARK: - Blob Conformance

extension Blob: PetDisplayable {}
