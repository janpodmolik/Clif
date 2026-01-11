import Foundation

/// Protocol for types that can be displayed as a pet in FloatingIslandView.
protocol PetDisplayable {
    var displayScale: CGFloat { get }
    var idleConfig: IdleConfig { get }
    func assetName(for mood: Mood) -> String
    func assetName(for windLevel: WindLevel) -> String
    func windConfig(for level: WindLevel) -> WindConfig
    func tapConfig(for type: TapAnimationType) -> TapConfig
}

// MARK: - EvolutionPhase Conformance

extension EvolutionPhase: PetDisplayable {}

// MARK: - Blob Conformance

extension Blob: PetDisplayable {}
