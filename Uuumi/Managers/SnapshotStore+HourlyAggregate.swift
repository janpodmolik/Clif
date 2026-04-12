import Foundation

extension SnapshotStore {
    /// Computes today's hourly breakdown from ALL usageThreshold events (pet-independent).
    /// Used for syncing to user_data — represents total screen time across all pets.
    func computeTodayBreakdown() -> DailyHourlyBreakdown? {
        let todayString = SnapshotEvent.dateString(from: Date())
        let allEvents = loadAll()

        struct ThresholdPoint {
            let timestamp: Date
            let cumulativeSeconds: Int
        }

        var points: [ThresholdPoint] = []
        for event in allEvents where event.date == todayString {
            if case .usageThreshold(let cumulativeSeconds) = event.eventType {
                points.append(ThresholdPoint(
                    timestamp: event.timestamp,
                    cumulativeSeconds: cumulativeSeconds
                ))
            }
        }

        let sorted = points.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2 else { return nil }

        let calendar = Calendar.current
        var hourlyMinutes = Array(repeating: 0.0, count: 24)

        for i in 1..<sorted.count {
            let delta = sorted[i].cumulativeSeconds - sorted[i - 1].cumulativeSeconds
            guard delta > 0 else { continue }

            let hour = calendar.component(.hour, from: sorted[i].timestamp)
            hourlyMinutes[hour] += Double(delta) / 60.0
        }

        return DailyHourlyBreakdown(date: todayString, hourlyMinutes: hourlyMinutes)
    }
}

// MARK: - HourlyAggregate from DailyHourlyBreakdown

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
