import Foundation

/// Pre-computed hourly usage pattern averaged across all tracked days.
/// Stores cumulative totals per hour (0-23) and day count for averaging.
struct HourlyAggregate: Codable, Equatable {
    /// Total added minutes per hour slot (index 0-23) across all tracked days.
    var hourlyTotals: [Double]
    /// Number of days included in the aggregate.
    var dayCount: Int

    /// Average minutes per hour slot.
    var hourlyAverages: [Double] {
        guard dayCount > 0 else { return Array(repeating: 0, count: 24) }
        return hourlyTotals.map { $0 / Double(dayCount) }
    }

    /// Average total daily screen time in minutes (sum of all hourly averages).
    var totalDailyAverage: Double {
        hourlyAverages.reduce(0, +)
    }

    /// Hour (0-23) with highest average usage, or nil if no data.
    var peakHour: Int? {
        let averages = hourlyAverages
        return averages.enumerated().max(by: { $0.element < $1.element }).flatMap { $0.element > 0 ? $0.offset : nil }
    }

    /// Creates an empty aggregate.
    static var empty: HourlyAggregate {
        HourlyAggregate(hourlyTotals: Array(repeating: 0, count: 24), dayCount: 0)
    }

}

#if DEBUG
extension HourlyAggregate {
    /// Mock with a realistic daily pattern: morning + evening peaks.
    static func mock(days: Int = 14) -> HourlyAggregate {
        var totals = Array(repeating: 0.0, count: 24)
        // Morning peak (8-10)
        totals[7] = 2.0 * Double(days)
        totals[8] = 5.0 * Double(days)
        totals[9] = 4.0 * Double(days)
        totals[10] = 3.0 * Double(days)
        // Midday dip
        totals[12] = 2.0 * Double(days)
        totals[13] = 1.5 * Double(days)
        // Afternoon
        totals[15] = 2.0 * Double(days)
        totals[16] = 3.0 * Double(days)
        // Evening peak (20-23)
        totals[19] = 3.0 * Double(days)
        totals[20] = 6.0 * Double(days)
        totals[21] = 8.0 * Double(days)
        totals[22] = 5.0 * Double(days)
        totals[23] = 2.0 * Double(days)
        return HourlyAggregate(hourlyTotals: totals, dayCount: days)
    }
}
#endif
