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

    // MARK: - Display Properties

    /// Theme color for the pet. Falls back to `.secondary` for blobs.
    var themeColor: Color {
        essence?.themeColor ?? .secondary
    }

    /// Display scale for the current evolution phase.
    var displayScale: CGFloat {
        essence?.phase(at: currentPhase)?.displayScale ?? Blob.shared.displayScale
    }

    // MARK: - Asset Resolution

    /// Returns the asset name for the current evolution state.
    /// Falls back to Blob asset when no essence is assigned.
    func assetName(for mood: Mood) -> String {
        guard let essence else {
            return Blob.shared.assetName(for: mood)
        }
        return essence.phase(at: currentPhase)?.assetName(for: mood) ?? essence.assetName
    }

    /// Returns the asset name based on wind level.
    func assetName(for windLevel: WindLevel) -> String {
        assetName(for: Mood(from: windLevel))
    }
}
