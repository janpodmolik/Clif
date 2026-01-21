import SwiftUI

struct BlobDragPreview: View {
    let screenHeight: CGFloat
    var dragVelocity: CGSize = .zero

    private enum Layout {
        static let maxRotation: CGFloat = 25
        static let velocityDamping: CGFloat = 0.008
        static let shadowOpacity: CGFloat = 0.25
        static let shadowRadius: CGFloat = 12
        static let shadowY: CGFloat = 10
    }

    /// Same calculation as IslandView.petHeight
    private var imageSize: CGFloat { screenHeight * 0.10 }

    private var rotation: Angle {
        // Rotate based on horizontal velocity - feels like physics
        let rotationAmount = -dragVelocity.width * Layout.velocityDamping
        let clamped = max(-Layout.maxRotation, min(Layout.maxRotation, rotationAmount))
        return .degrees(clamped)
    }

    var body: some View {
        Image(Blob.shared.assetName(for: .none))
            .resizable()
            .scaledToFit()
            .frame(width: imageSize, height: imageSize)
            .rotationEffect(rotation, anchor: .top)
            .shadow(
                color: .black.opacity(Layout.shadowOpacity),
                radius: Layout.shadowRadius,
                x: 0,
                y: Layout.shadowY
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: dragVelocity.width)
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
                .ignoresSafeArea()

            BlobDragPreview(screenHeight: geometry.size.height)
        }
    }
}
#endif
