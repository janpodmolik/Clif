import Foundation
import Statsig

enum StatsigConfig {
    static let sdkKey = "client-exN0VQofgnkuPnTq9tXqCPvRglqF27FilxXYQBx5Zo1"

    static func start(userId: String?) async {
        let user = StatsigUser(userID: userId)
        await withCheckedContinuation { continuation in
            Statsig.start(sdkKey: sdkKey, user: user, options: StatsigOptions()) { _ in
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
