import Foundation

extension SnapshotStore {
    /// Computes per-day hourly breakdowns from usageThreshold events.
    /// Uses same delta logic as computeHourlyAggregate but returns per-day instead of averaged.
    /// - Parameter petId: The pet ID to filter events for.
    func computeDailyHourlyBreakdowns(petId: UUID) -> [DailyHourlyBreakdown] {
        let allEvents = loadAll().filter { $0.petId == petId }

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

        guard !points.isEmpty else { return [] }

        let grouped = Dictionary(grouping: points, by: { $0.date })
        let calendar = Calendar.current
        var breakdowns: [DailyHourlyBreakdown] = []

        for (date, dayPoints) in grouped {
            let sorted = dayPoints.sorted { $0.timestamp < $1.timestamp }
            guard sorted.count >= 2 else { continue }

            var hourlyMinutes = Array(repeating: 0.0, count: 24)

            for i in 1..<sorted.count {
                let delta = sorted[i].cumulativeSeconds - sorted[i - 1].cumulativeSeconds
                guard delta > 0 else { continue }

                let hour = calendar.component(.hour, from: sorted[i].timestamp)
                hourlyMinutes[hour] += Double(delta) / 60.0
            }

            breakdowns.append(DailyHourlyBreakdown(date: date, hourlyMinutes: hourlyMinutes))
        }

        return breakdowns.sorted { $0.date < $1.date }
    }
}
