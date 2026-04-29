import SwiftUI

enum OverviewPetAction {
    case delete
    case showOnHomepage
    case replay
}

/// Actions for viewing an active pet from the Overview screen.
/// Shows delete + show on homepage, or replay + delete when blown away.
struct OverviewPetActionsCard: View {
    let isBlownAway: Bool
    var onAction: (OverviewPetAction) -> Void = { _ in }

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
            ActionButton(icon: "trash", label: "Delete", color: .red) {
                onAction(.delete)
            }
            Spacer()
            ActionButton(icon: "house.fill", label: "Show", color: .green) {
                onAction(.showOnHomepage)
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
#Preview("Normal") {
    OverviewPetActionsCard(
        isBlownAway: false
    )
    .padding()
}

#Preview("Blown away") {
    OverviewPetActionsCard(
        isBlownAway: true
    )
    .padding()
}
#endif
