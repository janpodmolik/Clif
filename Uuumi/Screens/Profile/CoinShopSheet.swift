import StoreKit
import SwiftUI

struct CoinShopSheet: View {
    var source: String = "profile"

    @Environment(StoreManager.self) private var storeManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var coinBalance = SharedDefaults.coinsBalance

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    coinPacks
                    premiumHint
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Get Coins")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .task {
                analytics.send(.paywallShown(source: source, type: "coins"))
                await storeManager.loadProducts()
            }
            .onChange(of: storeManager.purchaseState) { _, newState in
                if newState == .purchased {
                    coinBalance = SharedDefaults.coinsBalance
                }
            }
            .alert("Error", isPresented: hasError, presenting: storeManager.error) { _ in
                Button("OK") { storeManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            HStack(spacing: 4) {
                Text("\(coinBalance)")
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())
                Text("coins")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Coin Packs

    private var coinPacks: some View {
        VStack(spacing: 10) {
            ForEach(storeManager.coinPackProducts, id: \.id) { product in
                coinPackCard(product)
            }
        }
    }

    private func coinPackCard(_ product: Product) -> some View {
        let amount = storeManager.coinAmount(for: product)
        let isLarge = product.id == StoreManager.coinsLargeID
        let isThisPurchasing = storeManager.purchasingProductId == product.id
        let isAnyPurchasing = storeManager.purchaseState == .purchasing

        return Button {
            Task {
                await storeManager.purchase(product)
                switch storeManager.purchaseState {
                case .purchased:
                    analytics.send(.purchaseCompleted(product: product.id, source: source, revenue: product.displayPrice))
                case .failed:
                    analytics.send(.purchaseFailed(product: product.id, source: source, reason: storeManager.error?.localizedDescription ?? "unknown"))
                default:
                    break
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(amount) Coins")
                            .font(.body.weight(.semibold))
                        if isLarge {
                            Text("Best Value")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("PremiumGold").opacity(0.2))
                                .foregroundStyle(Color("PremiumGold"))
                                .clipShape(Capsule())
                        }
                    }
                    Text(packDescription(for: product.id))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isThisPurchasing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(product.displayPrice)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnyPurchasing)
    }

    // MARK: - Premium Hint

    @ViewBuilder
    private var premiumHint: some View {
        if !storeManager.isPremium {
            VStack(spacing: 8) {
                Text("Earn coins faster with Premium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("2× evolution rewards + break coins")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private func packDescription(for productId: String) -> String {
        switch productId {
        case StoreManager.coinsSmallID:
            return String(localized: "Quick boost for your collection")
        case StoreManager.coinsMediumID:
            return String(localized: "Unlock multiple essences")
        case StoreManager.coinsLargeID:
            return String(localized: "Best per-coin value")
        default:
            return ""
        }
    }

    private var hasError: Binding<Bool> {
        Binding(
            get: { storeManager.error != nil },
            set: { if !$0 { storeManager.clearError() } }
        )
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CoinShopSheet()
                .environment(StoreManager())
                .environment(AnalyticsManager())
        }
}
