import SwiftUI

/// Single source of truth for the user's coin balance.
/// Views that read `CoinStore.shared.balance` are automatically
/// re-rendered whenever the balance changes — no manual refresh needed.
///
/// All coin mutations must go through this class so the UI stays in sync.
@Observable
@MainActor
final class CoinStore {
    static let shared = CoinStore()

    private(set) var balance: Int

    private init() {
        balance = SharedDefaults.coinsBalance
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        withAnimation { balance += amount }
        SharedDefaults.coinsBalance = balance
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, balance >= amount else { return false }
        withAnimation { balance -= amount }
        SharedDefaults.coinsBalance = balance
        return true
    }

    /// Directly sets the balance (e.g. cloud restore, sign-out reset).
    func setBalance(_ newBalance: Int) {
        withAnimation { balance = newBalance }
        SharedDefaults.coinsBalance = newBalance
    }

    /// Re-reads the balance from SharedDefaults.
    /// Call after external writes that bypass CoinStore (e.g. EvolutionHistory).
    func reload() {
        let stored = SharedDefaults.coinsBalance
        guard stored != balance else { return }
        withAnimation { balance = stored }
    }
}
