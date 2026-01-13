import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @State private var petManager = PetManager()

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
                .onAppear { print("🟢 ContentView appeared") }
                .withDeepLinkHandling()
//                .withDebugOverlay()
        }
    }
}
