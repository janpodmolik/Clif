import SwiftUI

/// State for drag operation, shared with overlay for preview rendering.
struct EssenceDragState: Equatable {
    var isDragging = false
    var dragLocation: CGPoint = .zero
    var draggedEssence: Essence?
    var isSnapped = false
    var snapTargetCenter: CGPoint = .zero
}

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
    var hasSelectedEssence = false
    var dragState = EssenceDragState()
    var dismissDragOffset: CGFloat = 0
    var petDropFrame: CGRect?

    private var onDropOnPet: ((Essence) -> Void)?
    private var cleanupWorkItem: DispatchWorkItem?

    func show(petDropFrame: CGRect?, onDropOnPet: @escaping (Essence) -> Void) {
        cleanupWorkItem?.cancel()
        cleanupWorkItem = nil

        self.petDropFrame = petDropFrame
        self.onDropOnPet = onDropOnPet
        isShowing = true
    }

    func dismiss() {
        isShowing = false
        dismissDragOffset = 0

        cleanupWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hasSelectedEssence = false
            self?.dragState = EssenceDragState()
            self?.petDropFrame = nil
            self?.onDropOnPet = nil
            self?.cleanupWorkItem = nil
        }
        cleanupWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
    }

    func handleDrop(_ essence: Essence) {
        onDropOnPet?(essence)
        dismiss()
    }
}
