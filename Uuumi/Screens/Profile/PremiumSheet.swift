import SwiftUI
import StoreKit

enum PaywallSource: String {
    case profile
    case onboarding
    case petCreated = "pet_created"
    case committedBreak = "committed_break"
    case appearanceTheme = "appearance_theme"
    case appearanceSky = "appearance_sky"
    case essenceUnlock = "essence_unlock"
    case essenceApplicationUpsell = "essence_application_upsell"
    case evolutionUpsell = "evolution_upsell"
    case essenceCatalog = "essence_catalog"
    case petDetailTrend = "pet_detail_trend"
    case dayByDayStats = "day_by_day_stats"
    case dayDetailTimeline = "day_detail_timeline"
    case dailyPattern = "daily_pattern"
}

struct PremiumSheet: View {
    var source: PaywallSource = .profile

    @Environment(StoreManager.self) private var storeManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if storeManager.isPremium {
                        activePremiumView
                    } else if storeManager.isLoadingProducts {
                        ProgressView()
                            .padding(.top, 32)
                    } else if storeManager.productsLoadFailed {
                        productsUnavailableView
                    } else {
                        featureList
                        planPicker
                        purchaseButton
                        footer
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .task {
                analytics.send(.paywallShown(source: source.rawValue, type: "premium"))
                await storeManager.loadProducts()
                // Pre-select yearly as best value
                if selectedProduct == nil {
                    selectedProduct = storeManager.yearlyProduct
                }
            }
            .alert("Error", isPresented: hasError, presenting: storeManager.error) { _ in
                Button("OK") { storeManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert(restoreAlertTitle, isPresented: showRestoreAlert) {
                Button("OK") { storeManager.clearRestoreState() }
            } message: {
                Text(restoreAlertMessage)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image("premium")
                .resizable()
                .scaledToFit()
                .frame(height: 120)

            Text("Unlock the full journey.")
                .font(.title2.weight(.bold))
        }
        .padding(.top, 8)
    }

    // MARK: - Active Premium

    private var activePremiumView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Premium is Active")
                    .font(.headline)
            }

            if let productId = storeManager.activeProductId {
                Text(planLabel(for: productId))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let expiration = storeManager.expirationDate {
                Text("Renewal: \(expiration.formatted(.dateTime.day().month(.wide).year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await storeManager.showManageSubscriptions() }
            } label: {
                Text("Manage Subscription")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Products Unavailable

    private var productsUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Unable to load plans")
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
                    .background(Color("PremiumGold"))
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "arrow.up.forward.circle.fill", title: "Double evolution rewards", subtitle: "Earn 2x coins every time your pet evolves")
            featureRow(icon: "lock.shield.fill", title: "Committed Breaks", subtitle: "Real rewards, real consequences")
            featureRow(icon: "sun.horizon.fill", title: "Premium backgrounds", subtitle: "Dynamic Sky, Clear Sky & Twilight themes")
            featureRow(icon: "chart.line.uptrend.xyaxis", title: "Habit insights", subtitle: "Trends, daily timeline & extended history")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plan Picker

    private var planPicker: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("No commitment, cancel anytime")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)

            if let yearly = storeManager.yearlyProduct {
                planCard(yearly, badge: savingsBadge)
            }
            if let monthly = storeManager.monthlyProduct {
                planCard(monthly)
            }
        }
    }

    private func planCard(_ product: Product, badge: String? = nil) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == StoreManager.yearlyID

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isYearly ? String(localized: "Annual Plan") : String(localized: "Monthly Plan"))
                        .font(.body.weight(.semibold))
                    HStack(spacing: 0) {
                        Text(product.displayPrice)
                            .foregroundStyle(.primary)
                        Text(" · \(weeklyPrice(for: product)) per week")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(isYearly ? String(localized: "1-week") : String(localized: "No free"))
                        .font(.caption.weight(isYearly ? .semibold : .regular))
                        .foregroundStyle(isYearly ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    Text(isYearly ? String(localized: "free trial") : String(localized: "trial"))
                        .font(.caption.weight(isYearly ? .semibold : .regular))
                        .foregroundStyle(isYearly ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                }
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
                if let badge {
                    Text(badge)
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
                    analytics.send(.purchaseCompleted(product: product.id, source: source.rawValue, revenue: product.displayPrice))
                    await analytics.updatePremiumPlan(storeManager.activeProductId)
                case .failed:
                    analytics.send(.purchaseFailed(product: product.id, source: source.rawValue, reason: storeManager.error?.localizedDescription ?? "unknown"))
                default:
                    break
                }
            }
        } label: {
            Group {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(selectedProduct?.id == StoreManager.yearlyID ? "Try 7 Days Free" : "Continue")
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

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 24) {
            Text("Secured via the App Store")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("Restore Purchase") {
                    Task { await storeManager.restorePurchases() }
                }
                Link("Privacy & Terms", destination: URL(string: "https://uuumi.app/terms/")!)
                Button("Redeem Code") {
                    Task {
                        guard let scene = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene }).first else { return }
                        try? await AppStore.presentOfferCodeRedeemSheet(in: scene)
                    }
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("PremiumGold"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func planLabel(for productId: String) -> String {
        switch productId {
        case StoreManager.monthlyID: return String(localized: "Monthly")
        case StoreManager.yearlyID: return String(localized: "Yearly")
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
        return String(localized: "\(savings)% OFF")
    }

    private func weeklyPrice(for product: Product) -> String {
        let weeks: Decimal = product.id == StoreManager.yearlyID ? 52 : Decimal(3044) / Decimal(700)
        let perWeek = product.price / weeks
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 2
        return formatter.string(from: perWeek as NSDecimalNumber) ?? ""
    }

    private var hasError: Binding<Bool> {
        Binding(
            get: { storeManager.error != nil },
            set: { if !$0 { storeManager.clearError() } }
        )
    }

    private var showRestoreAlert: Binding<Bool> {
        Binding(
            get: { storeManager.restoreState == .restored || storeManager.restoreState == .nothingToRestore || storeManager.restoreState == .failed },
            set: { if !$0 { storeManager.clearRestoreState() } }
        )
    }

    private var restoreAlertTitle: String {
        switch storeManager.restoreState {
        case .restored: String(localized: "Purchase Restored")
        case .nothingToRestore: String(localized: "No Purchase Found")
        case .failed: String(localized: "Restore Failed")
        default: ""
        }
    }

    private var restoreAlertMessage: String {
        switch storeManager.restoreState {
        case .restored: String(localized: "Your premium subscription has been restored.")
        case .nothingToRestore: String(localized: "No active subscription was found for this Apple Account.")
        case .failed: String(localized: "Something went wrong. Please check your internet connection and try again.")
        default: ""
        }
    }
}

// MARK: - Presentation Modifier

extension View {
    func premiumSheet(isPresented: Binding<Bool>, source: PaywallSource = .profile) -> some View {
        fullScreenCover(isPresented: isPresented) {
            PremiumSheet(source: source)
        }
    }
}

#Preview {
    PremiumSheet()
        .environment(StoreManager.mock())
        .environment(AnalyticsManager())
}
