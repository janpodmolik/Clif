import Foundation

/// Rate-limits the evolution/essence premium upsell sheets. Evolving is a daily
/// action — an interstitial on every tap trains users to dismiss paywalls, so
/// free users see it at most once per `AppConstants.premiumUpsellCooldown`.
enum PremiumUpsellThrottle {

    /// Returns `true` when the upsell may be shown and stamps the cooldown;
    /// callers should fall through to the plain action on `false`.
    static func shouldShow(now: Date = Date()) -> Bool {
        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: DefaultsKeys.lastPremiumUpsellDate) as? Date,
           now.timeIntervalSince(last) < AppConstants.premiumUpsellCooldown {
            return false
        }
        defaults.set(now, forKey: DefaultsKeys.lastPremiumUpsellDate)
        return true
    }
}
