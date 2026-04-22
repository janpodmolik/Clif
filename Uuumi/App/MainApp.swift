import Auth
import Combine
import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @Environment(\.scenePhase) private var scenePhase

    @State private var petManager = PetManager()
    @State private var archivedPetManager = ArchivedPetManager()
    @State private var essenceCatalogManager = EssenceCatalogManager()
    @State private var authManager = AuthManager()
    @State private var storeManager = StoreManager()
    @State private var syncManager = SyncManager()
    @State private var analyticsManager = AnalyticsManager()
    @State private var deepLinkRouter = DeepLinkRouter()
    @State private var periodicSyncTimer: AnyCancellable?
    @State private var wasInBackground = false

    init() {
        #if DEBUG
        print("🟢 MainApp init")
        Self.checkPhantomBurstWorkaroundRelevance()
        #endif
        // Eagerly initialize ShieldManager so its Darwin notification observer
        // is registered before any extension threshold can fire.
        _ = ShieldManager.shared
    }

    #if DEBUG
    /// PHANTOM_BURST_WORKAROUND — reminds us at each run whether Apple may have
    /// shipped the iOS 26.2 DeviceActivity fix yet. If we're on a version at or
    /// past our assumed-fixed marker, grep `PHANTOM_BURST_WORKAROUND` and verify
    /// the workaround still serves a purpose before the next release.
    private static func checkPhantomBurstWorkaroundRelevance() {
        let target = AppConstants.phantomBurstAssumedFixedVersion
        guard ProcessInfo.processInfo.isOperatingSystemAtLeast(target) else { return }
        let current = ProcessInfo.processInfo.operatingSystemVersionString
        print("⚠️ PHANTOM_BURST_WORKAROUND: running on \(current) ≥ \(target.majorVersion).\(target.minorVersion) — re-test iOS DeviceActivity bug (FB21450954) and consider removing workaround.")
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withDeepLinkHandling()
                .environment(petManager)
                .environment(archivedPetManager)
                .environment(essenceCatalogManager)
                .environment(authManager)
                .environment(storeManager)
                .environment(syncManager)
                .environment(analyticsManager)
                .environment(deepLinkRouter)
                .onAppear {
                    ShieldManager.shared.analyticsManager = analyticsManager
                    petManager.syncManager = syncManager
                    #if DEBUG
                    print("🟢 ContentView appeared, authState=\(authManager.authState), hasPet=\(petManager.hasPet)")
                    #endif
                }
                .task {
                    await storeManager.checkCurrentEntitlements()
                    await analyticsManager.start(userId: authManager.currentUser?.id)
                    await analyticsManager.updateUser(
                        userId: authManager.currentUser?.id,
                        premiumPlan: storeManager.activeProductId
                    )
                    analyticsManager.send(.appOpened)
                }
                .onChange(of: authManager.authState) { oldState, newState in
                    #if DEBUG
                    print("🟢 onChange: \(oldState) → \(newState), hasPet=\(petManager.hasPet)")
                    #endif
                    handleAuthStateChange(from: oldState, to: newState)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleAuthStateChange(from oldState: AuthManager.AuthState, to newState: AuthManager.AuthState) {
        switch newState {
        case .authenticated:
            #if DEBUG
            print("[Sync] Auth → authenticated — oldState=\(oldState), userId=\(authManager.currentUser?.id.uuidString ?? "nil"), hasPet=\(petManager.hasPet), onboarding=\(hasCompletedOnboarding)")
            #endif
            Task {
                await analyticsManager.updateUser(
                    userId: authManager.currentUser?.id,
                    premiumPlan: storeManager.activeProductId
                )
            }
            if petManager.hasPet {
                // Local pet exists — restore user data from cloud (coins, hourly history, etc.)
                // then check for pet conflict and upload local settings if no conflict
                Task {
                    #if DEBUG
                    let coinsBefore = CoinStore.shared.balance
                    print("[Sync] hasPet path — restoring user data from cloud (coins before: \(coinsBefore))")
                    #endif

                    await syncManager.restoreUserData(essenceCatalogManager: essenceCatalogManager)

                    #if DEBUG
                    print("[Sync] User data restored (coins after: \(CoinStore.shared.balance))")
                    #endif

                    await syncManager.checkForPetConflict(
                        petManager: petManager,
                        archivedPetManager: archivedPetManager
                    )
                    if syncManager.pendingConflict == nil {
                        await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager)
                    }

                    // Claim any pending rewards (admin-granted coins)
                    let claimed = await syncManager.claimPendingRewards()
                    #if DEBUG
                    if claimed > 0 {
                        print("[Sync] Claimed \(claimed) pending reward coins on login")
                    }
                    #endif
                }
            } else {
                // No local pet — check if this is a reinstall with an existing cloud pet
                if !hasCompletedOnboarding {
                    // Reinstall scenario: Keychain token survived but onboarding was wiped.
                    // Show WelcomeBackSheet if a cloud pet exists, otherwise treat as new user.
                    #if DEBUG
                    print("[Sync] No pet + no onboarding — checking WelcomeBack (reinstall scenario)")
                    #endif
                    Task {
                        await syncManager.checkForWelcomeBack(
                            petManager: petManager,
                            archivedPetManager: archivedPetManager,
                            essenceCatalogManager: essenceCatalogManager
                        )
                    }
                } else {
                    // Onboarding already completed but no local pet — restore from cloud
                    // (e.g. onboarding flag survived reinstall, or local pet file was lost)
                    #if DEBUG
                    print("[Sync] No pet + onboarding done — restoring from cloud")
                    #endif
                    Task {
                        await syncManager.restoreUserData(essenceCatalogManager: essenceCatalogManager)
                        await syncManager.restoreFromCloud(
                            petManager: petManager,
                            archivedPetManager: archivedPetManager
                        )
                    }
                }
            }

        case .anonymous:
            // Signed out — clear local data (cloud backup preserved for future restore)
            #if DEBUG
            print("[Sync] Auth → anonymous — oldState=\(oldState)")
            #endif
            guard case .authenticated = oldState else { return }
            #if DEBUG
            print("[Sync] Was authenticated → clearing local data")
            #endif
            petManager.clearOnSignOut()
            archivedPetManager.clearOnSignOut()
            essenceCatalogManager.clearOnSignOut()
            syncManager.clearOnSignOut()
            ScheduledNotificationManager.cancelAll()

        case .loading:
            break
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if wasInBackground {
                analyticsManager.send(.appOpened)
                wasInBackground = false
            }

            // Refresh shield state (may have been activated by extension at 100%)
            ShieldState.shared.refresh()

            // Resume break monitoring (timer is lost when app is suspended/terminated)
            ShieldManager.shared.resumeBreakMonitoringIfNeeded()

            // Re-register monitoring thresholds to recover from external disruptions
            // (e.g., another Family Controls app being uninstalled, iOS clearing schedules)
            petManager.ensureMonitoringActive()

            // Check for blow-away state when returning to foreground
            // (windPoints is computed from SharedDefaults - no sync needed)
            petManager.performDailyResetIfNeeded()
            petManager.checkBlowAwayState()
            petManager.refreshDailyStats()

            // Refresh scheduled notifications (daily summary + evolution ready)
            ScheduledNotificationManager.refresh(
                isEvolutionAvailable: petManager.currentPet?.isEvolutionAvailable ?? false,
                hasPet: petManager.hasPet,
                nextEvolutionUnlockDate: petManager.currentPet?.evolutionHistory.nextEvolutionUnlockDate
            )

            // Sync active pet + settings to cloud (debounced)
            Task {
                await syncManager.syncActivePetIfNeeded(petManager: petManager)
                await syncManager.syncUserDataIfNeeded(essenceCatalogManager: essenceCatalogManager)

                // Claim admin-granted rewards (coins) and sync updated balance
                let claimed = await syncManager.claimPendingRewards()
                if claimed > 0 {
                    await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager)
                }
            }

            // Start periodic sync timer (every 5 min while foregrounded)
            if periodicSyncTimer == nil {
                periodicSyncTimer = Timer.publish(every: 300, on: .main, in: .common)
                    .autoconnect()
                    .sink { [syncManager, petManager, essenceCatalogManager] _ in
                        Task { @MainActor in
                            await syncManager.syncActivePetIfNeeded(petManager: petManager)
                            await syncManager.syncUserDataIfNeeded(essenceCatalogManager: essenceCatalogManager)

                            let claimed = await syncManager.claimPendingRewards()
                            if claimed > 0 {
                                await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager)
                            }
                        }
                    }
            }

            #if DEBUG
            print("🟢 App became active")
            #endif

        case .background:
            wasInBackground = true

            // Stop periodic sync timer
            periodicSyncTimer?.cancel()
            periodicSyncTimer = nil
            // Save current state when going to background
            petManager.savePet()

            // Sync to cloud before app is suspended
            // Skip if initial sync hasn't completed or conflict is pending
            if syncManager.pendingConflict == nil,
               UserDefaults.standard.bool(forKey: "hasCompletedInitialSync") {
                syncManager.syncInBackground { [petManager, archivedPetManager, essenceCatalogManager, syncManager] in
                    await syncManager.syncActivePet(petManager: petManager)
                    await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager)
                    await syncManager.initialSyncIfNeeded(archivedPetManager: archivedPetManager)
                }
            }

            #if DEBUG
            print("🟡 App went to background - saved pet state")
            #endif

        case .inactive:
            break

        @unknown default:
            break
        }
    }
}
