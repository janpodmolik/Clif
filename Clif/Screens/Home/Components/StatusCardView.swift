import SwiftUI

struct StatusCardContentView: View {
    // MARK: - Screen Time Properties
    let streakCount: Int
    let usedTimeText: String
    let dailyLimitText: String
    let progress: Double

    // MARK: - Pet Identity Properties
    let petName: String
    let evolutionStage: Int
    let maxEvolutionStage: Int
    let mood: Mood
    let purposeLabel: String?

    // MARK: - Button State
    let isEvolutionAvailable: Bool
    let isSaveEnabled: Bool
    let showDetailButton: Bool
    let isBlownAway: Bool

    // MARK: - Actions
    var onDetailTapped: () -> Void = {}
    var onEvolveTapped: () -> Void = {}
    var onSavePetTapped: () -> Void = {}
    var onBlowAwayTapped: () -> Void = {}
    var onReplayTapped: () -> Void = {}
    var onDeleteTapped: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            infoRow
            timeRow
            ProgressBarView(progress: progress)
            buttonsRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header Row (Pet Name + Mood + Detail)

    private var headerRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text(petName)
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
        switch mood {
        case .happy: return "😌"
        case .neutral: return "😐"
        case .sad: return "😞"
        case .blown: return "😵"
        }
    }

    private var detailButton: some View {
        Button(action: onDetailTapped) {
            Image(systemName: "ellipsis")
                .font(.system(size: 30))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Row (Purpose + Evolution + Streak)

    private var infoRow: some View {
        HStack(spacing: 8) {
            if let purposeLabel, !purposeLabel.isEmpty {
                Text(purposeLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("🧬 \(evolutionStage)")
                .font(.system(size: 14, weight: .semibold))

            streakBadge
        }
    }

    private var evolutionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(streakCount)")
        }
        .font(.system(size: 14, weight: .semibold))
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(streakCount)")
        }
        .font(.system(size: 14, weight: .semibold))
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(usedTimeText)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)

            Text("/")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Text(dailyLimitText)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(progress > 1.0 ? .red : .secondary)
        }
    }

    // MARK: - Buttons Row

    @ViewBuilder
    private var buttonsRow: some View {
        if isBlownAway {
            blownAwayContent
        } else {
            normalButtonsRow
        }
    }

    private var normalButtonsRow: some View {
        HStack(spacing: 12) {
            if isEvolutionAvailable {
                evolveButton
            }

            Spacer()

            blowAwayButton
        }
    }

    private var blownAwayContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Uuumi couldn't withstand the strong winds and was blown away.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)

            HStack(spacing: 12) {
                replayButton

                Spacer()

                deleteButton
            }
        }
    }

    private var evolveButton: some View {
        Button(action: onEvolveTapped) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Evolve!")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private var blowAwayButton: some View {
        Button(action: onBlowAwayTapped) {
            HStack(spacing: 6) {
                Image(systemName: "wind")
                Text("Blow Away")
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

    private var replayButton: some View {
        Button(action: onReplayTapped) {
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
        Button(action: onDeleteTapped) {
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
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        StatusCardDebugView()
    }
}
#endif
