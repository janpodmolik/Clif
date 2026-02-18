import SwiftUI

struct BlobDragPreview: View {
    let petHeight: CGFloat
    var dragVelocity: CGSize = .zero

    private enum Layout {
        static let maxRotation: CGFloat = 25
        static let velocityDamping: CGFloat = 0.008
    }

    private var rotation: Angle {
        // Rotate based on horizontal velocity - feels like physics
        let rotationAmount = -dragVelocity.width * Layout.velocityDamping
        let clamped = max(-Layout.maxRotation, min(Layout.maxRotation, rotationAmount))
        return .degrees(clamped)
    }

    var body: some View {
        PetImage(Blob.shared)
            .frame(height: petHeight)
            .rotationEffect(rotation, anchor: .top)
            .scaleEffect(Blob.shared.displayScale, anchor: .bottom)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: dragVelocity.width)
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
                .ignoresSafeArea()

            BlobDragPreview(petHeight: geometry.size.height * 0.10)
        }
    }
}
#endif
