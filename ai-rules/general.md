# General Swift/iOS Rules

<primary-directive>
Write production-quality Swift code. Prefer clarity over cleverness.
ALWAYS clarify ambiguities BEFORE coding. NEVER assume requirements.
</primary-directive>

## Rules (Priority Order)

1. **No force unwraps** - Use guard, if-let, or nil coalescing
2. **No God objects** - Single responsibility per type
3. **No stringly-typed APIs** - Use enums, constants
4. **Minimal imports** - Only import what you need
5. **Error handling** - Use Result or throws, never ignore errors

## Naming Conventions

- Types: PascalCase (`ScreenTimeManager`)
- Properties/methods: camelCase (`activitySelection`)
- Constants: camelCase in enum (`DefaultsKeys.dailyLimit`)
- UI strings: Czech language (user-facing)
- Code identifiers: English

## File Structure

```swift
import SwiftUI
import FamilyControls

// MARK: - Main Type
struct ExampleView: View { ... }

// MARK: - Subviews
private struct HeaderView: View { ... }

// MARK: - Preview
#Preview { ExampleView() }
```

## Anti-Patterns

- `try!` or `as!`
- Empty catch blocks
- Deeply nested if/guard statements
- Magic numbers without constants
- Xcode file headers (remove them)

## Pre-commit Checklist

- [ ] No force unwraps (`!`) in new code
- [ ] No `try!` or `as!`
- [ ] Constants extracted for magic numbers
