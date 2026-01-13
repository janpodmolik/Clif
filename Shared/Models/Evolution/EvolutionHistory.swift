import Foundation

/// Represents a single evolution transition event.
struct EvolutionEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let fromPhase: Int
    let toPhase: Int
    let date: Date

    init(id: UUID = UUID(), fromPhase: Int, toPhase: Int, date: Date = Date()) {
        self.id = id
        self.fromPhase = fromPhase
        self.toPhase = toPhase
        self.date = date
    }
}

/// Complete evolution history for a pet.
struct EvolutionHistory: Codable, Equatable {
    let createdAt: Date
    private(set) var essence: Essence?
    private(set) var events: [EvolutionEvent]
    private(set) var blownAt: Date?

    /// True if pet is still a blob (no essence applied yet)
    var isBlob: Bool {
        essence == nil
    }

    /// Current phase: 0 for blob, 1+ for evolved pets
    var currentPhase: Int {
        guard essence != nil else { return 0 }
        return events.last?.toPhase ?? 1
    }

    var maxPhase: Int {
        guard let essence else { return 0 }
        return EvolutionPath.path(for: essence).maxPhases
    }

    var canEvolve: Bool {
        guard !isBlob, !isBlown else { return false }
        return currentPhase < maxPhase
    }

    var isBlown: Bool {
        blownAt != nil
    }

    init(createdAt: Date = Date(), essence: Essence? = nil, events: [EvolutionEvent] = [], blownAt: Date? = nil) {
        self.createdAt = createdAt
        self.essence = essence
        self.events = events
        self.blownAt = blownAt
    }

    mutating func applyEssence(_ essence: Essence) {
        guard self.essence == nil else { return }
        self.essence = essence
    }

    mutating func recordEvolution(to phase: Int) {
        let event = EvolutionEvent(
            fromPhase: currentPhase,
            toPhase: phase,
            date: Date()
        )
        events.append(event)
    }

    mutating func markAsBlown() {
        blownAt = Date()
    }

    /// Returns dates for each phase transition for timeline display.
    /// First entry is always phase 1 with createdAt date.
    func phaseDates() -> [(phase: Int, date: Date)] {
        var result: [(Int, Date)] = [(1, createdAt)]
        for event in events {
            result.append((event.toPhase, event.date))
        }
        return result
    }

    /// Returns the date when a specific phase was reached, or nil if not yet reached.
    func dateForPhase(_ phase: Int) -> Date? {
        if phase == 1 {
            return createdAt
        }
        return events.first { $0.toPhase == phase }?.date
    }
}
