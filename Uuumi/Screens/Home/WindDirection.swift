import Foundation

/// Provides consistent wind direction based on the current date.
/// Direction changes daily but stays consistent throughout the day.
enum WindDirection {
    /// Returns wind direction for today: 1.0 (left→right) or -1.0 (right→left)
    static func forToday() -> CGFloat {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = calendar.component(.year, from: Date())
        let seed = year * 1000 + dayOfYear

        return (seed % 2 == 0) ? 1.0 : -1.0
    }
}
