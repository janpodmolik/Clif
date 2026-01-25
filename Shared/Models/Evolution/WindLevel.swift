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

    /// Returns the wind level zone for a given usage progress (0-1).
    /// - Parameter progress: Usage progress from 0 (no usage) to 1 (limit reached)
    /// - Returns: WindLevel zone for UI display and mood determination
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

// MARK: - LimitSettings

/// User-configurable settings for notifications and safety shield.
/// Stored in SharedDefaults for access from both app and extensions.
/// Note: Shields are activated manually (break button) or at 100% (safety shield).
struct LimitSettings: Codable, Equatable {

    // MARK: - Notification Settings

    /// WindLevel changes that trigger notifications.
    /// Default: all levels except none
    var notificationLevels: Set<WindLevel> = [.low, .medium, .high]

    // MARK: - Morning Shield

    /// Enable Morning Shield (shield active after day reset until preset selected).
    var morningShieldEnabled: Bool = true

    // MARK: - Debug Settings

    /// DEBUG ONLY: Disable the 100% safety shield.
    /// When true, no shield activates at 100% - pet can blow away without warning.
    /// Default: false (safety shield always active)
    var disableSafetyShield: Bool = false

    // MARK: - Defaults

    static let `default` = LimitSettings()
}
