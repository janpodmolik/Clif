import SwiftUI

// MARK: - HomeCardAction

enum HomeCardAction {
    case detail
    case evolve
    case replay
    case delete
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

    /// Whether shield is currently active (wind is decreasing).
    private var isShieldActive: Bool {
        SharedDefaults.isShieldActive
    }

    // Layout constants (must match HomeScreen values)
    private let cardInset: CGFloat = 16 // Distance from screen edge to card
    private let contentPadding: CGFloat = 20

    /// Concentric corner radius for inner elements (screen edge → card edge → content)
    private var innerCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: cardInset + contentPadding)
    }

    /// Corner radius of the card itself (concentric to screen edge)
    private var cardCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: cardInset)
    }

    var body: some View {
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
        .onAppear {
            if isShieldActive {
                isBreakPulsing = true
            }
        }
        .onChange(of: isShieldActive) { _, newValue in
            isBreakPulsing = newValue
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
private let previewCardCornerRadius = DeviceMetrics.concentricCornerRadius(inset: 16)

#Preview("Pet") {
    HomeCardView(
        pet: .mock(),
        streakCount: 12,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: previewCardCornerRadius))
    .padding(16)
}

#Preview("Pet - On Break") {
    HomeCardView(
        pet: .mockWithBreak(),
        streakCount: 5,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: previewCardCornerRadius))
    .padding(16)
}

#Preview("Pet - High Wind") {
    HomeCardView(
        pet: .mock(windPoints: 85),
        streakCount: 3,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: previewCardCornerRadius))
    .padding(16)
}
#endif
