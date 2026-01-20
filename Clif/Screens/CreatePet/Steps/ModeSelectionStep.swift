import SwiftUI

struct ModeSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        static let cardSpacing: CGFloat = 16
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let iconSize: CGFloat = 40
    }

    var body: some View {
        @Bindable var coordinator = coordinator

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
        static let selectedTint: CGFloat = 0.15
    }

    private var themeColor: Color {
        switch mode {
        case .daily: .blue
        case .dynamic: .orange
        }
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
                    .foregroundStyle(themeColor)
                    .font(.title2)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(Layout.padding)
            .contentShape(Rectangle())
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Image(systemName: mode.iconName)
            .font(.title2)
            .foregroundStyle(themeColor)
            .frame(width: Layout.iconSize, height: Layout.iconSize)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Layout.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isSelected
                        ? .regular.tint(themeColor.opacity(Layout.selectedTint))
                        : .regular,
                    in: shape
                )
                .overlay {
                    shape.stroke(
                        isSelected ? themeColor.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
                }
        } else {
            shape
                .fill(isSelected ? themeColor.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        isSelected ? themeColor.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
                }
        }
    }
}

// MARK: - PetMode Extensions

private extension PetMode {
    var displayName: String {
        switch self {
        case .daily: "Daily Limit"
        case .dynamic: "Dynamic Mode"
        }
    }

    var description: String {
        switch self {
        case .daily: "Set a fixed daily time limit. Simple and predictable."
        case .dynamic: "Wind rises while using apps, take breaks to recover."
        }
    }

    var iconName: String {
        switch self {
        case .daily: "clock.fill"
        case .dynamic: "wind"
        }
    }
}

#if DEBUG
#Preview {
    ModeSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
