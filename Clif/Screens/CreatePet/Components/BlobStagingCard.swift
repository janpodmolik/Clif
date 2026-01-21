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
            .glassBackground(cornerRadius: Layout.cornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color.secondary.opacity(Layout.strokeOpacity), lineWidth: 2)
            }
    }
}

#if DEBUG
#Preview {
    BlobStagingCard()
}
#endif
