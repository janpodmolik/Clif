import SwiftUI

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
    @AppStorage("isDarkModeEnabled")
    private var isDarkModeEnabled: Bool = false

    @Environment(PetManager.self) private var petManager

    @State private var activeTab: AppTab = .home
    @State private var showSearch = false
    @State private var showPremium = false
    @State private var essenceCoordinator = EssencePickerCoordinator()
    @State private var createPetCoordinator = CreatePetCoordinator()
    @State private var showMockSheet = false

    @Environment(\.scenePhase) private var scenePhase

    // Break picker states
    @State private var showBreakTypePicker = false
    @State private var showCommittedUnlockConfirmation = false
    @State private var showSafetyUnlockConfirmation = false

    private var shieldState: ShieldState { ShieldState.shared }

    @Namespace private var tabIndicatorNamespace

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
                        ProfileScreen()
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
            }
        }
        .environment(essenceCoordinator)
        .environment(createPetCoordinator)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        .onReceive(NotificationCenter.default.publisher(for: .selectPet)) { _ in
            activeTab = .home
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
        .confirmationDialog(
            "Ukončit Committed Break?",
            isPresented: $showCommittedUnlockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Ukončit a ztratit peta", role: .destructive) {
                confirmCommittedUnlock()
            }
            Button("Pokračovat v pauze", role: .cancel) {}
        } message: {
            Text("Ukončení committed breaku předčasně způsobí okamžitou ztrátu tvého peta. Tato akce je nevratná.")
        }
        .confirmationDialog(
            "Odemknout Safety Shield?",
            isPresented: $showSafetyUnlockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Odemknout a ztratit peta", role: .destructive) {
                confirmSafetyShieldUnlock()
            }
            Button("Počkat, až vítr klesne", role: .cancel) {}
        } message: {
            Text("Vítr je stále nad 80%. Odemčení teď způsobí ztrátu tvého mazlíčka.")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                ShieldState.shared.refresh()
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

            actionButtonGlass()
        }
    }

    private var premiumGoldColor: Color {
        Color(red: 0.9, green: 0.7, blue: 0.3)
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
        if shieldState.currentBreakType == .safety {
            if ShieldManager.shared.isSafetyUnlockSafe {
                ShieldManager.shared.processSafetyShieldUnlock()
            } else {
                showSafetyUnlockConfirmation = true
            }
        } else if shieldState.currentBreakType == .committed {
            showCommittedUnlockConfirmation = true
        } else {
            ShieldManager.shared.toggle()
        }
    }

    private func confirmSafetyShieldUnlock() {
        let result = ShieldManager.shared.processSafetyShieldUnlock()
        if result == .blownAway {
            petManager.blowAwayCurrentPet(reason: .limitExceeded)
        }
    }

    private func confirmCommittedUnlock() {
        // End break first (logs breakEnded), then blow away
        ShieldManager.shared.toggle(success: false)
        petManager.blowAwayCurrentPet(reason: .breakViolation)
    }

    private func startBreak(type: BreakType, durationMinutes: Int?) {
        ShieldManager.shared.turnOn(breakType: type, durationMinutes: durationMinutes)
    }

    @ViewBuilder
    private func tabBarContentFallback() -> some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy(duration: 0.25)) {
                        activeTab = tab
                    }
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if activeTab == tab {
                            Capsule()
                                .fill(.gray.opacity(0.3))
                                .padding(.vertical, 4)
                                .matchedGeometryEffect(id: "tabIndicator", in: tabIndicatorNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: tabBarHeight)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial, in: Capsule())

        actionButtonFallback()
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
}
