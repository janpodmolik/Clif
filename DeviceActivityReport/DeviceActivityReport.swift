import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct UuumiDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        OnboardingActivityReport { data in
            OnboardingActivityView(data: data)
        }
    }
}
