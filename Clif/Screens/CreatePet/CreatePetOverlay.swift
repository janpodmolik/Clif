import SwiftUI

struct CreatePetOverlay: View {
    let screenHeight: CGFloat

    @Environment(CreatePetCoordinator.self) private var coordinator

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
                    // When snapped, position at drop zone center
                    // When returning, position directly at dragLocation (which animates to staging card center)
                    // When dragging, apply offset to show pet below finger
                    let position: CGPoint = {
                        if coordinator.dragState.isOnTarget {
                            return coordinator.dragState.snapTarget
                        } else if coordinator.dragState.isReturning {
                            return coordinator.dragState.dragLocation
                        } else {
                            return DragPreviewOffset.adjustedPosition(from: coordinator.dragState.dragLocation)
                        }
                    }()

                    BlobDragPreview(
                        screenHeight: screenHeight,
                        dragVelocity: coordinator.dragState.isOnTarget ? .zero : coordinator.dragState.dragVelocity
                    )
                        .position(position)
                        .animation(
                            coordinator.dragState.isReturning
                                ? .spring(response: 0.4, dampingFraction: 0.7)
                                : .spring(response: 0.25, dampingFraction: 0.7),
                            value: position
                        )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        CreatePetOverlay(screenHeight: geometry.size.height)
            .environment(CreatePetCoordinator())
            .environment(PetManager.mock())
    }
}
#endif
