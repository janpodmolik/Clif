//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Created by Jan Podmolík on 07.12.2025.
//

import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

// Data model for the report
struct ActivityReportData {
    let totalDuration: TimeInterval
    let formattedTotal: String
    let dailyLimit: TimeInterval
    let progress: Double // 0.0 - 1.0+
    let apps: [AppActivityData]
}

struct AppActivityData: Identifiable {
    let id = UUID()
    let token: ApplicationToken?
    let duration: TimeInterval
    let formattedDuration: String
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReportData) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportData {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        
        // Read limit from SharedDefaults (App Group) - this is secondsToBlowAway
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let dailyLimit = TimeInterval(limitSeconds)
        
        var totalDuration: TimeInterval = 0
        var appDurations: [ApplicationToken: TimeInterval] = [:]
        
        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration
                
                // Collect per-app data
                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        if let token = appActivity.application.token {
                            let duration = appActivity.totalActivityDuration
                            appDurations[token, default: 0] += duration
                        }
                    }
                }
            }
        }
        
        // Sort apps by duration (descending) - no limit, show all
        let sortedApps = appDurations
            .sorted { $0.value > $1.value }
            .map { token, duration in
                AppActivityData(
                    token: token,
                    duration: duration,
                    formattedDuration: formatter.string(from: duration) ?? "0m"
                )
            }
        
        let progress = dailyLimit > 0 ? totalDuration / dailyLimit : 0
        
        return ActivityReportData(
            totalDuration: totalDuration,
            formattedTotal: formatter.string(from: totalDuration) ?? "0m",
            dailyLimit: dailyLimit,
            progress: progress,
            apps: sortedApps
        )
    }
}
