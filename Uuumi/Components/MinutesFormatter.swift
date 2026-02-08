import Foundation

/// Formats minute values into human-readable time strings.
enum MinutesFormatter {
    /// Compact format: "1h 30m", "45m", "2h"
    static func compact(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }

    /// Long format: "1 hour 30 min", "45 min", "2 hours"
    static func long(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else {
            return "\(mins) min"
        }
    }

    /// Rate format with suffix: "1h/day", "30m/day"
    static func rate(_ minutes: Int, suffix: String = "day") -> String {
        "\(compact(minutes))/\(suffix)"
    }
}
