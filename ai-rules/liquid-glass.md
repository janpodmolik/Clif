# Liquid Glass (iOS 26+)

<primary-directive>
Liquid Glass is a navigation layer - content below, glass components float above.
Use for controls (toolbars, buttons, cards), NOT for main content.
</primary-directive>

## API

```swift
// Basic usage
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

// Interactive (for buttons, tappable elements)
.glassEffect(.regular.interactive(), in: .capsule)

// With tint (ONLY with semantics - primary action, state)
.glassEffect(.regular.tint(.blue), in: .circle)
```

## Glass Variants

- `.regular` - standard blur with reflection
- `.clear` - minimal blur for subtle effects
- `.regular.interactive()` - responds to touch/hover

## Button Styles

```swift
.buttonStyle(.glass)           // secondary action
.buttonStyle(.glassProminent)  // primary action
```

## GlassEffectContainer

Use when multiple glass elements are close together (glass cannot sample other glass):

```swift
GlassEffectContainer {
    HStack {
        Button("A") { }.glassEffect()
        Button("B") { }.glassEffect()
    }
}
```

## Morphing Animations

```swift
@Namespace var namespace

// Element 1
.glassEffectID("button", in: namespace)

// Element 2 (smoothly transforms on state change)
.glassEffectID("button", in: namespace)
```

## DON'T

- Add `.blur`, `.opacity`, `.background` on glass view
- Put solid colors (`Color.white`, `Color.black`) under glass
- Use `.tint` just for decoration - only with semantics
- Add custom background on toolbars (they have automatic glass)
- Mix `.regular` and `.clear` in the same control group

## Fallback for iOS < 26

```swift
if #available(iOS 26.0, *) {
    content.glassEffect(.regular, in: shape)
} else {
    content
        .background(.ultraThinMaterial)
        .clipShape(shape)
}
```

## Accessibility

- Test with Increase Contrast, Reduce Transparency, Reduce Motion
- Apply glass conditionally in low power mode or with accessibility settings

## Container Concentricity (Nested Rounding)

**Principle:** Nested elements share the same center of rounding with parent. Inner radius = outer radius - padding.

```swift
// Automatic concentric rounding
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))

// With minimum fallback radius
.rect(corners: .concentric(minimum: 12), isUniform: true)

// Define container shape for children
.containerShape(.rect(cornerRadius: 24))
```

**When to use:**
- Buttons/badges inside cards
- Nested glass elements
- Components that work standalone or nested

**Rules:**
- Avoid "pinched" (too small) or "flared" (too large) inner corners
- `isUniform: true` for off-center elements (all corners same)
- Sufficient padding between container and inner elements

## Pre-commit Checklist

- [ ] iOS < 26 fallback provided for all `.glassEffect()` calls
- [ ] No `.background` or `.blur` on glass views
