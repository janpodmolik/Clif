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
        case .lion: return .lion
        case .stitches: return .stitches
        case .racoon: return .racoon
        case .moss: return .moss
        case .shroom: return .shroom
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
            EvolutionPhase(phaseNumber: 2, evolutionId: "orc", displayScale: 0.87, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "orc", displayScale: 0.98, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "orc", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 5, evolutionId: "orc", displayScale: 1.00, idleConfig: .default),
        ]
    )
}

// MARK: - Clicker Evolution Path

extension EvolutionPath {
    static let clicker = EvolutionPath(
        id: "clicker",
        displayName: "Clicker",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "clicker", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "clicker", displayScale: 1.04, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "clicker", displayScale: 1.11, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "clicker", displayScale: 1.14, idleConfig: .default),
        ]
    )
}

// MARK: - Lion Evolution Path

extension EvolutionPath {
    static let lion = EvolutionPath(
        id: "lion",
        displayName: "Lion",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "lion", displayScale: 0.88, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "lion", displayScale: 0.95, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "lion", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "lion", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 5, evolutionId: "lion", displayScale: 1.12, idleConfig: .default),
        ]
    )
}

// MARK: - Stitches Evolution Path

extension EvolutionPath {
    static let stitches = EvolutionPath(
        id: "stitches",
        displayName: "Stitches",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "stitches", displayScale: 0.85, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "stitches", displayScale: 0.90, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "stitches", displayScale: 0.92, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "stitches", displayScale: 0.97, idleConfig: .default),
        ]
    )
}

// MARK: - Racoon Evolution Path

extension EvolutionPath {
    static let racoon = EvolutionPath(
        id: "racoon",
        displayName: "Racoon",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "racoon", displayScale: 0.85, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "racoon", displayScale: 0.87, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "racoon", displayScale: 0.93, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "racoon", displayScale: 0.99, idleConfig: .default),
        ]
    )
}

// MARK: - Moss Evolution Path

extension EvolutionPath {
    static let moss = EvolutionPath(
        id: "moss",
        displayName: "Moss",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "moss", displayScale: 0.90, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "moss", displayScale: 0.96, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "moss", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "moss", displayScale: 1.05, idleConfig: .default),
        ]
    )
}

// MARK: - Shroom Evolution Path

extension EvolutionPath {
    static let shroom = EvolutionPath(
        id: "shroom",
        displayName: "Shroom",
        phases: [
            EvolutionPhase(phaseNumber: 1, evolutionId: "shroom", displayScale: 1.00, idleConfig: .default),
            EvolutionPhase(phaseNumber: 2, evolutionId: "shroom", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 3, evolutionId: "shroom", displayScale: 1.05, idleConfig: .default),
            EvolutionPhase(phaseNumber: 4, evolutionId: "shroom", displayScale: 1.10, idleConfig: .default),
        ]
    )
}
