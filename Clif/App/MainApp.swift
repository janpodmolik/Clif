import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        print("🟢 MainApp init")
        Task {
            await AppDelegate.requestNotificationPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { print("🟢 ContentView appeared") }
                .withDeepLinkHandling()
//                .withDebugOverlay()
        }
    }
}
