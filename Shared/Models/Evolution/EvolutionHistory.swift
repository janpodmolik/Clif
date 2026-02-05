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
    private(set) var createdAt: Date
    private(set) var essence: Essence?
    private(set) var events: [EvolutionEvent]
    private(set) var blownAt: Date?
    private(set) var lastProgressDate: Date?

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

    /// Whether evolution or essence application already happened today.
    var hasProgressedToday: Bool {
        guard let lastProgressDate else { return false }
        return Calendar.current.isDateInToday(lastProgressDate)
    }

    var canEvolve: Bool {
        guard !isBlob, !isBlown, !hasProgressedToday else { return false }
        return currentPhase < maxPhase
    }

    /// True if pet has reached the maximum evolution phase.
    var isFullyEvolved: Bool {
        guard !isBlob else { return false }
        return currentPhase >= maxPhase
    }

    var isBlown: Bool {
        blownAt != nil
    }

    init(createdAt: Date = Date(), essence: Essence? = nil, events: [EvolutionEvent] = [], blownAt: Date? = nil, lastProgressDate: Date? = nil) {
        self.createdAt = createdAt
        self.essence = essence
        self.events = events
        self.blownAt = blownAt
        self.lastProgressDate = lastProgressDate
    }

    mutating func applyEssence(_ essence: Essence) {
        guard self.essence == nil else { return }
        self.essence = essence
        lastProgressDate = Date()
        SharedDefaults.addCoins(CoinRewards.evolution)
    }

    mutating func recordEvolution(to phase: Int) {
        let event = EvolutionEvent(
            fromPhase: currentPhase,
            toPhase: phase,
            date: Date()
        )
        events.append(event)
        lastProgressDate = Date()
        SharedDefaults.addCoins(CoinRewards.evolution)
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

#if DEBUG
// MARK: - Debug Helpers

extension EvolutionHistory {
    /// Shifts createdAt back by one day, making the pet appear one day older.
    mutating func debugBumpDay() {
        guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: createdAt) else { return }
        createdAt = newDate
    }

    /// Resets evolution back to blob state (clears essence and all events).
    mutating func debugResetToBlob() {
        essence = nil
        events = []
        blownAt = nil
        lastProgressDate = nil
        createdAt = Date()
    }

    /// Clears the daily progress gate so evolution can be tested again immediately.
    mutating func debugClearDailyProgress() {
        lastProgressDate = nil
    }
}
#endif

// MARK: - Mock Data

extension EvolutionHistory {
    /// Creates mock evolution history for preview/testing.
    static func mock(
        phase: Int = 2,
        essence: Essence? = .plant,
        totalDays: Int = 14,
        isBlown: Bool = false
    ) -> EvolutionHistory {
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -totalDays, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        if essence != nil, phase > 1 {
            for p in 2...phase {
                let offset = p - totalDays
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                events.append(EvolutionEvent(fromPhase: p - 1, toPhase: p, date: date))
            }
        }

        let blownAt: Date? = isBlown ? Date() : nil

        return EvolutionHistory(
            createdAt: createdAt,
            essence: essence,
            events: events,
            blownAt: blownAt,
            lastProgressDate: nil
        )
    }
}
