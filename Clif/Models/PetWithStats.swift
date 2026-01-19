import FamilyControls
import Foundation
import ManagedSettings

/// Protocol for pets that track usage statistics.
protocol PetWithStats: PetEvolvable {
    var dailyStats: [DailyUsageStat] { get }
    var appUsage: [AppUsage] { get }
}

extension PetWithStats {
    /// Total days tracked.
    var totalDays: Int { dailyStats.count }
}

/// Protocol for active pets that also track limited apps for shielding.
protocol PetWithTokens: PetWithStats {
    var limitedApps: [LimitedApp] { get }
    var limitedCategories: [LimitedCategory] { get }
}

extension PetWithTokens {
    /// Application tokens extracted from limited apps.
    var applicationTokens: Set<ApplicationToken> {
        Set(limitedApps.compactMap(\.applicationToken))
    }

    /// Category tokens extracted from limited categories.
    var categoryTokens: Set<ActivityCategoryToken> {
        Set(limitedCategories.compactMap(\.categoryToken))
    }

    /// Count of limited apps and categories.
    var limitedAppCount: Int {
        limitedApps.count + limitedCategories.count
    }
}
