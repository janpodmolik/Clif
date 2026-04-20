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
    case overview = "Overview"
    case profile = "Profile"

    var symbol: String {
        switch self {
        case .home: return "house"
        case .overview: return "chart.bar"
        case .profile: return "person"
        }
    }
}

struct ContentView: View {
    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @AppStorage(DefaultsKeys.appearanceMode)
    private var appearanceMode: AppearanceMode = .automatic

    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(EssenceCatalogManager.self) private var essenceCatalogManager
    @Environment(SyncManager.self) private var syncManager
    @Environment(DeepLinkRouter.self) private var router
    @Environment(StoreManager.self) private var storeManager

    @State private var activeTab: AppTab = .home
    @State private var isDaytime: Bool = SkyGradient.isLightAppearance()
    @State private var navigationPaths: [AppTab: NavigationPath] = [:]
    @State private var essenceCoordinator = EssencePickerCoordinator()
    @State private var createPetCoordinator = CreatePetCoordinator()
    @State private var coinsAnimator = CoinsRewardAnimator()
    @State private var showMockSheet = false

    @Environment(\.scenePhase) private var scenePhase

    private var shieldState: ShieldState { ShieldState.shared }

    @State private var showTesterView = false
    @State private var showNotificationRequest = false
    @State private var showPostOnboardingPremium = false
    @AppStorage("hasSeenPostOnboardingPaywall") private var hasSeenPostOnboardingPaywall = false

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        GeometryReader { rootGeometry in
            Group {
                if hasCompletedOnboarding {
                    mainContent
                } else {
                    OnboardingView()
                        .ignoresSafeArea(.keyboard)
                        .preferredColorScheme(resolvedColorScheme)
                }
            }
            .environment(\.fullScreenHeight, rootGeometry.size.height)
        }
        .sheet(item: Bindable(syncManager).pendingWelcomeBack) { cloudPet in
            WelcomeBackSheet(cloudPet: cloudPet) { action, appSelection in
                Task {
                    await syncManager.resolveWelcomeBack(
                        action,
                        petManager: petManager,
                        archivedPetManager: archivedPetManager,
                        essenceCatalogManager: essenceCatalogManager
                    )
                    if action == .continueWithPet {
                        // Apply app selection before going to HomeScreen
                        if let appSelection {
                            let sources = LimitedSource.from(appSelection)
                            petManager.handleAppReselectionComplete(sources, selection: appSelection)
                        }
                        hasCompletedOnboarding = true
                    }
                    // archive/delete: hasCompletedOnboarding stays false → OnboardingView appears
                }
            }
        }
    }

    private var mainContent: some View {
        ZStack {
            TabView(selection: $activeTab) {
                Tab("Home", systemImage: "house", value: .home) {
                    HomeScreen()
                }
                Tab("Overview", systemImage: "chart.bar", value: .overview) {
                    OverviewScreen()
                }
                Tab("Profile", systemImage: "person", value: .profile) {
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
            isDaytime = SkyGradient.isLightAppearance()
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToNotificationSettings)) { _ in
            activeTab = .profile
            navigationPaths[.profile] = NavigationPath([ProfileDestination.notificationSettings])
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
        .testerOverlay(isPresented: $showTesterView)
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
                checkDayResetAndShowPicker()
                checkNotificationPrompt()
                if SharedDefaults.pendingShieldUnlock {
                    activeTab = .home
                }
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
        .fullScreenCover(isPresented: Bindable(router).showPresetPicker, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.drainPendingAction()
            }
        }) {
            DailyPresetPicker()
                .interactiveDismissDisabled()
        }
        .sheet(item: Bindable(router).showDailySummary) { request in
            if let pet = petManager.currentPet {
                let targetDate = request.notificationDate ?? Date()
                let dayStat = pet.dailyStats.first {
                    Calendar.current.isDate($0.date, inSameDayAs: targetDate)
                } ?? DailyUsageStat(
                    petId: pet.id,
                    date: targetDate,
                    totalMinutes: 0,
                    preset: pet.preset
                )
                DayDetailSheet(
                    day: dayStat,
                    petId: pet.id,
                    limitMinutes: Int(dayStat.preset?.minutesToBlowAway ?? pet.preset.minutesToBlowAway),
                    hourlyBreakdown: nil
                )
            }
        }
        .sheet(isPresented: $showNotificationRequest) {
            NotificationRequestSheet()
        }
        .sheet(isPresented: $showPostOnboardingPremium) {
            PremiumSheet(source: .onboarding)
        }
        .onAppear {
            checkDayResetAndShowPicker()

            if hasCompletedOnboarding, !hasSeenPostOnboardingPaywall, !storeManager.isPremium {
                hasSeenPostOnboardingPaywall = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showPostOnboardingPremium = true
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

    // MARK: - Daily Reset & Preset Picker

    private func checkDayResetAndShowPicker() {
        // End any break that expired while the app was closed
        ShieldManager.shared.endExpiredBreakIfNeeded()

        guard petManager.hasPet,
              SharedDefaults.isNewDay else {
            return
        }

        let settings = SharedDefaults.limitSettings
        if settings.dayStartShieldEnabled {
            // Show preset picker — applyPreset will set lastDayResetDate + todaySelectedPreset
            router.showPresetPicker = true
        } else if let pet = petManager.currentPet {
            // Auto-apply default preset
            let preset = WindPreset(rawValue: settings.defaultWindPresetRaw) ?? .balanced
            ScreenTimeManager.shared.applyPreset(preset, for: pet)
            petManager.savePet()
        }
    }

    // MARK: - Notification Re-prompt

    private func checkNotificationPrompt() {
        // Don't show if another sheet is presenting
        guard syncManager.pendingWelcomeBack == nil,
              syncManager.pendingConflict == nil,
              !router.showPresetPicker,
              router.showDailySummary == nil,
              !showNotificationRequest else {
            return
        }

        // Check cooldown (once per week)
        if let lastPrompt = UserDefaults.standard.object(forKey: DefaultsKeys.lastNotificationPromptDate) as? Date,
           Date().timeIntervalSince(lastPrompt) < AppConstants.notificationPromptCooldown {
            return
        }

        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus != .authorized else { return }

            // Delay to avoid conflicts with other sheets that may appear on foreground
            try await Task.sleep(for: .seconds(1))
            showNotificationRequest = true
            UserDefaults.standard.set(Date(), forKey: DefaultsKeys.lastNotificationPromptDate)
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
        .environment(DeepLinkRouter())
        .environment(AnalyticsManager())
}
