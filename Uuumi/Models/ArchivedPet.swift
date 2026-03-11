import Foundation

/// Archived version of a Pet for history/graveyard.
struct ArchivedPet: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let purpose: String?
    let archivedAt: Date
    let archiveReason: ArchiveReason

    let evolutionHistory: EvolutionHistory

    // MARK: - Stats

    let dailyStats: [DailyUsageStat]

    // MARK: - Wind & Breaks

    /// Break history from the pet's lifetime.
    let breakHistory: [CompletedBreak]

    /// Peak wind points reached during lifetime.
    let peakWindPoints: Double

    /// Total break minutes completed.
    let totalBreakMinutes: Double

    /// Total wind points decreased from breaks.
    let totalWindDecreased: Double

    /// Wind preset used for this pet.
    let preset: WindPreset

    // MARK: - Computed

    /// Total days tracked.
    var totalDays: Int { dailyStats.count }

    /// Alias for currentPhase - the phase when pet was archived.
    var finalPhase: Int { currentPhase }

    /// Number of successful breaks.
    var successfulBreaks: Int {
        breakHistory.filter { !$0.wasViolated }.count
    }

    /// Number of violated breaks.
    var violatedBreaks: Int {
        breakHistory.filter(\.wasViolated).count
    }

    /// Full usage stats for history display.
    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, name, purpose, archivedAt, archiveReason
        case evolutionHistory
        case dailyStats, breakHistory
        case peakWindPoints, totalBreakMinutes, totalWindDecreased, preset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        purpose = try container.decodeIfPresent(String.self, forKey: .purpose)
        archivedAt = try container.decode(Date.self, forKey: .archivedAt)
        archiveReason = try container.decode(ArchiveReason.self, forKey: .archiveReason)
        let dto = try container.decode(EvolutionHistoryDTO.self, forKey: .evolutionHistory)
        evolutionHistory = EvolutionHistory(from: dto)
        dailyStats = try container.decode([DailyUsageStat].self, forKey: .dailyStats)
        breakHistory = try container.decode([CompletedBreak].self, forKey: .breakHistory)
        peakWindPoints = try container.decode(Double.self, forKey: .peakWindPoints)
        totalBreakMinutes = try container.decode(Double.self, forKey: .totalBreakMinutes)
        totalWindDecreased = try container.decode(Double.self, forKey: .totalWindDecreased)
        preset = try container.decode(WindPreset.self, forKey: .preset)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(purpose, forKey: .purpose)
        try container.encode(archivedAt, forKey: .archivedAt)
        try container.encode(archiveReason, forKey: .archiveReason)
        try container.encode(EvolutionHistoryDTO(from: evolutionHistory), forKey: .evolutionHistory)
        try container.encode(dailyStats, forKey: .dailyStats)
        try container.encode(breakHistory, forKey: .breakHistory)
        try container.encode(peakWindPoints, forKey: .peakWindPoints)
        try container.encode(totalBreakMinutes, forKey: .totalBreakMinutes)
        try container.encode(totalWindDecreased, forKey: .totalWindDecreased)
        try container.encode(preset, forKey: .preset)
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        archiveReason: ArchiveReason,
        dailyStats: [DailyUsageStat] = [],
        breakHistory: [CompletedBreak] = [],
        peakWindPoints: Double = 0,
        totalBreakMinutes: Double = 0,
        totalWindDecreased: Double = 0,
        preset: WindPreset = .default
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.archiveReason = archiveReason
        self.dailyStats = dailyStats
        self.breakHistory = breakHistory
        self.peakWindPoints = peakWindPoints
        self.totalBreakMinutes = totalBreakMinutes
        self.totalWindDecreased = totalWindDecreased
        self.preset = preset
    }

}

// MARK: - Archiving from Pet

extension ArchivedPet {
    /// Creates an archived pet from an active Pet.
    init(archiving pet: Pet, reason: ArchiveReason, archivedAt: Date = Date()) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            archivedAt: archivedAt,
            archiveReason: reason,
            dailyStats: pet.dailyStats,
            breakHistory: pet.breakHistory,
            peakWindPoints: pet.peakWindPoints,
            totalBreakMinutes: pet.totalBreakMinutes,
            totalWindDecreased: pet.totalWindDecreased,
            preset: pet.preset
        )
    }
}

// MARK: - Mock Data

extension ArchivedPet {
    static func mock(
        name: String = "Windy",
        phase: Int = 3,
        essence: Essence? = .plant,
        archiveReason: ArchiveReason = .blown,
        totalDays: Int = 5
    ) -> ArchivedPet {
        let petId = UUID()
        let calendar = Calendar.current
        let archivedAt = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        // Generate some mock breaks
        let breakHistory: [CompletedBreak] = (0..<3).map { i in
            let startDate = calendar.date(byAdding: .hour, value: -(i * 4), to: archivedAt) ?? archivedAt
            let endDate = startDate.addingTimeInterval(30 * 60)
            return CompletedBreak(
                type: [.free, .committed][i % 2],
                startedAt: startDate,
                endedAt: endDate,
                windAtStart: Double(50 + i * 10),
                windDecreased: Double(10 + i * 5),
                wasViolated: i == 2
            )
        }

        return ArchivedPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(
                phase: phase,
                essence: essence,
                totalDays: totalDays,
                isBlown: archiveReason == .blown
            ),
            purpose: "Social Media",
            archivedAt: archivedAt,
            archiveReason: archiveReason,
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            breakHistory: breakHistory,
            peakWindPoints: 95,
            totalBreakMinutes: 90,
            totalWindDecreased: 35
        )
    }

    static func mockList() -> [ArchivedPet] {
        [
            .mock(name: "Storm", phase: 4, archiveReason: .completed, totalDays: 10),
            .mock(name: "Breeze", phase: 3, archiveReason: .blown, totalDays: 5),
            .mock(name: "Gust", phase: 2, archiveReason: .blown, totalDays: 2)
        ]
    }

    static func mockBlob(name: String = "Blobby") -> ArchivedPet {
        ArchivedPet(
            name: name,
            evolutionHistory: .mock(phase: 0, essence: nil, totalDays: 1, isBlown: false),
            purpose: nil,
            archiveReason: .manual
        )
    }
}
