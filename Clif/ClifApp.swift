//
//  ClifApp.swift
//  Clif
//
//  Created by Jan Podmolík on 07.12.2025.
//

import SwiftUI
import UserNotifications

// MARK: - AppDelegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when notification is tapped (app in background or closed)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        #if DEBUG
        print("[AppDelegate] Notification tapped with userInfo: \(userInfo)")
        #endif

        if let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            #if DEBUG
            print("[AppDelegate] Opening deep link: \(url)")
            #endif
            UIApplication.shared.open(url)
        }

        completionHandler()
    }

    // Called when notification arrives while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        #if DEBUG
        print("[AppDelegate] Notification received in foreground with userInfo: \(userInfo)")
        #endif

        // If app is in foreground and we get notification from shield, handle it directly
        if let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            #if DEBUG
            print("[AppDelegate] Handling deep link directly: \(url)")
            #endif
            // Post notification so ClifApp can handle it
            NotificationCenter.default.post(name: .deepLinkReceived, object: url)
            completionHandler([]) // Don't show the notification banner
        } else {
            completionHandler([.banner, .sound])
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}

// MARK: - Main App

@main
struct ClifApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Task {
            await Self.requestNotificationPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                DebugView()
                #else
                ContentView()
                #endif
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
                if let url = notification.object as? URL {
                    handleDeepLink(url)
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        #if DEBUG
        print("[ClifApp] Received deep link: \(url)")
        #endif

        // Handle clif:// URL scheme
        guard url.scheme == "clif" else { return }

        // clif://shield - opened from shield notification
        if url.host == "shield" {
            #if DEBUG
            print("[ClifApp] Opened from shield notification")
            #endif
            // TODO: Navigate to session tracking view when implemented
        }
    }

    private static func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            #if DEBUG
            print("[ClifApp] Notification permission \(granted ? "granted" : "denied")")
            #endif
        } catch {
            #if DEBUG
            print("[ClifApp] Notification permission error: \(error.localizedDescription)")
            #endif
        }
    }
}
