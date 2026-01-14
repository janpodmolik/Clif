import SwiftUI

// MARK: - Constants

private enum DragPortalSheetLayout {
    static let trayInset: CGFloat = 10
    static let dragHandleWidth: CGFloat = 36
    static let dragHandleHeight: CGFloat = 5
    static let dragHandleTopPadding: CGFloat = 4
    static let dragHandleBottomPadding: CGFloat = 4
    /// Extra touch area extending above the visible tray bounds
    static let dragHandleTouchExtensionAbove: CGFloat = 60
}

// MARK: - Excluded Drag Zones

private struct ExcludedDragZonesKey: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Marks this view as excluded from sheet dismiss drag gesture
    func excludeFromSheetDrag() -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ExcludedDragZonesKey.self,
                    value: [geo.frame(in: .named("sheetTray"))]
                )
            }
        )
    }
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

    @State private var stretchOffset: CGFloat = 0
    @State private var excludedZones: [CGRect] = []
    @State private var dragStartLocation: CGPoint?

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

                // Tray container - fixed to bottom
                VStack {
                    Spacer()

                    // Tray with drag handle
                    VStack(spacing: 0) {
                        dragHandleIndicator

                        content()

                        // Stretch space for rubber band effect
                        if stretchOffset > 0 {
                            Color.clear.frame(height: stretchOffset)
                        }
                    }
                    .coordinateSpace(name: "sheetTray")
                    .background(trayBackground)
                    .contentShape(Rectangle())
                    .gesture(dismissDragGesture)
                    .overlay(alignment: .top) {
                        aboveTrayGestureArea
                    }
                    .onPreferenceChange(ExcludedDragZonesKey.self) { zones in
                        excludedZones = zones
                    }
                    .offset(y: dismissDragOffset)
                    .padding(.horizontal, DragPortalSheetLayout.trayInset)
                    .padding(.bottom, DragPortalSheetLayout.trayInset)
                }
                .transition(.move(edge: .bottom))
            }

            overlay()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isPresented)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dismissDragOffset)
    }

    /// Visual drag handle indicator (no gesture)
    private var dragHandleIndicator: some View {
        Capsule()
            .fill(.secondary.opacity(0.4))
            .frame(width: DragPortalSheetLayout.dragHandleWidth, height: DragPortalSheetLayout.dragHandleHeight)
            .padding(.top, DragPortalSheetLayout.dragHandleTopPadding)
            .padding(.bottom, DragPortalSheetLayout.dragHandleBottomPadding)
            .frame(maxWidth: .infinity)
    }

    /// Invisible gesture area extending above visible tray bounds
    private var aboveTrayGestureArea: some View {
        let aboveExtension = DragPortalSheetLayout.dragHandleTouchExtensionAbove

        return Color.clear
            .frame(height: aboveExtension)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .offset(y: -aboveExtension)
            .gesture(dismissDragGesture)
    }

    private func isPointInExcludedZone(_ point: CGPoint) -> Bool {
        excludedZones.contains { $0.contains(point) }
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: DragPortalSheetDismiss.minDragDistance, coordinateSpace: .named("sheetTray"))
            .onChanged { value in
                // Check if drag started in excluded zone (only on first change)
                if dragStartLocation == nil {
                    dragStartLocation = value.startLocation
                    if isPointInExcludedZone(value.startLocation) {
                        return
                    }
                }

                // Ignore if started in excluded zone
                guard let startLoc = dragStartLocation, !isPointInExcludedZone(startLoc) else { return }

                let translation = value.translation.height
                if translation >= 0 {
                    // Dragging down - dismiss behavior
                    dismissDragOffset = translation
                    stretchOffset = 0
                } else {
                    // Dragging up - rubber band stretch
                    let resistance: CGFloat = 0.3
                    stretchOffset = -translation * resistance
                    dismissDragOffset = 0
                }
            }
            .onEnded { value in
                defer { dragStartLocation = nil }

                // Ignore if started in excluded zone
                guard let startLoc = dragStartLocation, !isPointInExcludedZone(startLoc) else { return }

                let translation = value.translation.height
                let velocity = value.velocity.height
                let predictedEnd = value.predictedEndTranslation.height

                if translation >= 0 {
                    // Was dragging down - check for dismiss
                    let draggedPastThreshold = translation > DragPortalSheetDismiss.dragThreshold
                    let fastFlick = velocity > DragPortalSheetDismiss.velocityThreshold
                    let momentumDismiss = predictedEnd > DragPortalSheetDismiss.predictedThreshold && translation > 20

                    if draggedPastThreshold || fastFlick || momentumDismiss {
                        dismiss()
                    } else {
                        dismissDragOffset = 0
                    }
                } else {
                    // Was dragging up - spring back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        stretchOffset = 0
                    }
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
