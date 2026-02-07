import SwiftUI

enum ActivePetAction {
    case progress
    case blowAway
    case replay
    case delete
    case archive
}

/// Actions for the currently active pet on homepage.
/// Shows progress (evolve/essence) + blow away, or replay + delete when blown away.
struct ActivePetActionsCard: View {
    let isBlob: Bool
    let isFullyEvolved: Bool
    let canProgress: Bool
    let canArchiveEarly: Bool
    let isBlownAway: Bool
    var themeColor: Color = .green
    var onAction: (ActivePetAction) -> Void = { _ in }

    @State private var showBlowAwayConfirmation = false

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
        .sheet(isPresented: $showBlowAwayConfirmation) {
            BlowAwaySheet {
                onAction(.blowAway)
            }
        }
    }

    private var normalActions: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                ActionButton(icon: "wind", label: "Blow Away", color: .red) {
                    showBlowAwayConfirmation = true
                }
                if canArchiveEarly {
                    ActionButton(icon: "archivebox", label: "Archive", color: .secondary) {
                        onAction(.archive)
                    }
                }
            }
            Spacer()
            progressSection
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if isFullyEvolved {
            ActionButton(icon: "checkmark.seal.fill", label: "Archive", color: themeColor) {
                onAction(.archive)
            }
        } else if canProgress {
            ActionButton(icon: isBlob ? "leaf.fill" : "sparkles", label: isBlob ? "Use Essence" : "Evolve!", color: .green) {
                onAction(.progress)
            }
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
#Preview("Waiting") {
    ActivePetActionsCard(
        isBlob: false,
        isFullyEvolved: false,
        canProgress: false,
        canArchiveEarly: false,
        isBlownAway: false
    )
    .padding()
}

#Preview("Can use essence") {
    ActivePetActionsCard(
        isBlob: true,
        isFullyEvolved: false,
        canProgress: true,
        canArchiveEarly: false,
        isBlownAway: false
    )
    .padding()
}

#Preview("Can evolve") {
    ActivePetActionsCard(
        isBlob: false,
        isFullyEvolved: false,
        canProgress: true,
        canArchiveEarly: false,
        isBlownAway: false
    )
    .padding()
}

#Preview("Early Archive") {
    ActivePetActionsCard(
        isBlob: false,
        isFullyEvolved: false,
        canProgress: false,
        canArchiveEarly: true,
        isBlownAway: false
    )
    .padding()
}

#Preview("Fully Evolved") {
    ActivePetActionsCard(
        isBlob: false,
        isFullyEvolved: true,
        canProgress: false,
        canArchiveEarly: false,
        isBlownAway: false,
        themeColor: .green
    )
    .padding()
}

#Preview("Blown away") {
    ActivePetActionsCard(
        isBlob: false,
        isFullyEvolved: false,
        canProgress: false,
        canArchiveEarly: false,
        isBlownAway: true
    )
    .padding()
}
#endif
