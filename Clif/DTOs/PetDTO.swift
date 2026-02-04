import Foundation

/// Codable DTO for Pet persistence.
/// windPoints, lastThresholdSeconds, and activeBreak are NOT stored - Pet reads from SharedDefaults as single source of truth.
struct PetDTO: Codable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let preset: WindPreset
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let limitedSourceChangesCount: Int
    let breakHistory: [CompletedBreak]

    init(from pet: Pet) {
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistory = pet.evolutionHistory
        self.purpose = pet.purpose
        self.preset = pet.preset
        self.dailyStats = pet.dailyStats
        self.limitedSources = pet.limitedSources
        self.limitedSourceChangesCount = pet.limitedSourceChangesCount
        self.breakHistory = pet.breakHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        evolutionHistory = try container.decode(EvolutionHistory.self, forKey: .evolutionHistory)
        purpose = try container.decodeIfPresent(String.self, forKey: .purpose)
        preset = try container.decode(WindPreset.self, forKey: .preset)
        dailyStats = try container.decode([DailyUsageStat].self, forKey: .dailyStats)
        limitedSources = try container.decode([LimitedSource].self, forKey: .limitedSources)
        limitedSourceChangesCount = try container.decodeIfPresent(Int.self, forKey: .limitedSourceChangesCount) ?? 0
        breakHistory = try container.decode([CompletedBreak].self, forKey: .breakHistory)
    }
}

extension Pet {
    convenience init(from dto: PetDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            evolutionHistory: dto.evolutionHistory,
            purpose: dto.purpose,
            preset: dto.preset,
            dailyStats: dto.dailyStats,
            limitedSources: dto.limitedSources,
            limitedSourceChangesCount: dto.limitedSourceChangesCount,
            breakHistory: dto.breakHistory
        )
    }
}
