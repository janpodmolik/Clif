import Foundation

/// Codable DTO for EvolutionHistory persistence.
/// Uses `String?` for essence to gracefully handle unknown/removed essence values.
struct EvolutionHistoryDTO: Codable, Equatable {
    let createdAt: Date
    let essence: String?
    let events: [EvolutionEvent]
    let blownAt: Date?
    let lastProgressDate: Date?
    let nextEvolutionUnlockDate: Date?

    init(
        createdAt: Date,
        essence: String?,
        events: [EvolutionEvent],
        blownAt: Date?,
        lastProgressDate: Date?,
        nextEvolutionUnlockDate: Date?
    ) {
        self.createdAt = createdAt
        self.essence = essence
        self.events = events
        self.blownAt = blownAt
        self.lastProgressDate = lastProgressDate
        self.nextEvolutionUnlockDate = nextEvolutionUnlockDate
    }

    init(from model: EvolutionHistory) {
        self.createdAt = model.createdAt
        self.essence = model.essenceRawValue
        self.events = model.events
        self.blownAt = model.blownAt
        self.lastProgressDate = model.lastProgressDate
        self.nextEvolutionUnlockDate = model.nextEvolutionUnlockDate
    }
}
