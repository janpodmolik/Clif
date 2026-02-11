import Foundation

/// Per-day hourly usage breakdown — 24 values representing minutes per hour.
/// Used in DayDetailSheet to show hourly bar chart for a specific day.
/// Lightweight alternative to syncing raw SnapshotEvents.
struct DailyHourlyBreakdown: Codable, Identifiable, Equatable {
    var id: String { date }
    /// Date in "YYYY-MM-DD" format.
    let date: String
    /// 24 values (index 0-23), minutes of usage per hour.
    let hourlyMinutes: [Double]

    var totalMinutes: Double {
        hourlyMinutes.reduce(0, +)
    }

    var peakHour: Int? {
        hourlyMinutes.enumerated()
            .max(by: { $0.element < $1.element })
            .flatMap { $0.element > 0 ? $0.offset : nil }
    }
}
