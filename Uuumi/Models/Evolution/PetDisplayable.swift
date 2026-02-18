import Foundation

/// Protocol for types that can be displayed as a pet in IslandView.
protocol PetDisplayable {
    var displayScale: CGFloat { get }
    var idleConfig: IdleConfig { get }
    func bodyAssetName(for windLevel: WindLevel) -> String
    func eyesAssetName(for windLevel: WindLevel) -> String
    func eyesAssetName(for windLevel: WindLevel, isBlownAway: Bool) -> String
    func scaredEyesAssetName(for windLevel: WindLevel) -> String?
    func reactionConfig(for type: PetReactionType) -> ReactionConfig
}

// MARK: - Default Implementations

extension PetDisplayable {
    func scaredEyesAssetName(for windLevel: WindLevel) -> String? { nil }
}

// MARK: - EvolutionPhase Conformance

extension EvolutionPhase: PetDisplayable {}

// MARK: - Blob Conformance

extension Blob: PetDisplayable {}
