import Foundation
import StoreKit
import UIKit

@Observable
@MainActor
final class StoreManager {

    // MARK: - Types

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed
    }

    enum StoreError: LocalizedError {
        case failedVerification
        case purchaseCancelled
        case purchasePending
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return String(localized: "Purchase verification failed")
            case .purchaseCancelled:
                return String(localized: "Purchase was cancelled")
            case .purchasePending:
                return String(localized: "Purchase is pending approval")
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }

    // MARK: - Product IDs

    static let monthlyID = "com.janpodmolik.Uuumi.premium.monthly"
    static let yearlyID = "com.janpodmolik.Uuumi.premium.yearly"

    static let coinsSmallID = "com.janpodmolik.Uuumi.coins.small"
    static let coinsMediumID = "com.janpodmolik.Uuumi.coins.medium"
    static let coinsLargeID = "com.janpodmolik.Uuumi.coins.large"

    private static let subscriptionIDs: Set<String> = [monthlyID, yearlyID]
    private static let coinPackIDs: Set<String> = [coinsSmallID, coinsMediumID, coinsLargeID]
    private static let allProductIDs: Set<String> = subscriptionIDs.union(coinPackIDs)

    static let coinPackAmounts: [String: Int] = [
        coinsSmallID: 100,
        coinsMediumID: 400,
        coinsLargeID: 1000,
    ]

    // MARK: - State

    private(set) var subscriptionProducts: [Product] = []
    private(set) var coinPackProducts: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var productsLoadFailed = false
    private(set) var isPremium = false
    private(set) var expirationDate: Date?
    private(set) var activeProductId: String?
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var purchasingProductId: String?
    private(set) var error: StoreError?

    private var transactionListener: Task<Void, Never>?

    // MARK: - Convenience

    var monthlyProduct: Product? { subscriptionProducts.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { subscriptionProducts.first { $0.id == Self.yearlyID } }

    var products: [Product] { subscriptionProducts }

    func coinAmount(for product: Product) -> Int {
        Self.coinPackAmounts[product.id] ?? 0
    }

    // MARK: - Init

    init() {
        // Bootstrap from cache so wasPremium is accurate on relaunch
        isPremium = SharedDefaults.isPremiumCached

        transactionListener = listenForTransactions()

        Task {
            await checkCurrentEntitlements()
            await loadProducts()
        }
    }

    private init(isMock: Bool) {}

    // MARK: - Load Products

    func loadProducts() async {
        guard subscriptionProducts.isEmpty, coinPackProducts.isEmpty else { return }
        await fetchProducts()
    }

    func retryLoadProducts() async {
        await fetchProducts()
    }

    private func fetchProducts() async {
        isLoadingProducts = true
        productsLoadFailed = false
        subscriptionProducts = []
        coinPackProducts = []

        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            subscriptionProducts = storeProducts
                .filter { Self.subscriptionIDs.contains($0.id) }
                .sorted { $0.price < $1.price }
            coinPackProducts = storeProducts
                .filter { Self.coinPackIDs.contains($0.id) }
                .sorted { $0.price < $1.price }
            productsLoadFailed = subscriptionProducts.isEmpty && coinPackProducts.isEmpty
        } catch {
            productsLoadFailed = true
            #if DEBUG
            print("StoreManager: Failed to load products — \(error)")
            #endif
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        purchasingProductId = product.id

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)

                if Self.coinPackIDs.contains(transaction.productID) {
                    let amount = Self.coinPackAmounts[transaction.productID] ?? 0
                    SharedDefaults.addCoins(amount)
                } else {
                    await updatePremiumStatus(from: transaction)
                }

                await transaction.finish()
                purchaseState = .purchased
                purchasingProductId = nil

            case .userCancelled:
                purchaseState = .idle
                purchasingProductId = nil

            case .pending:
                purchaseState = .idle
                purchasingProductId = nil
                self.error = .purchasePending

            @unknown default:
                purchaseState = .idle
                purchasingProductId = nil
            }
        } catch let storeError as StoreError {
            purchaseState = .failed
            purchasingProductId = nil
            self.error = storeError
        } catch {
            purchaseState = .failed
            purchasingProductId = nil
            self.error = .unknown(error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            #if DEBUG
            print("StoreManager: Restore failed — \(error)")
            #endif
        }
    }

    // MARK: - Manage Subscriptions

    func showManageSubscriptions() async {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            #if DEBUG
            print("StoreManager: showManageSubscriptions failed — \(error)")
            #endif
        }
    }

    // MARK: - Error

    func clearError() {
        error = nil
    }

    // MARK: - Entitlements

    func checkCurrentEntitlements() async {
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if Self.subscriptionIDs.contains(transaction.productID) {
                await updatePremiumStatus(from: transaction)
                foundActive = true
            }
        }

        if !foundActive {
            setPremiumActive(false)
            expirationDate = nil
            activeProductId = nil
        }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }

                if Self.coinPackIDs.contains(transaction.productID) {
                    let amount = Self.coinPackAmounts[transaction.productID] ?? 0
                    SharedDefaults.addCoins(amount)
                } else {
                    await updatePremiumStatus(from: transaction)
                }

                await transaction.finish()
            }
        }
    }

    private func checkVerification(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private func updatePremiumStatus(from transaction: Transaction) async {
        let isActive = transaction.revocationDate == nil
            && (transaction.expirationDate ?? .distantFuture) > Date()

        setPremiumActive(isActive)
        expirationDate = transaction.expirationDate
        activeProductId = isActive ? transaction.productID : nil
    }

    /// Updates premium status and resets appearance settings on downgrade.
    private func setPremiumActive(_ active: Bool) {
        let wasPremium = isPremium
        isPremium = active
        SharedDefaults.isPremiumCached = active

        if wasPremium && !active {
            resetPremiumAppearanceSettings()
        }
    }

    /// Resets premium appearance settings back to free defaults when subscription expires.
    private func resetPremiumAppearanceSettings() {
        let defaults = UserDefaults.standard

        // Reset dynamic sky toggle
        defaults.set(false, forKey: DefaultsKeys.useDynamicSky)

        // Reset premium day theme → free default
        if let storedTheme = defaults.string(forKey: DefaultsKeys.selectedDayTheme),
           let theme = DayTheme(rawValue: storedTheme),
           theme.isPremium {
            defaults.set(DayTheme.morningHaze.rawValue, forKey: DefaultsKeys.selectedDayTheme)
        }

        // Reset premium night theme → free default
        if let storedTheme = defaults.string(forKey: DefaultsKeys.selectedNightTheme),
           let theme = NightTheme(rawValue: storedTheme),
           theme.isPremium {
            defaults.set(NightTheme.deepNight.rawValue, forKey: DefaultsKeys.selectedNightTheme)
        }
    }
}

// MARK: - Mock & Debug

extension StoreManager {
    static func mock(isPremium: Bool = false) -> StoreManager {
        let manager = StoreManager(isMock: true)
        manager.isPremium = isPremium
        if isPremium {
            manager.activeProductId = Self.monthlyID
            manager.expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: .now)
        }
        return manager
    }

    #if DEBUG
    func debugSetPremium(_ active: Bool) {
        setPremiumActive(active)
        if active {
            activeProductId = Self.monthlyID
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: .now)
        } else {
            activeProductId = nil
            expirationDate = nil
        }
    }

    func forceLoadProducts() async {
        subscriptionProducts = []
        coinPackProducts = []
        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            subscriptionProducts = storeProducts
                .filter { Self.subscriptionIDs.contains($0.id) }
                .sorted { $0.price < $1.price }
            coinPackProducts = storeProducts
                .filter { Self.coinPackIDs.contains($0.id) }
                .sorted { $0.price < $1.price }
        } catch {
            print("StoreManager: Force load failed — \(error)")
        }
    }
    #endif
}
