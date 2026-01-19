import Foundation

/// Codable DTO for DailyPet persistence.
struct DailyPetDTO: Codable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let todayUsedMinutes: Int
    let dailyLimitMinutes: Int
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]

    init(from pet: DailyPet) {
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistory = pet.evolutionHistory
        self.purpose = pet.purpose
        self.todayUsedMinutes = pet.todayUsedMinutes
        self.dailyLimitMinutes = pet.dailyLimitMinutes
        self.dailyStats = pet.dailyStats
        self.limitedSources = pet.limitedSources
    }
}

extension DailyPet {
    convenience init(from dto: DailyPetDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            evolutionHistory: dto.evolutionHistory,
            purpose: dto.purpose,
            todayUsedMinutes: dto.todayUsedMinutes,
            dailyLimitMinutes: dto.dailyLimitMinutes,
            dailyStats: dto.dailyStats,
            limitedSources: dto.limitedSources
        )
    }
}
