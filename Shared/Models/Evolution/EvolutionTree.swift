import SwiftUI

/// Represents an entire evolution tree with all its phases.
struct EvolutionTree: Hashable {
    let evolutionId: String
    let displayName: String
    let themeColor: Color
    let phases: [EvolutionPhase]

    /// Returns the phase at given 1-indexed position.
    func phase(at index: Int) -> EvolutionPhase? {
        guard index >= 1, index <= phases.count else { return nil }
        return phases[index - 1]
    }

    var maxPhases: Int { phases.count }
}

// MARK: - Plant Evolution Tree

extension EvolutionTree {
    static let plant = EvolutionTree(
        evolutionId: "plant",
        displayName: "Plant",
        themeColor: .green,
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "plant", displayScale: 0.95, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "plant", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "plant", displayScale: 1.12, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "plant", displayScale: 1.40, idleConfig: .default),
        ]
    )
}
