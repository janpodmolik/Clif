import SwiftUI

/// Coordinates the essence picker overlay across the app.
///
/// This coordinator exists because the essence picker needs to appear IN FRONT OF
/// the tab bar (higher z-index), not just positioned above it. Since the tab bar
/// is rendered via `.safeAreaInset` on ContentView level, any overlay inside
/// HomeScreen (which is a child of TabView) will always render below the tab bar.
///
/// By using an Environment-based coordinator, HomeScreen can trigger the picker
/// and provide callbacks, while ContentView renders the actual overlay on top
/// of everything including the tab bar.
@Observable
final class EssencePickerCoordinator {
    var isShowing = false
    var dragState = EssenceDragState()
    var petDropFrame: CGRect?
    var onDropOnPet: ((Essence) -> Void)?

    func show(petDropFrame: CGRect?, onDropOnPet: @escaping (Essence) -> Void) {
        self.petDropFrame = petDropFrame
        self.onDropOnPet = onDropOnPet
        isShowing = true
    }

    func hide() {
        isShowing = false
        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.dragState = EssenceDragState()
            self?.petDropFrame = nil
            self?.onDropOnPet = nil
        }
    }
}
