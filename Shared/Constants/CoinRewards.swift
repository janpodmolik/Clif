import Foundation

enum CoinRewards {
    static let evolution = 5

    /// Coins for committed break: 1 coin per 15 minutes.
    /// Debug (0 min) returns 5 coins for testing.
    static func forBreak(minutes: Int) -> Int {
        #if DEBUG
        if minutes == 0 { return 5 }
        #endif
        return minutes / 15
    }
}
