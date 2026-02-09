import Foundation

extension SnapshotStore {
    /// Computes hourly usage aggregate from all usageThreshold events.
    /// For each day, calculates per-hour usage deltas from consecutive cumulative values,
    /// then averages across all days.
    func computeHourlyAggregate() -> HourlyAggregate {
        let allEvents = loadAll()

        // Filter to usageThreshold events only
        struct ThresholdPoint {
            let date: String
            let timestamp: Date
            let cumulativeSeconds: Int
        }

        var points: [ThresholdPoint] = []
        for event in allEvents {
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
