import Foundation

extension SnapshotStore {
    /// Generates daily usage stats from snapshot events for a given pet.
    /// Aggregates usageThreshold events by day, taking max cumulativeSeconds for each day.
    /// wasOverLimit is true if a blowAway event exists for that day.
    /// Days without activity are included with totalMinutes: 0 for visual continuity.
    func dailyUsageStats(petId: UUID) -> [DailyUsageStat] {
        let events = load(petId: petId)
        guard !events.isEmpty else { return [] }

        // Group by date
        let groupedByDate = Dictionary(grouping: events, by: { $0.date })

        // Find date range from events
        let allDates = groupedByDate.keys.compactMap { SnapshotEvent.date(from: $0) }
        guard let minDate = allDates.min(), let maxDate = allDates.max() else { return [] }

        // Generate all days in range
        let calendar = Calendar.current
        var stats: [DailyUsageStat] = []
        var currentDate = calendar.startOfDay(for: minDate)
        let endDate = calendar.startOfDay(for: maxDate)

        while currentDate <= endDate {
            let dateString = SnapshotEvent.dateString(from: currentDate)
            let dayEvents = groupedByDate[dateString] ?? []

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

            let stat = DailyUsageStat(
                petId: petId,
                date: currentDate,
                totalMinutes: maxCumulativeSeconds / 60,
                wasOverLimit: hasBlowAway
            )
            stats.append(stat)

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return stats
    }
}
