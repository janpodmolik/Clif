//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Created by Jan Podmolík on 07.12.2025.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ClifDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
