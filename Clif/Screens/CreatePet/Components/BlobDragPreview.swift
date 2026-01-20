import SwiftUI

struct BlobDragPreview: View {
    private enum Layout {
        static let imageSize: CGFloat = 70
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 28
        static let shadowOpacity: CGFloat = 0.18
        static let shadowRadius: CGFloat = 10
        static let shadowY: CGFloat = 8
    }

    var body: some View {
        Image(Blob.shared.assetName(for: .none))
            .resizable()
            .scaledToFit()
            .frame(width: Layout.imageSize, height: Layout.imageSize)
            .padding(Layout.padding)
            .background(previewBackground)
            .shadow(
                color: .black.opacity(Layout.shadowOpacity),
                radius: Layout.shadowRadius,
                x: 0,
                y: Layout.shadowY
            )
    }

    @ViewBuilder
    private var previewBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Layout.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
        } else {
            shape
                .fill(.ultraThinMaterial)
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        BlobDragPreview()
    }
}
#endif
