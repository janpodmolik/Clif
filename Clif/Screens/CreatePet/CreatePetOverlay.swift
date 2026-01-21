import SwiftUI

struct CreatePetOverlay: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        // Offset to position pet below finger during drag
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
                if coordinator.dragState.isDragging || coordinator.dragState.isReturning {
                    // When returning, position directly at dragLocation (which animates to staging card center)
                    // When dragging, apply offset to show pet below finger
                    let offset = coordinator.dragState.isReturning ? .zero : Layout.dragPreviewOffset

                    BlobDragPreview(dragVelocity: coordinator.dragState.dragVelocity)
                        .position(
                            x: coordinator.dragState.dragLocation.x + offset.width,
                            y: coordinator.dragState.dragLocation.y + offset.height
                        )
                        .animation(
                            coordinator.dragState.isReturning
                                ? .spring(response: 0.4, dampingFraction: 0.7)
                                : .interactiveSpring(response: 0.15, dampingFraction: 0.8),
                            value: coordinator.dragState.dragLocation
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
