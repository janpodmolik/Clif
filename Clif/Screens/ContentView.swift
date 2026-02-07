import SwiftUI
import Combine

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressableButton: PressableButtonStyle { PressableButtonStyle() }
}

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
    @AppStorage("appearanceMode")
    private var appearanceMode: AppearanceMode = .automatic

    @Environment(PetManager.self) private var petManager

    @State private var activeTab: AppTab = .home
    @State private var isDaytime: Bool = SkyGradient.isDaytime()
    @State private var navigationPaths: [AppTab: NavigationPath] = [:]
    @State private var showSearch = false
    @State private var showPremium = false
    @State private var essenceCoordinator = EssencePickerCoordinator()
    @State private var createPetCoordinator = CreatePetCoordinator()
    @State private var coinsAnimator = CoinsRewardAnimator()
    @State private var showMockSheet = false

    @Environment(\.scenePhase) private var scenePhase

    // Break picker states
    @State private var showBreakTypePicker = false
    @State private var showCommittedUnlock = false
    @State private var showSafetyUnlock = false

    private var shieldState: ShieldState { ShieldState.shared }

    private let tabBarHeight: CGFloat = 55

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        GeometryReader { geometry in
            ZStack {
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
                        ProfileScreen(navigationPath: navigationPathBinding(for: .profile))
                            .toolbarVisibility(.hidden, for: .tabBar)
                    }
                }
                .tint(.primary)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    customTabBar()
                        .padding(.horizontal, 20)
                }

                EssencePickerOverlay()
                CreatePetOverlay(screenHeight: geometry.size.height)

                // Coins reward tag overlay
                GeometryReader { overlayGeo in
                    let w = overlayGeo.size.width
                    let h = overlayGeo.size.height
                    // Profile tab is the 3rd of 3 tabs in the left capsule.
                    // Layout: |--20--[  tabs capsule  ]--10--[55 btn]--20--|
                    let tabsCapsuleWidth = w - 40 - 55 - 10
                    let profileTabCenterX = 20 + tabsCapsuleWidth * (5.0 / 6.0)

                    BigTagRewardView(
                        animator: coinsAnimator,
                        startPosition: CGPoint(x: w / 2, y: h * 0.62),
                        endPosition: CGPoint(x: profileTabCenterX, y: h - tabBarHeight - 10)
                    )
                }
                .allowsHitTesting(false)
            }
        }
        .environment(essenceCoordinator)
        .environment(createPetCoordinator)
        .environment(coinsAnimator)
        .preferredColorScheme(resolvedColorScheme)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            isDaytime = SkyGradient.isDaytime()
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectPet)) { _ in
            activeTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .showEssenceCatalog)) { _ in
            activeTab = .profile
            navigationPaths[.profile] = NavigationPath([ProfileDestination.essenceCatalog])
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: .showMockSheet)) { _ in
            showMockSheet = true
        }
        #endif
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .sheet(isPresented: $showPremium) {
            PremiumSheet()
        }
        .sheet(isPresented: $showMockSheet) {
            mockSheetContent
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showPetDebug) {
            PetDebugView()
        }
        .withDebugOverlay()
        #endif
        // Break picker
        .sheet(isPresented: $showBreakTypePicker) {
            BreakTypePicker(
                onSelectFree: {
                    startBreak(type: .free, durationMinutes: nil)
                },
                onConfirmCommitted: { durationMinutes in
                    startBreak(type: .committed, durationMinutes: durationMinutes)
                }
            )
        }
        .unlockConfirmations(showCommitted: $showCommittedUnlock, showSafety: $showSafetyUnlock)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                ShieldState.shared.refresh()
            }
        }
        .onChange(of: shieldState.lastEarnedCoins) { _, coins in
            if coins > 0 {
                coinsAnimator.showReward(coins)
                ShieldState.shared.clearEarnedCoins()
            }
        }
    }

    // MARK: - Tab Bar

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
            SwiftUITabBar(
                activeTab: $activeTab,
                onReselect: { tab in popToRoot(for: tab) },
                tabSymbol: { $0.symbol },
                pulsingTab: .profile,
                coinsAnimator: coinsAnimator
            )
            .padding(.horizontal, 4)
            .frame(height: tabBarHeight)
            .glassEffect(.regular.interactive(), in: .capsule)

            actionButtonGlass()
        }
    }

    private var premiumGoldColor: Color {
        Color("PremiumGold")
    }

    @ViewBuilder
    @available(iOS 26.0, *)
    private func actionButtonGlass() -> some View {
        actionButton()
            .glassEffect(.regular.interactive(), in: .circle)
    }

    @ViewBuilder
    private func actionButtonFallback() -> some View {
        actionButton()
            .background(.ultraThinMaterial, in: Circle())
    }

    @ViewBuilder
    private func actionButton() -> some View {
        Button {
            handleActionButtonTap()
        } label: {
            actionButtonIcon
                .font(.title2.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 55, height: 55)
        }
        .contentShape(Circle().inset(by: -10))
        .buttonStyle(.pressableButton)
    }

    @ViewBuilder
    private var actionButtonIcon: some View {
        switch activeTab {
        case .home:
            // Show lock if pet exists, otherwise plus for creation
            if petManager.currentPet != nil {
                Image(systemName: shieldState.isActive ? "lock.fill" : "lock.open.fill")
            } else {
                Image(systemName: "plus")
            }
        case .overview:
            Image(systemName: "magnifyingglass")
        case .profile:
            Image(systemName: "crown.fill")
                .foregroundStyle(premiumGoldColor)
        }
    }

    private func handleActionButtonTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch activeTab {
        case .home:
            handleHomeActionTap()
        case .overview:
            showSearch = true
        case .profile:
            showPremium = true
        }
    }

    private func handleHomeActionTap() {
        // No pet = pet creation flow
        guard petManager.currentPet != nil else {
            #if DEBUG
            createPetCoordinator.showDropOnly { _ in }
            #else
            createPetCoordinator.show { _ in }
            #endif
            return
        }

        // Toggle lock/unlock
        if shieldState.isActive {
            handleUnlock()
        } else {
            showBreakTypePicker = true
        }
    }

    private func handleUnlock() {
        handleShieldUnlock(
            shieldState: shieldState,
            showCommittedConfirmation: $showCommittedUnlock,
            showSafetyConfirmation: $showSafetyUnlock
        )
    }

    private func startBreak(type: BreakType, durationMinutes: Int?) {
        ShieldManager.shared.turnOn(breakType: type, durationMinutes: durationMinutes)
    }

    private static let navigableTabs: Set<AppTab> = [.profile]

    private func popToRoot(for tab: AppTab) {
        guard Self.navigableTabs.contains(tab) else { return }
        navigationPaths[tab] = NavigationPath()
    }

    private func navigationPathBinding(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { navigationPaths[tab, default: NavigationPath()] },
            set: { navigationPaths[tab] = $0 }
        )
    }

    @ViewBuilder
    private func tabBarContentFallback() -> some View {
        SwiftUITabBar(
            activeTab: $activeTab,
            onReselect: { tab in popToRoot(for: tab) },
            tabSymbol: { $0.symbol },
            pulsingTab: .profile,
            coinsAnimator: coinsAnimator
        )
        .padding(.horizontal, 4)
        .frame(height: tabBarHeight)
        .background(.ultraThinMaterial, in: Capsule())

        actionButtonFallback()
    }

    // MARK: - Appearance

    private var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case .automatic:
            return isDaytime ? .light : .dark
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // MARK: - Mock Sheet (DEBUG)

    private var mockSheetContent: some View {
        VStack(spacing: 16) {
            Text("Mock Sheet")
                .font(.headline)
            Text("Compare this height with essence picker tray")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(EssenceCatalogManager.mock())
}
