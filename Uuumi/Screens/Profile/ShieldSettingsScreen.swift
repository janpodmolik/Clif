import SwiftUI

struct ShieldSettingsScreen: View {
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var showPresetInfo = false

    private var defaultPresetBinding: Binding<WindPreset> {
        Binding(
            get: { WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced },
            set: { limitSettings.defaultWindPresetRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            // MARK: - Denní shield

            Section {
                Toggle("Denní shield", isOn: $limitSettings.dayStartShieldEnabled)
                    .tint(.blue)

                if !limitSettings.dayStartShieldEnabled {
                    Picker(selection: defaultPresetBinding) {
                        ForEach(WindPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    } label: {
                        Text("Výchozí preset")
                    }
                }
            } header: {
                HStack {
                    Text("Denní shield")
                    Spacer()
                    Button {
                        showPresetInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                if limitSettings.dayStartShieldEnabled {
                    Text("Každé ráno se zobrazí výběr presetu. Aplikace zůstanou zamčené, dokud nevybereš.")
                } else {
                    Text("Automaticky se použije výchozí preset. Aplikace nebudou ráno zamčené.")
                }
            }

            // MARK: - Safety Shield

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spustit safety shield při")
                        .fontWeight(.bold)
                    Text("Automatická ochrana při dosažení procenta větru.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                ChipPicker(
                    options: [80, 100],
                    selection: $limitSettings.safetyShieldActivationThreshold,
                    label: { "\($0) %" }
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bezpečné odemknutí pod")
                        .fontWeight(.bold)
                    Text("Vítr musí klesnout pod zvolený práh pro odemknutí bez postihu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                ChipPicker(
                    options: [0, 50, 80],
                    selection: $limitSettings.safetyUnlockThreshold,
                    label: { "\($0) %" }
                )
            }

            // MARK: - Po breaku

            Section {
                SettingsRow(
                    title: "Auto-lock po committed breaku",
                    description: "Zapne free break po dokončení committed breaku.",
                    isOn: $limitSettings.autoLockAfterCommittedBreak
                )
            }
        }
        .navigationTitle("Shield")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
        .sheet(isPresented: $showPresetInfo) {
            WindPresetComparisonSheet(
                currentPreset: WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced
            )
        }
    }
}

#Preview {
    NavigationStack {
        ShieldSettingsScreen()
    }
}
