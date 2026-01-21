import SwiftUI

struct PetStagingCard: View {
    private enum Layout {
        static let imageSize: CGFloat = 56
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
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
    PetStagingCard()
}
#endif
