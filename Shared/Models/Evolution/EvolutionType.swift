import Foundation

/// Protocol defining the interface for all pet evolution types.
protocol EvolutionType: CaseIterable, Hashable {
    /// Unique identifier for this evolution (e.g., "blob", "plant")
    static var evolutionId: String { get }

    /// Display name for UI (e.g., "Blob", "Plant")
    static var displayName: String { get }

    /// Base asset name for this evolution/phase (e.g., "plant-1", "blob")
    var assetName: String { get }

    /// Display scale multiplier for this evolution (default 1.0)
    var displayScale: CGFloat { get }

    /// Wind configuration for the specified wind level
    func windConfig(for level: WindLevel) -> WindConfig

    /// Asset name for specific mood variant
    func assetName(for mood: Mood) -> String
}

// MARK: - Mood Support

extension EvolutionType {
    /// Convenience method to get asset name from wind level.
    func assetName(for windLevel: WindLevel) -> String {
        assetName(for: Mood(from: windLevel))
    }
}
