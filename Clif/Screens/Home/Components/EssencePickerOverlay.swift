import SwiftUI

/// Full-screen overlay for essence picker, rendered at root level to appear above tab bar.
struct EssencePickerOverlay: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    private enum Layout {
        static let dragPreviewOffset = CGSize(width: -20, height: -50)
        static let trayInset: CGFloat = 10
        static let dragHandleWidth: CGFloat = 36
        static let dragHandleHeight: CGFloat = 5
        static let dragHandleAreaHeight: CGFloat = 44
    }

    private enum Dismiss {
        static let minDragDistance: CGFloat = 10
        static let dragThreshold: CGFloat = 100
        static let velocityThreshold: CGFloat = 300
    }

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
                .padding(.horizontal, Layout.trayInset)
                .padding(.bottom, Layout.trayInset)
                .offset(y: coordinator.dismissDragOffset)
                .transition(.move(edge: .bottom))
            }

            // Drag preview rendered at root level
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
                .frame(width: Layout.dragHandleWidth, height: Layout.dragHandleHeight)
        }
        .frame(height: Layout.dragHandleAreaHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(dismissDragGesture)
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: Dismiss.minDragDistance)
            .onChanged { value in
                let translation = max(0, value.translation.height)
                coordinator.dismissDragOffset = translation
            }
            .onEnded { value in
                let currentY = value.translation.height
                let velocity = value.predictedEndTranslation.height - currentY

                let draggedPastThreshold = currentY > Dismiss.dragThreshold
                let fastSwipeDetected = velocity > Dismiss.velocityThreshold

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
