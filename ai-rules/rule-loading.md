# Rule Loading Guide

## Trigger Keywords → Rule Files

| Keywords | Load |
|----------|------|
| view, screen, UI, layout, animation | swiftui-views.md |
| glass, iOS 26, material, blur | liquid-glass.md |
| screen time, family controls, shield, monitor, limit | screen-time-api.md |
| extension, widget, app group, shared defaults | extensions.md |
| swift, error, optional, naming, style | general.md |

## Quick Reference Scenarios

- "Add a new screen" → swiftui-views.md + liquid-glass.md
- "Implement shield" → screen-time-api.md + extensions.md
- "Fix a bug" → general.md
- "Add glass button" → liquid-glass.md + swiftui-views.md

## Loading Strategy

1. NEVER load all rules at once - wastes context
2. Load 1-2 most relevant rules based on task
3. If unsure, start with general.md
4. Load additional rules only when needed
