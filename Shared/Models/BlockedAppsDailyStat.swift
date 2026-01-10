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

    /// For mini chart - returns normalized values (0-1)
    func normalizedValues() -> [CGFloat] {
        guard maxMinutes > 0 else { return days.map { _ in 0 } }
        return days.map { CGFloat($0.totalMinutes) / CGFloat(maxMinutes) }
    }

    /// Creates mock data for preview/debug purposes
    static func mock() -> BlockedAppsWeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        let days = (0..<7).map { dayOffset -> BlockedAppsDailyStat in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let minutes = Int.random(in: 10...180)
            return BlockedAppsDailyStat(date: date, totalMinutes: minutes)
        }
        return BlockedAppsWeeklyStats(days: days)
    }
}
