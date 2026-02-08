import SwiftUI

struct WindPresetStep: View {
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
                ForEach(WindPreset.allCases, id: \.self) { preset in
                    WindPresetCard(
                        preset: preset,
                        isSelected: coordinator.preset == preset,
                        onTap: { coordinator.preset = preset }
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

// MARK: - Wind Preset Card

private struct WindPresetCard: View {
    let preset: WindPreset
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
                    Text(preset.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(preset.minutesToBlowAway)) min")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(preset.themeColor)

                    Text("to blow away")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(preset.themeColor)
                    .font(.title3)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(Layout.padding)
            .contentShape(Rectangle())
            .glassSelectableBackground(
                cornerRadius: Layout.cornerRadius,
                isSelected: isSelected,
                tintColor: preset.themeColor
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Image(systemName: preset.iconName)
            .font(.title3)
            .foregroundStyle(preset.themeColor)
            .frame(width: 28, height: 28)
    }
}

#if DEBUG
#Preview {
    WindPresetStep()
        .environment(CreatePetCoordinator())
}
#endif
