import Foundation

/// Represents an evolution path with all its phases.
/// Each Essence maps to exactly one EvolutionPath.
struct EvolutionPath: Hashable {
    let id: String
    let displayName: String
    let phases: [EvolutionPhase]

    /// Returns the phase at given 1-indexed position.
    func phase(at index: Int) -> EvolutionPhase? {
        guard index >= 1, index <= phases.count else { return nil }
        return phases[index - 1]
    }

    var maxPhases: Int { phases.count }
}

// MARK: - Essence Lookup

extension EvolutionPath {
    /// Returns the evolution path for a given essence.
    static func path(for essence: Essence) -> EvolutionPath {
        switch essence {
        case .plant: return .plant
        case .troll: return .troll
        case .orc: return .orc
        case .clicker: return .clicker
        }
    }
}

// MARK: - Plant Evolution Path

extension EvolutionPath {
    static let plant = EvolutionPath(
        id: "plant",
        displayName: "Plant",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "plant", displayScale: 0.95, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "plant", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "plant", displayScale: 1.12, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "plant", displayScale: 1.40, idleConfig: .default),
            EvolutionPhase(phaseNumber: 5, evolutionId: "plant", displayScale: 1.40, idleConfig: .default),
            EvolutionPhase(phaseNumber: 6, evolutionId: "plant", displayScale: 1.40, idleConfig: .default),
            EvolutionPhase(phaseNumber: 7, evolutionId: "plant", displayScale: 1.50, idleConfig: .default),
            EvolutionPhase(phaseNumber: 8, evolutionId: "plant", displayScale: 1.50, idleConfig: .default),
        ]
    )
}

// MARK: - Troll Evolution Path

extension EvolutionPath {
    static let troll = EvolutionPath(
        id: "troll",
        displayName: "Troll",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "troll", displayScale: 0.80, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "troll", displayScale: 0.80, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "troll", displayScale: 0.80, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "troll", displayScale: 0.84, idleConfig: .default),
            EvolutionPhase(phaseNumber: 5, evolutionId: "troll", displayScale: 1.10, idleConfig: .default),
            EvolutionPhase(phaseNumber: 6, evolutionId: "troll", displayScale: 1.25, idleConfig: .default),
        ]
    )
}

// MARK: - Orc Evolution Path

extension EvolutionPath {
    static let orc = EvolutionPath(
        id: "orc",
        displayName: "Orc",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "orc", displayScale: 0.85, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "orc", displayScale: 0.90, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "orc", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "orc", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 5, evolutionId: "orc", displayScale: 1.10, idleConfig: .default),
        ]
    )
}

// MARK: - Clicker Evolution Path

extension EvolutionPath {
    static let clicker = EvolutionPath(
        id: "clicker",
        displayName: "Clicker",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "clicker", displayScale: 0.85, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "clicker", displayScale: 0.95, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "clicker", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "clicker", displayScale: 1.15, idleConfig: .default),
        ]
    )
}
