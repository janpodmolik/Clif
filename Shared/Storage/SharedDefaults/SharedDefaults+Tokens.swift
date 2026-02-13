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

    /// Clears active tokens and stored selection (call when archiving/deleting the pet).
    static func clearActiveTokens() {
        defaults?.removeObject(forKey: DefaultsKeys.applicationTokens)
        defaults?.removeObject(forKey: DefaultsKeys.categoryTokens)
        defaults?.removeObject(forKey: DefaultsKeys.webDomainTokens)
        defaults?.removeObject(forKey: DefaultsKeys.familyActivitySelection)
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

    // MARK: - FamilyActivitySelection Storage

    /// Saves the current FamilyActivitySelection for pre-populating the picker on edit.
    static func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        defaults?.set(try? PropertyListEncoder().encode(selection), forKey: DefaultsKeys.familyActivitySelection)
    }

    /// Loads the stored FamilyActivitySelection.
    static func loadFamilyActivitySelection() -> FamilyActivitySelection? {
        guard let data = defaults?.data(forKey: DefaultsKeys.familyActivitySelection) else {
            return nil
        }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    // MARK: - My Apps Selection ("Moje aplikace")

    /// Saves the user's "Moje aplikace" preset for quick reuse in pet creation.
    static func saveMyAppsSelection(_ selection: FamilyActivitySelection) {
        defaults?.set(try? PropertyListEncoder().encode(selection), forKey: DefaultsKeys.myAppsSelection)
    }

    /// Loads the stored "Moje aplikace" preset.
    static func loadMyAppsSelection() -> FamilyActivitySelection? {
        guard let data = defaults?.data(forKey: DefaultsKeys.myAppsSelection) else {
            return nil
        }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    /// Clears the stored "Moje aplikace" preset.
    static func clearMyAppsSelection() {
        defaults?.removeObject(forKey: DefaultsKeys.myAppsSelection)
    }

    /// Whether the user has a saved "Moje aplikace" preset.
    static var hasMyAppsSelection: Bool {
        defaults?.data(forKey: DefaultsKeys.myAppsSelection) != nil
    }
}
