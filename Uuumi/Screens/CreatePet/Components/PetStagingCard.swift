import SwiftUI

struct PetStagingCard: View {
    var isDragging: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var glowPhase: CGFloat = 0

    private enum Layout {
        static let imageSize: CGFloat = 56
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let strokeOpacity: CGFloat = 0.3
        static let glowRadius: CGFloat = 12
        static let glowOpacity: CGFloat = 0.6
    }

    private var glowColor: Color {
        colorScheme == .dark ? .white : .green
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
                            .stroke(glowColor.opacity(Layout.strokeOpacity + glowPhase * 0.3), lineWidth: 2)
                    }
                    .shadow(
                        color: glowColor.opacity(Layout.glowOpacity * glowPhase),
                        radius: Layout.glowRadius * glowPhase
                    )
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDragging)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                glowPhase = 1
            }
        }
    }
}

#if DEBUG
#Preview {
    PetStagingCard()
}
#endif
