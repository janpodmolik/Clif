import SwiftUI

struct CreatePetOverlay: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        static let dragPreviewOffset = CGSize(width: -20, height: -50)
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        ZStack {
            // iOS sheet for steps 1-4
            // Note: No onDismiss needed - interactiveDismissDisabled prevents swipe,
            // and dismiss is handled via coordinator methods
            Color.clear
                .sheet(isPresented: $coordinator.isShowing) {
                    CreatePetMultiStep()
                        .environment(coordinator)
                        .interactiveDismissDisabled()
                }

            // DragPortalSheet for drop step
            DragPortalSheet(
                isPresented: $coordinator.isDropping,
                dismissDragOffset: $coordinator.dismissDragOffset,
                configuration: .petDrop
            ) {
                PetDropStep()
            } overlay: {
                if coordinator.dragState.isDragging {
                    BlobDragPreview()
                        .position(
                            x: coordinator.dragState.dragLocation.x + Layout.dragPreviewOffset.width,
                            y: coordinator.dragState.dragLocation.y + Layout.dragPreviewOffset.height
                        )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    CreatePetOverlay()
        .environment(CreatePetCoordinator())
        .environment(PetManager.mock())
}
#endif
