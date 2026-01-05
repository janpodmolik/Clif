# App Extensions Rules

<primary-directive>
Extensions run in separate processes with limited resources.
All cross-process communication MUST go through App Groups.
</primary-directive>

## Extension Types in Clif

| Extension | Purpose | Trigger |
|-----------|---------|---------|
| DeviceActivityMonitor | React to thresholds | System calls |
| DeviceActivityReport | Show usage data | SwiftUI context |
| ShieldConfiguration | Customize shield UI | Shield display |
| ShieldAction | Handle shield buttons | User tap |

## App Group Communication

```swift
// Shared container
let defaults = UserDefaults(suiteName: Constants.appGroupId)!

// Read in extension
let tokens = SharedDefaults.applicationTokens
let progress = SharedDefaults.currentProgress
```

## Performance Rules

1. **Minimize work** - Extensions have strict memory/time limits
2. **No network calls** - Use cached data only
3. **Light dependencies** - Don't import heavy frameworks
4. **Precompute in main app** - Store computed values for extensions

## DeviceActivityMonitor Pattern

```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        // Called when monitoring interval begins
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // Called when threshold reached - apply shield here
        let store = ManagedSettingsStore()
        store.shield.applications = SharedDefaults.applicationTokens
    }
}
```

## ShieldConfiguration Pattern

```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding app: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            title: ShieldConfiguration.Label(text: "Time's up!", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close App")
        )
    }
}
```
