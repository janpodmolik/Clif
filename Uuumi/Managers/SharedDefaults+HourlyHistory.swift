import Foundation

extension SharedDefaults {

    /// Full hourly history — one DailyHourlyBreakdown per day, pet-independent.
    /// Source of truth for DailyPatternCard after restore.
    static var hourlyHistory: [DailyHourlyBreakdown] {
        get {
            guard let data = hourlyHistoryData else { return [] }
            return (try? JSONDecoder().decode([DailyHourlyBreakdown].self, from: data)) ?? []
        }
        set {
            hourlyHistoryData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Merges today's breakdown into the stored history.
    /// Replaces the entry for today if it already exists.
    static func updateHourlyHistory(with today: DailyHourlyBreakdown) {
        var history = hourlyHistory
        if let index = history.firstIndex(where: { $0.date == today.date }) {
            history[index] = today
        } else {
            history.append(today)
        }
        hourlyHistory = history
    }
}
