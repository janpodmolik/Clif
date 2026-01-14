import SwiftUI

/// Essence picker presented in a DragPortalSheet for cross-screen drag operations.
struct EssencePickerOverlay: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    private enum Layout {
        static let dragPreviewOffset = CGSize(width: -20, height: -50)
    }

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
                    .position(
                        x: coordinator.dragState.dragLocation.x + Layout.dragPreviewOffset.width,
                        y: coordinator.dragState.dragLocation.y + Layout.dragPreviewOffset.height
                    )
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
