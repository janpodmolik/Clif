import Foundation

/// Usage data for a single blocked app during pet's lifetime.
struct ArchivedAppUsage: Codable, Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let totalMinutes: Int

    init(id: UUID = UUID(), displayName: String, totalMinutes: Int) {
        self.id = id
        self.displayName = displayName
        self.totalMinutes = totalMinutes
    }
}

struct ArchivedPet: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int
    let dailyLimitMinutes: Int
    let dailyStats: [BlockedAppsDailyStat]
    let appUsage: [ArchivedAppUsage]

    var isBlown: Bool { evolutionHistory.isBlown }
    var finalPhase: Int { evolutionHistory.currentPhase }
    var essence: Essence { evolutionHistory.essence }
    var phase: EvolutionPhase? { essence.phase(at: finalPhase) }

    /// Returns last 7 days of stats for chart display, or all if less than 7.
    var weeklyStats: BlockedAppsWeeklyStats {
        let lastSevenDays = Array(dailyStats.suffix(7))
        return BlockedAppsWeeklyStats(days: lastSevenDays)
    }

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        totalDays: Int,
        dailyLimitMinutes: Int = 60,
        dailyStats: [BlockedAppsDailyStat] = [],
        appUsage: [ArchivedAppUsage] = []
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
        let dailyStats = (0..<totalDays).map { dayOffset -> BlockedAppsDailyStat in
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
            return BlockedAppsDailyStat(date: date, totalMinutes: minutes)
        }

        // Generate app usage
        let appUsage = [
            ArchivedAppUsage(displayName: "Instagram", totalMinutes: Int.random(in: 60...180)),
            ArchivedAppUsage(displayName: "TikTok", totalMinutes: Int.random(in: 40...120)),
            ArchivedAppUsage(displayName: "Twitter", totalMinutes: Int.random(in: 20...80)),
            ArchivedAppUsage(displayName: "YouTube", totalMinutes: Int.random(in: 30...100)),
            ArchivedAppUsage(displayName: "Facebook", totalMinutes: Int.random(in: 10...50))
        ].sorted { $0.totalMinutes > $1.totalMinutes }

        return ArchivedPet(
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
}
