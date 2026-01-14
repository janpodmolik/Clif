import SwiftUI

// MARK: - Constants

private enum DragPortalSheetLayout {
    static let trayInset: CGFloat = 10
    static let dragHandleWidth: CGFloat = 36
    static let dragHandleHeight: CGFloat = 5
    static let dragHandleAreaHeight: CGFloat = 44
}

private enum DragPortalSheetDismiss {
    static let minDragDistance: CGFloat = 5
    static let dragThreshold: CGFloat = 100
    static let velocityThreshold: CGFloat = 800
    static let predictedThreshold: CGFloat = 200
}

// MARK: - DragPortalSheet

/// A sheet that supports drag-and-drop operations across screen boundaries.
///
/// Unlike native sheets, `DragPortalSheet` renders at root level, allowing drag operations
/// to extend beyond the sheet's bounds to other parts of the screen. Use this when you need
/// to drag items from the sheet to a target elsewhere in the app.
struct DragPortalSheet<Content: View, Overlay: View>: View {
    @Binding var isPresented: Bool
    @Binding var dismissDragOffset: CGFloat
    var onDismiss: (() -> Void)?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Tap-to-dismiss background
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }
                    .ignoresSafeArea()

                // Tray with drag handle
                VStack(spacing: 0) {
                    dragHandleArea

                    content()
                        .contentShape(Rectangle())
                }
                .background(trayBackground)
                .padding(.horizontal, DragPortalSheetLayout.trayInset)
                .padding(.bottom, DragPortalSheetLayout.trayInset)
                .offset(y: dismissDragOffset)
                .transition(.move(edge: .bottom))
            }

            overlay()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isPresented)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dismissDragOffset)
    }

    private var dragHandleArea: some View {
        Capsule()
            .fill(.secondary.opacity(0.4))
            .frame(width: DragPortalSheetLayout.dragHandleWidth, height: DragPortalSheetLayout.dragHandleHeight)
            .frame(maxWidth: .infinity, maxHeight: DragPortalSheetLayout.dragHandleAreaHeight)
            .contentShape(Rectangle())
            .gesture(dismissDragGesture)
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: DragPortalSheetDismiss.minDragDistance)
            .onChanged { value in
                let translation = max(0, value.translation.height)
                dismissDragOffset = translation
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.velocity.height
                let predictedEnd = value.predictedEndTranslation.height

                let draggedPastThreshold = translation > DragPortalSheetDismiss.dragThreshold
                let fastFlick = velocity > DragPortalSheetDismiss.velocityThreshold
                let momentumDismiss = predictedEnd > DragPortalSheetDismiss.predictedThreshold && translation > 20

                if draggedPastThreshold || fastFlick || momentumDismiss {
                    dismiss()
                } else {
                    dismissDragOffset = 0
                }
            }
    }

    @ViewBuilder
    private var trayBackground: some View {
        let shape = RoundedRectangle(cornerRadius: DeviceMetrics.sheetCornerRadius)
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular, in: shape)
        } else {
            shape.fill(.ultraThinMaterial)
        }
    }

    private func dismiss() {
        isPresented = false
        dismissDragOffset = 0
        onDismiss?()
    }
}

// MARK: - Convenience Init (No Overlay)

extension DragPortalSheet where Overlay == EmptyView {
    init(
        isPresented: Binding<Bool>,
        dismissDragOffset: Binding<CGFloat>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self._dismissDragOffset = dismissDragOffset
        self.onDismiss = onDismiss
        self.content = content
        self.overlay = { EmptyView() }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var offset: CGFloat = 0

    DragPortalSheet(
        isPresented: $isPresented,
        dismissDragOffset: $offset
    ) {
        Text("Sheet Content")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
    }
}
#endif
