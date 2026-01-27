import SwiftUI

// MARK: - HomeCardAction

enum HomeCardAction {
    case detail
    case evolve
    case replay
    case delete
}

// MARK: - Bump Size Preference Key

private struct BumpSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Layout Constants

private enum HomeCardLayout {
    // Card layout (must match HomeScreen values)
    static let cardInset: CGFloat = 16
    static let contentPadding: CGFloat = 20

    // Bump layout
    static let bumpHorizontalPadding: CGFloat = 12
    static let bumpVerticalPadding: CGFloat = 8
    static let bumpTransitionRadius: CGFloat = 16
}

// MARK: - Animation Constants

private enum HomeCardAnimation {
    // Main spring animation for bump shape (must match external animation)
    static let bumpSpring: Animation = .spring(duration: 0.4)
    // Bump content show animation (delayed to let shape grow first)
    static let contentShowDelay: Double = 0.15
    // Bump content hide animation duration (fast, before shape collapses)
    static let contentHideDuration: Double = 0.12
}

// MARK: - Bump Type

private enum BumpType: Equatable {
    case evolve(isBlob: Bool)
    case blown
}

// MARK: - HomeCardView

struct HomeCardView: View {
    let pet: Pet
    let streakCount: Int
    let showDetailButton: Bool
    /// Effective wind progress (0-1), passed from parent to ensure proper refresh
    var windProgress: CGFloat = 0
    var onAction: (HomeCardAction) -> Void = { _ in }

    @State private var isBreakPulsing = false
    /// Measured size of bump content. Not reset when bump hides (bumpWidth/bumpHeight return 0 via guard).
    @State private var bumpContentSize: CGSize = .zero
    @State private var showBumpContent = false
    /// Cached bump type to keep content visible during hide animation
    @State private var cachedBumpType: BumpType? = nil

    /// Whether shield is currently active (wind is decreasing).
    private var isShieldActive: Bool {
        SharedDefaults.isShieldActive
    }

    /// Concentric corner radius for inner elements (screen edge → card edge → content)
    private var innerCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: HomeCardLayout.cardInset + HomeCardLayout.contentPadding)
    }

    /// Corner radius of the card itself (concentric to screen edge)
    private var cardCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: HomeCardLayout.cardInset)
    }

    /// Current bump type based on pet state (nil when no bump should show)
    private var currentBumpType: BumpType? {
        if pet.isBlown {
            return .blown
        } else if pet.isEvolutionAvailable {
            return .evolve(isBlob: pet.isBlob)
        }
        return nil
    }

    /// Whether bump should be visible (driven by actual state for shape/layout animation)
    private var isBumpVisible: Bool {
        currentBumpType != nil
    }

    /// Calculated bump width based on content
    private var bumpWidth: CGFloat {
        guard isBumpVisible, bumpContentSize.width > 0 else { return 0 }
        return bumpContentSize.width + HomeCardLayout.bumpHorizontalPadding * 2
    }

    /// Calculated bump height based on content height + padding
    private var bumpHeight: CGFloat {
        guard isBumpVisible, bumpContentSize.height > 0 else { return 0 }
        return bumpContentSize.height + HomeCardLayout.bumpVerticalPadding * 2
    }

    /// Corner radius for bump ends (capsule style)
    private var bumpCornerRadius: CGFloat {
        bumpHeight / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            cardContent

            // Bump content (evolve button or blown actions)
            bumpContent
                .scaleEffect(showBumpContent ? 1 : 0.5)
                .opacity(showBumpContent ? 1 : 0)
                .overlay(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: BumpSizePreferenceKey.self,
                            value: geo.size
                        )
                    }
                )
                .frame(height: isBumpVisible ? nil : 0, alignment: .center)
                .padding(.vertical, isBumpVisible ? HomeCardLayout.bumpVerticalPadding : 0)
        }
        .background(
            .ultraThinMaterial,
            in: HomeCardWithBumpShape(
                cornerRadius: cardCornerRadius,
                bumpWidth: bumpWidth,
                bumpHeight: bumpHeight,
                bumpCornerRadius: bumpCornerRadius,
                transitionRadius: HomeCardLayout.bumpTransitionRadius
            )
        )
        .onPreferenceChange(BumpSizePreferenceKey.self) { size in
            // Only update if we have a valid measurement
            if size.width > 0, size.height > 0 {
                bumpContentSize = size
            }
        }
        .onAppear {
            if isShieldActive {
                isBreakPulsing = true
            }
            // Initialize cached bump type and show content immediately on appear (no animation needed)
            if let bumpType = currentBumpType {
                cachedBumpType = bumpType
                showBumpContent = true
            }
        }
        .onChange(of: isShieldActive) { _, newValue in
            isBreakPulsing = newValue
        }
        .onChange(of: currentBumpType) { oldValue, newValue in
            if let newType = newValue {
                // Show: update cache immediately, animate content after delay (let shape grow first)
                cachedBumpType = newType
                DispatchQueue.main.asyncAfter(deadline: .now() + HomeCardAnimation.contentShowDelay) {
                    withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                        showBumpContent = true
                    }
                }
            } else if oldValue != nil {
                // Hide: animate content out immediately (before shape collapses)
                withAnimation(.easeOut(duration: HomeCardAnimation.contentHideDuration)) {
                    showBumpContent = false
                }
                // Clear cache after shape animation completes (0.4s spring duration)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // Only clear if still hidden (no new bump appeared)
                    if currentBumpType == nil {
                        cachedBumpType = nil
                    }
                }
            }
        }
        // Animate bump shape changes (show/hide)
        .animation(HomeCardAnimation.bumpSpring, value: isBumpVisible)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tappable area above progress bar
            VStack(alignment: .leading, spacing: 12) {
                headerRow
                infoRow
                statsRow
            }
            .contentShape(Rectangle())
            .onTapGesture { onAction(.detail) }

            WindProgressBar(progress: Double(windProgress), isPulsing: isShieldActive)
        }
        .padding(HomeCardLayout.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bump Content

    @ViewBuilder
    private var bumpContent: some View {
        // Use cached bump type to keep content visible during hide animation
        if let bumpType = cachedBumpType {
            switch bumpType {
            case .blown:
                blownActions
                    .transition(.blurReplace)
            case .evolve(let isBlob):
                evolveButton(isBlob: isBlob)
                    .transition(.blurReplace)
            }
        }
    }

    private func evolveButton(isBlob: Bool) -> some View {
        Button { onAction(.evolve) } label: {
            HStack(spacing: 6) {
                Image(systemName: isBlob ? "leaf.fill" : "sparkles")
                Text(isBlob ? "Use Essence" : "Evolve!")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.green, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var blownActions: some View {
        HStack(spacing: 12) {
            Button { onAction(.replay) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "memories")
                    Text("Replay")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Button { onAction(.delete) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header Row (Pet Name + Mood + Detail)

    private var headerRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text(pet.name)
                    .font(.system(size: 20, weight: .semibold))

                Text(pet.mood.emoji)
                    .font(.system(size: 18))
            }

            Spacer()

            if showDetailButton {
                detailButton
            }
        }
    }

    private var detailButton: some View {
        Button { onAction(.detail) } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 30))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Row (Purpose + Evolution + Streak)

    private var infoRow: some View {
        HStack(spacing: 8) {
            if let purpose = pet.purpose, !purpose.isEmpty {
                Text(purpose)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !pet.isBlob {
                Text("🧬 \(pet.currentPhase)")
                    .font(.system(size: 14, weight: .semibold))
            }

            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            Text("\(streakCount)")
        }
        .font(.system(size: 14, weight: .semibold))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(Int(windProgress * 100))%")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(windProgress >= 1.0 ? .red : .primary)

            Spacer()

            if isShieldActive {
                Text("Calming the wind...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.cyan)
                    .opacity(isBreakPulsing ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isBreakPulsing
                    )
            }
        }
    }

}

// MARK: - Preview

#if DEBUG
#Preview("Bump Animation") {
    struct AnimatedPreview: View {
        @State private var showBump = true

        var body: some View {
            VStack(spacing: 24) {
                HomeCardView(
                    pet: .mock(phase: showBump ? 2 : 4), // phase 2 = can evolve, phase 4 = max
                    streakCount: 12,
                    showDetailButton: true,
                    windProgress: 0.45
                )

                Button(showBump ? "Hide Bump" : "Show Bump") {
                    showBump.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }
    return AnimatedPreview()
}

#Preview("With Evolve Bump") {
    HomeCardView(
        pet: .mock(phase: 2),
        streakCount: 12,
        showDetailButton: true,
        windProgress: 0.45
    )
    .padding(16)
    .padding(.bottom, 40)
}

#Preview("Max Phase (No Bump)") {
    HomeCardView(
        pet: .mock(phase: 4),
        streakCount: 5,
        showDetailButton: true,
        windProgress: 0.3
    )
    .padding(16)
}

#Preview("Blob with Essence") {
    HomeCardView(
        pet: .mockBlob(canUseEssence: true),
        streakCount: 2,
        showDetailButton: true,
        windProgress: 0.2
    )
    .padding(16)
    .padding(.bottom, 40)
}

#Preview("Blown Pet") {
    HomeCardView(
        pet: .mockBlown(),
        streakCount: 8,
        showDetailButton: true,
        windProgress: 1.0
    )
    .padding(16)
    .padding(.bottom, 40)
}

#Preview("State Transitions") {
    enum PetState: String, CaseIterable {
        case normal = "Normal (no bump)"
        case canEvolve = "Can Evolve"
        case blown = "Blown"
    }

    struct StatePreview: View {
        @State private var state: PetState = .canEvolve

        private var pet: Pet {
            switch state {
            case .normal:
                return .mock(phase: 4) // max phase, no evolution available
            case .canEvolve:
                return .mock(phase: 2)
            case .blown:
                return .mockBlown()
            }
        }

        var body: some View {
            VStack(spacing: 24) {
                HomeCardView(
                    pet: pet,
                    streakCount: 7,
                    showDetailButton: true,
                    windProgress: 0.45
                )

                Picker("State", selection: $state) {
                    ForEach(PetState.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }

    return StatePreview()
}
#endif
