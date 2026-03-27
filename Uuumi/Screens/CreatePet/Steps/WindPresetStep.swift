import SwiftUI

struct WindPresetStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator
    @State private var useEveryDay = !SharedDefaults.limitSettings.dayStartShieldEnabled

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
                        onTap: {
                            HapticType.impactLight.trigger()
                            coordinator.preset = preset
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            dailyShieldToggle
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Daily Shield Toggle

    private var dailyShieldToggle: some View {
        VStack(spacing: 8) {
            Toggle(isOn: $useEveryDay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skip daily selection")
                        .font(.subheadline.weight(.medium))

                    Text(useEveryDay
                         ? "The default preset applies automatically each morning."
                         : "You'll choose a preset each morning before using your apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)
            .padding(12)
            .glassBackground(cornerRadius: 12)
            .onChange(of: useEveryDay) { _, newValue in
                var settings = SharedDefaults.limitSettings
                settings.dayStartShieldEnabled = !newValue
                SharedDefaults.limitSettings = settings
            }
        }
    }
}

// MARK: - Wind Preset Card

struct WindPresetCard: View {
    let preset: WindPreset
    let isSelected: Bool
    let onTap: () -> Void

    private enum Layout {
        static let cornerRadius: CGFloat = 20
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

                    Text("~\(Int(preset.minutesToBlowAway)) min to blow away")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("~\(Int(preset.minutesToRecover)) min to recover")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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
