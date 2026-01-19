import Foundation

/// Protocol for usage stats that can be displayed in charts.
protocol UsageStatsProtocol {
    var days: [DailyUsageStat] { get }
    var dailyLimitMinutes: Int { get }
    var maxMinutes: Int { get }
}

/// Daily usage data point for limited apps.
struct DailyUsageStat: Codable, Identifiable, Equatable {
    let id: UUID
    let petId: UUID
    let date: Date
    let totalMinutes: Int
    /// Whether limit was exceeded this day (wind reached 100 for dynamic, minutes > limit for daily).
    let wasOverLimit: Bool

    init(id: UUID = UUID(), petId: UUID, date: Date, totalMinutes: Int, wasOverLimit: Bool = false) {
        self.id = id
        self.petId = petId
        self.date = date
        self.totalMinutes = totalMinutes
        self.wasOverLimit = wasOverLimit
    }
}

// MARK: - Mock Data

extension DailyUsageStat {
    /// Creates mock daily stats for testing.
    /// - Parameters:
    ///   - minMinutes: Minimum minutes per day (default 20).
    ///   - dailyLimitMinutes: Daily limit (Daily mode). If nil, uses Dynamic mode.
    ///   - wasBlown: If true, last day exceeded limit and pet was blown away.
    ///
    /// Logic: All days except last must be under limit (otherwise pet would already be blown).
    /// Last day can exceed limit only if wasBlown is true.
    static func mockList(
        petId: UUID,
        days: Int,
        minMinutes: Int = 20,
        dailyLimitMinutes: Int? = nil,
        wasBlown: Bool = false
    ) -> [DailyUsageStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            let isLastDay = dayOffset == days - 1

            let minutes: Int
            let wasOverLimit: Bool

            if let limit = dailyLimitMinutes {
                // Daily mode: all days except last must be under limit
                if isLastDay && wasBlown {
                    // Last day, blown - exceed limit
                    minutes = Int.random(in: (limit + 1)...(limit + 60))
                    wasOverLimit = true
                } else {
                    // Normal day - random between min and (limit - 1), clamped to valid range
                    let upperBound = max(minMinutes, limit - 1)
                    minutes = Int.random(in: minMinutes...upperBound)
                    wasOverLimit = false
                }
            } else {
                // Dynamic mode: random minutes, only last day can be over limit
                minutes = Int.random(in: minMinutes...120)
                wasOverLimit = wasBlown && isLastDay
            }
            return DailyUsageStat(petId: petId, date: date, totalMinutes: minutes, wasOverLimit: wasOverLimit)
        }
    }
}

/// Weekly stats container for chart display.
struct WeeklyUsageStats: Codable, Equatable, UsageStatsProtocol {
    let days: [DailyUsageStat]
    let dailyLimitMinutes: Int
    let previousWeekTotal: Int?

    init(days: [DailyUsageStat], dailyLimitMinutes: Int, previousWeekTotal: Int? = nil) {
        self.days = days
        self.dailyLimitMinutes = dailyLimitMinutes
        self.previousWeekTotal = previousWeekTotal
    }

    var averageMinutes: Int {
        guard !days.isEmpty else { return 0 }
        return days.reduce(0) { $0 + $1.totalMinutes } / days.count
    }

    var maxMinutes: Int {
        days.map(\.totalMinutes).max() ?? 0
    }

    var totalMinutes: Int {
        days.reduce(0) { $0 + $1.totalMinutes }
    }

    /// Trend percentage compared to previous week (positive = worse, negative = better)
    var trendPercentage: Int? {
        guard let previous = previousWeekTotal, previous > 0 else { return nil }
        return ((totalMinutes - previous) * 100) / previous
    }

    /// Day with highest usage
    var worstDay: DailyUsageStat? {
        days.max(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// Day with lowest usage
    var bestDay: DailyUsageStat? {
        days.min(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// For mini chart - returns normalized values (0-1)
    func normalizedValues() -> [CGFloat] {
        guard maxMinutes > 0 else { return days.map { _ in 0 } }
        return days.map { CGFloat($0.totalMinutes) / CGFloat(maxMinutes) }
    }

    /// Days over limit count.
    var daysOverLimit: Int {
        days.filter(\.wasOverLimit).count
    }

    /// Empty stats
    static func empty(dailyLimitMinutes: Int = 60) -> WeeklyUsageStats {
        WeeklyUsageStats(days: [], dailyLimitMinutes: dailyLimitMinutes)
    }

    /// Creates mock data for preview/debug purposes.
    /// All days are under limit (pet still alive).
    static func mock(dailyLimitMinutes: Int = 60) -> WeeklyUsageStats {
        let mockPetId = UUID()
        let days = DailyUsageStat.mockList(
            petId: mockPetId,
            days: 7,
            dailyLimitMinutes: dailyLimitMinutes
        )
        // Mock previous week total (slightly higher to show improvement)
        let currentTotal = days.reduce(0) { $0 + $1.totalMinutes }
        let previousWeekTotal = Int(Double(currentTotal) * 1.15)
        return WeeklyUsageStats(days: days, dailyLimitMinutes: dailyLimitMinutes, previousWeekTotal: previousWeekTotal)
    }
}
