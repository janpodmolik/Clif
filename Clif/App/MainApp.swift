import SwiftUI
import UserNotifications

@main
struct MainApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        Task {
            await AppDelegate.requestNotificationPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withDeepLinkHandling()
//                .withDebugOverlay()
        }
    }
}
