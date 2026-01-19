import SwiftUI

/// Reusable action card for pet overview context.
/// Shows different buttons based on blown away state.
struct OverviewActionsCard: View {
    let isBlownAway: Bool
    let themeColor: Color
    var onDelete: () -> Void = {}
    var onShowOnHomepage: () -> Void = {}
    var onReplay: () -> Void = {}

    var body: some View {
        if isBlownAway {
            blownAwayActions
        } else {
            normalActions
        }
    }

    private var normalActions: some View {
        HStack(spacing: 16) {
            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onShowOnHomepage) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text("Zobrazit")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(themeColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeColor.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }

    private var blownAwayActions: some View {
        HStack(spacing: 16) {
            Button(action: onReplay) {
                HStack(spacing: 6) {
                    Image(systemName: "memories")
                    Text("Replay")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview("Normal") {
    VStack {
        OverviewActionsCard(
            isBlownAway: false,
            themeColor: .green
        )
    }
    .padding()
}

#Preview("Blown Away") {
    VStack {
        OverviewActionsCard(
            isBlownAway: true,
            themeColor: .green
        )
    }
    .padding()
}
#endif
