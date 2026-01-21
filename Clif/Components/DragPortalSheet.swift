import SwiftUI

// MARK: - Configuration

struct DragPortalSheetConfiguration {
    var showsDragHandle: Bool = true
    var allowsSwipeToDismiss: Bool = true
    var usesGlassBackground: Bool = true

    static let `default` = DragPortalSheetConfiguration()

    static let petDrop = DragPortalSheetConfiguration(
        showsDragHandle: false,
        allowsSwipeToDismiss: false,
        usesGlassBackground: false
    )
}

// MARK: - Constants

private enum DragPortalSheetLayout {
    static let trayInset: CGFloat = 10
    static let dragHandleWidth: CGFloat = 36
    static let dragHandleHeight: CGFloat = 5
    static let dragHandleTopPadding: CGFloat = 8
    static let dragHandleBottomPadding: CGFloat = 4
    /// Extra touch area extending above the visible tray bounds
    static let dragHandleTouchExtensionAbove: CGFloat = 60
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
    var configuration: DragPortalSheetConfiguration
    var onDismiss: (() -> Void)?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay

    @State private var stretchOffset: CGFloat = 0

    init(
        isPresented: Binding<Bool>,
        dismissDragOffset: Binding<CGFloat>,
        configuration: DragPortalSheetConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self._isPresented = isPresented
        self._dismissDragOffset = dismissDragOffset
        self.configuration = configuration
        self.onDismiss = onDismiss
        self.content = content
        self.overlay = overlay
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Tap-to-dismiss background (only if swipe dismiss allowed)
                if configuration.allowsSwipeToDismiss {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismiss()
                        }
                        .ignoresSafeArea()
                }

                // Tray container - fixed to bottom
                VStack {
                    Spacer()

                    // Tray with optional drag handle
                    VStack(spacing: 0) {
                        if configuration.showsDragHandle {
                            dragHandleIndicator
                        }

                        content()

                        // Stretch space for rubber band effect
                        if stretchOffset > 0 {
                            Color.clear.frame(height: stretchOffset)
                        }
                    }
                    .background(trayBackground)
                    .clipShape(trayClipShape)
                    .contentShape(Rectangle())
                    .gesture(rubberBandGesture)
                    .overlay(alignment: .top) {
                        if configuration.showsDragHandle {
                            aboveTrayGestureArea
                        }
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
            .fill(.secondary.opacity(0.6))
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
            .gesture(rubberBandGesture)
    }

    private var rubberBandGesture: some Gesture {
        DragGesture(minimumDistance: DragPortalSheetDismiss.minDragDistance)
            .onChanged { value in
                let translation = value.translation.height
                let resistance: CGFloat = 0.3

                if translation >= 0 {
                    // Dragging down
                    if configuration.allowsSwipeToDismiss {
                        // Full dismiss behavior - no resistance
                        dismissDragOffset = translation
                        stretchOffset = 0
                    } else {
                        // Rubber band with resistance (sheet moves down slightly)
                        dismissDragOffset = translation * resistance
                        stretchOffset = 0
                    }
                } else {
                    // Dragging up - rubber band stretch (sheet grows taller)
                    stretchOffset = -translation * resistance
                    dismissDragOffset = 0
                }
            }
            .onEnded { value in
                let translation = value.translation.height

                if translation >= 0 && configuration.allowsSwipeToDismiss {
                    // Was dragging down with dismiss enabled - check for dismiss
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
                } else {
                    // Spring back (either dragging up, or dismiss disabled)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        stretchOffset = 0
                        dismissDragOffset = 0
                    }
                }
            }
    }

    private var trayClipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: DragPortalSheetLayout.trayInset))
    }

    @ViewBuilder
    private var trayBackground: some View {
        if configuration.usesGlassBackground {
            if #available(iOS 26.0, *) {
                // ConcentricRectangle automatically calculates correct radius based on distance from screen edge
                Color.clear.glassEffect(.regular, in: ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true))
            } else {
                // Manual calculation for iOS < 26
                trayClipShape.fill(.ultraThinMaterial)
            }
        } else {
            // Solid background matching iOS sheet style
            trayClipShape.fill(Color(.systemBackground))
        }
    }

    private func dismiss() {
        isPresented = false
        dismissDragOffset = 0
        onDismiss?()
    }
}

// MARK: - Convenience Init

extension DragPortalSheet where Overlay == EmptyView {
    init(
        isPresented: Binding<Bool>,
        dismissDragOffset: Binding<CGFloat>,
        configuration: DragPortalSheetConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self._dismissDragOffset = dismissDragOffset
        self.configuration = configuration
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
