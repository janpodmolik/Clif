import SwiftUI

/// Animated drop zone indicator shown on the island during pet creation.
/// Pulses to draw attention to where the user should drop the pet.
/// Uses same corner radius as PetStagingCard for visual consistency.
struct PetDropZone: View {
    var isHighlighted: Bool = false
    var isSnapped: Bool = false
    var size: CGFloat = Layout.defaultSize

    @State private var pulsePhase: CGFloat = 0

    private enum Layout {
        static let defaultSize: CGFloat = 80
        static let cornerRadius: CGFloat = 24  // Same as PetStagingCard
        static let innerScale: CGFloat = 0.7
        static let pulseScale: CGFloat = 1.2
        static let baseOpacity: CGFloat = 0.4
        static let highlightOpacity: CGFloat = 0.7
    }

    private var currentOpacity: CGFloat {
        isHighlighted ? Layout.highlightOpacity : Layout.baseOpacity
    }

    private var strokeColor: Color {
        isSnapped ? .green : .white
    }

    private var innerCornerRadius: CGFloat {
        Layout.cornerRadius * Layout.innerScale
    }

    var body: some View {
        ZStack {
            // Outer pulsing ring
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(
                    strokeColor.opacity(currentOpacity * (1 - pulsePhase * 0.5)),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
                .scaleEffect(1 + pulsePhase * (Layout.pulseScale - 1))

            // Inner dashed ring
            RoundedRectangle(cornerRadius: innerCornerRadius)
                .stroke(
                    strokeColor.opacity(currentOpacity * 0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .frame(width: size * Layout.innerScale, height: size * Layout.innerScale)
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        .animation(.easeInOut(duration: 0.15), value: isSnapped)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                pulsePhase = 1
            }
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            PetDropZone(isHighlighted: false)
            PetDropZone(isHighlighted: true)
            PetDropZone(isHighlighted: true, isSnapped: true)
        }
    }
}
#endif
