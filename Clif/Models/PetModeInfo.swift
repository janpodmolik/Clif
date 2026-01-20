import SwiftUI

/// Represents the game mode configuration for a pet.
/// Used in header cards to display mode-specific information.
/// This is a read-only informational model - purpose is displayed in the header, not here.
enum PetModeInfo {
    case daily(DailyModeInfo)
    case dynamic(DynamicModeInfo)

    struct DailyModeInfo {
        let dailyLimitMinutes: Int
        let limitedSources: [LimitedSource]

        var formattedLimit: String {
            let hours = dailyLimitMinutes / 60
            let minutes = dailyLimitMinutes % 60
            if hours > 0 {
                return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            }
            return "\(minutes)m"
        }
    }

    struct DynamicModeInfo {
        let config: DynamicModeConfig
        let limitedSources: [LimitedSource]
    }

    // MARK: - Computed Properties

    var modeName: String {
        switch self {
        case .daily: return "Daily Mode"
        case .dynamic: return "Dynamic Mode"
        }
    }

    var modeIcon: String {
        switch self {
        case .daily: return "clock.fill"
        case .dynamic: return "gauge.with.needle.fill"
        }
    }

    var modeColor: Color {
        switch self {
        case .daily: return .blue
        case .dynamic: return .yellow
        }
    }

    var limitedSources: [LimitedSource] {
        switch self {
        case .daily(let info): return info.limitedSources
        case .dynamic(let info): return info.limitedSources
        }
    }
}

// MARK: - Convenience Initializers

extension PetModeInfo {
    init(from pet: DailyPet) {
        self = .daily(DailyModeInfo(
            dailyLimitMinutes: pet.dailyLimitMinutes,
            limitedSources: pet.limitedSources
        ))
    }

    init(from pet: ArchivedDailyPet) {
        self = .daily(DailyModeInfo(
            dailyLimitMinutes: pet.dailyLimitMinutes,
            limitedSources: pet.limitedSources
        ))
    }

    init(from pet: DynamicPet) {
        self = .dynamic(DynamicModeInfo(
            config: pet.config,
            limitedSources: pet.limitedSources
        ))
    }

    init(from pet: ArchivedDynamicPet) {
        self = .dynamic(DynamicModeInfo(
            config: pet.config,
            limitedSources: pet.limitedSources
        ))
    }
}
