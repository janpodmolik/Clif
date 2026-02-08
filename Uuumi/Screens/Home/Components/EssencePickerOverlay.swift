import SwiftUI

/// Essence picker presented in a DragPortalSheet for cross-screen drag operations.
struct EssencePickerOverlay: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        DragPortalSheet(
            isPresented: $coordinator.isShowing,
            dismissDragOffset: $coordinator.dismissDragOffset,
            onDismiss: { coordinator.dismiss() }
        ) {
            EssencePicker()
        } overlay: {
            if coordinator.dragState.isDragging,
               let essence = coordinator.dragState.draggedEssence {
                EssenceDragPreview(essence: essence)
                    .position(DragPreviewOffset.adjustedPosition(from: coordinator.dragState.dragLocation))
                    .allowsHitTesting(false)
            }
        }
    }
}

#if DEBUG
#Preview {
    EssencePickerOverlay()
        .environment(EssencePickerCoordinator())
}
#endif
