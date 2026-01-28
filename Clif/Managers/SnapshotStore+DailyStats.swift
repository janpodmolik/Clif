import Foundation

extension SnapshotStore {
    /// Generates daily usage stats from snapshot events for a given pet.
    /// Aggregates usageThreshold events by day, taking max cumulativeSeconds for each day.
    /// wasOverLimit is true if a blowAway event exists for that day.
    func dailyUsageStats(petId: UUID) -> [DailyUsageStat] {
        let events = load(petId: petId)

        // Group by date
        let groupedByDate = Dictionary(grouping: events, by: { $0.date })

        // Date formatter for parsing date strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = .current

        var stats: [DailyUsageStat] = []

        for (dateString, dayEvents) in groupedByDate {
            // Find max cumulativeSeconds from usageThreshold events
            var maxCumulativeSeconds = 0
            var hasBlowAway = false

            for event in dayEvents {
                switch event.eventType {
                case .usageThreshold(let cumulativeSeconds):
                    maxCumulativeSeconds = max(maxCumulativeSeconds, cumulativeSeconds)
                case .blowAway:
                    hasBlowAway = true
                default:
                    break
                }
            }

            // Only include days with usage data
            guard maxCumulativeSeconds > 0 || hasBlowAway else { continue }

            // Parse date string to Date
            guard let date = dateFormatter.date(from: dateString) else { continue }

            let stat = DailyUsageStat(
                petId: petId,
                date: date,
                totalMinutes: maxCumulativeSeconds / 60,
                wasOverLimit: hasBlowAway
            )
            stats.append(stat)
        }

        // Sort chronologically
        return stats.sorted { $0.date < $1.date }
    }
}
