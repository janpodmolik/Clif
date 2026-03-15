import Foundation

enum CoinRewards {

    // MARK: - Evolution

    static let freeEvolution = 5
    static let premiumEvolution = 10

    static func forEvolution(isPremium: Bool) -> Int {
        isPremium ? premiumEvolution : freeEvolution
    }

    // MARK: - Committed Break (Premium only)

    /// Coins for committed break: 1 coin per 15 minutes, capped at `maxBreakCoins`.
    static let maxBreakCoins = 10

    static func forBreak(minutes: Int) -> Int {
        min(minutes / 15, maxBreakCoins)
    }
}
