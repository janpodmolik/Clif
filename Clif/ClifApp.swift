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
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
