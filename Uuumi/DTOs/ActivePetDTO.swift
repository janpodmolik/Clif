import Foundation

/// DTO for the `active_pets` remote table.
/// Maps between local PetLocalDTO and remote JSONB columns.
struct ActivePetDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let purpose: String?
    let preset: String
    let lastLimitedSourceChangeDate: Date?
    let evolutionHistory: EvolutionHistoryDTO
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let breakHistory: [CompletedBreak]
    let windPoints: Double
    let isBlownAway: Bool
    let hourlyAggregate: HourlyAggregate?
    let hourlyPerDay: [DailyHourlyBreakdown]
    let schemaVersion: Int
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, preset
        case userId = "user_id"
        case lastLimitedSourceChangeDate = "last_limited_source_change_date"
        case evolutionHistory = "evolution_history"
        case dailyStats = "daily_stats"
        case limitedSources = "limited_sources"
        case breakHistory = "break_history"
        case windPoints = "wind_points"
        case isBlownAway = "is_blown_away"
        case hourlyAggregate = "hourly_aggregate"
        case hourlyPerDay = "hourly_per_day"
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
    }

    /// Creates a remote DTO from local PetLocalDTO + sync data.
    init(
        from petDTO: PetLocalDTO,
        userId: UUID,
        windPoints: Double,
        isBlownAway: Bool,
        hourlyAggregate: HourlyAggregate?,
        hourlyPerDay: [DailyHourlyBreakdown]
    ) {
        self.id = petDTO.id
        self.userId = userId
        self.name = petDTO.name
        self.purpose = petDTO.purpose
        self.preset = petDTO.preset.rawValue
        self.lastLimitedSourceChangeDate = petDTO.lastLimitedSourceChangeDate
        self.evolutionHistory = petDTO.evolutionHistory
        self.dailyStats = petDTO.dailyStats
        self.limitedSources = petDTO.limitedSources
        self.breakHistory = petDTO.breakHistory
        self.windPoints = windPoints
        self.isBlownAway = isBlownAway
        self.hourlyAggregate = hourlyAggregate
        self.hourlyPerDay = hourlyPerDay
        self.schemaVersion = 1
        self.updatedAt = Date()
    }
}

// MARK: - Conversion to PetLocalDTO

extension PetLocalDTO {
    /// Creates a PetLocalDTO from a cloud DTO (used during restore).
    init(from remoteDTO: ActivePetDTO) {
        self.init(
            id: remoteDTO.id,
            name: remoteDTO.name,
            evolutionHistory: remoteDTO.evolutionHistory,
            purpose: remoteDTO.purpose,
            preset: WindPreset(rawValue: remoteDTO.preset) ?? .balanced,
            dailyStats: remoteDTO.dailyStats,
            limitedSources: remoteDTO.limitedSources,
            lastLimitedSourceChangeDate: remoteDTO.lastLimitedSourceChangeDate,
            breakHistory: remoteDTO.breakHistory
        )
    }
}
