import StoreKit
import SwiftUI

struct CoinShopSheet: View {
    var source: String = "profile"

    @Environment(StoreManager.self) private var storeManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var coinBalance = SharedDefaults.coinsBalance
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if storeManager.isLoadingProducts {
                        ProgressView()
                            .padding(.top, 32)
                    } else if storeManager.productsLoadFailed {
                        productsUnavailableView
                    } else {
                        coinPacks
                        purchaseButton
                        premiumHint
                        footer
                    }
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
                if selectedProduct == nil {
                    selectedProduct = storeManager.coinPackProducts.first { $0.id == StoreManager.coinsMediumID }
                }
            }
            .onChange(of: storeManager.purchaseState) { _, newState in
                if newState == .purchased {
                    coinBalance = SharedDefaults.coinsBalance
                    Task {
                        try? await Task.sleep(for: .seconds(0.8))
                        dismiss()
                    }
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
            Image(packImageName(for: selectedProduct))
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .animation(.easeInOut(duration: 0.2), value: selectedProduct?.id)

            HStack(spacing: 4) {
                Text("\(coinBalance)")
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())
                Text("coins")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Text("Power up your collection.")
                .font(.title2.weight(.bold))
        }
        .padding(.top, 8)
    }

    // MARK: - Products Unavailable

    private var productsUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Unable to load coin packs")
                .font(.subheadline.weight(.medium))

            Text("Check your internet connection and try again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await storeManager.retryLoadProducts() }
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Coin Packs

    private var coinPacks: some View {
        VStack(spacing: 12) {
            ForEach(storeManager.coinPackProducts.reversed(), id: \.id) { product in
                coinPackCard(product)
            }
        }
    }

    private func coinPackCard(_ product: Product) -> some View {
        let amount = storeManager.coinAmount(for: product)
        let isLarge = product.id == StoreManager.coinsLargeID
        let isSelected = selectedProduct?.id == product.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(amount) Coins")
                        .font(.body.weight(.semibold))
                    HStack(spacing: 0) {
                        Text(product.displayPrice)
                            .foregroundStyle(.primary)
                        Text(" · \(pricePerCoin(for: product)) per coin")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color("PremiumGold").opacity(0.08) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color("PremiumGold") : Color(.separator).opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .top) {
                if isLarge {
                    Text("Best Value")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color("PremiumGold"), in: Capsule())
                        .offset(y: -14)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
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
            Group {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .tint(.black)
                } else if let product = selectedProduct {
                    Text("Buy \(storeManager.coinAmount(for: product)) Coins")
                        .font(.title3.weight(.bold))
                } else {
                    Text("Select a pack")
                        .font(.title3.weight(.bold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 65)
            .background(Color("PremiumGold"))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedProduct == nil || storeManager.purchaseState == .purchasing)
    }

    // MARK: - Premium Hint

    @ViewBuilder
    private var premiumHint: some View {
        if !storeManager.isPremium {
            VStack(spacing: 4) {
                Text("Earn coins faster with Premium")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("2× evolution rewards + break coins")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Secured via the App Store")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private func packImageName(for product: Product?) -> String {
        switch product?.id {
        case StoreManager.coinsSmallID:
            return "coin-shop-small-pack"
        case StoreManager.coinsMediumID:
            return "coin-shop-medium-pack"
        case StoreManager.coinsLargeID:
            return "coin-shop-large-pack"
        default:
            return "coin-shop-medium-pack"
        }
    }

    private func pricePerCoin(for product: Product) -> String {
        let amount = Decimal(storeManager.coinAmount(for: product))
        guard amount > 0 else { return "" }
        let perCoin = product.price / amount
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 3
        return formatter.string(from: perCoin as NSDecimalNumber) ?? ""
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
