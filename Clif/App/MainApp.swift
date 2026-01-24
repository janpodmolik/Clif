import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @State private var petManager = PetManager()
    @State private var archivedPetManager = ArchivedPetManager()

    init() {
        print("🟢 MainApp init")
        Task {
            await AppDelegate.requestNotificationPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(petManager)
                .environment(archivedPetManager)
                .onAppear { print("🟢 ContentView appeared") }
                .withDeepLinkHandling()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Check for blow-away state when returning to foreground
            // (windPoints is computed from SharedDefaults - no sync needed)
            petManager.performDailyResetIfNeeded()
            petManager.checkBlowAwayState()

            #if DEBUG
            print("🟢 App became active")
            #endif

        case .background:
            // Save current state when going to background
            petManager.savePet()

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
