import Foundation

extension SharedDefaults {

    private enum CoinsKeys {
        static let balance = "coins.balance"
    }

    static var coinsBalance: Int {
        get { defaults?.integer(forKey: CoinsKeys.balance) ?? 0 }
        set { defaults?.set(newValue, forKey: CoinsKeys.balance) }
    }

    static func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coinsBalance += amount
    }
}
