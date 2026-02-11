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

    init(
        id: UUID,
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        preset: WindPreset,
        dailyStats: [DailyUsageStat],
        limitedSources: [LimitedSource],
        limitedSourceChangesCount: Int,
        breakHistory: [CompletedBreak]
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.preset = preset
        self.dailyStats = dailyStats
        self.limitedSources = limitedSources
        self.limitedSourceChangesCount = limitedSourceChangesCount
        self.breakHistory = breakHistory
    }

    init(from pet: Pet) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            preset: pet.preset,
            dailyStats: pet.dailyStats,
            limitedSources: pet.limitedSources,
            limitedSourceChangesCount: pet.limitedSourceChangesCount,
            breakHistory: pet.breakHistory
        )
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
