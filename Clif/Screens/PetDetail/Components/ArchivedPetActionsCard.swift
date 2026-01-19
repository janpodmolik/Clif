import SwiftUI

enum ArchivedPetAction {
    case delete
    case showOnHomepage
    case replay
}

/// Actions for archived/historical pets in overview.
/// Shows delete + show on homepage, or replay + delete when blown away.
struct ArchivedPetActionsCard: View {
    let isBlownAway: Bool
    let themeColor: Color
    var onAction: (ArchivedPetAction) -> Void = { _ in }

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
            ActionButton(icon: "trash", label: "Smazat", color: .red) {
                onAction(.delete)
            }
            Spacer()
            ActionButton(icon: "house.fill", label: "Zobrazit", color: themeColor) {
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
    ArchivedPetActionsCard(
        isBlownAway: false,
        themeColor: .green
    )
    .padding()
}

#Preview("Blown away") {
    ArchivedPetActionsCard(
        isBlownAway: true,
        themeColor: .green
    )
    .padding()
}
#endif
