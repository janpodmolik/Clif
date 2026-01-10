import SwiftUI

/// Essence determines which evolution path a pet follows.
/// This is a lightweight reference - all logic lives in EvolutionType.
enum Essence: String, Codable, CaseIterable {
    case plant
    // Future: crystal, flame, water

    /// Returns the associated EvolutionType for this essence
    var evolutionType: any EvolutionType.Type {
        switch self {
        case .plant: return PlantEvolution.self
        }
    }

    /// Convenience: displayName from EvolutionType
    var displayName: String {
        evolutionType.displayName
    }

    /// Convenience: evolutionId from EvolutionType
    var evolutionId: String {
        evolutionType.evolutionId
    }

    /// Convenience: themeColor from EvolutionType
    var themeColor: Color {
        evolutionType.themeColor
    }

    /// Convenience: all phases count from EvolutionType
    var maxPhases: Int {
        switch self {
        case .plant: return PlantEvolution.allCases.count
        }
    }

    /// Asset path for essence icon: "evolutions/plant/essence"
    var assetName: String {
        "evolutions/\(rawValue)/essence"
    }

    /// Returns all evolution phases for this essence
    func allPhases() -> [any EvolutionType] {
        switch self {
        case .plant: return PlantEvolution.allCases.map { $0 as any EvolutionType }
        }
    }

    /// Returns the evolution phase for a given phase number (1-indexed)
    func phase(at index: Int) -> (any EvolutionType)? {
        let phases = allPhases()
        guard index >= 1, index <= phases.count else { return nil }
        return phases[index - 1]
    }
}
