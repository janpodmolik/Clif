//
//  ContentView.swift
//  Clif
//
//  Created by Jan Podmolík on 07.12.2025.
//

import SwiftUI
import FamilyControls
import DeviceActivity

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
                        screenTimeReportSection
                        limitSliderSection
                        appSelectionSection
                        progressSection
                        
                        // Supabase test button
                        NavigationLink(destination: SupabaseTestView()) {
                            HStack {
                                Image(systemName: "server.rack")
                                Text("Supabase Test")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
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
            Text("Daily Limit: \(formattedLimit)")
                .font(.headline)
            
            Slider(value: $dailyLimit, in: 5...600, step: 5) {
                Text("Limit")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    dailyLimitMinutes = Int(dailyLimit)
                    refreshReport()
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
    
    private var formattedLimit: String {
        let mins = Int(dailyLimit)
        if mins >= 60 {
            let hours = mins / 60
            let remainder = mins % 60
            return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
        }
        return "\(mins)m"
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
    
    @State private var reportFilter: DeviceActivityFilter?
    @State private var reportId = UUID()
    
    private var screenTimeReportSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Today's Screen Time", systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    // Refresh report
                    reportFilter = nil
                    reportId = UUID()
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await MainActor.run {
                            reportFilter = createFilter()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            if let filter = reportFilter {
                DeviceActivityReport(.totalActivity, filter: filter)
                    .id(reportId)
                    .frame(minHeight: 180)
            } else {
                // Placeholder while loading
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Načítám data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 180)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .task {
            await MainActor.run {
                reportFilter = createFilter()
            }
        }
    }
    
    private func createFilter() -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .hourly(
                during: Calendar.current.dateInterval(of: .day, for: .now)!
            ),
            users: .all,
            devices: .init([.iPhone]),
            applications: manager.activitySelection.applicationTokens,
            categories: manager.activitySelection.categoryTokens
        )
    }
    
    private func refreshReport() {
        reportFilter = nil
        reportId = UUID()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                reportFilter = createFilter()
            }
        }
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
