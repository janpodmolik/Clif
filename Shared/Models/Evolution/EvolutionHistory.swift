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
    let essence: Essence
    private(set) var events: [EvolutionEvent]
    private(set) var blownAt: Date?

    var currentPhase: Int {
        events.last?.toPhase ?? 1
    }

    var maxPhase: Int {
        essence.maxPhases
    }

    var canEvolve: Bool {
        currentPhase < maxPhase
    }

    var isBlown: Bool {
        blownAt != nil
    }

    init(createdAt: Date = Date(), essence: Essence, events: [EvolutionEvent] = [], blownAt: Date? = nil) {
        self.createdAt = createdAt
        self.essence = essence
        self.events = events
        self.blownAt = blownAt
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
