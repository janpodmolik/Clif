# SwiftUI Views Rules

<primary-directive>
This project uses MV (Model-View) architecture, NOT MVVM.
Views observe models directly. No ViewModel layer.
</primary-directive>

## MV Architecture

```swift
// CORRECT - View observes model directly
struct HomeScreen: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared

    var body: some View {
        Text(screenTimeManager.isAuthorized ? "Ready" : "Setup needed")
    }
}

// WRONG - Don't create ViewModels
class HomeViewModel: ObservableObject { ... } // NO!
```

## State Management

| Wrapper | Use For |
|---------|---------|
| @StateObject | Own the model instance |
| @ObservedObject | Receive model from parent |
| @State | Local view state only |
| @AppStorage | UserDefaults binding |
| @Published | Model properties |

## View Composition Patterns

```swift
// Generic content with ViewBuilder
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// Custom view modifiers
struct HomeScreen: View {
    var body: some View {
        content
            .withDeepLinkHandling()
            .withDebugOverlay()
    }
}
```

## Animation Patterns

```swift
// State-driven animation
withAnimation(.smooth(duration: 0.3)) {
    isExpanded.toggle()
}

// Continuous animation (TimelineView)
TimelineView(.animation) { context in
    Canvas { ... }
}
```

## Rules

1. Keep views small - extract subviews aggressively
2. Use `private` for internal subviews
3. Always provide `#Preview` blocks
4. Use GeometryReader sparingly (prefer frame/padding)
5. Debounce rapid state changes (300ms standard)
