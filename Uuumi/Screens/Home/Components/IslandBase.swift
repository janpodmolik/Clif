import SwiftUI

// MARK: - Island Layout

/// Shared layout constants for island positioning.
/// On non-notch devices (iPhone SE, etc.) the entire island is shifted down so the
/// bottom clips off-screen, giving more space above the pet. All proportions and
/// animations remain identical — only the Y position changes.
/// On notch / Dynamic Island devices the offset is zero (no change).
enum IslandLayout {
    /// Whether the current device lacks a notch / Dynamic Island.
    /// All non-notch iPhones have a native screen height ≤ 736pt (iPhone 8 Plus).
    /// All notch iPhones start at 812pt (iPhone X). Safe to read at any time.
    static let isCompactDevice: Bool = UIScreen.main.bounds.height <= 736

    /// How far to push the entire island down on compact devices.
    /// The bottom of the rock simply clips off-screen.
    static let compactDownshift: CGFloat = isCompactDevice ? 60 : 0
}

// MARK: - Island Base

/// Base island component with rock and grass.
/// Used by both IslandView and EmptyIslandView to ensure consistent positioning.
struct IslandBase: View {
    let screenHeight: CGFloat

    var islandHeight: CGFloat { screenHeight * 0.6 }

    var body: some View {
        Image("rock")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: islandHeight)
            .overlay(alignment: .top) {
                Image("grass")
                    .resizable()
                    .scaledToFit()
            }
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandBase(screenHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
