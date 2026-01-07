import Foundation

/// Protocol defining the interface for all pet evolution types.
protocol EvolutionType: CaseIterable, Hashable {
    /// Unique identifier for this evolution (e.g., "blob", "plant")
    static var evolutionId: String { get }

    /// Display name for UI (e.g., "Blob", "Plant")
    static var displayName: String { get }

    /// Asset name for this evolution/phase (e.g., "plant-1", "blob")
    var assetName: String { get }

    /// Wind configuration for the specified wind level
    func windConfig(for level: WindLevel) -> WindConfig
}
