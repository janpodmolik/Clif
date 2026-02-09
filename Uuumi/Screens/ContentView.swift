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
    @AppStorage("lockButtonSide")
    private var lockButtonSide: LockButtonSide = .trailing

    @Environment(PetManager.self) private var petManager

    @State private var activeTab: AppTab = .home
    @State private var isDaytime: Bool = SkyGradient.isDaytime()
    @State private var navigationPaths: [AppTab: NavigationPath] = [:]
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

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        GeometryReader { geometry in
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

                // Floating lock button — Home tab only, hidden during pet creation
                if activeTab == .home && !createPetCoordinator.isShowing {
                    VStack {
                        Spacer()
                        HStack {
                            if lockButtonSide == .trailing { Spacer() }
                            floatingLockButton()
                            if lockButtonSide == .leading { Spacer() }
                        }
                        .padding(lockButtonSide == .trailing ? .trailing : .leading, 20)
                        .padding(.bottom, geometry.size.height * 0.25)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(true)
                }

                EssencePickerOverlay()
                CreatePetOverlay(screenHeight: geometry.size.height)

                // Coins reward tag overlay
                GeometryReader { overlayGeo in
                    BigTagRewardView(
                        animator: coinsAnimator,
                        position: CGPoint(x: overlayGeo.size.width / 2, y: overlayGeo.size.height * 0.62)
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
            }
        }
    }

    // MARK: - Floating Lock Button

    @ViewBuilder
    private func floatingLockButton() -> some View {
        if #available(iOS 26.0, *) {
            lockButton()
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            lockButton()
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    @ViewBuilder
    private func lockButton() -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            handleHomeActionTap()
        } label: {
            Group {
                if petManager.currentPet != nil {
                    Image(systemName: shieldState.isActive ? "lock.fill" : "lock.open.fill")
                } else {
                    Image(systemName: "plus")
                }
            }
            .font(.title2.weight(.semibold))
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 55, height: 55)
        }
        .contentShape(Circle().inset(by: -10))
        .buttonStyle(.pressableButton)
    }

    // MARK: - Lock Actions

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
}
