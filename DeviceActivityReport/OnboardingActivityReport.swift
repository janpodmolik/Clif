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

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        if let token = appActivity.application.token {
                            appDurations[token, default: 0] += appActivity.totalActivityDuration
                        }
                    }
                }
            }
        }

        let topApps = appDurations
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { token, duration in
                AppActivityData(
                    token: token,
                    duration: duration,
                    formattedDuration: formatter.string(from: duration) ?? "0m"
                )
            }

        return OnboardingReportData(
            formattedTotal: formatter.string(from: totalDuration) ?? "0m",
            apps: topApps
        )
    }
}
