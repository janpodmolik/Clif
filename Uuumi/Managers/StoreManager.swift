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
                return "Ověření nákupu selhalo"
            case .purchaseCancelled:
                return "Nákup byl zrušen"
            case .purchasePending:
                return "Nákup čeká na schválení"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }

    // MARK: - Product IDs

    static let monthlyID = "com.janpodmolik.Uuumi.premium.monthly"
    static let yearlyID = "com.janpodmolik.Uuumi.premium.yearly"

    private static let productIDs: Set<String> = [monthlyID, yearlyID]

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var expirationDate: Date?
    private(set) var activeProductId: String?
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var error: StoreError?

    private var transactionListener: Task<Void, Never>?

    // MARK: - Convenience

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }

    // MARK: - Init

    init() {
        transactionListener = listenForTransactions()

        Task {
            await checkCurrentEntitlements()
            await loadProducts()
        }
    }

    private init(isMock: Bool) {}

    // MARK: - Load Products

    func loadProducts() async {
        guard products.isEmpty else { return }
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            #if DEBUG
            print("StoreManager: Failed to load products — \(error)")
            #endif
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await updatePremiumStatus(from: transaction)
                await transaction.finish()
                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .idle
                self.error = .purchasePending

            @unknown default:
                purchaseState = .idle
            }
        } catch let storeError as StoreError {
            purchaseState = .failed
            self.error = storeError
        } catch {
            purchaseState = .failed
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

            if Self.productIDs.contains(transaction.productID) {
                await updatePremiumStatus(from: transaction)
                foundActive = true
            }
        }

        if !foundActive {
            isPremium = false
            expirationDate = nil
            activeProductId = nil
        }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await updatePremiumStatus(from: transaction)
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

        isPremium = isActive
        expirationDate = transaction.expirationDate
        activeProductId = isActive ? transaction.productID : nil
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
        isPremium = active
        if active {
            activeProductId = Self.monthlyID
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: .now)
        } else {
            activeProductId = nil
            expirationDate = nil
        }
    }

    func forceLoadProducts() async {
        products = []
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("StoreManager: Force load failed — \(error)")
        }
    }
    #endif
}
