import SwiftUI

struct EssenceUnlockSheet: View {
    let essence: Essence

    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(SyncManager.self) private var syncManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPremiumSheet = false
    @State private var showCoinShopSheet = false
    @State private var showConfirmation = false
    @State private var showUnlockCelebration = false

    private var path: EvolutionPath { .path(for: essence) }
    private var balance: Int { CoinStore.shared.balance }
    private var canAfford: Bool { balance >= essence.price }
    private var coinsNeeded: Int { max(0, essence.price - balance) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    priceSection
                    if canAfford {
                        unlockButton
                    } else {
                        notEnoughCoinsView
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(path.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
        }
        .tint(.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet(source: "essence_unlock")
        }
        .sheet(isPresented: $showCoinShopSheet) {
            CoinShopSheet(source: "essence_unlock")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(essence.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .scaleEffect(showUnlockCelebration ? 1.2 : 1.0)
                .overlay {
                    EssenceUnlockParticleView(
                        isActive: showUnlockCelebration,
                        color: Color("PremiumGold")
                    )
                    .frame(width: 350, height: 350)
                }

            Text(essence.catalogDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Price

    private var priceSection: some View {
        HStack(spacing: 0) {
            priceItem(
                value: "\(essence.price)",
                label: String(localized: "Price")
            )
            priceDivider
            balanceItem
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func priceItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(value)
            }
            .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var balanceItem: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("\(balance)")
            }
            .font(.headline)
            .foregroundStyle(Color.primary)
            Text(String(localized: "Your Balance"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var priceDivider: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 1, height: 28)
    }

    // MARK: - Can Afford

    private var unlockButton: some View {
        VStack(spacing: 12) {
            Text("You can unlock this now")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showConfirmation = true
            } label: {
                Text("Unlock \(path.displayName)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green, in: RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: 26)))
            }
            .padding(.horizontal, 20)
            .confirmationDialog(
                "Spend \(essence.price) coins to unlock this essence?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Confirm") {
                    let result = catalogManager.purchaseEssence(essence)
                    if result == .success {
                        Task {
                            await syncManager.syncUserData(essenceCatalogManager: catalogManager)
                        }
                        HapticType.notificationSuccess.trigger()
                        SoundManager.shared.play(.essenceUnlock)
                        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                            showUnlockCelebration = true
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(1.0))
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }

            if !storeManager.isPremium {
                PremiumButton("Earn coins faster with Premium", style: .inline) { showPremiumSheet = true }
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Can't Afford

    private var notEnoughCoinsView: some View {
        VStack(spacing: 12) {
            Text("You need \(coinsNeeded) more coins")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showCoinShopSheet = true
            } label: {
                Text("Get More Coins")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: 26)))
            }
            .padding(.horizontal, 20)

            if !storeManager.isPremium {
                PremiumButton("Earn coins faster with Premium", style: .inline) { showPremiumSheet = true }
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EssenceUnlockSheet(essence: .troll)
                .environment(EssenceCatalogManager.mock())
                .environment(SyncManager())
                .environment(StoreManager())
        }
}
