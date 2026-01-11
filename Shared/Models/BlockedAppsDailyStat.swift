import Foundation

/// Daily blocked apps usage data point.
struct BlockedAppsDailyStat: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let totalMinutes: Int

    init(id: UUID = UUID(), date: Date, totalMinutes: Int) {
        self.id = id
        self.date = date
        self.totalMinutes = totalMinutes
    }
}

/// Weekly stats container for chart display.
struct BlockedAppsWeeklyStats: Codable, Equatable {
    let days: [BlockedAppsDailyStat]
    let previousWeekTotal: Int?

    init(days: [BlockedAppsDailyStat], previousWeekTotal: Int? = nil) {
        self.days = days
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
    var worstDay: BlockedAppsDailyStat? {
        days.max(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// Day with lowest usage
    var bestDay: BlockedAppsDailyStat? {
        days.min(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// For mini chart - returns normalized values (0-1)
    func normalizedValues() -> [CGFloat] {
        guard maxMinutes > 0 else { return days.map { _ in 0 } }
        return days.map { CGFloat($0.totalMinutes) / CGFloat(maxMinutes) }
    }

    /// Empty stats
    static func empty() -> BlockedAppsWeeklyStats {
        BlockedAppsWeeklyStats(days: [], previousWeekTotal: nil)
    }

    /// Creates mock data for preview/debug purposes
    static func mock() -> BlockedAppsWeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        let days = (0..<7).map { dayOffset -> BlockedAppsDailyStat in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let minutes = Int.random(in: 30...180)
            return BlockedAppsDailyStat(date: date, totalMinutes: minutes)
        }
        // Mock previous week total (slightly higher to show improvement)
        let currentTotal = days.reduce(0) { $0 + $1.totalMinutes }
        let previousWeekTotal = Int(Double(currentTotal) * 1.15)
        return BlockedAppsWeeklyStats(days: days, previousWeekTotal: previousWeekTotal)
    }
}
