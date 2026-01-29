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

    var description: String {
        switch self {
        case .none: return "Calm"
        case .low: return "Light Breeze"
        case .medium: return "Moderate Wind"
        case .high: return "Strong Gust"
        }
    }

    var petStatus: String {
        switch self {
        case .none: return "Uuumi is thriving"
        case .low: return "Feeling the breeze"
        case .medium: return "Getting a bit stressed"
        case .high: return "Struggling to hold on"
        }
    }

    var wiggleSpeed: Double {
        switch self {
        case .none: return 0.3
        case .low: return 0.4
        case .medium: return 0.7
        case .high: return 1.0
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
        switch progress * 100 {
        case ..<WindLevel.low.threshold: return .none
        case ..<WindLevel.medium.threshold: return .low
        case ..<WindLevel.high.threshold: return .medium
        default: return .high
        }
    }

    // MARK: - Wind Points

    /// Wind points threshold where this level begins.
    var threshold: Double {
        switch self {
        case .none: return 0
        case .low: return 5
        case .medium: return 50
        case .high: return 80
        }
    }

    /// Returns the wind level zone based on wind points (0-100).
    ///
    /// Zone thresholds (aligned with progress thresholds):
    /// - none: 0-4 points (<5%)
    /// - low: 5-49 points (5% to <50%)
    /// - medium: 50-79 points (50% to <80%)
    /// - high: 80-100 points (80%+)
    static func from(windPoints: Double) -> WindLevel {
        switch windPoints {
        case ..<WindLevel.low.threshold: return .none
        case ..<WindLevel.medium.threshold: return .low
        case ..<WindLevel.high.threshold: return .medium
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
