import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case overview = "Přehled"
    case profile = "Profil"

    var symbol: String {
        switch self {
        case .home: return "house"
        case .overview: return "chart.bar"
        case .profile: return "person"
        }
    }
}

struct ContentView: View {
    @AppStorage("isDarkModeEnabled")
    private var isDarkModeEnabled: Bool = false

    @State private var activeTab: AppTab = .home
    @State private var selectedPetId: UUID?
    @State private var showSearch = false
    @State private var showPremium = false

    @Namespace private var tabButtonNamespace

    private let tabBarHeight: CGFloat = 55
    private let premiumParticleSize = CGSize(width: 90, height: 180)
    private let premiumParticleVerticalOffset: CGFloat = -10

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                HomeScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: .overview) {
                OverviewScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: .profile) {
                ProfileScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .tint(.primary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar()
                .padding(.horizontal, 20)
        }
        .overlayPreferenceValue(CenterButtonAnchorKey.self) { anchor in
            GeometryReader { geo in
                if let anchor {
                    let rect = geo[anchor]
                    let centerY = rect.maxY - premiumParticleSize.height / 2 + premiumParticleVerticalOffset
                    PremiumTabBarParticles(isDarkMode: isDarkModeEnabled, isActive: showPremiumButtonEffect)
                        .frame(width: premiumParticleSize.width, height: premiumParticleSize.height)
                        .position(x: rect.midX, y: centerY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .allowsHitTesting(false)
        }
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        .onReceive(NotificationCenter.default.publisher(for: .selectPet)) { notification in
            if let petId = notification.userInfo?["petId"] as? UUID {
                selectedPetId = petId
                activeTab = .home
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .sheet(isPresented: $showPremium) {
            PremiumSheet()
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showPetDebug) {
            PetDebugView()
        }
        #endif
    }

    @ViewBuilder
    private func customTabBar() -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                tabBarContent()
            }
            .frame(height: tabBarHeight)
        } else {
            HStack(spacing: 10) {
                tabBarContentFallback()
            }
            .frame(height: tabBarHeight)
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func tabBarContent() -> some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                CustomTabBar(size: geo.size, activeTab: $activeTab) { tab in
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .symbolVariant(.fill)
                    .frame(maxWidth: .infinity)
                }
                .glassEffect(.regular.interactive(), in: .capsule)
            }

            centerButtonGlass()
        }
    }

    private var centerButtonIcon: String {
        switch activeTab {
        case .home: "plus"
        case .overview: "magnifyingglass"
        case .profile: "sparkles"
        }
    }

    private var showPremiumButtonEffect: Bool {
        activeTab == .profile
    }

    private var premiumGoldColor: Color {
        Color(red: 0.9, green: 0.7, blue: 0.3)
    }

    @ViewBuilder
    @available(iOS 26.0, *)
    private func centerButtonGlass() -> some View {
        centerButton()
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID("centerButton", in: tabButtonNamespace)
            .anchorPreference(key: CenterButtonAnchorKey.self, value: .bounds) { $0 }
    }

    @ViewBuilder
    private func centerButtonFallback() -> some View {
        centerButton()
            .background(.ultraThinMaterial, in: Circle())
            .anchorPreference(key: CenterButtonAnchorKey.self, value: .bounds) { $0 }
    }

    @ViewBuilder
    private func centerButton() -> some View {
        Button {
            handleCenterButtonTap()
        } label: {
            Image(systemName: centerButtonIcon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(showPremiumButtonEffect ? premiumGoldColor : .primary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 55, height: 55)
        }
        .buttonStyle(.plain)
    }

    private func handleCenterButtonTap() {
        switch activeTab {
        case .home:
            #if DEBUG
            showPetDebug = true
            #endif
        case .overview:
            showSearch = true
        case .profile:
            showPremium = true
        }
    }

    @ViewBuilder
    private func tabBarContentFallback() -> some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .symbolVariant(.fill)
                    .foregroundStyle(.primary.opacity(activeTab == tab ? 1 : 0.45))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: tabBarHeight)
        .background(.ultraThinMaterial, in: Capsule())

        centerButtonFallback()
    }
}

#Preview {
    ContentView()
}

private struct CenterButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
