import Foundation
import Statsig

enum StatsigConfig {
    static let sdkKey = "client-exN0VQofgnkuPnTq9tXqCPvRglqF27FilxXYQBx5Zo1"

    private static var environmentTier: String {
        #if DEBUG
        return "development"
        #else
        return TesterConfig.isTestFlight ? "staging" : "production"
        #endif
    }

    static func start(userId: String?) async {
        let user = StatsigUser(userID: userId)
        let options = StatsigOptions(environment: StatsigEnvironment(tier: environmentTier))
        await withCheckedContinuation { continuation in
            Statsig.start(sdkKey: sdkKey, user: user, options: options) { _ in
                continuation.resume()
            }
        }
    }

    static func updateUser(userId: String?, premiumPlan: String?) async {
        let user = StatsigUser(
            userID: userId,
            custom: ["premium_plan": premiumPlan ?? "none"]
        )
        await withCheckedContinuation { continuation in
            Statsig.updateUser(user) { _ in
                continuation.resume()
            }
        }
    }
}
