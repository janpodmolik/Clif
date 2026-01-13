import SwiftUI

struct PetDetailActions: View {
    let isBlob: Bool
    let canProgress: Bool       // canUseEssence for blob, canEvolve for evolved
    let daysUntilProgress: Int? // daysUntilEssence for blob, daysUntilEvolution for evolved
    let isBlownAway: Bool
    var onProgress: () -> Void = {}  // opens picker for blob, evolves for evolved
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
            progressSection

            Spacer()

            blowAwayButton
        }
        .padding()
        .glassCard()
    }

    @ViewBuilder
    private var progressSection: some View {
        if canProgress {
            progressButton
        } else if let days = daysUntilProgress {
            countdownLabel(days: days)
        } else {
            countdownLabel(days: 1)
        }
    }

    private var progressButton: some View {
        Button(action: onProgress) {
            HStack(spacing: 8) {
                Image(systemName: isBlob ? "leaf.fill" : "sparkles")
                Text(isBlob ? "Use Essence" : "Evolve!")
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

    private func countdownLabel(days: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isBlob ? "leaf.fill" : "sparkles")
            Text(countdownText(days: days))
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private func countdownText(days: Int) -> String {
        if isBlob {
            return days == 1 ? "Ready for Essence Tomorrow" : "Ready for Essence in \(days) days"
        } else {
            return days == 1 ? "Evolve Tomorrow" : "Evolve in \(days) days"
        }
    }

    private var blownAwayActions: some View {
        HStack(spacing: 16) {
            replayButton
            Spacer()
            deleteButton
        }
        .padding()
        .glassCard()
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
    ScrollView {
        VStack(spacing: 20) {
            // Blob - waiting for essence
            Text("Blob - Day 1").font(.caption)
            PetDetailActions(
                isBlob: true,
                canProgress: false,
                daysUntilProgress: 1,
                isBlownAway: false
            )

            // Blob - can use essence
            Text("Blob - Ready for Essence").font(.caption)
            PetDetailActions(
                isBlob: true,
                canProgress: true,
                daysUntilProgress: nil,
                isBlownAway: false
            )

            // Evolved - can evolve
            Text("Evolved - Can Evolve").font(.caption)
            PetDetailActions(
                isBlob: false,
                canProgress: true,
                daysUntilProgress: nil,
                isBlownAway: false
            )

            // Evolved - waiting
            Text("Evolved - Waiting").font(.caption)
            PetDetailActions(
                isBlob: false,
                canProgress: false,
                daysUntilProgress: 1,
                isBlownAway: false
            )

            // Blown away
            Text("Blown Away").font(.caption)
            PetDetailActions(
                isBlob: false,
                canProgress: false,
                daysUntilProgress: nil,
                isBlownAway: true
            )
        }
        .padding()
    }
}
#endif
