import SwiftUI

/// Essence determines which evolution path a pet follows.
/// This is a lightweight reference - all logic lives in EvolutionTree.
enum Essence: String, Codable, CaseIterable {
    case plant
    // Future: crystal, flame, water

    /// Returns the associated EvolutionTree for this essence
    var tree: EvolutionTree {
        switch self {
        case .plant: return .plant
        }
    }

    /// Convenience: displayName from tree
    var displayName: String {
        tree.displayName
    }

    /// Convenience: evolutionId from tree
    var evolutionId: String {
        tree.evolutionId
    }

    /// Convenience: themeColor from tree
    var themeColor: Color {
        tree.themeColor
    }

    /// Convenience: all phases count from tree
    var maxPhases: Int {
        tree.maxPhases
    }

    /// Asset path for essence icon: "evolutions/plant/essence"
    var assetName: String {
        "evolutions/\(rawValue)/essence"
    }

    /// Returns the evolution phase for a given phase number (1-indexed)
    func phase(at index: Int) -> EvolutionPhase? {
        tree.phase(at: index)
    }
}
