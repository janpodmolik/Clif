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

    init(id: UUID = UUID(), petId: UUID, date: Date, totalMinutes: Int) {
        self.id = id
        self.petId = petId
        self.date = date
        self.totalMinutes = totalMinutes
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
        days.filter { $0.totalMinutes > dailyLimitMinutes }.count
    }

    /// Empty stats
    static func empty(dailyLimitMinutes: Int = 60) -> WeeklyUsageStats {
        WeeklyUsageStats(days: [], dailyLimitMinutes: dailyLimitMinutes)
    }

    /// Creates mock data for preview/debug purposes
    static func mock(dailyLimitMinutes: Int = 60) -> WeeklyUsageStats {
        let calendar = Calendar.current
        let today = Date()
        let mockPetId = UUID()
        let days = (0..<7).map { dayOffset -> DailyUsageStat in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let minutes = Int.random(in: 30...180)
            return DailyUsageStat(petId: mockPetId, date: date, totalMinutes: minutes)
        }
        // Mock previous week total (slightly higher to show improvement)
        let currentTotal = days.reduce(0) { $0 + $1.totalMinutes }
        let previousWeekTotal = Int(Double(currentTotal) * 1.15)
        return WeeklyUsageStats(days: days, dailyLimitMinutes: dailyLimitMinutes, previousWeekTotal: previousWeekTotal)
    }
}
