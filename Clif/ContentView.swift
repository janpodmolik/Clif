//
//  ContentView.swift
//  Clif
//
//  Created by Jan Podmolík on 07.12.2025.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var isPickerPresented = false
    
    @AppStorage(DefaultsKeys.currentProgress, store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var currentProgress = 0
    
    @AppStorage(DefaultsKeys.dailyLimitMinutes, store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var dailyLimitMinutes = AppConstants.defaultDailyLimitMinutes
    
    @State private var dailyLimit: Double = Double(AppConstants.defaultDailyLimitMinutes)
    
    #if DEBUG
    @State private var extensionLog = ""
    #endif
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !manager.isAuthorized {
                        authorizationSection
                    } else {
                        limitSliderSection
                        appSelectionSection
                        progressSection
                        
                        #if DEBUG
                        debugSection
                        #endif
                    }
                }
                .padding()
            }
            .navigationTitle("Clif")
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $manager.activitySelection
            )
            .onChange(of: manager.activitySelection) { _, _ in
                manager.saveSelection()
            }
        }
    }
    
    // MARK: - View Components
    
    private var authorizationSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Screen Time Access Required")
                .font(.headline)
            
            Text("Clif needs access to Screen Time to monitor your app usage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Authorize Screen Time") {
                Task {
                    await manager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var limitSliderSection: some View {
        VStack {
            Text("Daily Limit: \(Int(dailyLimit)) min")
                .font(.headline)
            
            Slider(value: $dailyLimit, in: 1...120, step: 1) {
                Text("Limit")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    dailyLimitMinutes = Int(dailyLimit)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            dailyLimit = Double(dailyLimitMinutes)
        }
    }
    
    private var appSelectionSection: some View {
        VStack(spacing: 12) {
            Button("Select Apps to Limit") {
                isPickerPresented = true
            }
            .buttonStyle(.bordered)
            
            let appCount = manager.activitySelection.applicationTokens.count
            let catCount = manager.activitySelection.categoryTokens.count
            
            if appCount > 0 || catCount > 0 {
                Text("Monitoring \(appCount) apps, \(catCount) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            Text("Today's Usage")
                .font(.headline)
            
            Text("\(currentProgress)%")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)
            
            // Time spent indicator
            Text(timeSpentText)
                .font(.title3)
                .foregroundColor(.orange)
            
            // Progress bar
            ProgressView(value: Double(min(currentProgress, 100)), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal)
            
            if let lastUpdate = SharedDefaults.lastMonitorUpdate {
                Text("Updated: \(lastUpdate.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var progressColor: Color {
        if currentProgress >= 100 { return .red }
        if currentProgress >= 80 { return .orange }
        return .blue
    }
    
    private var timeSpentText: String {
        let totalSeconds = (dailyLimitMinutes * 60 * currentProgress) / 100
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "⏱️ ~\(minutes)m \(seconds)s / \(dailyLimitMinutes)m"
    }
}

#if DEBUG
extension ContentView {
    private var debugSection: some View {
        VStack(spacing: 8) {
            Divider()
            
            Text("Debug Tools")
                .font(.caption)
                .foregroundColor(.orange)
            
            HStack(spacing: 8) {
                Button("Restart Monitor") {
                    manager.startMonitoring()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("Clear Shield") {
                    manager.clearShield()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("Apply Shield") {
                    manager.updateShield()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            
            Button("Show Extension Log") {
                showExtensionLog()
            }
            .buttonStyle(.bordered)
            .font(.caption)
            
            if !extensionLog.isEmpty {
                ScrollView {
                    Text(extensionLog)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
                .background(Color.black)
                .cornerRadius(8)
            }
            
            Text("Apps: \(manager.activitySelection.applicationTokens.count) | Categories: \(manager.activitySelection.categoryTokens.count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private func showExtensionLog() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            extensionLog = "❌ Cannot access App Group container"
            return
        }
        
        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")
        
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            extensionLog = (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "❌ Error reading log"
        } else {
            extensionLog = "📭 No log file yet"
        }
    }
}
#endif

#Preview {
    ContentView()
}
