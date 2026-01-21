import SwiftUI

/// Displays the floating island without a pet, showing a drop zone indicator.
/// Used during pet creation flow before the pet is dropped.
struct EmptyIslandView: View {
    let screenHeight: CGFloat
    var showDropZone: Bool = false
    var isDropZoneHighlighted: Bool = false
    var isDropZoneSnapped: Bool = false
    var onDropZoneFrameChange: ((CGRect) -> Void)?

    /// Same calculation as IslandView.petHeight
    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    var body: some View {
        ZStack(alignment: .top) {
            IslandBase(screenHeight: screenHeight)

            // Drop zone indicator (only during pet creation)
            // Uses same structure as IslandView.petContent
            if showDropZone {
                ZStack {
                    PetDropZone(isHighlighted: isDropZoneHighlighted, isSnapped: isDropZoneSnapped)
                        .frame(height: petHeight)
                        .scaleEffect(Blob.shared.displayScale, anchor: .bottom)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: EmptyIslandDropZoneFrameKey.self,
                                        value: proxy.frame(in: .global)
                                    )
                            }
                        }
                }
                .padding(.top, petHeight * 0.6)
                .offset(y: petOffset)
                .onPreferenceChange(EmptyIslandDropZoneFrameKey.self) { frame in
                    onDropZoneFrameChange?(frame)
                }
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
#Preview("Empty") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            EmptyIslandView(screenHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("With Drop Zone") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            EmptyIslandView(
                screenHeight: geometry.size.height,
                showDropZone: true
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
                showDropZone: true,
                isDropZoneHighlighted: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
