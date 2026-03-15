import SwiftUI

struct DailyPresetPicker: View {
    @Environment(PetManager.self) private var petManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset: WindPreset = .balanced
    @State private var dontAskAgain = false

    private var currentPet: Pet? { petManager.currentPet }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: DayStartGreeting.iconName)
                        .font(.system(size: 48))
                        .foregroundStyle(DayStartGreeting.isMorning ? Color.orange.gradient : Color.blue.gradient)

                    Text(DayStartGreeting.text)
                        .font(.title.bold())

                    Text("What kind of day do you want?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Preset options
                VStack(spacing: 12) {
                    ForEach(WindPreset.allCases, id: \.self) { preset in
                        PresetOptionRow(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            withAnimation(.snappy) {
                                selectedPreset = preset
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    dontAskAgainToggle

                    // Confirm button
                    Button {
                        confirmSelection()
                    } label: {
                        Text("Start your day")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPreset.themeColor, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selectedPreset = WindPreset(rawValue: SharedDefaults.limitSettings.defaultWindPresetRaw) ?? .balanced
        }
    }

    // MARK: - Don't Ask Again Toggle

    private var dontAskAgainToggle: some View {
        VStack(spacing: 4) {
            Toggle(isOn: $dontAskAgain) {
                Text("Use this preset every day")
                    .font(.subheadline)
            }
            .tint(.blue)

            Text("You can change this anytime in Settings → Daily Preset.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

    private func confirmSelection() {
        if dontAskAgain {
            var settings = SharedDefaults.limitSettings
            settings.dayStartShieldEnabled = false
            settings.defaultWindPresetRaw = selectedPreset.rawValue
            SharedDefaults.limitSettings = settings
        }

        if let pet = currentPet {
            ScreenTimeManager.shared.applyDailyPreset(selectedPreset, for: pet)
        }
        analytics.send(.presetSelected(presetName: selectedPreset.rawValue, context: .daily))
        dismiss()
    }
}

private struct PresetOptionRow: View {
    let preset: WindPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: preset.iconName)
                    .font(.title2)
                    .foregroundStyle(preset.themeColor)
                    .frame(width: 32)

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

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(preset.themeColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? preset.themeColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? preset.themeColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }


}

#Preview {
    DailyPresetPicker()
        .environment(PetManager.mock())
        .environment(AnalyticsManager())
}
