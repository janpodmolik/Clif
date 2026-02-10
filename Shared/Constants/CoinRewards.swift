import Foundation

enum CoinRewards {
    static let evolution = 5

    /// Coins for committed break: 1 coin per 15 minutes.
    static func forBreak(minutes: Int) -> Int {
        minutes / 15
    }
}
