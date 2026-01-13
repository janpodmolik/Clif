import SwiftUI

/// Protocol for pet types that have evolution history.
/// Provides centralized asset, color, and display scale resolution with blob fallbacks.
protocol PetEvolvable {
    var evolutionHistory: EvolutionHistory { get }
}

extension PetEvolvable {
    // MARK: - Delegated Properties

    var essence: Essence? { evolutionHistory.essence }
    var currentPhase: Int { evolutionHistory.currentPhase }
    var isBlob: Bool { evolutionHistory.isBlob }
    var canEvolve: Bool { evolutionHistory.canEvolve }
    var isBlown: Bool { evolutionHistory.isBlown }

    /// The evolution path for this pet, if essence is assigned.
    var evolutionPath: EvolutionPath? {
        guard let essence else { return nil }
        return EvolutionPath.path(for: essence)
    }

    /// Current evolution phase, if pet has essence and is at phase 1+.
    var phase: EvolutionPhase? {
        evolutionPath?.phase(at: currentPhase)
    }

    // MARK: - Display Properties

    /// Theme color for the pet. Falls back to `.secondary` for blobs.
    var themeColor: Color {
        evolutionPath?.themeColor ?? .secondary
    }

    /// Display scale for the current evolution phase.
    var displayScale: CGFloat {
        phase?.displayScale ?? Blob.shared.displayScale
    }

    // MARK: - Asset Resolution

    /// Returns the asset name for the current evolution state.
    /// Falls back to Blob asset when no essence is assigned.
    func assetName(for mood: Mood) -> String {
        guard let essence else {
            return Blob.shared.assetName(for: mood)
        }
        return phase?.assetName(for: mood) ?? essence.assetName
    }

    /// Returns the asset name based on wind level.
    func assetName(for windLevel: WindLevel) -> String {
        assetName(for: Mood(from: windLevel))
    }
}
