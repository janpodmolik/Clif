import SwiftUI

struct PetStagingCard: View {
    var isDragging: Bool = false

    private enum Layout {
        static let imageSize: CGFloat = 56
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let strokeOpacity: CGFloat = 0.3
    }

    var body: some View {
        ZStack {
            if isDragging {
                // Empty placeholder when pet is being dragged
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .strokeBorder(
                        Color.secondary.opacity(0.2),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .frame(
                        width: Layout.imageSize + Layout.padding * 2,
                        height: Layout.imageSize + Layout.padding * 2
                    )
            } else {
                Image(Blob.shared.assetName(for: .none))
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
                    .padding(Layout.padding)
                    .glassBackground(cornerRadius: Layout.cornerRadius)
                    .overlay {
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .stroke(Color.secondary.opacity(Layout.strokeOpacity), lineWidth: 2)
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDragging)
    }
}

#if DEBUG
#Preview {
    PetStagingCard()
}
#endif
