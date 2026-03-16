import SwiftUI

struct EssenceUnlockSheet: View {
    let essence: Essence

    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(SyncManager.self) private var syncManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPremiumSheet = false

    private var path: EvolutionPath { .path(for: essence) }
    private var balance: Int { SharedDefaults.coinsBalance }
    private var canAfford: Bool { balance >= essence.price }
    private var coinsNeeded: Int { max(0, essence.price - balance) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    priceSection
                    unlockButton
                    premiumHint
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
            PremiumSheet()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(essence.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

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
                label: String(localized: "Price"),
                icon: "u.circle.fill"
            )
            priceDivider
            balanceItem
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func priceItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(Color("PremiumGold"))
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
                Image(systemName: "u.circle.fill")
                    .foregroundStyle(Color("PremiumGold"))
                Text("\(balance)")
            }
            .font(.headline)
            .foregroundStyle(canAfford ? Color.primary : Color.red)
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

    // MARK: - Unlock Button

    private var unlockButton: some View {
        Button {
            let result = catalogManager.purchaseEssence(essence)
            if result == .success {
                Task {
                    await syncManager.syncUserData(essenceCatalogManager: catalogManager)
                }
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: canAfford ? "lock.open.fill" : "lock.fill")
                if canAfford {
                    Text("Unlock for \(essence.price)")
                } else {
                    Text("Need \(coinsNeeded) more coins")
                }
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(canAfford ? .green : .gray)
        .disabled(!canAfford)
        .padding(.horizontal, 20)
    }

    // MARK: - Premium Hint

    @ViewBuilder
    private var premiumHint: some View {
        if !storeManager.isPremium {
            Button {
                showPremiumSheet = true
            } label: {
                Text("Earn more coins with Premium")
                    .font(.caption)
                    .foregroundStyle(.blue)
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
