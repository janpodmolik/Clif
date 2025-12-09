//
//  ClifApp.swift
//  Clif
//
//  Created by Jan Podmolík on 07.12.2025.
//

import SwiftUI
import UserNotifications

@main
struct ClifApp: App {

    init() {
        Task {
            await Self.requestNotificationPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            DebugView()
            #else
            ContentView()
            #endif
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
