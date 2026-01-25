# Wind System Architecture

Screen time limit tracking via wind level (0-100 points). Pet blows away at 100%.

## Architecture Overview

```
MAIN APP                              EXTENSIONS (separate processes, ~6MB limit)
┌─────────────────────────────┐       ┌─────────────────────────────────────────┐
│ ScreenTimeManager           │       │ DeviceActivityMonitorExtension          │
│ - startMonitoring()         │       │ - eventDidReachThreshold() → wind calc  │
│ - applyMorningPreset()      │       │ - intervalDidStart() → daily reset      │
│ - toggleShield()            │       │ - activateShield() → blocks apps        │
│ - processUnlock()           │       ├─────────────────────────────────────────┤
├─────────────────────────────┤       │ ShieldConfigurationExtension            │
│ SharedDefaults (App Group)  │◄─────►│ - Shield UI appearance (shows wind %)   │
│ - monitoredWindPoints       │       ├─────────────────────────────────────────┤
│ - monitoredRiseRate/FallRate│       │ ShieldActionExtension                   │
│ - isShieldActive            │       │ - Button taps on shield                 │
│ - breakStartedAt            │       │ - Break violation detection             │
└─────────────────────────────┘       └─────────────────────────────────────────┘
```

## Core Files

| File | Location | Purpose |
|------|----------|---------|
| DeviceActivityMonitorExtension | `DeviceActivityMonitor/` | Receives system callbacks on app usage, calculates wind delta, activates shields |
| ScreenTimeManager | `Clif/Managers/` | Main app singleton - authorization, monitoring, unlock processing |
| SharedDefaults | `Shared/Storage/` | App Group UserDefaults wrapper for cross-process state |
| WindPreset | `Clif/Models/` | Difficulty presets: gentle/balanced/intense with rise/fall rates |
| WindLevel | `Shared/Models/Evolution/` | Wind zones (none/low/medium/high) + LimitSettings config |
| Constants | `Shared/Constants/` | DefaultsKeys, maxThresholds=20, minimumThresholdSeconds=6 |

## Shield & Break Files

| File | Location | Purpose |
|------|----------|---------|
| ShieldConfigurationExtension | `ShieldConfiguration/` | Shield UI - morning mode vs usage mode with wind % display |
| ShieldActionExtension | `ShieldAction/` | Handles shield button taps, break violations, blow away at 100% |
| ActiveBreak + BreakType | `Clif/Models/` | Break model with free (1.0x) vs committed (1.5x) fall rate multiplier |
| BlowAwayNotification | `Shared/Notifications/` | Shared helper for blow away notification |

## Logging Files

| File | Location | Purpose |
|------|----------|---------|
| SnapshotStore | `Shared/Storage/` | JSONL append-only log for events (usageThreshold, breakStarted/Ended, blowAway) |
| SnapshotEventType | `Shared/Models/Snapshot/` | Event type definitions |
| ExtensionLogger | `Shared/Storage/` | File-based logger for extensions (can't use print) |

## Wind Calculation

**Presets:**
| Preset | minutesToBlowAway | riseRate (pts/min) | fallRate (pts/min) |
|--------|-------------------|--------------------|--------------------|
| gentle | 15 | 6.67 | 3.33 |
| balanced | 8 | 12.5 | 5 |
| intense | 5 | 20 | 6.67 |

**Threshold events:** DeviceActivity API allows max 20 thresholds. For 8-min limit → threshold every 24s.

**Wind update in extension:**
```swift
let deltaSeconds = currentThreshold - previousThreshold
let windIncrease = Double(deltaSeconds) * (riseRate / 60.0)
newWindPoints = min(oldWindPoints + windIncrease, 100)
```

**WindLevel zones:**
- none: 0-4 pts
- low: 5-49 pts
- medium: 50-79 pts
- high: 80-100 pts

## Lifecycle

1. **Day start (midnight):** Reset wind to 0, activate Morning Shield
2. **Preset selection:** User picks difficulty → stores rates in SharedDefaults → starts monitoring
3. **App usage:** Thresholds fire → extension calculates wind increase → checks notifications/shield activation
4. **Shield activation:** When wind crosses `shieldActivationLevel` → blocks apps via ManagedSettingsStore
5. **Unlock:** Deep link from ShieldAction → ScreenTimeManager.processUnlock() → applies wind decrease
6. **Blow away:** At 100% wind when unlocking OR committed break violation

## Break System

| Type | fallRateMultiplier | Violation penalty |
|------|-------------------|-------------------|
| free | 1.0x | None |
| committed | 1.5x | Pet blows away |

Wind decrease: `elapsedMinutes * preset.fallRate * type.fallRateMultiplier`

## Cross-Process Communication

All state shared via `SharedDefaults` (App Group UserDefaults). Extensions have fresh UserDefaults instance on each read for sync.

Key flags: `isShieldActive`, `isMorningShieldActive`, `shieldActivatedAt`, `breakStartedAt`, `petBlownAway`
