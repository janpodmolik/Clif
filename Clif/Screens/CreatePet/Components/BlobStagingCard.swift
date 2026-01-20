import SwiftUI

struct BlobStagingCard: View {
    private enum Layout {
        static let imageSize: CGFloat = 80
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 32
        static let strokeOpacity: CGFloat = 0.3
    }

    var body: some View {
        Image(Blob.shared.assetName(for: .none))
            .resizable()
            .scaledToFit()
            .frame(width: Layout.imageSize, height: Layout.imageSize)
            .padding(Layout.padding)
            .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Layout.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
                .overlay {
                    shape.stroke(Color.secondary.opacity(Layout.strokeOpacity), lineWidth: 2)
                }
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.stroke(Color.secondary.opacity(Layout.strokeOpacity), lineWidth: 2)
                }
        }
    }
}

#if DEBUG
#Preview {
    BlobStagingCard()
}
#endif
