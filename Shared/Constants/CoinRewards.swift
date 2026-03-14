import Foundation

enum CoinRewards {
    static let evolution = 5

    /// Coins for committed break: 1 coin per 15 minutes, capped at `maxBreakCoins`.
    static let maxBreakCoins = 10

    static func forBreak(minutes: Int) -> Int {
        min(minutes / 15, maxBreakCoins)
    }
}
