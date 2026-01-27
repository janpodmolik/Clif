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
        case .high: return "wind"
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

    /// Asset folder name for pet images based on wind intensity.
    /// Maps to: happy (none/low), neutral (medium), sad (high)
    var assetFolder: String {
        switch self {
        case .none, .low: return "happy"
        case .medium: return "neutral"
        case .high: return "sad"
        }
    }

    /// Asset folder for blown away state (always sad).
    static let blownAssetFolder = "sad"

    /// Returns the wind level zone for a given usage progress (0-1).
    /// - Parameter progress: Usage progress from 0 (no usage) to 1 (limit reached)
    /// - Returns: WindLevel zone for UI display and asset selection
    ///
    /// Zone thresholds:
    /// - none: <5% (essentially no usage)
    /// - low: 5% to <50%
    /// - medium: 50% to <80%
    /// - high: 80%+
    static func from(progress: CGFloat) -> WindLevel {
        switch progress {
        case ..<0.05: return .none
        case ..<0.50: return .low
        case ..<0.80: return .medium
        default: return .high
        }
    }

    // MARK: - Wind Points

    /// Returns the wind level zone based on wind points (0-100).
    ///
    /// Zone thresholds (aligned with progress thresholds):
    /// - none: 0-4 points (<5%)
    /// - low: 5-49 points (5% to <50%)
    /// - medium: 50-79 points (50% to <80%)
    /// - high: 80-100 points (80%+)
    static func from(windPoints: Double) -> WindLevel {
        switch windPoints {
        case ..<5: return .none
        case ..<50: return .low
        case ..<80: return .medium
        default: return .high
        }
    }
}

// MARK: - Codable

extension WindLevel: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = WindLevel(rawValue: rawValue) ?? .none
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Hashable (for Set usage)

extension WindLevel: Hashable {}
