import SwiftUI

/// Wind intensity levels determined by blocked app usage time.
enum WindLevel: Int, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .none: return "sun.max.fill"
        case .low: return "wind"
        case .medium: return "wind"
        case .high: return "tornado"
        }
    }

    var label: String {
        switch self {
        case .none: return "Klid"
        case .low: return "Mírný"
        case .medium: return "Střední"
        case .high: return "Silný"
        }
    }

    var color: Color {
        switch self {
        case .none: return .yellow
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    /// Returns the wind level zone for a given usage progress (0-1).
    /// - Parameter progress: Usage progress from 0 (no usage) to 1 (limit reached)
    /// - Returns: WindLevel zone for UI display and mood determination
    ///
    /// Zone thresholds:
    /// - none: <5% (essentially no usage)
    /// - low: 5% to <50%
    /// - medium: 50% to <75%
    /// - high: 75%+
    static func from(progress: CGFloat) -> WindLevel {
        switch progress {
        case ..<0.05: return .none
        case ..<0.50: return .low
        case ..<0.75: return .medium
        default: return .high
        }
    }

    /// Representative progress value for this wind level.
    /// Use this when you need to convert a discrete WindLevel back to a progress value
    /// (e.g., for debug pickers that select WindLevel but need to pass progress to animations).
    var representativeProgress: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 0.25
        case .medium: return 0.60
        case .high: return 0.90
        }
    }
}
