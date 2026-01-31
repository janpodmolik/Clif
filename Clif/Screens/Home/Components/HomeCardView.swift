import FamilyControls
import ManagedSettings
import SwiftUI

// MARK: - HomeCardAction

enum HomeCardAction {
    case detail
    case evolve
    case replay
    case delete
    case archive
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
    case archive
}

// MARK: - Debug Bump State

#if DEBUG
enum DebugBumpState: String, CaseIterable {
    case actual = "Actual"
    case evolve = "Evolve"
    case archive = "Archive"
    case blown = "Blown"
    case hidden = "Hidden"
}
#endif

// MARK: - HomeCardView

struct HomeCardView: View {
    let pet: Pet
    let streakCount: Int
    let showDetailButton: Bool
    /// Effective wind progress (0-1), passed from parent to ensure proper refresh
    var windProgress: CGFloat = 0
    #if DEBUG
    /// Debug override for bump state testing
    var debugBumpState: DebugBumpState = .actual
    #endif
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
        #if DEBUG
        switch debugBumpState {
        case .actual:
            return actualBumpType
        case .evolve:
            return .evolve(isBlob: pet.isBlob)
        case .archive:
            return .archive
        case .blown:
            return .blown
        case .hidden:
            return nil
        }
        #else
        return actualBumpType
        #endif
    }

    /// Actual bump type based on real pet state
    private var actualBumpType: BumpType? {
        if pet.isBlown {
            return .blown
        } else if pet.isEvolutionAvailable {
            return .evolve(isBlob: pet.isBlob)
        } else if pet.isFullyEvolved {
            return .archive
        }
        return nil
    }

    /// Whether bump should be visible (driven by actual state for shape/layout animation)
    private var isBumpVisible: Bool {
        currentBumpType != nil
    }

    /// Target bump width (non-zero when bump should be visible and measured)
    private var targetBumpWidth: CGFloat {
        guard isBumpVisible, bumpContentSize.width > 0 else { return 0 }
        return bumpContentSize.width + HomeCardLayout.bumpHorizontalPadding * 2
    }

    /// Target bump height (non-zero when bump should be visible and measured)
    private var targetBumpHeight: CGFloat {
        guard isBumpVisible, bumpContentSize.height > 0 else { return 0 }
        return bumpContentSize.height + HomeCardLayout.bumpVerticalPadding * 2
    }

    /// Animated bump width - use @State to enable smooth animation
    @State private var animatedBumpWidth: CGFloat = 0
    /// Animated bump height - use @State to enable smooth animation
    @State private var animatedBumpHeight: CGFloat = 0

    /// Corner radius for bump ends (capsule style)
    private var bumpCornerRadius: CGFloat {
        animatedBumpHeight / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            cardContent

            // Bump content (evolve button or blown actions)
            // Always render for measurement, but clip to animated height
            bumpContent
                .scaleEffect(showBumpContent ? 1 : 0.5)
                .opacity(showBumpContent ? 1 : 0)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: BumpSizePreferenceKey.self,
                            value: geo.size
                        )
                    }
                )
                // Use animated height for smooth transition
                .frame(height: animatedBumpHeight > 0 ? animatedBumpHeight : nil)
                .frame(height: animatedBumpHeight, alignment: .center)
                .clipped()
        }
        .background(
            .ultraThinMaterial,
            in: HomeCardWithBumpShape(
                cornerRadius: cardCornerRadius,
                bumpWidth: animatedBumpWidth,
                bumpHeight: animatedBumpHeight,
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
            // Initialize cached bump type and dimensions immediately on appear (no animation needed)
            if let bumpType = currentBumpType {
                cachedBumpType = bumpType
                showBumpContent = true
                animatedBumpWidth = targetBumpWidth
                animatedBumpHeight = targetBumpHeight
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
        // Animate bump dimensions when target changes
        .onChange(of: targetBumpWidth) { _, newValue in
            withAnimation(HomeCardAnimation.bumpSpring) {
                animatedBumpWidth = newValue
            }
        }
        .onChange(of: targetBumpHeight) { _, newValue in
            withAnimation(HomeCardAnimation.bumpSpring) {
                animatedBumpHeight = newValue
            }
        }
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
            case .archive:
                archiveBumpButton
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

    private var archiveBumpButton: some View {
        Button { onAction(.archive) } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                Text("Archive")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(pet.themeColor, in: Capsule())
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

    // MARK: - Header Row (Pet Name + Purpose + Detail)

    private var headerRow: some View {
        HStack {
            HStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 20, weight: .semibold))

                if let purpose = pet.purpose, !purpose.isEmpty {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(purpose)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .font(.system(size: 20, weight: .semibold))

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
            LimitedSourcesPreview(
                applicationTokens: pet.applicationTokens,
                categoryTokens: pet.categoryTokens,
                webDomainTokens: pet.webDomainTokens
            )

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
            if let activeBreak = pet.activeBreak {
                breakCountdownView(activeBreak)
                    .transition(.blurReplace)
            } else if pet.isBlown {
                Text("Blown away!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .transition(.blurReplace)
            }

            Spacer()

            Text("\(Int(windProgress * 100))%")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(windProgressColor)
        }
        .animation(.easeInOut(duration: 0.3), value: isShieldActive)
    }

    private var windProgressColor: Color {
        if windProgress >= 1.0 {
            return .red
        } else if isShieldActive {
            let isSafety = SharedDefaults.activeBreakType == .safety
            return isSafety && windProgress >= 0.8 ? .red : .cyan
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private func breakCountdownView(_ activeBreak: ActiveBreak) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let remaining = activeBreak.remainingSeconds {
                // Committed break: countdown
                Text(formatTime(remaining))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .contentTransition(.identity)
                Text("left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Free break: elapsed time
                Text(formatTime(activeBreak.elapsedMinutes * 60))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .contentTransition(.identity)
                Text("on break")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(isBreakPulsing ? 1.0 : 0.6)
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isBreakPulsing
        )
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
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
