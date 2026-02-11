import SwiftUI
import StoreKit

struct PremiumSheet: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if storeManager.isPremium {
                        activePremiumView
                    } else {
                        featureList
                        planPicker
                        purchaseButton
                        restoreButton
                    }

                    legalLinks
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .task {
                await storeManager.loadProducts()
                // Pre-select yearly as best value
                if selectedProduct == nil {
                    selectedProduct = storeManager.yearlyProduct
                }
            }
            .alert("Chyba", isPresented: hasError, presenting: storeManager.error) { _ in
                Button("OK") { storeManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("PremiumGold"))

            Text("Uuumi Premium")
                .font(.title.weight(.bold))

            Text("Odemkni plný potenciál svých petů.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Active Premium

    private var activePremiumView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Premium je aktivní")
                    .font(.headline)
            }

            if let productId = storeManager.activeProductId {
                Text(planLabel(for: productId))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let expiration = storeManager.expirationDate {
                Text("Obnovení: \(expiration.formatted(.dateTime.day().month(.wide).year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await storeManager.showManageSubscriptions() }
            } label: {
                Text("Spravovat předplatné")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "sparkles", text: "Exkluzivní evoluce")
            featureRow(icon: "paintpalette.fill", text: "Speciální témata")
            featureRow(icon: "chart.bar.fill", text: "Detailní statistiky")
            featureRow(icon: "infinity", text: "Neomezený počet petů")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plan Picker

    private var planPicker: some View {
        VStack(spacing: 10) {
            if let yearly = storeManager.yearlyProduct {
                planCard(yearly, badge: savingsBadge)
            }
            if let monthly = storeManager.monthlyProduct {
                planCard(monthly)
            }
            if let weekly = storeManager.weeklyProduct {
                planCard(weekly)
            }
        }
    }

    private func planCard(_ product: Product, badge: String? = nil) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(planLabel(for: product.id))
                            .font(.body.weight(.semibold))
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("PremiumGold").opacity(0.2))
                                .foregroundStyle(Color("PremiumGold"))
                                .clipShape(Capsule())
                        }
                    }
                    if let intro = introOfferText(for: product) {
                        Text(intro)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.body.weight(.semibold))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("PremiumGold").opacity(0.1) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color("PremiumGold") : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task { await storeManager.purchase(product) }
        } label: {
            Group {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Získat Premium")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("PremiumGold"))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedProduct == nil || storeManager.purchaseState == .purchasing)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await storeManager.restorePurchases() }
        } label: {
            Text("Obnovit nákupy")
                .font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Legal

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Podmínky", destination: URL(string: "https://uuumi.app/terms")!)
            Text("·").foregroundStyle(.secondary)
            Link("Ochrana soukromí", destination: URL(string: "https://uuumi.app/privacy")!)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("PremiumGold"))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }

    private func planLabel(for productId: String) -> String {
        switch productId {
        case StoreManager.weeklyID: return "Týdenní"
        case StoreManager.monthlyID: return "Měsíční"
        case StoreManager.yearlyID: return "Roční"
        default: return productId
        }
    }

    private var savingsBadge: String? {
        guard let monthly = storeManager.monthlyProduct,
              let yearly = storeManager.yearlyProduct else { return nil }
        let monthlyPerYear = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        guard monthlyPerYear > 0 else { return nil }
        let savings = Int(((monthlyPerYear - yearlyPrice) / monthlyPerYear * 100).rounded())
        guard savings > 0 else { return nil }
        return "Ušetři \(savings) %"
    }

    private func introOfferText(for product: Product) -> String? {
        guard let intro = product.subscription?.introductoryOffer else { return nil }
        switch intro.period.unit {
        case .day:
            return "\(intro.period.value) dní zdarma"
        case .week:
            return "\(intro.period.value) týdnů zdarma"
        case .month:
            return "\(intro.period.value) měsíců zdarma"
        case .year:
            return "\(intro.period.value) rok zdarma"
        @unknown default:
            return nil
        }
    }

    private var hasError: Binding<Bool> {
        Binding(
            get: { storeManager.error != nil },
            set: { if !$0 { storeManager.clearError() } }
        )
    }
}

#Preview {
    PremiumSheet()
        .environment(StoreManager.mock())
}
