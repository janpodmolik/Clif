import SwiftUI

struct EssenceApplicationUpsellSheet: View {
    let petName: String
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showPremiumSheet = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color("PremiumGold"))

                Text("Give \(petName) an essence!")
                    .font(.title3.weight(.semibold))

                Text("Every evolution earns you coins. Premium doubles the reward.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            coinComparison

            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text("More coins. More features. More Uuumi.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    PremiumButton("Double Your Reward") { showPremiumSheet = true }
                }
                .padding(.horizontal, 20)

                Button {
                    onApply()
                    dismiss()
                } label: {
                    Text("Apply anyway")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: 26)))
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .premiumSheet(isPresented: $showPremiumSheet, source: .essenceApplicationUpsell)
    }

    // MARK: - Coin Comparison

    private var coinComparison: some View {
        HStack(spacing: 0) {
            coinColumn(
                amount: CoinRewards.freeEvolution,
                label: String(localized: "Free"),
                highlighted: false
            )

            Rectangle()
                .fill(.quaternary)
                .frame(width: 1, height: 48)

            coinColumn(
                amount: CoinRewards.premiumEvolution,
                label: String(localized: "Premium"),
                highlighted: true
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Text("2\u{00d7}")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("PremiumGold"), in: Capsule())
                .rotationEffect(.degrees(12))
                .offset(x: 8, y: -10)
        }
        .padding(.horizontal, 20)
    }

    private func coinColumn(amount: Int, label: String, highlighted: Bool) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("+\(amount)")
            }
            .font(highlighted ? .title2.weight(.bold) : .title3.weight(.bold))
            .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EssenceApplicationUpsellSheet(petName: "Blobby", onApply: {})
                .environment(StoreManager.mock())
        }
}
#endif
