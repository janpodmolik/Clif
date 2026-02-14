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
    @AppStorage(DefaultsKeys.appearanceMode)
    private var appearanceMode: AppearanceMode = .automatic

    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(EssenceCatalogManager.self) private var essenceCatalogManager
    @Environment(SyncManager.self) private var syncManager

    @State private var activeTab: AppTab = .home
    @State private var isDaytime: Bool = SkyGradient.isDaytime()
    @State private var navigationPaths: [AppTab: NavigationPath] = [:]
    @State private var essenceCoordinator = EssencePickerCoordinator()
    @State private var createPetCoordinator = CreatePetCoordinator()
    @State private var coinsAnimator = CoinsRewardAnimator()
    @State private var showMockSheet = false

    @Environment(\.scenePhase) private var scenePhase

    private var shieldState: ShieldState { ShieldState.shared }

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        ZStack {
            TabView(selection: $activeTab) {
                Tab("Home", systemImage: "house", value: .home) {
                    HomeScreen()
                }
                Tab("Přehled", systemImage: "chart.bar", value: .overview) {
                    OverviewScreen()
                }
                Tab("Profil", systemImage: "person", value: .profile) {
                    ProfileScreen(navigationPath: navigationPathBinding(for: .profile))
                }
            }
            .tint(.primary)

            EssencePickerOverlay()
            CreatePetOverlay()

            // Coins reward tag overlay
            GeometryReader { overlayGeo in
                CoinTagRewardView(
                    animator: coinsAnimator,
                    position: CGPoint(x: overlayGeo.size.width / 2, y: overlayGeo.size.height * 0.62)
                )
            }
            .allowsHitTesting(coinsAnimator.isAnimating)
        }
        .environment(essenceCoordinator)
        .environment(createPetCoordinator)
        .environment(coinsAnimator)
        .preferredColorScheme(resolvedColorScheme)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            isDaytime = SkyGradient.isDaytime()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateHome)) { _ in
            activeTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectPet)) { _ in
            activeTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .showEssenceCatalog)) { _ in
            activeTab = .profile
            navigationPaths[.profile] = NavigationPath([ProfileDestination.essenceCatalog])
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDailySummary)) { _ in
            guard petManager.currentPet != nil else { return }
            activeTab = .home
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: .showMockSheet)) { _ in
            showMockSheet = true
        }
        #endif
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
        .onChange(of: activeTab) {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                ShieldState.shared.refresh()
            }
        }
        .onChange(of: shieldState.lastEarnedCoins) { _, coins in
            if coins > 0 {
                coinsAnimator.showReward(coins)
                ShieldState.shared.clearEarnedCoins()
                // Immediately sync coins to cloud so they survive sign-out / force-quit
                Task { await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager) }
            }
        }
        .onChange(of: syncManager.lastClaimedRewards) { _, coins in
            if coins > 0 {
                coinsAnimator.showReward(coins)
                syncManager.lastClaimedRewards = 0
            }
        }
        .sheet(item: Bindable(syncManager).pendingConflict) { conflict in
            PetConflictSheet(conflict: conflict) { resolution in
                Task {
                    await syncManager.resolveConflict(
                        resolution,
                        conflict: conflict,
                        petManager: petManager,
                        archivedPetManager: archivedPetManager,
                        essenceCatalogManager: essenceCatalogManager
                    )
                }
            }
        }
    }

    // MARK: - Navigation

    private func navigationPathBinding(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { navigationPaths[tab, default: NavigationPath()] },
            set: { navigationPaths[tab] = $0 }
        )
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
        .environment(AuthManager.mock())
        .environment(StoreManager.mock())
        .environment(SyncManager())
}
