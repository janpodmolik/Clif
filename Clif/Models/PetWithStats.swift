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

/// Protocol for active pets that also track app tokens for shielding.
protocol PetWithTokens: PetWithStats {
    var applicationTokens: Set<ApplicationToken> { get }
    var categoryTokens: Set<ActivityCategoryToken> { get }
}

extension PetWithTokens {
    /// Count of limited apps and categories.
    var limitedAppCount: Int {
        applicationTokens.count + categoryTokens.count
    }
}
