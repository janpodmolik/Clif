import SwiftUI

struct DynamicModeSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

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
        static let selectedTint: CGFloat = 0.15
    }

    private var themeColor: Color {
        switch config {
        case .gentle: .green
        case .balanced: .orange
        case .intense: .red
        }
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
                        .foregroundStyle(themeColor)

                    Text("to blow away")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(themeColor)
                    .font(.title3)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(Layout.padding)
            .contentShape(Rectangle())
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(themeColor)
            .frame(width: 28, height: 28)
    }

    private var iconName: String {
        switch config {
        case .gentle: "leaf.fill"
        case .balanced: "scalemass.fill"
        case .intense: "flame.fill"
        }
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

#if DEBUG
#Preview {
    DynamicModeSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
