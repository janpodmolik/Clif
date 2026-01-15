import Foundation

struct ArchivedPet: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int
    let dailyLimitMinutes: Int
    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]

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
        totalDays: Int,
        dailyLimitMinutes: Int = 60,
        dailyStats: [DailyUsageStat] = [],
        appUsage: [AppUsage] = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.totalDays = totalDays
        self.dailyLimitMinutes = dailyLimitMinutes
        self.dailyStats = dailyStats
        self.appUsage = appUsage
    }
}

// MARK: - Mock Data

extension ArchivedPet {
    static func mock(
        name: String = "Fern",
        phase: Int = 4,
        isBlown: Bool = false,
        daysAgo: Int = 14,
        totalDays: Int = 12,
        dailyLimitMinutes: Int = 60
    ) -> ArchivedPet {
        let petId = UUID()
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        if phase > 1 {
            for p in 2...phase {
                let offset = -daysAgo + (p * 3)
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                events.append(EvolutionEvent(fromPhase: p - 1, toPhase: p, date: date))
            }
        }

        let archivedAt = calendar.date(byAdding: .day, value: -daysAgo + totalDays, to: Date()) ?? Date()
        let blownAt = isBlown ? archivedAt : nil

        // Generate daily stats
        let dailyStats = (0..<totalDays).map { dayOffset -> DailyUsageStat in
            let date = calendar.date(byAdding: .day, value: -daysAgo + dayOffset, to: Date()) ?? Date()
            let isLastDay = dayOffset == totalDays - 1
            let minutes: Int
            if isBlown && isLastDay {
                // Last day exceeded limit
                minutes = dailyLimitMinutes + Int.random(in: 10...30)
            } else {
                // Under limit
                minutes = Int.random(in: 5...(dailyLimitMinutes - 5))
            }
            return DailyUsageStat(petId: petId, date: date, totalMinutes: minutes)
        }

        // Generate app usage with daily breakdown
        let appUsage = AppUsage.mockList(days: totalDays, petId: petId)

        return ArchivedPet(
            id: petId,
            name: name,
            evolutionHistory: EvolutionHistory(
                createdAt: createdAt,
                essence: .plant,
                events: events,
                blownAt: blownAt
            ),
            purpose: "Social Media",
            archivedAt: archivedAt,
            totalDays: totalDays,
            dailyLimitMinutes: dailyLimitMinutes,
            dailyStats: dailyStats,
            appUsage: appUsage
        )
    }

    static func mockList() -> [ArchivedPet] {
        [
            .mock(name: "Fern", phase: 4, isBlown: false, daysAgo: 28, totalDays: 21),
            .mock(name: "Ivy", phase: 4, isBlown: false, daysAgo: 45, totalDays: 18),
            .mock(name: "Willow", phase: 4, isBlown: false, daysAgo: 60, totalDays: 25),
            .mock(name: "Sage", phase: 4, isBlown: false, daysAgo: 90, totalDays: 30),
            .mock(name: "Clover", phase: 4, isBlown: false, daysAgo: 120, totalDays: 28),
            .mock(name: "Moss", phase: 3, isBlown: true, daysAgo: 14, totalDays: 9),
            .mock(name: "Sprout", phase: 2, isBlown: true, daysAgo: 10, totalDays: 4),
            .mock(name: "Leaf", phase: 1, isBlown: true, daysAgo: 5, totalDays: 2)
        ]
    }

    /// Creates a mock blob (no essence) for preview purposes
    static func mockBlob(name: String = "Blobby", totalDays: Int = 3) -> ArchivedPet {
        let petId = UUID()
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -totalDays, to: Date()) ?? Date()

        return ArchivedPet(
            id: petId,
            name: name,
            evolutionHistory: EvolutionHistory(createdAt: createdAt, essence: nil, events: []),
            purpose: nil,
            archivedAt: Date(),
            totalDays: totalDays,
            dailyLimitMinutes: 60,
            dailyStats: [],
            appUsage: []
        )
    }
}

// MARK: - Archiving from ActivePet

extension ArchivedPet {
    /// Creates an archived pet from an active pet.
    init(archiving pet: ActivePet, archivedAt: Date = Date()) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            archivedAt: archivedAt,
            totalDays: pet.totalDays,
            dailyLimitMinutes: pet.dailyLimitMinutes,
            dailyStats: pet.dailyStats,
            appUsage: pet.appUsage
        )
    }
}
