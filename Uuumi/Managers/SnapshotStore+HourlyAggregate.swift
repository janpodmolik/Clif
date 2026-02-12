import Foundation

extension SnapshotStore {
    /// Computes hourly usage aggregate from usageThreshold events.
    /// For each day, calculates per-hour usage deltas from consecutive cumulative values,
    /// then averages across all days.
    /// - Parameter daysLimit: When set, only includes events from the last N days.
    func computeHourlyAggregate(daysLimit: Int? = nil) -> HourlyAggregate {
        let allEvents = loadAll()

        let cutoffDate: String? = daysLimit.map { limit in
            let cutoff = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
            return SnapshotEvent.dateString(from: cutoff)
        }

        // Filter to usageThreshold events only
        struct ThresholdPoint: Sendable {
            let date: String
            let timestamp: Date
            let cumulativeSeconds: Int
        }

        var points: [ThresholdPoint] = []
        for event in allEvents {
            if let cutoff = cutoffDate, event.date < cutoff { continue }
            if case .usageThreshold(let cumulativeSeconds) = event.eventType {
                points.append(ThresholdPoint(
                    date: event.date,
                    timestamp: event.timestamp,
                    cumulativeSeconds: cumulativeSeconds
                ))
            }
        }

        guard !points.isEmpty else { return .empty }

        // Group by date
        let grouped = Dictionary(grouping: points, by: { $0.date })

        let calendar = Calendar.current
        var hourlyTotals = Array(repeating: 0.0, count: 24)
        var dayCount = 0

        for (_, dayPoints) in grouped {
            let sorted = dayPoints.sorted { $0.timestamp < $1.timestamp }
            guard sorted.count >= 2 else { continue }

            dayCount += 1

            for i in 1..<sorted.count {
                let delta = sorted[i].cumulativeSeconds - sorted[i - 1].cumulativeSeconds
                guard delta > 0 else { continue }

                let hour = calendar.component(.hour, from: sorted[i].timestamp)
                hourlyTotals[hour] += Double(delta) / 60.0 // convert to minutes
            }
        }

        return HourlyAggregate(hourlyTotals: hourlyTotals, dayCount: dayCount)
    }
}

// MARK: - HourlyAggregate from DailyHourlyBreakdown (cloud restore fallback)

extension HourlyAggregate {
    /// Computes an aggregate from per-day hourly breakdowns (cloud restore fallback).
    /// When SnapshotEvents are unavailable, this allows recomputing filtered variants
    /// (7d/14d/30d) from synced DailyHourlyBreakdown data.
    static func fromBreakdowns(_ breakdowns: [DailyHourlyBreakdown], daysLimit: Int? = nil) -> HourlyAggregate {
        let sorted = breakdowns.sorted { $0.date < $1.date }
        let filtered: ArraySlice<DailyHourlyBreakdown> = if let limit = daysLimit {
            sorted.suffix(limit)
        } else {
            sorted[...]
        }
        guard !filtered.isEmpty else { return .empty }

        var totals = Array(repeating: 0.0, count: 24)
        for breakdown in filtered {
            for (hour, minutes) in breakdown.hourlyMinutes.prefix(24).enumerated() {
                totals[hour] += minutes
            }
        }
        return HourlyAggregate(hourlyTotals: totals, dayCount: filtered.count)
    }
}
