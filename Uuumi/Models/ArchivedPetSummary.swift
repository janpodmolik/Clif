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

    // MARK: - Evolution (DTO for storage, cached Model for logic)

    private let evolutionHistoryDTO: EvolutionHistoryDTO
    let evolutionHistory: EvolutionHistory

    var finalPhase: Int { currentPhase }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, name, purpose, archivedAt, totalDays, archiveReason
        case evolutionHistoryDTO = "evolutionHistory"
    }

    init(
        id: UUID,
        name: String,
        purpose: String?,
        archivedAt: Date,
        totalDays: Int,
        archiveReason: ArchiveReason,
        evolutionHistoryDTO: EvolutionHistoryDTO,
        evolutionHistory: EvolutionHistory
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.totalDays = totalDays
        self.archiveReason = archiveReason
        self.evolutionHistoryDTO = evolutionHistoryDTO
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
        evolutionHistoryDTO = try container.decode(EvolutionHistoryDTO.self, forKey: .evolutionHistoryDTO)
        evolutionHistory = EvolutionHistory(from: evolutionHistoryDTO)
    }
}

// MARK: - Factory Methods

extension ArchivedPetSummary {
    init(from pet: ArchivedPet) {
        let dto = EvolutionHistoryDTO(from: pet.evolutionHistory)
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistoryDTO = dto
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
        let history = EvolutionHistory.mock(
            phase: phase,
            essence: .plant,
            totalDays: totalDays,
            isBlown: archiveReason == .blown
        )
        return ArchivedPetSummary(
            id: UUID(),
            name: name,
            purpose: "Social Media",
            archivedAt: Date(),
            totalDays: totalDays,
            archiveReason: archiveReason,
            evolutionHistoryDTO: EvolutionHistoryDTO(from: history),
            evolutionHistory: history
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
