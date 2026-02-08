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
    let archiveReason: ArchiveReason

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
        self.archiveReason = pet.archiveReason
    }
}

// MARK: - Mock Data

extension ArchivedPetSummary {
    static func mock(
        name: String = "Fern",
        phase: Int = 4,
        archiveReason: ArchiveReason = .completed,
        totalDays: Int = 21
    ) -> ArchivedPetSummary {
        ArchivedPetSummary(
            id: UUID(),
            name: name,
            evolutionHistory: .mock(
                phase: phase,
                essence: .plant,
                totalDays: totalDays,
                isBlown: archiveReason == .blown
            ),
            purpose: "Social Media",
            archivedAt: Date(),
            totalDays: totalDays,
            archiveReason: archiveReason
        )
    }

    static func mockList() -> [ArchivedPetSummary] {
        [
            .mock(name: "Fern", phase: 4, archiveReason: .completed, totalDays: 21),
            .mock(name: "Ivy", phase: 4, archiveReason: .completed, totalDays: 18),
            .mock(name: "Storm", phase: 3, archiveReason: .blown, totalDays: 5),
            .mock(name: "Sprout", phase: 2, archiveReason: .blown, totalDays: 4)
        ]
    }
}
