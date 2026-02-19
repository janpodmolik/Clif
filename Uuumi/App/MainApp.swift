import Auth
import Combine
import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

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

    init() {
        #if DEBUG
        print("🟢 MainApp init")
        #endif
        // Eagerly initialize ShieldManager so its Darwin notification observer
        // is registered before any extension threshold can fire.
        _ = ShieldManager.shared
        analyticsManager.initialize()
    }

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
                    petManager.syncManager = syncManager
                    #if DEBUG
                    print("🟢 ContentView appeared, authState=\(authManager.authState), hasPet=\(petManager.hasPet)")
                    #endif
                }
                .task {
                    await storeManager.checkCurrentEntitlements()
                    analyticsManager.configure(
                        userId: authManager.currentUser?.id,
                        premiumPlan: storeManager.activeProductId
                    )
                    analyticsManager.sendConfigSnapshot()
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
            analyticsManager.configure(
                userId: authManager.currentUser?.id,
                premiumPlan: storeManager.activeProductId
            )
            if petManager.hasPet {
                // Local pet exists — check if cloud also has one (potential conflict)
                // Only upload local settings if no conflict (conflict resolution handles sync)
                Task {
                    await syncManager.checkForPetConflict(
                        petManager: petManager,
                        archivedPetManager: archivedPetManager
                    )
                    if syncManager.pendingConflict == nil {
                        await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager)
                    }
                }
            } else {
                // No local pet — restore settings first, then pet (reinstall recovery)
                Task {
                    await syncManager.restoreUserData(essenceCatalogManager: essenceCatalogManager)
                    await syncManager.restoreFromCloud(
                        petManager: petManager,
                        archivedPetManager: archivedPetManager
                    )
                }
            }

        case .anonymous:
            // Signed out — clear local data (cloud backup preserved for future restore)
            guard case .authenticated = oldState else { return }
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
