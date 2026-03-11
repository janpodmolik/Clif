import Foundation

/// Codable DTO for Pet persistence.
/// windPoints, lastThresholdSeconds, and activeBreak are NOT stored - Pet reads from SharedDefaults as single source of truth.
struct PetLocalDTO: Codable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistoryDTO
    let purpose: String?
    let preset: WindPreset
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let lastLimitedSourceChangeDate: Date?
    let breakHistory: [CompletedBreak]

    init(
        id: UUID,
        name: String,
        evolutionHistory: EvolutionHistoryDTO,
        purpose: String?,
        preset: WindPreset,
        dailyStats: [DailyUsageStat],
        limitedSources: [LimitedSource],
        lastLimitedSourceChangeDate: Date?,
        breakHistory: [CompletedBreak]
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.preset = preset
        self.dailyStats = dailyStats
        self.limitedSources = limitedSources
        self.lastLimitedSourceChangeDate = lastLimitedSourceChangeDate
        self.breakHistory = breakHistory
    }

    init(from pet: Pet) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: EvolutionHistoryDTO(from: pet.evolutionHistory),
            purpose: pet.purpose,
            preset: pet.preset,
            dailyStats: pet.dailyStats,
            limitedSources: pet.limitedSources,
            lastLimitedSourceChangeDate: pet.lastLimitedSourceChangeDate,
            breakHistory: pet.breakHistory
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        evolutionHistory = try container.decode(EvolutionHistoryDTO.self, forKey: .evolutionHistory)
        purpose = try container.decodeIfPresent(String.self, forKey: .purpose)
        preset = try container.decode(WindPreset.self, forKey: .preset)
        dailyStats = try container.decode([DailyUsageStat].self, forKey: .dailyStats)
        limitedSources = try container.decode([LimitedSource].self, forKey: .limitedSources)
        lastLimitedSourceChangeDate = try container.decodeIfPresent(Date.self, forKey: .lastLimitedSourceChangeDate)
        breakHistory = try container.decode([CompletedBreak].self, forKey: .breakHistory)
    }
}

extension Pet {
    convenience init(from dto: PetLocalDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            evolutionHistory: EvolutionHistory(from: dto.evolutionHistory),
            purpose: dto.purpose,
            preset: dto.preset,
            dailyStats: dto.dailyStats,
            limitedSources: dto.limitedSources,
            lastLimitedSourceChangeDate: dto.lastLimitedSourceChangeDate,
            breakHistory: dto.breakHistory
        )
    }
}
