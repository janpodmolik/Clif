import Foundation
import FamilyControls
import ManagedSettings

extension SharedDefaults {

    // MARK: - Active Token Storage

    /// Saves tokens for the active pet (used by extensions for shielding/monitoring).
    static func saveActiveTokens(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        defaults?.set(try? PropertyListEncoder().encode(applications), forKey: DefaultsKeys.applicationTokens)
        defaults?.set(try? PropertyListEncoder().encode(categories), forKey: DefaultsKeys.categoryTokens)
        defaults?.set(try? PropertyListEncoder().encode(webDomains), forKey: DefaultsKeys.webDomainTokens)
    }

    /// Clears active tokens (call when archiving/deleting the pet).
    static func clearActiveTokens() {
        defaults?.removeObject(forKey: DefaultsKeys.applicationTokens)
        defaults?.removeObject(forKey: DefaultsKeys.categoryTokens)
        defaults?.removeObject(forKey: DefaultsKeys.webDomainTokens)
    }

    // MARK: - Active Token Access (used by extensions)

    /// Loads application tokens for the currently monitored pet.
    static func loadApplicationTokens() -> Set<ApplicationToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.applicationTokens) else {
            return nil
        }
        return try? PropertyListDecoder().decode(Set<ApplicationToken>.self, from: data)
    }

    /// Loads category tokens for the currently monitored pet.
    static func loadCategoryTokens() -> Set<ActivityCategoryToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.categoryTokens) else {
            return nil
        }
        return try? PropertyListDecoder().decode(Set<ActivityCategoryToken>.self, from: data)
    }

    /// Loads web domain tokens for the currently monitored pet.
    static func loadWebDomainTokens() -> Set<WebDomainToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.webDomainTokens) else {
            return nil
        }
        return try? PropertyListDecoder().decode(Set<WebDomainToken>.self, from: data)
    }
}
