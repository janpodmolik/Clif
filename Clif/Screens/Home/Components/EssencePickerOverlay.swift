import SwiftUI

/// Full-screen overlay for essence picker, rendered at root level to appear above tab bar.
struct EssencePickerOverlay: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    private let dragPreviewOffset = CGSize(width: -20, height: -50)

    var body: some View {
        @Bindable var coordinator = coordinator

        ZStack(alignment: .bottom) {
            if coordinator.isShowing {
                // Tap-to-dismiss background
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        coordinator.dismiss()
                    }
                    .ignoresSafeArea()

                // Tray with drag handle
                VStack(spacing: 0) {
                    dragHandleArea

                    EssencePicker()
                        .contentShape(Rectangle())
                }
                .background(trayBackground)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .offset(y: coordinator.dismissDragOffset)
                .transition(.move(edge: .bottom))
            }

            // Drag preview rendered at root level
            if coordinator.dragState.isDragging,
               let essence = coordinator.dragState.draggedEssence {
                EssenceDragPreview(essence: essence)
                    .position(
                        x: coordinator.dragState.dragLocation.x + dragPreviewOffset.width,
                        y: coordinator.dragState.dragLocation.y + dragPreviewOffset.height
                    )
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: coordinator.isShowing)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: coordinator.dismissDragOffset)
    }

    @ViewBuilder
    private var dragHandleArea: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(dismissDragGesture)
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let translation = max(0, value.translation.height)
                coordinator.dismissDragOffset = translation
            }
            .onEnded { value in
                // Use predicted end translation to detect fast swipes
                // If the predicted position is significantly past our threshold, dismiss
                let predictedEndY = value.predictedEndTranslation.height
                let currentY = value.translation.height

                // Dismiss if: dragged past threshold OR fast swipe detected
                let draggedPastThreshold = currentY > 100
                let fastSwipeDetected = predictedEndY > 200 && currentY > 20

                if draggedPastThreshold || fastSwipeDetected {
                    coordinator.dismiss()
                } else {
                    coordinator.dismissDragOffset = 0
                }
            }
    }

    @ViewBuilder
    private var trayBackground: some View {
        let cornerRadius = DeviceMetrics.sheetCornerRadius
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}

#if DEBUG
#Preview {
    EssencePickerOverlay()
        .environment(EssencePickerCoordinator())
}
#endif
