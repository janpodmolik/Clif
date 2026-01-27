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

// MARK: - HomeCardView

struct HomeCardView: View {
    let pet: Pet
    let streakCount: Int
    let showDetailButton: Bool
    /// Refresh trigger from parent (increments when shield state changes or timer ticks)
    var refreshTick: Int = 0
    var onAction: (HomeCardAction) -> Void = { _ in }

    // Pulsing for "Calming the wind..." text (when shield active)
    @State private var isBreakPulsing = false
    @State private var evolveButtonSize: CGSize = .zero

    /// Whether shield is currently active (wind is decreasing).
    private var isShieldActive: Bool {
        SharedDefaults.isShieldActive
    }

    // Layout constants (must match HomeScreen values)
    private let cardInset: CGFloat = 16 // Distance from screen edge to card
    private let contentPadding: CGFloat = 20

    // Bump layout constants
    private let bumpHorizontalPadding: CGFloat = 12
    private let bumpVerticalPadding: CGFloat = 8
    private let bumpTransitionRadius: CGFloat = 16

    /// Concentric corner radius for inner elements (screen edge → card edge → content)
    private var innerCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: cardInset + contentPadding)
    }

    /// Corner radius of the card itself (concentric to screen edge)
    private var cardCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: cardInset)
    }

    /// Whether to show the evolve button bump
    private var showEvolveBump: Bool {
        pet.isEvolutionAvailable && !pet.isBlown
    }

    /// Calculated bump width based on button content
    private var bumpWidth: CGFloat {
        guard showEvolveBump, evolveButtonSize.width > 0 else { return 0 }
        return evolveButtonSize.width + bumpHorizontalPadding * 2
    }

    /// Calculated bump height based on button height + padding
    private var bumpHeight: CGFloat {
        guard showEvolveBump, evolveButtonSize.height > 0 else { return 0 }
        return evolveButtonSize.height + bumpVerticalPadding * 2
    }

    /// Corner radius for bump ends (capsule style)
    private var bumpCornerRadius: CGFloat {
        bumpHeight / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            cardContent

            // Evolve button in bump area
            if showEvolveBump {
                evolveButton
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: BumpSizePreferenceKey.self,
                                value: geo.size
                            )
                        }
                    )
                    .padding(.vertical, bumpVerticalPadding)
            }
        }
        .background(
            .ultraThinMaterial,
            in: HomeCardWithBumpShape(
                cornerRadius: cardCornerRadius,
                bumpWidth: bumpWidth,
                bumpHeight: bumpHeight,
                bumpCornerRadius: bumpCornerRadius,
                transitionRadius: bumpTransitionRadius
            )
        )
        .onPreferenceChange(BumpSizePreferenceKey.self) { size in
            evolveButtonSize = size
        }
        .onAppear {
            if isShieldActive {
                isBreakPulsing = true
            }
        }
        .onChange(of: isShieldActive) { _, newValue in
            isBreakPulsing = newValue
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

            ProgressBarView(progress: Double(pet.windProgress), isPulsing: isShieldActive)
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Evolve Button

    private var evolveButton: some View {
        Button { onAction(.evolve) } label: {
            HStack(spacing: 6) {
                Image(systemName: pet.isBlob ? "leaf.fill" : "sparkles")
                Text(pet.isBlob ? "Use Essence" : "Evolve!")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.green, in: Capsule())
        }
        .buttonStyle(.plain)
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
            Text("\(Int(pet.windProgress * 100))%")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(pet.windProgress >= 1.0 ? .red : .primary)

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
                    showDetailButton: true
                )
                .animation(.spring(duration: 0.4), value: showBump)

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
        showDetailButton: true
    )
    .padding(16)
    .padding(.bottom, 40)
}

#Preview("Max Phase (No Bump)") {
    HomeCardView(
        pet: .mock(phase: 4),
        streakCount: 5,
        showDetailButton: true
    )
    .padding(16)
}

#Preview("Blob with Essence") {
    HomeCardView(
        pet: .mockBlob(canUseEssence: true),
        streakCount: 2,
        showDetailButton: true
    )
    .padding(16)
    .padding(.bottom, 40)
}
#endif
