import Foundation
import FamilyControls
import ManagedSettings

extension SharedDefaults {

    // MARK: - Per-Pet Token Storage

    private static func tokenKey(_ petId: UUID, _ suffix: String) -> String {
        "pet_\(petId.uuidString)_\(suffix)"
    }

    /// Saves tokens for a specific pet.
    static func saveTokens(
        petId: UUID,
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        defaults?.set(try? PropertyListEncoder().encode(applications), forKey: tokenKey(petId, "appTokens"))
        defaults?.set(try? PropertyListEncoder().encode(categories), forKey: tokenKey(petId, "catTokens"))
        defaults?.set(try? PropertyListEncoder().encode(webDomains), forKey: tokenKey(petId, "webTokens"))

        // Also save to active keys for extension access
        defaults?.set(try? PropertyListEncoder().encode(applications), forKey: DefaultsKeys.applicationTokens)
        defaults?.set(try? PropertyListEncoder().encode(categories), forKey: DefaultsKeys.categoryTokens)
        defaults?.set(try? PropertyListEncoder().encode(webDomains), forKey: DefaultsKeys.webDomainTokens)
    }

    /// Clears tokens for a specific pet.
    static func clearTokens(petId: UUID) {
        // Clear per-pet keys
        defaults?.removeObject(forKey: tokenKey(petId, "appTokens"))
        defaults?.removeObject(forKey: tokenKey(petId, "catTokens"))
        defaults?.removeObject(forKey: tokenKey(petId, "webTokens"))

        // Also clear active token keys used by extensions
        defaults?.removeObject(forKey: DefaultsKeys.applicationTokens)
        defaults?.removeObject(forKey: DefaultsKeys.categoryTokens)
        defaults?.removeObject(forKey: DefaultsKeys.webDomainTokens)
    }

    /// Loads application tokens for a specific pet.
    static func loadApplicationTokens(petId: UUID) -> Set<ApplicationToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "appTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<ApplicationToken>.self, from: data)
    }

    /// Loads category tokens for a specific pet.
    static func loadCategoryTokens(petId: UUID) -> Set<ActivityCategoryToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "catTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<ActivityCategoryToken>.self, from: data)
    }

    /// Loads web domain tokens for a specific pet.
    static func loadWebDomainTokens(petId: UUID) -> Set<WebDomainToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "webTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<WebDomainToken>.self, from: data)
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
