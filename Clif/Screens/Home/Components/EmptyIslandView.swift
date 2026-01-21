import SwiftUI

/// Displays the floating island without a pet, showing a drop zone indicator.
/// Used during pet creation flow before the pet is dropped.
struct EmptyIslandView: View {
    let screenHeight: CGFloat
    var isDropZoneHighlighted: Bool = false
    var onDropZoneFrameChange: ((CGRect) -> Void)?

    private var islandHeight: CGFloat { screenHeight * 0.6 }
    private var dropZoneVerticalOffset: CGFloat { screenHeight * 0.10 * 0.6 }
    private var dropZoneOffset: CGFloat { -(screenHeight * 0.10) }

    var body: some View {
        ZStack(alignment: .top) {
            // Rock with grass overlay
            Image("rock")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: islandHeight)
                .overlay(alignment: .top) {
                    Image("grass")
                        .resizable()
                        .scaledToFit()
                }

            // Drop zone indicator
            PetDropZone(isHighlighted: isDropZoneHighlighted)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: EmptyIslandDropZoneFrameKey.self,
                                value: proxy.frame(in: .global)
                            )
                    }
                }
                .padding(.top, dropZoneVerticalOffset)
                .offset(y: dropZoneOffset)
                .onPreferenceChange(EmptyIslandDropZoneFrameKey.self) { frame in
                    onDropZoneFrameChange?(frame)
                }
        }
    }
}

private struct EmptyIslandDropZoneFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            EmptyIslandView(
                screenHeight: geometry.size.height,
                isDropZoneHighlighted: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Highlighted") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            EmptyIslandView(
                screenHeight: geometry.size.height,
                isDropZoneHighlighted: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
