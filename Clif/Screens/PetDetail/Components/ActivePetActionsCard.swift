import SwiftUI

enum ActivePetAction {
    case progress
    case blowAway
    case replay
    case delete
}

/// Actions for the currently active pet on homepage.
/// Shows progress (evolve/essence) + blow away, or replay + delete when blown away.
struct ActivePetActionsCard: View {
    let isBlob: Bool
    let canProgress: Bool
    let daysUntilProgress: Int?
    let isBlownAway: Bool
    var onAction: (ActivePetAction) -> Void = { _ in }

    var body: some View {
        Group {
            if isBlownAway {
                blownAwayActions
            } else {
                normalActions
            }
        }
        .padding()
        .glassCard()
    }

    private var normalActions: some View {
        HStack(spacing: 16) {
            progressSection
            Spacer()
            ActionButton(icon: "wind", label: "Blow Away", color: .red) {
                onAction(.blowAway)
            }
        }
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
        Button { onAction(.progress) } label: {
            HStack(spacing: 8) {
                Image(systemName: isBlob ? "leaf.fill" : "sparkles")
                Text(isBlob ? "Use Essence" : "Evolve!")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.green, in: Capsule())
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
            ActionButton(icon: "memories", label: "Replay", color: .blue) {
                onAction(.replay)
            }
            Spacer()
            ActionButton(icon: "trash", label: "Delete", color: .red) {
                onAction(.delete)
            }
        }
    }
}

#if DEBUG
#Preview("Blob waiting") {
    ActivePetActionsCard(
        isBlob: true,
        canProgress: false,
        daysUntilProgress: 1,
        isBlownAway: false
    )
    .padding()
}

#Preview("Can use essence") {
    ActivePetActionsCard(
        isBlob: true,
        canProgress: true,
        daysUntilProgress: nil,
        isBlownAway: false
    )
    .padding()
}

#Preview("Can evolve") {
    ActivePetActionsCard(
        isBlob: false,
        canProgress: true,
        daysUntilProgress: nil,
        isBlownAway: false
    )
    .padding()
}

#Preview("Blown away") {
    ActivePetActionsCard(
        isBlob: false,
        canProgress: false,
        daysUntilProgress: nil,
        isBlownAway: true
    )
    .padding()
}
#endif
