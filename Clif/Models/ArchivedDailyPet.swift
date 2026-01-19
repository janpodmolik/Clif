import Foundation

struct ArchivedDailyPet: Codable, Identifiable, Equatable, PetWithSources {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let dailyLimitMinutes: Int

    // MARK: - PetWithSources

    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]

    /// Alias for currentPhase - the phase when pet was archived
    var finalPhase: Int { currentPhase }

    /// Returns last 7 days of stats for chart display, or all if less than 7.
    var weeklyStats: WeeklyUsageStats {
        let lastSevenDays = Array(dailyStats.suffix(7))
        return WeeklyUsageStats(days: lastSevenDays, dailyLimitMinutes: dailyLimitMinutes)
    }

    /// Full statistics for extended history display.
    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats, dailyLimitMinutes: dailyLimitMinutes)
    }

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        dailyLimitMinutes: Int = 60,
        dailyStats: [DailyUsageStat] = [],
        limitedSources: [LimitedSource] = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.dailyLimitMinutes = dailyLimitMinutes
        self.dailyStats = dailyStats
        self.limitedSources = limitedSources
    }
}

// MARK: - Mock Data

extension ArchivedDailyPet {
    static func mock(
        name: String = "Fern",
        phase: Int = 4,
        isBlown: Bool = false,
        daysAgo: Int = 14,
        totalDays: Int = 12,
        dailyLimitMinutes: Int = 60
    ) -> ArchivedDailyPet {
        let petId = UUID()
        let calendar = Calendar.current
        let archivedAt = calendar.date(byAdding: .day, value: -daysAgo + totalDays, to: Date()) ?? Date()

        // Generate daily stats with special blow away logic
        let dailyStats = (0..<totalDays).map { dayOffset -> DailyUsageStat in
            let date = calendar.date(byAdding: .day, value: -(totalDays - 1) + dayOffset, to: archivedAt)!
            let isLastDay = dayOffset == totalDays - 1
            let minutes: Int
            if isBlown && isLastDay {
                minutes = dailyLimitMinutes + Int.random(in: 10...30)
            } else {
                minutes = Int.random(in: 5...(dailyLimitMinutes - 5))
            }
            return DailyUsageStat(petId: petId, date: date, totalMinutes: minutes)
        }

        return ArchivedDailyPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: .plant, totalDays: totalDays, isBlown: isBlown),
            purpose: "Social Media",
            archivedAt: archivedAt,
            dailyLimitMinutes: dailyLimitMinutes,
            dailyStats: dailyStats,
            limitedSources: LimitedSource.mockList(days: totalDays)
        )
    }

    static func mockList() -> [ArchivedDailyPet] {
        [
            .mock(name: "Fern", phase: 4, isBlown: false, totalDays: 21),
            .mock(name: "Ivy", phase: 4, isBlown: false, totalDays: 18),
            .mock(name: "Willow", phase: 4, isBlown: false, totalDays: 25),
            .mock(name: "Sage", phase: 4, isBlown: false, totalDays: 30),
            .mock(name: "Clover", phase: 4, isBlown: false, totalDays: 28),
            .mock(name: "Moss", phase: 3, isBlown: true, totalDays: 9),
            .mock(name: "Sprout", phase: 2, isBlown: true, totalDays: 4),
            .mock(name: "Leaf", phase: 1, isBlown: true, totalDays: 2)
        ]
    }

    /// Creates a mock blob (no essence) for preview purposes
    static func mockBlob(name: String = "Blobby", totalDays: Int = 3) -> ArchivedDailyPet {
        let petId = UUID()

        return ArchivedDailyPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: 0, essence: nil, totalDays: totalDays),
            purpose: nil,
            archivedAt: Date(),
            dailyLimitMinutes: 60,
            dailyStats: [],
            limitedSources: []
        )
    }
}

// MARK: - Archiving from DailyPet

extension ArchivedDailyPet {
    /// Creates an archived pet from an active pet.
    init(archiving pet: DailyPet, archivedAt: Date = Date()) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            archivedAt: archivedAt,
            dailyLimitMinutes: pet.dailyLimitMinutes,
            dailyStats: pet.dailyStats,
            limitedSources: pet.limitedSources
        )
    }
}
