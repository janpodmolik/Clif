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
    var isFullyEvolved: Bool { evolutionHistory.isFullyEvolved }

    /// The evolution path for this pet, if essence is assigned.
    var evolutionPath: EvolutionPath? {
        guard let essence else { return nil }
        return EvolutionPath.path(for: essence)
    }

    /// Current evolution phase, if pet has essence and is at phase 1+.
    var phase: EvolutionPhase? {
        evolutionPath?.phase(at: currentPhase)
    }

    // MARK: - Evolution Timing

    /// Days since pet was created.
    var daysSinceCreation: Int {
        Calendar.current.dateComponents(
            [.day],
            from: evolutionHistory.createdAt,
            to: Date()
        ).day ?? 0
    }

    /// True if blob can use essence (at least 1 day old and hasn't progressed today).
    var canUseEssence: Bool {
        guard isBlob, !evolutionHistory.hasProgressedToday else { return false }
        return daysSinceCreation >= 1
    }

    /// Days until essence can be used (for blob pets).
    var daysUntilEssence: Int? {
        guard isBlob, !canUseEssence else { return nil }
        let remaining = 1 - daysSinceCreation
        return remaining > 0 ? remaining : nil
    }

    /// Days until next evolution (1 day per phase).
    var daysUntilEvolution: Int? {
        guard !isBlob else { return nil }
        guard !evolutionHistory.isFullyEvolved else { return nil }
        guard !evolutionHistory.isBlown else { return nil }

        if evolutionHistory.hasProgressedToday {
            return 1
        }

        let nextEvolutionDay = evolutionHistory.currentPhase
        let remaining = nextEvolutionDay - daysSinceCreation
        return remaining > 0 ? remaining : nil
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

    /// Returns the asset name based on wind level.
    func assetName(for windLevel: WindLevel) -> String {
        guard let essence else {
            return Blob.shared.assetName(for: windLevel)
        }
        return phase?.assetName(for: windLevel) ?? essence.assetName
    }

    /// Returns the asset name based on wind level and blown away state.
    func assetName(for windLevel: WindLevel, isBlownAway: Bool) -> String {
        guard let essence else {
            return Blob.shared.assetName(for: windLevel, isBlownAway: isBlownAway)
        }
        return phase?.assetName(for: windLevel, isBlownAway: isBlownAway) ?? essence.assetName
    }
}
