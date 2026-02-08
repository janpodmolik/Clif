import SwiftUI

/// Card shape with an optional capsule-shaped bump extending from the bottom edge.
/// Used for HomeCard when evolve button should appear as part of the card.
///
/// ```
/// ┌──────────────────────────┐
/// │                          │
/// │      Card Content        │
/// │                          │
/// └────────╭──────╮──────────┘
///          │ Bump │
///          ╰──────╯
/// ```
struct HomeCardWithBumpShape: Shape {
    /// Corner radius of the main card
    let cornerRadius: CGFloat
    /// Width of the bump (capsule)
    var bumpWidth: CGFloat
    /// Height of the bump extending below the card
    var bumpHeight: CGFloat
    /// Corner radius of the bump ends (typically bumpHeight/2 for capsule)
    var bumpCornerRadius: CGFloat
    /// Radius for the transition arcs between card and bump
    var transitionRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(bumpWidth, AnimatablePair(bumpHeight, bumpCornerRadius))
        }
        set {
            bumpWidth = newValue.first
            bumpHeight = newValue.second.first
            bumpCornerRadius = newValue.second.second
        }
    }

    init(
        cornerRadius: CGFloat,
        bumpWidth: CGFloat = 0,
        bumpHeight: CGFloat = 0,
        bumpCornerRadius: CGFloat? = nil,
        transitionRadius: CGFloat = 8
    ) {
        self.cornerRadius = cornerRadius
        self.bumpWidth = bumpWidth
        self.bumpHeight = bumpHeight
        self.bumpCornerRadius = bumpCornerRadius ?? (bumpHeight / 2)
        self.transitionRadius = transitionRadius
    }

    func path(in rect: CGRect) -> Path {
        // If no bump, just return rounded rectangle
        guard bumpWidth > 0, bumpHeight > 0 else {
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        }

        let centerX = rect.width / 2
        let cardBottom = rect.height - bumpHeight

        // Bump horizontal bounds
        let bumpLeft = centerX - bumpWidth / 2
        let bumpRight = centerX + bumpWidth / 2

        // Clamp transition radius to reasonable bounds
        let effectiveTransition = min(transitionRadius, bumpHeight, cornerRadius)

        var path = Path()

        // Start at top-left corner (after the corner arc)
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        // Top-right corner
        path.addArc(
            tangent1End: CGPoint(x: rect.width, y: 0),
            tangent2End: CGPoint(x: rect.width, y: cornerRadius),
            radius: cornerRadius
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: cardBottom - cornerRadius))

        // Bottom-right corner
        path.addArc(
            tangent1End: CGPoint(x: rect.width, y: cardBottom),
            tangent2End: CGPoint(x: rect.width - cornerRadius, y: cardBottom),
            radius: cornerRadius
        )

        // Bottom edge to bump start
        path.addLine(to: CGPoint(x: bumpRight + effectiveTransition, y: cardBottom))

        // Right transition arc (card → bump)
        path.addArc(
            tangent1End: CGPoint(x: bumpRight, y: cardBottom),
            tangent2End: CGPoint(x: bumpRight, y: cardBottom + effectiveTransition),
            radius: effectiveTransition
        )

        // Right side of bump going down
        path.addLine(to: CGPoint(x: bumpRight, y: rect.height - bumpCornerRadius))

        // Bottom-right of bump (capsule end)
        path.addArc(
            tangent1End: CGPoint(x: bumpRight, y: rect.height),
            tangent2End: CGPoint(x: bumpRight - bumpCornerRadius, y: rect.height),
            radius: bumpCornerRadius
        )

        // Bottom of bump
        path.addLine(to: CGPoint(x: bumpLeft + bumpCornerRadius, y: rect.height))

        // Bottom-left of bump (capsule end)
        path.addArc(
            tangent1End: CGPoint(x: bumpLeft, y: rect.height),
            tangent2End: CGPoint(x: bumpLeft, y: rect.height - bumpCornerRadius),
            radius: bumpCornerRadius
        )

        // Left side of bump going up
        path.addLine(to: CGPoint(x: bumpLeft, y: cardBottom + effectiveTransition))

        // Left transition arc (bump → card)
        path.addArc(
            tangent1End: CGPoint(x: bumpLeft, y: cardBottom),
            tangent2End: CGPoint(x: bumpLeft - effectiveTransition, y: cardBottom),
            radius: effectiveTransition
        )

        // Rest of bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: cardBottom))

        // Bottom-left corner
        path.addArc(
            tangent1End: CGPoint(x: 0, y: cardBottom),
            tangent2End: CGPoint(x: 0, y: cardBottom - cornerRadius),
            radius: cornerRadius
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Top-left corner
        path.addArc(
            tangent1End: CGPoint(x: 0, y: 0),
            tangent2End: CGPoint(x: cornerRadius, y: 0),
            radius: cornerRadius
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("With Bump") {
    VStack {
        Text("Card Content")
            .frame(maxWidth: .infinity)
            .padding(40)
    }
    .background(
        .ultraThinMaterial,
        in: HomeCardWithBumpShape(
            cornerRadius: 24,
            bumpWidth: 120,
            bumpHeight: 24,
            transitionRadius: 10
        )
    )
    .padding(40)
    .padding(.bottom, 30)
    .background(Color.blue.opacity(0.3))
}

#Preview("Without Bump") {
    VStack {
        Text("Card Content")
            .frame(maxWidth: .infinity)
            .padding(40)
    }
    .background(
        .ultraThinMaterial,
        in: HomeCardWithBumpShape(
            cornerRadius: 24,
            bumpWidth: 0,
            bumpHeight: 0
        )
    )
    .padding(40)
    .background(Color.blue.opacity(0.3))
}

#Preview("Animated") {
    struct AnimatedPreview: View {
        @State private var showBump = false

        var body: some View {
            VStack {
                Text("Card Content")
                    .frame(maxWidth: .infinity)
                    .padding(40)
            }
            .background(
                .ultraThinMaterial,
                in: HomeCardWithBumpShape(
                    cornerRadius: 24,
                    bumpWidth: showBump ? 140 : 0,
                    bumpHeight: showBump ? 28 : 0,
                    transitionRadius: 10
                )
            )
            .padding(40)
            .padding(.bottom, 30)
            .background(Color.green.opacity(0.3))
            .onTapGesture {
                withAnimation(.spring(duration: 0.4)) {
                    showBump.toggle()
                }
            }
        }
    }

    return AnimatedPreview()
}
