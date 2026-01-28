import FamilyControls
import Foundation
import ManagedSettings

/// Protocol for pets that track usage statistics with limited sources.
protocol PetWithSources: PetEvolvable {
    var dailyStats: [DailyUsageStat] { get }
    var limitedSources: [LimitedSource] { get }
}

extension PetWithSources {
    /// Total days tracked.
    var totalDays: Int { dailyStats.count }

    // MARK: - Filtered Access

    /// All app sources.
    var appSources: [AppSource] {
        limitedSources.compactMap {
            if case .app(let source) = $0 { return source }
            return nil
        }
    }

    /// All category sources.
    var categorySources: [CategorySource] {
        limitedSources.compactMap {
            if case .category(let source) = $0 { return source }
            return nil
        }
    }

    /// All website sources.
    var websiteSources: [WebsiteSource] {
        limitedSources.compactMap {
            if case .website(let source) = $0 { return source }
            return nil
        }
    }

    // MARK: - Token Sets (for shielding)

    /// Application tokens extracted from app sources.
    var applicationTokens: Set<ApplicationToken> {
        Set(appSources.compactMap(\.applicationToken))
    }

    /// Category tokens extracted from category sources.
    var categoryTokens: Set<ActivityCategoryToken> {
        Set(categorySources.compactMap(\.categoryToken))
    }

    /// Web domain tokens extracted from website sources.
    var webDomainTokens: Set<WebDomainToken> {
        Set(websiteSources.compactMap(\.webDomainToken))
    }

    // MARK: - Counts

    /// Count of limited apps.
    var limitedAppCount: Int {
        appSources.count
    }

    /// Count of limited categories.
    var limitedCategoryCount: Int {
        categorySources.count
    }

    /// Count of limited websites.
    var limitedWebsiteCount: Int {
        websiteSources.count
    }

    /// Total count of all limited sources.
    var totalLimitedCount: Int {
        limitedSources.count
    }

}
