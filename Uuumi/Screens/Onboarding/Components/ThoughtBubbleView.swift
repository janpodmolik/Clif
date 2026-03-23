import SwiftUI

/// Thought bubble displaying an evolution preview above the pet.
/// Shows trailing circles leading to a cloud-shaped bubble with pet evolution image inside.
struct ThoughtBubbleView: View {
    let isVisible: Bool

    /// Pet animation transform for following movement
    var petTransform: PetAnimationTransform = .zero

    // MARK: - Layout

    private let cloudSize: CGFloat = 100
    /// Vertical shift of the entire group (negative = higher above pet)
    private let verticalOffset: CGFloat = -90
    /// Horizontal shift of the entire group from pet center
    private let horizontalOffset: CGFloat = 60
    /// Vertical spacing between cloud → circle2 → circle1
    private let trailSpacing: CGFloat = 6
    /// Horizontal nudge for each trailing circle (creates a curved trail)
    private let circle2HorizontalNudge: CGFloat = -15
    private let circle1HorizontalNudge: CGFloat = -30

    // MARK: - State

    @State private var smoothedOffset: CGFloat = 0
    @State private var smoothedRotation: CGFloat = 0

    @State private var showCircle1 = false
    @State private var showCircle2 = false
    @State private var showCloud = false

    private var followOffset: CGFloat {
        petTransform.swayOffset + petTransform.topOffset
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .overlay {
                VStack(spacing: trailSpacing) {
                    cloudBubble

                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .offset(x: circle2HorizontalNudge)
                        .opacity(showCircle2 ? 1 : 0)
                        .scaleEffect(showCircle2 ? 1 : 0.3)

                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 10, height: 10)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .offset(x: circle1HorizontalNudge)
                        .opacity(showCircle1 ? 1 : 0)
                        .scaleEffect(showCircle1 ? 1 : 0.3)
                }
                .offset(x: horizontalOffset + smoothedOffset, y: verticalOffset)
            }
        .rotationEffect(.degrees(smoothedRotation * 0.2), anchor: .bottom)
        .onChange(of: followOffset) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                smoothedOffset = newValue
            }
        }
        .onChange(of: petTransform.rotation) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                smoothedRotation = newValue
            }
        }
        .onAppear {
            smoothedOffset = followOffset
            smoothedRotation = petTransform.rotation
            if isVisible {
                animateIn()
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                animateIn()
            } else {
                resetState()
            }
        }
    }

    // MARK: - Cloud Bubble

    private var cloudBubble: some View {
        ZStack {
            ThoughtCloudShape()
                .fill(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

            // Plant phase 3 evolution preview
            PetImage(
                bodyAssetName: "evolutions/plant/3/body",
                eyesAssetName: "evolutions/plant/3/eyes/neutral"
            )
            .padding(20)
        }
        .frame(width: cloudSize, height: cloudSize)
        .opacity(showCloud ? 1 : 0)
        .scaleEffect(showCloud ? 1 : 0.4)
    }

    // MARK: - Animation

    private func animateIn() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            showCircle1 = true
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.2)) {
            showCircle2 = true
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.45)) {
            showCloud = true
        }
    }

    private func resetState() {
        showCircle1 = false
        showCircle2 = false
        showCloud = false
    }
}

// MARK: - Thought Cloud Shape

/// Cloud-shaped path for thought bubble — organic bumpy outline.
/// Path fills the entire rect (no dead space at bottom).
struct ThoughtCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var path = Path()

        path.move(to: CGPoint(x: w * 0.20, y: h * 0.88))

        // Bottom-left bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.05, y: h * 0.59),
            control: CGPoint(x: w * 0.00, y: h * 0.82)
        )

        // Left bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.24),
            control: CGPoint(x: -w * 0.02, y: h * 0.35)
        )

        // Top-left bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.06),
            control: CGPoint(x: w * 0.20, y: -h * 0.06)
        )

        // Top-right bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.24),
            control: CGPoint(x: w * 0.80, y: -h * 0.06)
        )

        // Right bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.59),
            control: CGPoint(x: w * 1.02, y: h * 0.35)
        )

        // Bottom-right bump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.88),
            control: CGPoint(x: w * 1.00, y: h * 0.82)
        )

        // Bottom-right bulge
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.95),
            control: CGPoint(x: w * 0.68, y: h * 1.05)
        )

        // Bottom-left bulge
        path.addQuadCurve(
            to: CGPoint(x: w * 0.20, y: h * 0.88),
            control: CGPoint(x: w * 0.32, y: h * 1.05)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Thought Bubble") {
    OnboardingStepPreview(showBlob: true, showWind: false, showThoughtBubble: true) { _, _, _, _ in
        Color.clear
    }
}

#Preview("Cloud Shape") {
    ThoughtCloudShape()
        .fill(.white)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .frame(width: 120, height: 120)
        .padding()
        .background(Color.gray.opacity(0.3))
}
#endif
