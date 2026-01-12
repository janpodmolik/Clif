import Foundation

/// Trend direction for screen time usage.
enum UsageTrend: String, Codable {
    case improving   // usage decreasing
    case stable      // ±10% change
    case worsening   // usage increasing

    var displayName: String {
        switch self {
        case .improving: "Klesá"
        case .stable: "Stabilní"
        case .worsening: "Roste"
        }
    }

    var icon: String {
        switch self {
        case .improving: "arrow.down.right"
        case .stable: "arrow.right"
        case .worsening: "arrow.up.right"
        }
    }
}

/// Full statistics container for extended history display (5-30 days).
struct FullUsageStats: Codable, Equatable {
    let days: [DailyUsageStat]
    let dailyLimitMinutes: Int

    init(days: [DailyUsageStat], dailyLimitMinutes: Int) {
        self.days = days
        self.dailyLimitMinutes = dailyLimitMinutes
    }

    var totalDays: Int { days.count }

    var totalMinutes: Int {
        days.reduce(0) { $0 + $1.totalMinutes }
    }

    var averageMinutes: Int {
        guard !days.isEmpty else { return 0 }
        return totalMinutes / days.count
    }

    var maxMinutes: Int {
        days.map(\.totalMinutes).max() ?? 0
    }

    var daysOverLimit: Int {
        days.filter { $0.totalMinutes > dailyLimitMinutes }.count
    }

    var daysUnderLimit: Int {
        days.filter { $0.totalMinutes <= dailyLimitMinutes }.count
    }

    /// Compliance rate (0-1), percentage of days under limit.
    var complianceRate: Double {
        guard !days.isEmpty else { return 1.0 }
        return Double(daysUnderLimit) / Double(days.count)
    }

    /// Trend based on comparing first 3 days vs last 3 days average.
    var trend: UsageTrend {
        guard days.count >= 6 else { return .stable }

        let firstThree = days.prefix(3)
        let lastThree = days.suffix(3)

        let firstAvg = firstThree.reduce(0) { $0 + $1.totalMinutes } / 3
        let lastAvg = lastThree.reduce(0) { $0 + $1.totalMinutes } / 3

        guard firstAvg > 0 else { return .stable }

        let changePercent = Double(lastAvg - firstAvg) / Double(firstAvg)

        if changePercent < -0.1 {
            return .improving
        } else if changePercent > 0.1 {
            return .worsening
        } else {
            return .stable
        }
    }

    /// Day with highest usage.
    var worstDay: DailyUsageStat? {
        days.max(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// Day with lowest usage.
    var bestDay: DailyUsageStat? {
        days.min(by: { $0.totalMinutes < $1.totalMinutes })
    }

    /// For sparkline chart - returns normalized values (0-1).
    func normalizedValues() -> [CGFloat] {
        guard maxMinutes > 0 else { return days.map { _ in 0 } }
        return days.map { CGFloat($0.totalMinutes) / CGFloat(maxMinutes) }
    }

    /// Empty stats.
    static func empty(dailyLimitMinutes: Int = 60) -> FullUsageStats {
        FullUsageStats(days: [], dailyLimitMinutes: dailyLimitMinutes)
    }

    /// Creates mock data for preview/debug purposes.
    static func mock(days: Int = 14, dailyLimitMinutes: Int = 60) -> FullUsageStats {
        let calendar = Calendar.current
        let today = Date()
        let mockPetId = UUID()
        let dailyStats = (0..<days).map { dayOffset -> DailyUsageStat in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            // Mix of under and over limit days, with slight improvement trend
            let baseMinutes = Int.random(in: 20...(dailyLimitMinutes + 20))
            // Earlier days slightly higher to show improving trend
            let trendAdjustment = dayOffset < days / 2 ? Int.random(in: 5...15) : 0
            let minutes = max(5, baseMinutes + trendAdjustment)
            return DailyUsageStat(petId: mockPetId, date: date, totalMinutes: minutes)
        }
        return FullUsageStats(days: dailyStats, dailyLimitMinutes: dailyLimitMinutes)
    }
}
