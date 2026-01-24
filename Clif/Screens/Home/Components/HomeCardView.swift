import SwiftUI

// MARK: - HomeCardAction

enum HomeCardAction {
    case detail
    case evolve
    case replay
    case delete
    case toggleShield
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

    // Pulsing for "Calm the Wind" button (when wind > 80% and shield NOT active)
    @State private var isButtonPulsing = false

    /// Whether shield is currently active (wind is decreasing).
    private var isShieldActive: Bool {
        SharedDefaults.isShieldActive
    }

    private var shouldButtonPulse: Bool {
        pet.windProgress > 0.8 && !isShieldActive
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
            buttonsRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if isShieldActive {
                isBreakPulsing = true
            }
            if shouldButtonPulse {
                isButtonPulsing = true
            }
        }
        .onChange(of: isShieldActive) { _, newValue in
            isBreakPulsing = newValue
        }
        .onChange(of: shouldButtonPulse) { _, newValue in
            isButtonPulsing = newValue
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

    // MARK: - Buttons Row

    @ViewBuilder
    private var buttonsRow: some View {
        if pet.isBlown {
            blownAwayContent
        } else {
            normalButtonsRow
        }
    }

    @ViewBuilder
    private var normalButtonsRow: some View {
        HStack {
            if pet.isEvolutionAvailable {
                evolveButton
            } else if let days = pet.daysUntilNextMilestone {
                evolutionCountdownLabel(days: days)
            }

            Spacer()

            breakButton
        }
    }

    // MARK: - Evolution Helpers

    private func evolutionCountdownLabel(days: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: pet.isBlob ? "leaf.fill" : "sparkles")
            Text(countdownText(days: days))
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }

    private func countdownText(days: Int) -> String {
        if pet.isBlob {
            return days == 1 ? "Ready for Essence Tomorrow" : "Ready for Essence in \(days) days"
        } else {
            return days == 1 ? "Evolve Tomorrow" : "Evolve in \(days) days"
        }
    }

    // MARK: - Blown Away Content

    private var blownAwayContent: some View {
        HStack(spacing: 12) {
            replayButton
            Spacer()
            deleteButton
        }
    }

    // MARK: - Shield Toggle Button

    private var breakButton: some View {
        Button { onAction(.toggleShield) } label: {
            Text(isShieldActive ? "Release the Wind" : "Calm the Wind")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.cyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.cyan.opacity(isShieldActive ? 0.15 : 0.2), in: Capsule())
                .opacity(shouldButtonPulse ? (isButtonPulsing ? 1.0 : 0.7) : 1.0)
                .scaleEffect(shouldButtonPulse ? (isButtonPulsing ? 1.05 : 1.0) : 1.0)
        }
        .buttonStyle(.plain)
        .animation(
            shouldButtonPulse ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
            value: isButtonPulsing
        )
    }

    // MARK: - Buttons

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

    private var replayButton: some View {
        ActionButton(icon: "memories", label: "Replay", color: .blue) {
            onAction(.replay)
        }
    }

    private var deleteButton: some View {
        ActionButton(icon: "trash", label: "Delete", color: .red) {
            onAction(.delete)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Pet") {
    HomeCardView(
        pet: .mock(),
        streakCount: 12,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}

#Preview("Pet - On Break") {
    HomeCardView(
        pet: .mockWithBreak(),
        streakCount: 5,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}

#Preview("Pet - High Wind") {
    HomeCardView(
        pet: .mock(windPoints: 85),
        streakCount: 3,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}
#endif
