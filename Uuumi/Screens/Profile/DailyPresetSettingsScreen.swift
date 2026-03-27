import SwiftUI

struct DailyPresetSettingsScreen: View {
    @Environment(PetManager.self) private var petManager
    @State private var limitSettings = SharedDefaults.limitSettings

    private var todayPreset: WindPreset? {
        guard let raw = SharedDefaults.todaySelectedPreset else { return nil }
        return WindPreset(rawValue: raw)
    }

    private var defaultPreset: WindPreset {
        WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced
    }

    private var useEveryDayBinding: Binding<Bool> {
        Binding(
            get: { !limitSettings.dayStartShieldEnabled },
            set: { limitSettings.dayStartShieldEnabled = !$0 }
        )
    }

    var body: some View {
        Form {
            // MARK: - Today

            if petManager.currentPet != nil {
                Section("Today") {
                    if let preset = todayPreset {
                        HStack(spacing: 12) {
                            Image(systemName: preset.iconName)
                                .font(.title3)
                                .foregroundStyle(preset.themeColor)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.displayName)
                                    .font(.headline)

                                Text("~\(Int(preset.minutesToBlowAway)) min to blow away")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("~\(Int(preset.minutesToRecover)) min to recover")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Label("Not yet selected", systemImage: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Default Preset

            Section {
                ForEach(WindPreset.allCases, id: \.self) { preset in
                    Button {
                        HapticType.impactLight.trigger()
                        withAnimation(.snappy) {
                            limitSettings.defaultWindPresetRaw = preset.rawValue
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: preset.iconName)
                                .font(.title3)
                                .foregroundStyle(preset.themeColor)
                                .frame(width: 28, height: 28)

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

                            if preset == defaultPreset {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(preset.themeColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Default preset")
            } footer: {
                Text("Pre-selected when the daily picker appears, or used automatically if daily selection is off.")
            }

            // MARK: - Daily Selection

            Section {
                Toggle(isOn: useEveryDayBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skip daily selection")
                            .font(.body)

                        Text(limitSettings.dayStartShieldEnabled
                             ? "You'll choose a preset each morning before using your apps."
                             : "The default preset applies automatically each morning.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.blue)
            }
        }
        .navigationTitle("Daily Preset")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
    }
}

#Preview {
    NavigationStack {
        DailyPresetSettingsScreen()
    }
    .environment(PetManager.mock())
}
