import SwiftUI

// MARK: - HomeCardAction

enum HomeCardAction {
    case detail
    case evolve
    case replay
    case delete
    case startBreak
}

// MARK: - HomeCardView

struct HomeCardView: View {
    let pet: ActivePet
    let streakCount: Int
    let showDetailButton: Bool
    var onAction: (HomeCardAction) -> Void = { _ in }

    // Pulsing for "Calming the wind..." text (when on break)
    @State private var isBreakPulsing = false

    // Pulsing for "Calm the Wind" button (when wind > 80% and NOT on break)
    @State private var isButtonPulsing = false

    private var shouldButtonPulse: Bool {
        pet.windProgress > 0.8 && !pet.isOnBreak
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

            ProgressBarView(progress: Double(pet.windProgress), isPulsing: pet.isOnBreak)
            buttonsRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if pet.isOnBreak {
                isBreakPulsing = true
            }
            if shouldButtonPulse {
                isButtonPulsing = true
            }
        }
        .onChange(of: pet.isOnBreak) { _, newValue in
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

                Text(moodEmoji)
                    .font(.system(size: 18))
            }

            Spacer()

            if showDetailButton {
                detailButton
            }
        }
    }

    private var moodEmoji: String {
        switch pet.mood {
        case .happy: "😄"
        case .neutral: "🙂"
        case .sad: "😞"
        case .blown: "😵"
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

    // MARK: - Stats Row (Mode-Specific)

    @ViewBuilder
    private var statsRow: some View {
        switch pet {
        case .daily(let dailyPet):
            dailyStatsRow(dailyPet)
        case .dynamic(let dynamicPet):
            dynamicStatsRow(dynamicPet)
        }
    }

    private func dailyStatsRow(_ pet: DailyPet) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(formatMinutes(pet.todayUsedMinutes))
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)

            Text("/")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Text(formatMinutes(pet.dailyLimitMinutes))
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(pet.windProgress * 100))%")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(pet.windProgress > 1.0 ? .red : .primary)
        }
    }

    private func dynamicStatsRow(_ pet: DynamicPet) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(Int(pet.windProgress * 100))%")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(pet.windProgress >= 1.0 ? .red : .primary)

            Spacer()

            if pet.activeBreak != nil {
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

            if case .dynamic(let dynamicPet) = pet {
                breakButton(for: dynamicPet)
            }
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

    // MARK: - Break Button

    @ViewBuilder
    private func breakButton(for pet: DynamicPet) -> some View {
        let isOnBreak = pet.activeBreak != nil

        Button { onAction(.startBreak) } label: {
            Text(isOnBreak ? "Release the Wind" : "Calm the Wind")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.cyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.cyan.opacity(isOnBreak ? 0.15 : 0.2), in: Capsule())
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
        Button { onAction(.replay) } label: {
            HStack(spacing: 6) {
                Image(systemName: "memories")
                Text("Replay")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color.blue.opacity(0.15),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button { onAction(.delete) } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color.red.opacity(0.15),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Daily Pet") {
    HomeCardView(
        pet: .daily(.mock()),
        streakCount: 7,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}

#Preview("Dynamic Pet") {
    HomeCardView(
        pet: .dynamic(.mock()),
        streakCount: 12,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}

#Preview("Dynamic Pet - On Break") {
    HomeCardView(
        pet: .dynamic(.mockWithBreak()),
        streakCount: 5,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}

#Preview("Dynamic Pet - High Wind") {
    HomeCardView(
        pet: .dynamic(.mock(windPoints: 85)),
        streakCount: 3,
        showDetailButton: true
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}
#endif
