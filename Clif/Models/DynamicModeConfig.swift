import Foundation

/// Wind difficulty presets for Dynamic mode.
/// Each preset defines how quickly wind rises during app usage and falls during breaks.
enum DynamicModeConfig: String, Codable, CaseIterable {
    /// Low pressure mode for beginners: 15 min to blow away, 30 min to recover.
    case gentle

    /// Default balanced mode: 8 min to blow away, 20 min to recover.
    case balanced

    /// High stakes mode: 5 min to blow away, 15 min to recover.
    case intense

    // MARK: - Wind Rise (during app usage)

    /// Minutes of blocked app usage to reach blow away (wind 0 → 100).
    var minutesToBlowAway: Double {
        switch self {
        case .gentle: return 15
        case .balanced: return 8
        case .intense: return 5
        }
    }

    /// Wind points gained per minute of blocked app usage.
    var riseRate: Double {
        100 / minutesToBlowAway
    }

    // MARK: - Wind Fall (during breaks)

    /// Minutes of break to fully recover (wind 100 → 0).
    var minutesToRecover: Double {
        switch self {
        case .gentle: return 30
        case .balanced: return 20
        case .intense: return 15
        }
    }

    /// Wind points decreased per minute during a break.
    var fallRate: Double {
        100 / minutesToRecover
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .balanced: return "Balanced"
        case .intense: return "Intense"
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Low pressure, learning"
        case .balanced: return "Real friction"
        case .intense: return "High stakes"
        }
    }
}

// MARK: - Default

extension DynamicModeConfig {
    static let `default`: DynamicModeConfig = .balanced
}
