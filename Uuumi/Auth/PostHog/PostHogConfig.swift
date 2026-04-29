import Foundation
import PostHog

enum AppPostHog {
    static let apiKey = "phc_n2kBBPZqYmjku8hRvLbsT66WZXERhrGxKFiebSdbvt8n"
    static let host = "https://eu.i.posthog.com"

    private static var didSetup = false

    private static var environmentTier: String {
        #if DEBUG
        return "development"
        #else
        return TesterConfig.isTestFlight ? "staging" : "production"
        #endif
    }

    static func start() {
        guard !didSetup else { return }
        didSetup = true

        let config = PostHogConfig(apiKey: apiKey, host: host)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false
        config.personProfiles = .identifiedOnly
        config.preloadFeatureFlags = false
        config.sendFeatureFlagEvent = false
        // Session replay disabled: screenshotMode rasterizes private system views
        // (FamilyActivityPicker, Sign in with Apple) which maskAllTextInputs can't
        // mask, and the privacy manifest doesn't declare OtherUserContent/SensitiveInfo.
        // Re-enable only after deciding per-screen masking strategy.
        config.sessionReplay = false

        let tier = environmentTier
        config.setBeforeSend { event in
            event.properties["environment"] = tier
            return event
        }

        PostHogSDK.shared.setup(config)

        if PostHogOptOut.isOptedOut {
            PostHogSDK.shared.optOut()
        }
    }

    static func identify(userId: String, premiumPlan: String?) {
        let properties: [String: Any] = ["premium_plan": premiumPlan ?? "none"]
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    static func updatePremiumPlan(_ plan: String?) {
        PostHogSDK.shared.setPersonProperties(
            userPropertiesToSet: ["premium_plan": plan ?? "none"]
        )
    }

    static func signOut() {
        PostHogSDK.shared.reset()
    }

    static func setOptedOut(_ optedOut: Bool) {
        PostHogOptOut.isOptedOut = optedOut
        if optedOut {
            PostHogSDK.shared.optOut()
        } else {
            PostHogSDK.shared.optIn()
        }
    }
}

enum PostHogOptOut {
    private static let key = "posthog_opted_out"

    static var isOptedOut: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
