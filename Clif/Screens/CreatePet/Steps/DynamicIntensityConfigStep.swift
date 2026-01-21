import SwiftUI

struct DynamicIntensityConfigStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 8) {
            Text("Choose intensity")
                .font(.title3.weight(.semibold))

            Text("How challenging should it be?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(DynamicModeConfig.allCases, id: \.self) { config in
                    DynamicConfigCard(
                        config: config,
                        isSelected: coordinator.dynamicConfig == config,
                        onTap: { coordinator.dynamicConfig = config }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - Dynamic Config Card

private struct DynamicConfigCard: View {
    let config: DynamicModeConfig
    let isSelected: Bool
    let onTap: () -> Void

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(config.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(config.minutesToBlowAway)) min")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(config.themeColor)

                    Text("to blow away")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(config.themeColor)
                    .font(.title3)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(Layout.padding)
            .contentShape(Rectangle())
            .glassSelectableBackground(
                cornerRadius: Layout.cornerRadius,
                isSelected: isSelected,
                tintColor: config.themeColor
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Image(systemName: config.iconName)
            .font(.title3)
            .foregroundStyle(config.themeColor)
            .frame(width: 28, height: 28)
    }
}

#if DEBUG
#Preview {
    DynamicIntensityConfigStep()
        .environment(CreatePetCoordinator())
}
#endif
