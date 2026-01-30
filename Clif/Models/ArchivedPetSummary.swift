import Foundation

/// Lightweight summary for archived pet listings.
/// Contains only fields needed for ArchivedPetRow, ArchivedPetGridItem, EssenceCollectionCarousel.
struct ArchivedPetSummary: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int

    var finalPhase: Int { currentPhase }
}

// MARK: - Factory Methods

extension ArchivedPetSummary {
    init(from pet: ArchivedPet) {
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistory = pet.evolutionHistory
        self.purpose = pet.purpose
        self.archivedAt = pet.archivedAt
        self.totalDays = pet.totalDays
    }
}

// MARK: - Mock Data

extension ArchivedPetSummary {
    static func mock(
        name: String = "Fern",
        phase: Int = 4,
        isBlown: Bool = false,
        totalDays: Int = 21
    ) -> ArchivedPetSummary {
        ArchivedPetSummary(
            id: UUID(),
            name: name,
            evolutionHistory: .mock(phase: phase, essence: .plant, totalDays: totalDays, isBlown: isBlown),
            purpose: "Social Media",
            archivedAt: Date(),
            totalDays: totalDays
        )
    }

    static func mockList() -> [ArchivedPetSummary] {
        [
            .mock(name: "Fern", phase: 4, isBlown: false, totalDays: 21),
            .mock(name: "Ivy", phase: 4, isBlown: false, totalDays: 18),
            .mock(name: "Storm", phase: 3, isBlown: true, totalDays: 5),
            .mock(name: "Sprout", phase: 2, isBlown: true, totalDays: 4)
        ]
    }
}
