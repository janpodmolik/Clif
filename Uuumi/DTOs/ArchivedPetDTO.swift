import Foundation

/// DTO for the `archived_pets` remote table.
/// Maps between local ArchivedPet and remote JSONB columns.
struct ArchivedPetDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let purpose: String?
    let preset: String
    let archivedAt: Date
    let archiveReason: String
    let peakWindPoints: Double
    let totalBreakMinutes: Double
    let totalWindDecreased: Double
    let evolutionHistory: EvolutionHistoryDTO
    let dailyStats: [DailyUsageStat]
    let breakHistory: [CompletedBreak]
    let hourlyAggregate: HourlyAggregate?
    let hourlyPerDay: [DailyHourlyBreakdown]
    let schemaVersion: Int

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, preset
        case userId = "user_id"
        case archivedAt = "archived_at"
        case archiveReason = "archive_reason"
        case peakWindPoints = "peak_wind_points"
        case totalBreakMinutes = "total_break_minutes"
        case totalWindDecreased = "total_wind_decreased"
        case evolutionHistory = "evolution_history"
        case dailyStats = "daily_stats"
        case breakHistory = "break_history"
        case hourlyAggregate = "hourly_aggregate"
        case hourlyPerDay = "hourly_per_day"
        case schemaVersion = "schema_version"
    }

    /// Creates a remote DTO from a local ArchivedPet + hourly data.
    init(
        from archivedPet: ArchivedPet,
        userId: UUID,
        hourlyAggregate: HourlyAggregate? = nil,
        hourlyPerDay: [DailyHourlyBreakdown] = []
    ) {
        self.id = archivedPet.id
        self.userId = userId
        self.name = archivedPet.name
        self.purpose = archivedPet.purpose
        self.preset = archivedPet.preset.rawValue
        self.archivedAt = archivedPet.archivedAt
        self.archiveReason = archivedPet.archiveReason.rawValue
        self.peakWindPoints = archivedPet.peakWindPoints
        self.totalBreakMinutes = archivedPet.totalBreakMinutes
        self.totalWindDecreased = archivedPet.totalWindDecreased
        self.evolutionHistory = EvolutionHistoryDTO(from: archivedPet.evolutionHistory)
        self.dailyStats = archivedPet.dailyStats
        self.breakHistory = archivedPet.breakHistory
        self.hourlyAggregate = hourlyAggregate
        self.hourlyPerDay = hourlyPerDay
        self.schemaVersion = 1
    }
}

// MARK: - Conversion to ArchivedPet

extension ArchivedPet {
    /// Creates an ArchivedPet from a cloud DTO (used during restore).
    init(from remoteDTO: ArchivedPetDTO) {
        self.init(
            id: remoteDTO.id,
            name: remoteDTO.name,
            evolutionHistory: EvolutionHistory(from: remoteDTO.evolutionHistory),
            purpose: remoteDTO.purpose,
            archivedAt: remoteDTO.archivedAt,
            archiveReason: ArchiveReason(rawValue: remoteDTO.archiveReason) ?? .manual,
            dailyStats: remoteDTO.dailyStats,
            breakHistory: remoteDTO.breakHistory,
            peakWindPoints: remoteDTO.peakWindPoints,
            totalBreakMinutes: remoteDTO.totalBreakMinutes,
            totalWindDecreased: remoteDTO.totalWindDecreased,
            preset: WindPreset(rawValue: remoteDTO.preset) ?? .balanced
        )
    }
}
