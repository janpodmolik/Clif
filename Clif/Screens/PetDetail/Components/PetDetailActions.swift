import SwiftUI

struct PetDetailActions: View {
    let canEvolve: Bool
    let daysUntilEvolution: Int?
    let isBlownAway: Bool
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        if isBlownAway {
            blownAwayActions
        } else {
            normalActions
        }
    }

    private var normalActions: some View {
        HStack(spacing: 16) {
            if canEvolve {
                evolveButton
            } else if let days = daysUntilEvolution {
                evolutionCountdownLabel(days: days)
            }

            Spacer()

            blowAwayButton
        }
        .padding()
        .glassCard()
    }

    private func evolutionCountdownLabel(days: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text(days == 1 ? "Evolve Tomorrow" : "Evolve in \(days) days")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private var blownAwayActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                replayButton
                Spacer()
                deleteButton
            }
        }
        .padding()
        .glassCard()
    }

    private var evolveButton: some View {
        Button(action: onEvolve) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Evolve!")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
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
        Button(action: onBlowAway) {
            HStack(spacing: 6) {
                Image(systemName: "wind")
                Text("Blow Away")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var replayButton: some View {
        Button(action: onReplay) {
            HStack(spacing: 6) {
                Image(systemName: "memories")
                Text("Replay Blow")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        PetDetailActions(
            canEvolve: true,
            daysUntilEvolution: nil,
            isBlownAway: false
        )

        PetDetailActions(
            canEvolve: false,
            daysUntilEvolution: 1,
            isBlownAway: false
        )

        PetDetailActions(
            canEvolve: false,
            daysUntilEvolution: 3,
            isBlownAway: false
        )

        PetDetailActions(
            canEvolve: false,
            daysUntilEvolution: nil,
            isBlownAway: true
        )
    }
    .padding()
}
#endif
