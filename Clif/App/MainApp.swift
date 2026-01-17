import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

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
//                .withDebugOverlay()
        }
    }
}
