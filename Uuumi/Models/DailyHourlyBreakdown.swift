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

    /// Loads all cloud-restored breakdowns from disk, merged across all pet files.
    /// Used as fallback for DailyPatternCard when SnapshotEvents are unavailable.
    static func loadAllFromDisk() -> [DailyHourlyBreakdown] {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent("hourly_per_day")

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return [] }

        var allBreakdowns: [String: DailyHourlyBreakdown] = [:]
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let breakdowns = try? JSONDecoder().decode([DailyHourlyBreakdown].self, from: data) else {
                continue
            }
            // Merge by date — if multiple pets have data for the same date, sum them
            for breakdown in breakdowns {
                if let existing = allBreakdowns[breakdown.date] {
                    let merged = zip(existing.hourlyMinutes.prefix(24), breakdown.hourlyMinutes.prefix(24)).map(+)
                    allBreakdowns[breakdown.date] = DailyHourlyBreakdown(
                        date: breakdown.date,
                        hourlyMinutes: merged
                    )
                } else {
                    allBreakdowns[breakdown.date] = breakdown
                }
            }
        }
        return Array(allBreakdowns.values)
    }
}
