import Foundation

/// Lightweight summary for archived pet listings.
/// Contains only fields needed for ArchivedPetRow, ArchivedPetGridItem, EssenceCollectionCarousel.
struct ArchivedPetSummary: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int
    let archiveReason: ArchiveReason

    let evolutionHistory: EvolutionHistory

    var finalPhase: Int { currentPhase }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, name, purpose, archivedAt, totalDays, archiveReason
        case evolutionHistory
    }

    init(
        id: UUID,
        name: String,
        purpose: String?,
        archivedAt: Date,
        totalDays: Int,
        archiveReason: ArchiveReason,
        evolutionHistory: EvolutionHistory
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.totalDays = totalDays
        self.archiveReason = archiveReason
        self.evolutionHistory = evolutionHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        purpose = try container.decodeIfPresent(String.self, forKey: .purpose)
        archivedAt = try container.decode(Date.self, forKey: .archivedAt)
        totalDays = try container.decode(Int.self, forKey: .totalDays)
        archiveReason = try container.decode(ArchiveReason.self, forKey: .archiveReason)
        let dto = try container.decode(EvolutionHistoryDTO.self, forKey: .evolutionHistory)
        evolutionHistory = EvolutionHistory(from: dto)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(purpose, forKey: .purpose)
        try container.encode(archivedAt, forKey: .archivedAt)
        try container.encode(totalDays, forKey: .totalDays)
        try container.encode(archiveReason, forKey: .archiveReason)
        try container.encode(EvolutionHistoryDTO(from: evolutionHistory), forKey: .evolutionHistory)
    }
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
        return ArchivedPetSummary(
            id: UUID(),
            name: name,
            purpose: "Social Media",
            archivedAt: Date(),
            totalDays: totalDays,
            archiveReason: archiveReason,
            evolutionHistory: .mock(
                phase: phase,
                essence: .plant,
                totalDays: totalDays,
                isBlown: archiveReason == .blown
            )
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
