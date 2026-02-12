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

    init() {
        print("🟢 MainApp init")
        // Eagerly initialize ShieldManager so its Darwin notification observer
        // is registered before any extension threshold can fire.
        _ = ShieldManager.shared
        Task {
            await AppDelegate.requestNotificationPermission()
        }
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
                .onAppear {
                    petManager.syncManager = syncManager
                    print("🟢 ContentView appeared")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
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

            // Sync active pet to cloud (debounced)
            Task {
                await syncManager.syncActivePetIfNeeded(petManager: petManager)
            }

            #if DEBUG
            print("🟢 App became active")
            #endif

        case .background:
            // Save current state when going to background
            petManager.savePet()

            // Sync to cloud before app is suspended
            syncManager.syncInBackground { [petManager, archivedPetManager, syncManager] in
                await syncManager.syncActivePet(petManager: petManager)
                await syncManager.initialSyncIfNeeded(archivedPetManager: archivedPetManager)
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
