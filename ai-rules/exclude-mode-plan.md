# Exclude Mode — Future Implementation Plan

> "Block all apps except selected" as an alternative to "Block selected apps"

## Context

Currently users pick specific apps/categories to block. Exclude mode inverts this — block everything by default, user picks what's **allowed** (whitelisted).

## Key Technical Findings

- **Shielding:** `ManagedSettingsStore` natively supports `.all(except: tokens)` — trivial to flip
- **Monitoring:** `DeviceActivityEvent` with empty token sets has `includesAllActivity == true` — monitors total device usage
- **Limitation:** No "monitor all except X" for thresholds — wind rises from ALL usage including whitelisted apps. This is a product decision: either total screen time drives wind (simpler), or we'd need creative workarounds to exclude whitelisted apps from wind calculation

## Implementation Steps

### 1. Model Layer

- Add `SelectionMode` enum to `Pet`:
  ```swift
  enum SelectionMode: String, Codable {
      case block    // current behavior — selected apps are blocked
      case exclude  // inverted — selected apps are allowed, rest blocked
  }
  ```
- Add `var selectionMode: SelectionMode = .block` to `Pet`
- Migrate existing pets to `.block` (default, no migration needed)

### 2. Creation Flow (`AppSelectionStep`)

- Add a segmented control / toggle before `FamilyActivityPicker`:
  - "Block selected" (default, current behavior)
  - "Allow selected" (exclude mode)
- Change picker header text based on mode:
  - Block: "Choose apps to limit"
  - Exclude: "Choose apps to keep available"
- Pass `selectionMode` through `CreatePetCoordinator` to pet creation

### 3. Shield Activation (`ShieldManager`)

- Branch on `selectionMode`:
  ```swift
  switch mode {
  case .block:
      store.shield.applicationCategories = .specific(categories, except: Set())
  case .exclude:
      store.shield.applicationCategories = .all(except: categories)
  }
  ```
- Same pattern for `applications` and `webDomains`
- Update `ShieldManager.activate()` signature to accept mode
- Update all callers (extension included via SharedDefaults)

### 4. Monitoring (`ScreenTimeManager`)

- In `.exclude` mode, register events with **empty** token sets → `includesAllActivity == true`
- Wind rises from total device usage (not just blocked apps)
- Store `selectionMode` in SharedDefaults for extension access

### 5. DeviceActivityMonitor Extension

- Read `selectionMode` from SharedDefaults
- In `.exclude` mode, activate shields with `.all(except:)` pattern
- Threshold handling stays the same (seconds-based wind calculation)

### 6. Edit Flow (`EditLimitedSourcesSheet`, `LimitedAppsSheet`)

- Display mode indicator (what the list represents — blocked vs. allowed)
- Allow mode change as part of the 3-change limit (or decide: does mode switch count as a change?)

### 7. SharedDefaults

- Add `selectionMode` key for cross-process communication
- Extension reads mode to determine shield activation pattern

## Open Product Decisions

1. **Does wind rise from whitelisted app usage?** (Technically yes with current API — is that acceptable?)
2. **Does switching modes count as one of the 3 limited source changes?**
3. **Can the user switch modes after creation, or is it locked at pet creation?**
4. **UI copy** — "Block selected" vs "Allow selected" vs other wording?

## Estimated Effort

~2-3 days for full implementation + testing across both modes.
