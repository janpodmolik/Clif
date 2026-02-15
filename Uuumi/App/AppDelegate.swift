import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        #if DEBUG
        print("[AppDelegate] Notification tapped: \(userInfo)")
        #endif

        if let deepLink = userInfo["deepLink"] as? String, var url = URL(string: deepLink) {
            // For daily summary, append the notification's delivery date so we show
            // the correct day even if the user taps the notification the next morning.
            if url.host == DeepLinkHost.dailySummary.rawValue,
               var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                let timestamp = response.notification.date.timeIntervalSince1970
                components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "date", value: "\(timestamp)")]
                url = components.url ?? url
            }
            UIApplication.shared.open(url)
        }

        center.removeAllDeliveredNotifications()
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        #if DEBUG
        print("[AppDelegate] Notification in foreground: \(userInfo)")
        #endif

        let identifier = notification.request.identifier
        let alwaysShowInForeground = identifier == EvolutionReadyNotification.identifier

        if alwaysShowInForeground {
            completionHandler([.banner, .sound])
        } else if let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            NotificationCenter.default.post(name: .deepLinkReceived, object: url)
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }

    static func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            #if DEBUG
            print("[AppDelegate] Notification permission \(granted ? "granted" : "denied")")
            #endif
        } catch {
            #if DEBUG
            print("[AppDelegate] Permission error: \(error.localizedDescription)")
            #endif
        }
    }
}
