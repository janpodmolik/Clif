# Screen Time API Rules

<primary-directive>
Screen Time APIs require careful handling of FamilyActivitySelection tokens
and cross-process communication via App Groups.
</primary-directive>

## Key Components

| Component | Purpose |
|-----------|---------|
| FamilyActivitySelection | User's selected apps/categories |
| DeviceActivityCenter | Start/stop monitoring schedules |
| ManagedSettingsStore | Apply/remove shields |
| DeviceActivityEvent | Threshold triggers (50%, 90%, 100%) |

## Authorization Flow

```swift
// Request authorization ONCE at app launch
AuthorizationCenter.shared.requestAuthorization(for: .individual)

// Check status
let status = AuthorizationCenter.shared.authorizationStatus
```

## Saving Selection (App Group)

```swift
// Encode full selection for main app
let encoded = try JSONEncoder().encode(selection)
SharedDefaults.familyActivitySelectionData = encoded

// Extract tokens for extensions (lighter weight)
SharedDefaults.applicationTokens = selection.applicationTokens
SharedDefaults.categoryTokens = selection.categoryTokens
```

## Monitoring Pattern

```swift
// Set up schedule with events
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59),
    repeats: true
)

let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
    .fiftyPercent: DeviceActivityEvent(threshold: .init(minute: 30)),
    .hundredPercent: DeviceActivityEvent(threshold: .init(minute: 60))
]

try center.startMonitoring(.daily, during: schedule, events: events)
```

## Anti-Patterns

- Don't store FamilyActivitySelection directly in UserDefaults (tokens are device-specific)
- Don't call startMonitoring rapidly - debounce changes (300ms)
- Don't forget to handle authorization denial gracefully
