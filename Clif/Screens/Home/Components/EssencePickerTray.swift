import SwiftUI
import Combine

/// State for drag operation, shared with parent for overlay rendering
struct EssenceDragState {
    var isDragging: Bool = false
    var dragLocation: CGPoint = .zero
    var draggedEssence: Essence?
}

/// Essence picker with catalog and staging area.
struct EssencePickerTray: View {
    var petDropFrame: CGRect?
    var onDropOnPet: ((Essence) -> Void)?
    var onClose: (() -> Void)?
    @Binding var dragState: EssenceDragState

    @State private var selectedEssence: Essence?
    @State private var fillProgress: CGFloat = 0
    @State private var lastDragLocation: CGPoint = .zero
    @StateObject private var hapticController = DragHapticController()

    private let fillDuration: TimeInterval = 1.0

    private var selectedPath: EvolutionPath? {
        selectedEssence.map { EvolutionPath.path(for: $0) }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top row: info + staging area
            HStack(spacing: 16) {
                // Close button
                if onClose != nil {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    if let path = selectedPath {
                        Text(path.displayName)
                            .font(.headline)
                    } else {
                        Text("Select an essence")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Drag to your pet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Staging area (right side, with border)
                EssenceStagingCard(
                    essence: selectedEssence,
                    fillProgress: fillProgress
                )
                .onLongPressGesture(
                    minimumDuration: fillDuration,
                    maximumDistance: 20,
                    pressing: { isPressing in
                        handlePressingChanged(isPressing)
                    },
                    perform: {
                        handleLongPressComplete()
                    }
                )
                .simultaneousGesture(dragGesture)
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Catalog - all essences
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Essence.allCases, id: \.self) { essence in
                        EssenceCatalogCard(
                            essence: essence,
                            isSelected: essence == selectedEssence
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedEssence = essence
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .onDisappear {
            hapticController.stop()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                lastDragLocation = value.location
                guard dragState.isDragging else { return }
                dragState.dragLocation = value.location
                updateDragHaptics(at: value.location)
            }
            .onEnded { value in
                lastDragLocation = value.location
                guard dragState.isDragging else { return }
                handleDragEnded(at: value.location)
            }
    }

    private func handlePressingChanged(_ isPressing: Bool) {
        guard selectedEssence != nil else { return }

        if isPressing {
            fillProgress = 0
            withAnimation(.linear(duration: fillDuration)) {
                fillProgress = 1
            }
            hapticController.startFilling()
        } else if !dragState.isDragging {
            withAnimation(.easeOut(duration: 0.2)) {
                fillProgress = 0
            }
            hapticController.stop()
        }
    }

    private func handleLongPressComplete() {
        guard let essence = selectedEssence else { return }
        dragState.isDragging = true
        dragState.dragLocation = lastDragLocation
        dragState.draggedEssence = essence
        hapticController.startDragging()
        updateDragHaptics(at: lastDragLocation)
    }

    private func handleDragEnded(at location: CGPoint) {
        defer {
            dragState.isDragging = false
            dragState.draggedEssence = nil
            hapticController.stop()
            withAnimation(.easeOut(duration: 0.2)) {
                fillProgress = 0
            }
        }

        guard let essence = selectedEssence else { return }
        guard let petDropFrame, petDropFrame.contains(location) else { return }

        onDropOnPet?(essence)
        selectedEssence = nil
        HapticType.notificationSuccess.trigger()
    }

    private func updateDragHaptics(at location: CGPoint) {
        guard let petDropFrame else {
            hapticController.updateIntensity(0.2)
            return
        }

        let center = CGPoint(x: petDropFrame.midX, y: petDropFrame.midY)
        let distance = hypot(location.x - center.x, location.y - center.y)
        let maxDistance = max(petDropFrame.width, petDropFrame.height) * 2.4
        let normalized = max(0, min(1, 1 - (distance / maxDistance)))
        let intensity = 0.15 + (normalized * 0.85)
        hapticController.updateIntensity(intensity)
    }
}

// MARK: - Staging Card

private struct EssenceStagingCard: View {
    let essence: Essence?
    let fillProgress: CGFloat

    private var path: EvolutionPath? {
        essence.map { EvolutionPath.path(for: $0) }
    }

    var body: some View {
        Group {
            if let essence {
                Image(essence.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.tertiary)
                    .frame(width: 60, height: 60)
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let themeColor = path?.themeColor ?? .secondary

        ZStack {
            baseBackground(themeColor: themeColor)
            if fillProgress > 0 {
                fillOverlay(themeColor: themeColor)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeColor.opacity(0.3), lineWidth: 2)
        }
    }

    @ViewBuilder
    private func baseBackground(themeColor: Color) -> some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    essence != nil
                        ? .regular.tint(themeColor.opacity(0.15))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(essence != nil ? themeColor.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func fillOverlay(themeColor: Color) -> some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let fillHeight = max(0, height * fillProgress)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeColor.opacity(0.45),
                            themeColor.opacity(0.18)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: fillHeight)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }
}

// MARK: - Catalog Card (Tappable)

private struct EssenceCatalogCard: View {
    let essence: Essence
    let isSelected: Bool
    let onTap: () -> Void

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .padding(12)
            .background(cardBackground)
            .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isSelected
                        ? .regular.tint(path.themeColor.opacity(0.15))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? path.themeColor.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? path.themeColor.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                }
        }
    }
}

struct EssenceDragPreview: View {
    let essence: Essence

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 56, height: 56)
            .padding(10)
            .background(previewBackground)
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 6)
    }

    @ViewBuilder
    private var previewBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(path.themeColor.opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(path.themeColor.opacity(0.25), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(path.themeColor.opacity(0.12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(path.themeColor.opacity(0.25), lineWidth: 1)
                }
        }
    }
}

private final class DragHapticController: ObservableObject {
    private var timer: Timer?
    private var generator = UIImpactFeedbackGenerator(style: .light)
    private var intensity: CGFloat = 0.2

    func startFilling() {
        start(style: .heavy, intensity: 0.9, interval: 0.08)
    }

    func startDragging() {
        start(style: .light, intensity: 0.2, interval: 0.15)
    }

    func updateIntensity(_ intensity: CGFloat) {
        self.intensity = max(0, min(1, intensity))
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func start(
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat,
        interval: TimeInterval
    ) {
        self.intensity = max(0, min(1, intensity))
        timer?.invalidate()
        generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    deinit {
        stop()
    }
}

#if DEBUG
#Preview {
    @Previewable @State var dragState = EssenceDragState()
    EssencePickerTray(dragState: $dragState)
}
#endif
