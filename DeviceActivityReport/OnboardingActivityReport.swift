import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct OnboardingReportData {
    let formattedTotal: String
    let apps: [AppActivityData]
}

struct OnboardingActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .onboardingOverview
    let content: (OnboardingReportData) -> OnboardingActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> OnboardingReportData {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll

        var totalDuration: TimeInterval = 0
        var appDurations: [ApplicationToken: TimeInterval] = [:]
        var appNames: [ApplicationToken: String] = [:]
        var daysWithActivity = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration
                if segment.totalActivityDuration > 0 {
                    daysWithActivity += 1
                }

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        if let token = appActivity.application.token {
                            appDurations[token, default: 0] += appActivity.totalActivityDuration
                            if let name = appActivity.application.localizedDisplayName {
                                appNames[token] = name
                            }
                        }
                    }
                }
            }
        }

        let divisor = TimeInterval(max(daysWithActivity, 1))
        let averageTotal = totalDuration / divisor

        let topApps = appDurations
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { token, duration in
                let averageDuration = duration / divisor
                return AppActivityData(
                    token: token,
                    name: appNames[token],
                    duration: averageDuration,
                    formattedDuration: formatter.string(from: averageDuration) ?? "0m"
                )
            }

        return OnboardingReportData(
            formattedTotal: formatter.string(from: averageTotal) ?? "0m",
            apps: topApps
        )
    }
}
