import SwiftUI

/// Protocol for pet types that have evolution history.
/// Provides centralized asset, color, and display scale resolution with blob fallbacks.
protocol PetEvolvable {
    var evolutionHistory: EvolutionHistory { get }
}

extension PetEvolvable {
    // MARK: - Delegated Properties

    var essence: Essence? { evolutionHistory.essence }
    var evolutionTypeName: String { essence?.rawValue ?? "blob" }
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

    /// Total days the pet has been alive (day 1 = creation day).
    var totalDays: Int { daysSinceCreation + 1 }

    /// Days since pet was created (calendar days, not 24h periods).
    var daysSinceCreation: Int {
        let calendar = Calendar.current
        let created = calendar.startOfDay(for: evolutionHistory.createdAt)
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: created, to: today).day ?? 0
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

    /// Returns the body asset name based on wind level.
    func bodyAssetName(for windLevel: WindLevel) -> String {
        guard let essence else {
            return Blob.shared.bodyAssetName(for: windLevel)
        }
        return phase?.bodyAssetName(for: windLevel) ?? essence.assetName
    }

    /// Returns the eyes asset name based on wind level.
    func eyesAssetName(for windLevel: WindLevel) -> String {
        guard let essence else {
            return Blob.shared.eyesAssetName(for: windLevel)
        }
        return phase?.eyesAssetName(for: windLevel) ?? Blob.shared.eyesAssetName(for: windLevel)
    }

    /// Returns the eyes asset name based on wind level and blown away state.
    func eyesAssetName(for windLevel: WindLevel, isBlownAway: Bool) -> String {
        guard let essence else {
            return Blob.shared.eyesAssetName(for: windLevel, isBlownAway: isBlownAway)
        }
        return phase?.eyesAssetName(for: windLevel, isBlownAway: isBlownAway) ?? Blob.shared.eyesAssetName(for: windLevel, isBlownAway: isBlownAway)
    }

    func scaredEyesAssetName(for windLevel: WindLevel) -> String? {
        guard let essence else {
            return Blob.shared.scaredEyesAssetName(for: windLevel)
        }
        return phase?.scaredEyesAssetName(for: windLevel)
    }
}
