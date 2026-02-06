import Foundation
import SwiftUI

/// Wind intensity presets that control how quickly wind rises during app usage and falls during breaks.
enum WindPreset: String, Codable, CaseIterable {
    /// Low pressure mode for beginners: 15 min to blow away, 30 min to recover.
    case gentle

    /// Default balanced mode: 8 min to blow away, 20 min to recover.
    case balanced

    /// High stakes mode: 5 min to blow away, 15 min to recover.
    case intense

    // MARK: - Wind Rise (during app usage)

    /// Minutes of blocked app usage to reach blow away (wind 0 → 100).
    var minutesToBlowAway: Double {
        #if DEBUG
        if DebugConfig.isEnabled {
            return DebugConfig.minutesToBlowAway
        }
        #endif
        switch self {
        case .gentle: return 20
        case .balanced: return 12
        case .intense: return 8
        }
    }

    /// Wind points gained per minute of blocked app usage.
    var riseRate: Double {
        #if DEBUG
        if DebugConfig.isEnabled {
            return DebugConfig.riseRate
        }
        #endif
        return 100 / minutesToBlowAway
    }

    // MARK: - Wind Fall (during breaks)

    /// Minutes of break to fully recover (wind 100 → 0).
    var minutesToRecover: Double {
        #if DEBUG
        if DebugConfig.isEnabled {
            return DebugConfig.minutesToRecover
        }
        #endif
        switch self {
        case .gentle: return 30
        case .balanced: return 20
        case .intense: return 15
        }
    }

    /// Wind points decreased per minute during a break.
    var fallRate: Double {
        #if DEBUG
        if DebugConfig.isEnabled {
            return DebugConfig.fallRate
        }
        #endif
        return 100 / minutesToRecover
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

    var themeColor: Color {
        switch self {
        case .gentle: .green
        case .balanced: .blue
        case .intense: .red
        }
    }

    var iconName: String {
        switch self {
        case .gentle: "leaf.fill"
        case .balanced: "scalemass.fill"
        case .intense: "flame.fill"
        }
    }
}

// MARK: - Default

extension WindPreset {
    static let `default`: WindPreset = .balanced
}
