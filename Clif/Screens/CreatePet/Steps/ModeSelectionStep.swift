import SwiftUI

struct ModeSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        static let cardSpacing: CGFloat = 16
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Choose your mode")
                .font(.title3.weight(.semibold))

            Text("How do you want to manage your screen time?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: Layout.cardSpacing) {
                ModeOptionCard(
                    mode: .daily,
                    isSelected: coordinator.selectedMode == .daily,
                    onTap: { coordinator.selectedMode = .daily }
                )

                ModeOptionCard(
                    mode: .dynamic,
                    isSelected: coordinator.selectedMode == .dynamic,
                    onTap: { coordinator.selectedMode = .dynamic }
                )
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - Mode Option Card

private struct ModeOptionCard: View {
    let mode: PetMode
    let isSelected: Bool
    let onTap: () -> Void

    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let padding: CGFloat = 16
        static let iconSize: CGFloat = 36
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                iconView

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(mode.themeColor)
                    .font(.title2)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(Layout.padding)
            .contentShape(Rectangle())
            .glassSelectableBackground(
                cornerRadius: Layout.cornerRadius,
                isSelected: isSelected,
                tintColor: mode.themeColor
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Image(systemName: mode.iconName)
            .font(.title2)
            .foregroundStyle(mode.themeColor)
            .frame(width: Layout.iconSize, height: Layout.iconSize)
    }
}

#if DEBUG
#Preview {
    ModeSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
