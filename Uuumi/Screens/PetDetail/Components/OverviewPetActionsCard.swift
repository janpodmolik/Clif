import SwiftUI

enum OverviewPetAction {
    case delete
    case showOnHomepage
}

/// Actions for viewing an active pet from the Overview screen.
struct OverviewPetActionsCard: View {
    let isBlownAway: Bool
    var onAction: (OverviewPetAction) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 16) {
            ActionButton(icon: "trash", label: "Delete", color: .red) {
                onAction(.delete)
            }
            if !isBlownAway {
                Spacer()
                ActionButton(icon: "house.fill", label: "Show", color: .green) {
                    onAction(.showOnHomepage)
                }
            }
        }
        .padding()
        .glassCard()
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
